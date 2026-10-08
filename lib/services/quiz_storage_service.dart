import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/caso_quiz.dart';

/// Capa de datos del quiz basada en **Supabase Storage** (JSON), para no
/// consumir el almacenamiento de Postgres (que ya está cerca del límite con la
/// metadata de sentencias).
///
/// Estructura en el bucket `quiz`:
///  - `casos/lote_{timestamp}.json`  -> banco de preguntas (compartido)
///  - `progreso/{uid}.json`          -> progreso de cada usuario
class QuizStorageService {
  static final _supabase = Supabase.instance.client;
  static final _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  static String? get _uid => _firebaseAuth.currentUser?.uid;
  static const String bucket = 'quiz';
  static const Duration _cooldown = Duration(hours: 24);

  final Random _random = Random();

  List<CasoQuiz>? _cacheCasos;

  // ---------------------------------------------------------------------------
  // Banco de preguntas (batches JSON)
  // ---------------------------------------------------------------------------

  /// Sube un lote de casos como un archivo JSON en Storage.
  Future<void> guardarBatch(List<CasoQuiz> casos) async {
    if (casos.isEmpty) return;
    final nombre = 'lote_${DateTime.now().millisecondsSinceEpoch}.json';
    final json = jsonEncode(casos.map((c) => c.toJson()).toList());
    await _supabase.storage.from(bucket).uploadBinary(
          'casos/$nombre',
          utf8.encode(json),
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'application/json',
          ),
        );
    _cacheCasos = null; // invalidar caché
    debugPrint('✅ Lote guardado en Storage: casos/$nombre (${casos.length} casos)');
  }

  /// Carga todos los casos del banco (descarga batches y los parsea).
  Future<List<CasoQuiz>> listarCasos() async {
    if (_cacheCasos != null) return _cacheCasos!;
    try {
      final files = await _supabase.storage.from(bucket).list(path: 'casos');
      final casos = <CasoQuiz>[];
      for (final f in files) {
        if (!f.name.endsWith('.json')) continue;
        final bytes = await _supabase.storage
            .from(bucket)
            .download('casos/${f.name}');
        final data = jsonDecode(utf8.decode(bytes)) as List<dynamic>;
        for (final item in data) {
          casos.add(CasoQuiz.fromJson(item as Map<String, dynamic>));
        }
      }
      _cacheCasos = casos;
      debugPrint('📚 Banco del quiz cargado: ${casos.length} casos');
      return casos;
    } catch (e) {
      debugPrint('❌ Error cargando banco del quiz: $e');
      return [];
    }
  }

  /// Si el banco está vacío, sube los casos iniciales (semilla).
  Future<void> sembrarInicial(List<CasoQuiz> casos) async {
    final existentes = await listarCasos();
    if (existentes.isNotEmpty) return;
    await guardarBatch(casos);
  }

  // ---------------------------------------------------------------------------
  // Selección de pregunta (anti-predecible + cooldown)
  // ---------------------------------------------------------------------------

  /// Obtiene un caso para el nivel dado, excluyendo los fallados en cooldown
  /// y priorizando no repetir los ya respondidos. Baraja las opciones.
  Future<CasoQuiz?> obtenerCaso(int nivel, {Set<String>? excluirIds}) async {
    final casos = await listarCasos();
    if (casos.isEmpty) return null;

    final tramo = _tramoDeNivel(nivel);
    final excluir = excluirIds ?? <String>{};

    // 1. Casos del tramo actual, no excluidos.
    var candidatos = casos
        .where((c) => c.tramo == tramo && !excluir.contains(c.id))
        .toList();

    // 2. Si no hay suficientes, ampliar a cualquier tramo.
    if (candidatos.length < 3) {
      candidatos = casos.where((c) => !excluir.contains(c.id)).toList();
    }

    // 3. Si aun así no hay (todo excluido), permitir repetir.
    if (candidatos.isEmpty) candidatos = casos;

    final elegido = candidatos[_random.nextInt(candidatos.length)];
    return elegido.conOpcionesBarajadas(_random);
  }

  int _tramoDeNivel(int nivel) {
    if (nivel <= 20) return 1; // parte general
    if (nivel <= 40) return 2; // delitos contra las personas
    if (nivel <= 60) return 3; // delitos contra la propiedad
    if (nivel <= 80) return 4; // COPP
    if (nivel <= 100) return 5; // delitos especiales
    return (nivel % 5) + 1;
  }

  // ---------------------------------------------------------------------------
  // Progreso por usuario (1 archivo JSON en Storage)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> progresoInicial() => {
        'nivel_actual': 1,
        'xp': 0,
        'puntos': 0,
        'racha_actual': 0,
        'racha_maxima': 0,
        'apelaciones': 5,
        'ultima_regeneracion': DateTime.now().toIso8601String(),
        'falladas': <Map<String, dynamic>>[],
        'respondidas': <String>[],
      };

  Future<Map<String, dynamic>> cargarProgreso() async {
    final uid = _uid;
    if (uid == null) return progresoInicial();
    try {
      final bytes = await _supabase.storage
          .from(bucket)
          .download('progreso/$uid.json');
      final data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return progresoInicial();
    }
  }

  Future<void> guardarProgreso(Map<String, dynamic> progreso) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _supabase.storage.from(bucket).uploadBinary(
            'progreso/$uid.json',
            utf8.encode(jsonEncode(progreso)),
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'application/json',
            ),
          );
    } catch (e) {
      debugPrint('❌ Error guardando progreso del quiz: $e');
    }
  }

  static const int _maxApelaciones = 5;
  static const int _baseMinutos = 5;

  /// Tiempo acumulado (minutos) para regenerar N apelaciones: 5, 15, 30, 50, 75.
  /// La 1ª tarda 5 min y el resto se va prolongando.
  static int _minutosPara(int n) {
    var total = 0;
    for (var i = 1; i <= n; i++) {
      total += _baseMinutos * i;
    }
    return total;
  }

  /// Regenera apelaciones con curva progresiva.
  Map<String, dynamic> regenerarApelaciones(Map<String, dynamic> progreso) {
    final copia = Map<String, dynamic>.from(progreso);
    final actual = (copia['apelaciones'] as num?)?.toInt() ?? _maxApelaciones;
    final faltantes = _maxApelaciones - actual;
    if (faltantes <= 0) return copia;

    final ahora = DateTime.now();
    final ultima =
        DateTime.tryParse(copia['ultima_regeneracion'] as String? ?? '');
    final base = ultima ?? ahora;
    final elapsedMin = ahora.difference(base).inMinutes;

    var regeneradas = 0;
    for (var k = 1; k <= faltantes; k++) {
      if (elapsedMin >= _minutosPara(k)) regeneradas = k;
    }
    if (regeneradas > 0) {
      copia['apelaciones'] = (actual + regeneradas).clamp(0, _maxApelaciones);
    }
    return copia;
  }

  /// Tiempo restante para la próxima apelación (null si ya está lleno).
  static Duration? tiempoSiguienteApelacion(Map<String, dynamic> progreso) {
    final actual = (progreso['apelaciones'] as num?)?.toInt() ?? _maxApelaciones;
    final faltantes = _maxApelaciones - actual;
    if (faltantes <= 0) return null;

    final ahora = DateTime.now();
    final ultima =
        DateTime.tryParse(progreso['ultima_regeneracion'] as String? ?? '');
    final base = ultima ?? ahora;
    final elapsedMin = ahora.difference(base).inMinutes;

    var regeneradas = 0;
    for (var k = 1; k <= faltantes; k++) {
      if (elapsedMin >= _minutosPara(k)) regeneradas = k;
    }
    final siguiente = regeneradas + 1;
    if (siguiente > faltantes) return null;

    final target = Duration(minutes: _minutosPara(siguiente));
    final restante = target - ahora.difference(base);
    return restante.isNegative ? Duration.zero : restante;
  }

  /// IDs a excluir: falladas dentro del cooldown + ya respondidas.
  Set<String> idsExcluidos(Map<String, dynamic> progreso) {
    final excluir = <String>{};
    final ahora = DateTime.now();

    final falladas = (progreso['falladas'] as List<dynamic>? ?? const []);
    for (final f in falladas) {
      final map = f as Map<String, dynamic>;
      final ultima = DateTime.tryParse(map['ultima'] as String? ?? '');
      if (ultima != null && ahora.difference(ultima) < _cooldown) {
        excluir.add(map['caso_id'] as String);
      }
    }

    final respondidas = (progreso['respondidas'] as List<dynamic>? ?? const []);
    excluir.addAll(respondidas.map((e) => e.toString()));

    return excluir;
  }

  /// Registra un fallo (para el cooldown de "no repetir").
  Map<String, dynamic> registrarFallo(
      Map<String, dynamic> progreso, String casoId) {
    final falladas =
        (progreso['falladas'] as List<dynamic>? ?? const []).toList();
    final idx = falladas.indexWhere((f) => (f as Map)['caso_id'] == casoId);
    final ahora = DateTime.now().toIso8601String();
    if (idx >= 0) {
      final m = (falladas[idx] as Map<String, dynamic>);
      m['veces'] = ((m['veces'] as num?)?.toInt() ?? 0) + 1;
      m['ultima'] = ahora;
      falladas[idx] = m;
    } else {
      falladas.add({'caso_id': casoId, 'veces': 1, 'ultima': ahora});
    }
    final copia = Map<String, dynamic>.from(progreso);
    copia['falladas'] = falladas;
    return copia;
  }

  /// Registra un logro (certificado) en el progreso del usuario.
  Map<String, dynamic> registrarLogro(
      Map<String, dynamic> progreso, Map<String, dynamic> logro) {
    final copia = Map<String, dynamic>.from(progreso);
    final logros = (copia['logros'] as List<dynamic>? ?? const []).toList();
    logros.add(logro);
    copia['logros'] = logros;
    return copia;
  }

  /// Registra un acierto (marca la pregunta como respondida).
  Map<String, dynamic> registrarAcierto(
      Map<String, dynamic> progreso, String casoId) {
    final respondidas =
        (progreso['respondidas'] as List<dynamic>? ?? const []).toList();
    if (!respondidas.contains(casoId)) respondidas.add(casoId);
    final copia = Map<String, dynamic>.from(progreso);
    copia['respondidas'] = respondidas;
    return copia;
  }
}

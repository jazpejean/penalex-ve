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
///  - `casos_usuario/{uid}/lote_{timestamp}.json` -> banco PERSONAL de preguntas
///    de cada usuario (cada quien recibe casos hipotéticos únicos generados
///    para él; no hay banco compartido).
///  - `progreso/{uid}.json`                       -> progreso de cada usuario
///
/// Diseño "sin materias": NO hay tramos. Todos los casos son casos hipotéticos
/// aplicados de cualquier área del derecho penal; la selección es aleatoria de
/// todo el banco personal, excluyendo falladas (reposo hasta agotar el banco)
/// y respondidas (nunca se repiten).
class QuizStorageService {
  static final _supabase = Supabase.instance.client;
  static final _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  /// UID de sesión; si Firebase no está disponible (arranque, red caída) se
  /// devuelve null: el quiz continúa con el progreso por defecto en vez de
  /// romper la inicialización de la pantalla.
  static String? get _uid {
    try {
      return _firebaseAuth.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }
  static const String bucket = 'quiz';

  /// UID de sesión público (para el sync por usuario).
  static String? get uidSesion => _uid;

  final Random _random = Random();

  List<CasoQuiz>? _cacheCasos;
  String? _cacheUid;

  /// Prefijo del banco personal del usuario actual.
  static String get _rutaCasos {
    final uid = _uid;
    return uid == null ? 'casos' : 'casos_usuario/$uid';
  }

  // ---------------------------------------------------------------------------
  // Banco de preguntas (batches JSON por usuario)
  // ---------------------------------------------------------------------------

  /// Sube un lote de casos como un archivo JSON en Storage (banco personal).
  Future<void> guardarBatch(List<CasoQuiz> casos) async {
    if (casos.isEmpty) return;
    final nombre = 'lote_${DateTime.now().millisecondsSinceEpoch}.json';
    final json = jsonEncode(casos.map((c) => c.toJson()).toList());
    await _supabase.storage.from(bucket).uploadBinary(
          '$_rutaCasos/$nombre',
          utf8.encode(json),
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'application/json',
          ),
        );
    _cacheCasos = null; // invalidar caché
    _cacheUid = _uid;
    debugPrint('✅ Lote guardado en Storage: $_rutaCasos/$nombre (${casos.length} casos)');
  }

  /// Carga todos los casos del banco PERSONAL del usuario (descarga batches y
  /// los parsea). La caché se invalida si cambia el usuario.
  Future<List<CasoQuiz>> listarCasos() async {
    final uid = _uid;
    if (_cacheCasos != null && _cacheUid == uid) return _cacheCasos!;
    _cacheCasos = null;
    try {
      final files = await _supabase.storage
          .from(bucket)
          .list(path: _rutaCasos);
      final casos = <CasoQuiz>[];
      for (final f in files) {
        if (!f.name.endsWith('.json')) continue;
        final bytes = await _supabase.storage
            .from(bucket)
            .download('$_rutaCasos/${f.name}');
        final data = jsonDecode(utf8.decode(bytes)) as List<dynamic>;
        for (final item in data) {
          casos.add(CasoQuiz.fromJson(item as Map<String, dynamic>));
        }
      }
      _cacheCasos = casos;
      _cacheUid = uid;
      debugPrint('📚 Banco personal del quiz cargado: ${casos.length} casos');
      return casos;
    } catch (e) {
      debugPrint('❌ Error cargando banco del quiz: $e');
      return [];
    }
  }

  /// Si el banco personal está vacío, sube los casos iniciales (semilla).
  Future<void> sembrarInicial(List<CasoQuiz> casos) async {
    final existentes = await listarCasos();
    if (existentes.isNotEmpty) return;
    await guardarBatch(casos);
  }

  // ---------------------------------------------------------------------------
  // Selección de pregunta (anti-predecible + reposo estricto)
  // ---------------------------------------------------------------------------

  /// Obtiene un caso hipotético de TODO el banco personal (sin materias),
  /// excluyendo falladas en reposo y respondidas. Baraja las opciones.
  Future<CasoQuiz?> obtenerCaso({
    Set<String>? excluirIds,
    List<int>? dificultadesPreferidas,
  }) async {
    final casos = await listarCasos();
    if (casos.isEmpty) return null;

    final excluir = excluirIds ?? <String>{};

    // 1. Casos disponibles (no fallados en reposo, no respondidos).
    var candidatos = casos.where((c) => !excluir.contains(c.id)).toList();

    // 2. Progresión por carrera judicial: si hay dificultades objetivo, se
    //    filtra por ellas en orden de preferencia. Si el banco no tiene de esa
    //    dificultad, se cae a la siguiente preferida y finalmente a cualquiera
    //    (nunca se queda sin caso).
    if (dificultadesPreferidas != null && dificultadesPreferidas.isNotEmpty) {
      for (final d in dificultadesPreferidas) {
        final filtrados = candidatos.where((c) => c.dificultad == d).toList();
        if (filtrados.isNotEmpty) {
          return filtrados[_random.nextInt(filtrados.length)]
              .conOpcionesBarajadas(_random);
        }
      }
    }

    // 3. Si el banco personal se agotó (todo respondido o en reposo), permite
    //    repetir los fallados para que la sesión no se quede sin casos.
    if (candidatos.isEmpty) candidatos = casos;

    final elegido = candidatos[_random.nextInt(candidatos.length)];
    return elegido.conOpcionesBarajadas(_random);
  }

  // ---------------------------------------------------------------------------
  // Progreso por usuario (1 archivo JSON en Storage)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> progresoInicial() => {
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

  /// IDs a excluir: TODAS las falladas (reposo hasta agotar el banco personal)
  /// + ya respondidas (nunca se repiten).
  Set<String> idsExcluidos(Map<String, dynamic> progreso) {
    final excluir = <String>{};

    // Reposo temporal: una pregunta fallada queda fuera hasta que vence su
    // reposo (1, 2 o 4 días según las veces falladas). Al vencer vuelve para
    // repaso; si se acierta, pasa a "respondidas" y no se repite más.
    final ahora = DateTime.now();
    final falladas = (progreso['falladas'] as List<dynamic>? ?? const []);
    for (final f in falladas) {
      final map = f as Map<String, dynamic>;
      final hasta = DateTime.tryParse(map['reposo_hasta'] as String? ?? '');
      if (hasta == null || hasta.isAfter(ahora)) {
        excluir.add(map['caso_id'] as String);
      }
    }

    final respondidas = (progreso['respondidas'] as List<dynamic>? ?? const []);
    excluir.addAll(respondidas.map((e) => e.toString()));

    return excluir;
  }

  /// Registra un fallo (para el cooldown de "no repetir").
  /// Reposo base de una pregunta fallada: no reaparece en la misma sesión y
  /// vuelve para repaso al día siguiente (se duplica con cada fallo nuevo).
  static Duration _reposoPorFallos(int veces) {
    switch (veces) {
      case 1:
        return const Duration(days: 1);
      case 2:
        return const Duration(days: 2);
      default:
        return const Duration(days: 4);
    }
  }

  Map<String, dynamic> registrarFallo(
      Map<String, dynamic> progreso, String casoId) {
    final falladas =
        (progreso['falladas'] as List<dynamic>? ?? const []).toList();
    final idx = falladas.indexWhere((f) => (f as Map)['caso_id'] == casoId);
    final ahora = DateTime.now();
    final ahoraIso = ahora.toIso8601String();
    if (idx >= 0) {
      final m = (falladas[idx] as Map<String, dynamic>);
      final veces = ((m['veces'] as num?)?.toInt() ?? 0) + 1;
      m['veces'] = veces;
      m['ultima'] = ahoraIso;
      m['reposo_hasta'] = ahora.add(_reposoPorFallos(veces)).toIso8601String();
      falladas[idx] = m;
    } else {
      falladas.add({
        'caso_id': casoId,
        'veces': 1,
        'ultima': ahoraIso,
        'reposo_hasta':
            ahora.add(_reposoPorFallos(1)).toIso8601String(),
      });
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
    // Si estaba en reposo por fallo y ahora se acierta, sale del reposo.
    final falladas =
        (progreso['falladas'] as List<dynamic>? ?? const []).toList();
    falladas.removeWhere((f) => (f as Map)['caso_id'] == casoId);
    copia['falladas'] = falladas;
    return copia;
  }
}

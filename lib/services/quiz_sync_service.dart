import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/caso_quiz.dart';
import 'quiz_storage_service.dart';
import 'quiz_validador_service.dart';

/// Sincroniza los lotes VALIDADOS del worker (bucket `quiz/pendientes/` en
/// Supabase) hacia el banco local de la app (`quiz/casos/`).
///
/// Pipeline de cero error (sin revisión humana):
///  1. Descarga cada lote pendiente.
///  2. Pasa CADA caso por [QuizValidadorService] (gate 100% máquina: cita
///     por ley, fundamentación literal, firma de elementos, ambigüedad,
///     penas desde el corpus, dedup).
///  3. Solo los casos aprobados entran al banco local.
///  4. El lote se elimina de `pendientes/` (procesado = descartado).
///
/// El generador local (DeepSeek) queda como respaldo ÚNICO si no hay lote
/// pendiente y el banco está bajo el umbral.
class QuizSyncService {
  static bool _sincronizando = false;
  static List<LeyCorpus>? _corpusCache;

  /// Importa los lotes pendientes validados. Devuelve cuántos casos entraron
  /// al banco local. Idempotente y seguro de reintentar (los lotes solo se
  /// borran cuando se procesaron completos).
  static Future<int> sincronizarPendientes({List<LeyCorpus>? corpus}) async {
    if (_sincronizando) return 0;
    _sincronizando = true;
    var importados = 0;
    try {
      final supabase = Supabase.instance.client;
      final objs = await supabase.storage.from('quiz').list(path: 'pendientes');
      if (objs.isEmpty) return 0;
      final leyes = corpus ?? await _cargarCorpusAssets();
      final validador = QuizValidadorService();
      final existentes = await QuizStorageService().listarCasos();
      final idsPrevios = existentes.map((c) => c.id).toSet();

      for (final obj in objs) {
        try {
          final bytes = await supabase.storage
              .from('quiz')
              .download('pendientes/${obj.name}');
          final json = jsonDecode(utf8.decode(bytes));
          final casos = json is List
              ? json
              : (json as Map<String, dynamic>)['casos'] as List?;
          if (casos == null) continue;

          final aprobados = <CasoQuiz>[];
          for (final c in casos) {
            if (c is! Map) continue;
            final v = validador.validarCaso(
              c.cast<String, dynamic>(),
              leyes,
              idsPrevios: idsPrevios,
            );
            if (!v.valido) {
              debugPrint('🗑️ Lote ${obj.name}: caso descartado: ${v.errores.first}');
              continue;
            }
            final formato = QuizValidadorService.aFormatoApp(
                c.cast<String, dynamic>());
            final caso = CasoQuiz.fromJson(formato);
            if (!idsPrevios.add(caso.id)) continue; // dedup en memoria
            aprobados.add(caso);
          }

          if (aprobados.isNotEmpty) {
            await QuizStorageService().guardarBatch(aprobados);
            importados += aprobados.length;
            debugPrint('✅ Sync: ${aprobados.length} casos del lote ${obj.name}');
          }
          // Procesado = eliminado (los rechazados quedan descartados; el
          // reporte de errores del usuario sirve de cuarentena posterior).
          await supabase.storage
              .from('quiz')
              .remove(['pendientes/${obj.name}']);
        } catch (e) {
          // No se borra el lote si falla su procesamiento (reintento seguro).
          debugPrint('⚠️ Lote ${obj.name} no procesado: $e');
        }
      }
      return importados;
    } catch (e) {
      debugPrint('⚠️ Sync quiz pendientes falló: $e');
      return importados;
    } finally {
      _sincronizando = false;
    }
  }

  /// Carga el corpus de leyes desde los assets locales (esquema local:
  /// {secciones, articulos:[{numero_texto, parrafos}]}) — cacheado.
  static Future<List<LeyCorpus>> _cargarCorpusAssets() async {
    if (_corpusCache != null) return _corpusCache!;
    const dir = 'assets/data/leyes';
    // _indice.json es un dict con "leyes": [{"id": "codigo_penal_2005", ...}];
    // el archivo JSON real es "<id>.json". Respaldo: lista de leyes críticas
    // que el worker puede citar (si el índice fallara).
    const criticas = [
      'codigo_penal_2005.json',
      'codigo_organico_procesal_penal_2021.json',
      'ley_organica_de_drogas_2010.json',
      'ley_organica_para_la_proteccion_de_ninos_ninas_y_adolescentes_2015.json',
      'ley_contra_la_corrupcion_2022.json',
      'ley_contra_el_secuestro_y_la_extorsion_2009.json',
      'ley_especial_contra_los_delitos_informaticos_2001.json',
      'ley_organica_contra_la_delincuencia_organizada_y_financiamiento_al_terrorismo_2012.json',
      'ley_organica_sobre_el_derecho_de_las_mujeres_a_una_vida_libre_de_violencia_2021.json',
    ];
    var nombres = <String>[];
    try {
      final indice =
          jsonDecode(await rootBundle.loadString('$dir/_indice.json'));
      if (indice is Map<String, dynamic>) {
        nombres = ((indice['leyes'] as List?) ?? const [])
            .map((e) => '${(e as Map)['id']}.json')
            .toList();
      } else if (indice is List) {
        nombres = indice.map((e) => e.toString()).toList();
      }
    } catch (e) {
      debugPrint('⚠️ _indice.json no legible: $e');
    }
    for (final c in criticas) {
      if (!nombres.contains(c)) nombres.add(c);
    }

    final leyes = <LeyCorpus>[];
    final vistos = <String>{};
    for (final nombre in nombres) {
      if (!nombre.endsWith('.json') || !vistos.add(nombre)) continue;
      try {
        final raw = await rootBundle.loadString('$dir/$nombre');
        leyes.add(QuizValidadorService.cargarLey(
          jsonDecode(raw) as Map<String, dynamic>,
          nombre,
        ));
      } catch (e) {
        debugPrint('⚠️ Corpus $nombre no cargado: $e');
      }
    }
    _corpusCache = leyes;
    return leyes;
  }
}
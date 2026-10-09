// Validador de preguntas del quiz (CLI).
//
// Uso:
// ignore_for_file: avoid_relative_lib_imports, avoid_print
//   dart tool/validar_preguntas.dart <lote.json> [--corpus DIR] [--salida FILE]
//
// - <lote.json>: archivo con una lista de casos (o {"casos": [...]}).
// - --corpus: directorio con los JSON de leyes (esquema del bucket de
//   Supabase o assets locales; por defecto assets/data/leyes).
// - --salida: archivo donde se escriben SOLO los casos aprobados (formato
//   de la app: CasoQuiz.toJson). Sin --salida, solo imprime el diagnóstico.
//
// Salida: una línea por caso con VALIDO/NO VALIDO + motivos, y un resumen.
import 'dart:convert';
import 'dart:io';

import '../lib/services/quiz_validador_service.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Uso: dart tool/validar_preguntas.dart <lote.json> '
        '[--corpus DIR] [--salida FILE]');
    exit(2);
  }

  final lotePath = args.first;
  var corpusDir = 'assets/data/leyes';
  String? salida;
  for (var i = 1; i < args.length; i++) {
    if (args[i] == '--corpus' && i + 1 < args.length) {
      corpusDir = args[i + 1];
      i++;
    } else if (args[i] == '--salida' && i + 1 < args.length) {
      salida = args[i + 1];
      i++;
    }
  }

  // Cargar corpus -----------------------------------------------------------
  final dir = Directory(corpusDir);
  if (!dir.existsSync()) {
    stderr.writeln('Directorio de corpus no existe: $corpusDir');
    exit(2);
  }
  final corpus = <LeyCorpus>[];
  for (final f in dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))) {
    try {
      final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      corpus.add(QuizValidadorService.cargarLey(json, f.uri.pathSegments.last));
    } catch (e) {
      stderr.writeln('Omitiendo ${f.path} (JSON inválido): $e');
    }
  }
  if (corpus.isEmpty) {
    stderr.writeln('Sin leyes cargadas desde $corpusDir');
    exit(2);
  }

  // Cargar lote --------------------------------------------------------------
  final raw = jsonDecode(File(lotePath).readAsStringSync());
  final casos = raw is List
      ? raw.cast<Map<String, dynamic>>()
      : (raw as Map<String, dynamic>)['casos'] as List<dynamic>;

  // Validar ------------------------------------------------------------------
  final service = QuizValidadorService();
  var validos = 0;
  final aprobados = <Map<String, dynamic>>[];
  for (var i = 0; i < casos.length; i++) {
    final c = (casos[i] as Map).cast<String, dynamic>();
    final v = service.validarCaso(c, corpus);
    final nro = c['id'] ?? (i + 1);
    if (v.valido) {
      validos++;
      aprobados.add(QuizValidadorService.aFormatoApp(c));
      stdout.writeln('  ✅ CASO $nro: VALIDO');
    } else {
      stdout.writeln('  ❌ CASO $nro: NO VALIDO');
      for (final e in v.errores) {
        stdout.writeln('      - $e');
      }
    }
    for (final a in v.advertencias) {
      stdout.writeln('      ⚠ $a');
    }
  }

  stdout.writeln('---');
  stdout.writeln('RESUMEN: $validos/${casos.length} casos aprobados '
      '(corpus: ${corpus.length} leyes desde $corpusDir)');

  if (salida != null) {
    File(salida).writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(aprobados));
    stdout.writeln('Aprobados escritos en: $salida');
  }
}
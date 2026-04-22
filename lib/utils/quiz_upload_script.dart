import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class QuizUploadScript {
  static Future<void> uploadAllQuizQuestions() async {
    await massUploadQuiz();
  }
}

Future<void> massUploadQuiz() async {
  final List<String> jsonFiles = <String>[
    'assets/data/deepseek_json_part1.json',
    'assets/data/deepseek_json_part2.json',
  ];

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  int totalSubido = 0;
  int batchCount = 0;

  for (final assetPath in jsonFiles) {
    try {
      debugPrint('📂 Procesando archivo: $assetPath');

      final String jsonString = await rootBundle.loadString(assetPath);
      final List<dynamic> data = json.decode(jsonString);

      debugPrint('📊 Encontradas ${data.length} preguntas en $assetPath');

      const int batchSize = 400;
      for (int i = 0; i < data.length; i += batchSize) {
        final WriteBatch batch = firestore.batch();
        final int endIndex = (i + batchSize < data.length) ? i + batchSize : data.length;

        for (int j = i; j < endIndex; j++) {
          final dynamic item = data[j];
          final String docId = 'nivel_${item['nivel']}_pregunta_${j + 1}';
          final DocumentReference docRef = firestore.collection('preguntas').doc(docId);

          batch.set(docRef, <String, dynamic>{
            'nivel': item['nivel'] ?? 1,
            'pregunta': item['pregunta'] ?? '',
            'opciones': item['opciones'] ?? <dynamic>[],
            'respuesta_correcta': item['respuesta_correcta'] ?? 0,
            'fundamentacion': item['fundamentacion'] ?? '',
            'fecha_carga': FieldValue.serverTimestamp(),
            'activo': true,
          });
        }

        await batch.commit();
        batchCount++;
        final int batchUploaded = endIndex - i;
        totalSubido += batchUploaded;
        debugPrint('✅ Batch $batchCount: $batchUploaded preguntas subidas');
      }
    } on Exception catch (e) {
      debugPrint('❌ Error procesando $assetPath: $e');
    }
  }

  debugPrint('🚀 CARGA COMPLETADA');
  debugPrint('📈 Total de preguntas en Firebase: $totalSubido');
  debugPrint('📦 Total de batches procesados: $batchCount');
}
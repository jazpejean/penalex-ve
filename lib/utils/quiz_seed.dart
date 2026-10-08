import 'package:flutter/foundation.dart';

import '../data/quiz_questions_data.dart';
import '../models/caso_quiz.dart';
import '../services/quiz_storage_service.dart';

/// Semilla inicial del banco de preguntas (aprovecha los 25 casos ya escritos
/// en [QuizQuestionsData]). Es idempotente: solo sube si el banco está vacío.
/// Los casos generados con IA (con fundamentación) los añade el generador.
Future<void> sembrarCasosIniciales() async {
  try {
    final service = QuizStorageService();
    final existentes = await service.listarCasos();
    if (existentes.isNotEmpty) return;

    // Niveles representativos para extraer los 25 casos únicos (5 por tramo).
    const niveles = <int>[
      1, 2, 3, 4, 5, // parte general
      21, 22, 23, 24, 25, // personas
      41, 42, 43, 44, 45, // propiedad
      61, 62, 63, 64, 65, // COPP
      81, 82, 83, 84, 85, // especiales
    ];

    final casos = <CasoQuiz>[];
    for (final n in niveles) {
      final c = QuizQuestionsData.getCasoForLevel(n);
      casos.add(CasoQuiz(
        id: c.id,
        nivel: c.nivel,
        tramo: _tramo(n),
        delitoBase: c.delitoBase,
        contextoNarrativo: c.contextoNarrativo,
        opciones: c.opciones,
        respuestaCorrecta: c.respuestaCorrecta,
        dificultad: c.dificultad,
        // La fundamentación detallada la aporta el generador de IA.
        fundamentacion: '',
        articulos: const [],
        sentencias: const [],
      ));
    }

    await service.guardarBatch(casos);
    debugPrint('🌱 Semilla inicial: ${casos.length} casos subidos a Storage');
  } catch (e) {
    debugPrint('❌ Error sembrando casos iniciales: $e');
  }
}

int _tramo(int nivel) {
  if (nivel <= 20) return 1;
  if (nivel <= 40) return 2;
  if (nivel <= 60) return 3;
  if (nivel <= 80) return 4;
  return 5;
}

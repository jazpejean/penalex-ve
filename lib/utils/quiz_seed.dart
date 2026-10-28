import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

import '../data/quiz_questions_data.dart';
import '../models/caso_quiz.dart';
import '../services/quiz_generador_local_service.dart';
import '../services/quiz_storage_service.dart';

/// Semilla inicial del banco PERSONAL de preguntas (casos hipotéticos
/// aplicados de todo el derecho penal — sin materias). Es idempotente: solo
/// sube si el banco personal del usuario está vacío.
///
/// Fuente por defecto: el [QuizGeneradorLocalService], que construye casos
/// desde el corpus local de leyes con fundamentación literal (se muestra
/// in-app al fallar/acertar). Los 25 casos manuales quedan solo como respaldo
/// si el generador local no produce nada. Cuando el usuario recargue saldo de
/// IA, el worker genera casos hipotéticos ÚNICOS por usuario (nada compartido).
Future<void> sembrarCasosIniciales() async {
  try {
    final service = QuizStorageService();
    final existentes = await service.listarCasos();
    if (existentes.isNotEmpty) return;

    // Piso local: cientos de casos base con fundamentación real del corpus.
    var casos = await QuizGeneradorLocalService.generarCasosBase(cantidad: 300);

    // Respaldo: si el corpus no dio casos, usar los 25 manuales escritos.
    if (casos.isEmpty) {
      casos = _casosManuales();
    }

    // Mezcla por usuario: el orden en el banco personal es propio de cada
    // jugador (semilla derivada de su UID), así nadie recorre la misma
    // secuencia. Con el banco real (IA) cada usuario tendrá casos distintos.
    final rng = Random(_seedUsuario());
    casos.shuffle(rng);

    await service.guardarBatch(casos);
    debugPrint('🌱 Semilla personal: ${casos.length} casos subidos a Storage');
  } catch (e) {
    debugPrint('❌ Error sembrando casos iniciales: $e');
  }
}

/// Los 25 casos manuales ya escritos (respaldo sin fundamentación IA).
List<CasoQuiz> _casosManuales() {
  // Niveles representativos para extraer los 25 casos únicos.
  const niveles = <int>[
    1, 2, 3, 4, 5, // teoría del delito
    21, 22, 23, 24, 25, // delitos contra las personas
    41, 42, 43, 44, 45, // delitos contra la propiedad
    61, 62, 63, 64, 65, // COPP
    81, 82, 83, 84, 85, // delitos especiales
  ];
  final casos = <CasoQuiz>[];
  for (final n in niveles) {
    final c = QuizQuestionsData.getCasoForLevel(n);
    casos.add(CasoQuiz(
      id: c.id,
      nivel: 0, // sin nivel numérico: la progresión es la carrera judicial
      tramo: 0, // sin materias: todos los casos se mezclan
      delitoBase: c.delitoBase,
      contextoNarrativo: c.contextoNarrativo,
      opciones: c.opciones,
      respuestaCorrecta: c.respuestaCorrecta,
      dificultad: c.dificultad,
      fundamentacion: '',
      articulos: const [],
      sentencias: const [],
    ));
  }
  return casos;
}

/// Semilla estable por usuario para la mezcla del banco personal.
int _seedUsuario() {
  try {
    final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid ?? '';
    return uid.hashCode & 0x7fffffff;
  } catch (_) {
    return DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
  }
}
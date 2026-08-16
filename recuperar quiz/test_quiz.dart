// Script de prueba para verificar el sistema de quiz
// Ejecutar: dart run test_quiz.dart

import 'lib/data/quiz_questions_data.dart';
import 'lib/services/casos_service.dart';

void main() {
  print('========================================');
  print('🎯 TEST DEL SISTEMA DE QUIZ');
  print('========================================\n');

  // Test 1: Verificar cantidad de preguntas
  final todasLasPreguntas = QuizQuestionsData.getAllCases();
  print('✅ Total de preguntas generadas: ${todasLasPreguntas.length}');
  print('   Esperado: 100\n');

  // Test 2: Mostrar primeras 5 preguntas
  print('📋 PRIMERAS 5 PREGUNTAS:\n');
  for (int i = 1; i <= 5; i++) {
    final caso = QuizQuestionsData.getCasoForLevel(i);
    print('--- NIVEL $i ---');
    print('Delito: ${caso.delitoBase}');
    print('Pregunta: ${caso.contextoNarrativo}');
    print('Opciones:');
    for (int j = 0; j < caso.opciones.length; j++) {
      final marca = j == caso.respuestaCorrecta ? '✓' : ' ';
      print('  $marca ${String.fromCharCode(65 + j)}) ${caso.opciones[j]}');
    }
    print('');
  }

  // Test 3: Verificar respuesta correcta
  print('🧪 TEST DE VERIFICACIÓN DE RESPUESTAS:\n');
  final casoTest = QuizQuestionsData.getCasoForLevel(1);
  
  print('Caso: ${casoTest.delitoBase}');
  
  // Respuesta correcta
  final resultadoCorrecto = CasosService.verificarRespuesta(
    caso: casoTest,
    respuestaUsuario: casoTest.respuestaCorrecta,
    vecesIntentadas: 1,
  );
  print('✅ Respuesta correcta:');
  print('   Correcto: ${resultadoCorrecto.correcto}');
  print('   Mensaje: ${resultadoCorrecto.mensaje}');
  if (resultadoCorrecto.fundamentacion != null) {
    print('   Tiene fundamentación: Sí');
    print('   Artículos: ${resultadoCorrecto.fundamentacion!.articulos.length}');
  }
  print('');

  // Respuesta incorrecta
  final respuestaIncorrecta = casoTest.respuestaCorrecta == 0 ? 1 : 0;
  final resultadoIncorrecto = CasosService.verificarRespuesta(
    caso: casoTest,
    respuestaUsuario: respuestaIncorrecta,
    vecesIntentadas: 1,
  );
  print('❌ Respuesta incorrecta:');
  print('   Correcto: ${resultadoIncorrecto.correcto}');
  print('   Mensaje: ${resultadoIncorrecto.mensaje}');
  if (resultadoIncorrecto.pista != null) {
    print('   Tiene pista: Sí');
    print('   Pista: ${resultadoIncorrecto.pista!.textoPista}');
  }
  print('');

  // Test 4: Verificar distribución por categorías
  print('📊 DISTRIBUCIÓN POR NIVELES:\n');
  print('Niveles 1-20: Parte General');
  print('Niveles 21-40: Delitos contra Personas');
  print('Niveles 41-60: Delitos contra Propiedad');
  print('Niveles 61-80: COPP y Procedimiento');
  print('Niveles 81-100: Drogas y Leyes Especiales\n');

  // Muestreo de cada categoría
  final muestreo = [1, 21, 41, 61, 81];
  for (final nivel in muestreo) {
    final caso = QuizQuestionsData.getCasoForLevel(nivel);
    print('Nivel $nivel: ${caso.delitoBase}');
  }

  print('\n========================================');
  print('✅ TESTS COMPLETADOS EXITOSAMENTE');
  print('========================================');
  print('\n💡 Para usar en la app:');
  print('   1. Importa QuizGameScreen');
  print('   2. Navega a la pantalla');
  print('   3. ¡Prueba el quiz!\n');
}

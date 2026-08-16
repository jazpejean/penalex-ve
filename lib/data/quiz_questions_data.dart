// ============================================================================
// BANCO DE 100 PREGUNTAS DE PRUEBA - DERECHO PENAL VENEZOLANO
// Sistema de Quiz Gamificado con Casos Hipotéticos
// ============================================================================

import '../models/caso_hipotetico_model.dart';

/// Pool de 5 casos por cada nivel (rotación anti-trampa)
/// Distribución: 100 niveles × 5 casos = 500 casos totales
/// Solo para testing inicial, luego migrar a Supabase

class QuizQuestionsData {
  
  // ========== NIVELES 1-10: PARTE GENERAL - TEORÍA DEL DELITO ==========
  
  static final List<CasoHipotetico> _nivel1Pool = [
    CasoHipotetico(
      id: 'caso_1_1',
      nivel: 1,
      poolId: 1,
      delitoBase: 'Tentativa de Hurto',
      contextoNarrativo: 'José intenta robar un celular de una mesa en un café, pero el dueño lo ve y lo detiene antes de que pueda salir del local. ¿Cuál es la calificación jurídica correcta?',
      opciones: [
        'Hurto consumado (Art. 453 CP)',
        'Tentativa de hurto (Art. 80 + 453 CP)',
        'Apropiación indebida (Art. 470 CP)',
        'Acto preparatorio impune',
      ],
      respuestaCorrecta: 1,
      dificultad: 1,
    ),
    CasoHipotetico(
      id: 'caso_1_2',
      nivel: 1,
      poolId: 2,
      delitoBase: 'Legítima Defensa',
      contextoNarrativo: 'María es atacada con un cuchillo en la calle. Para defenderse, toma una piedra y golpea al agresor causándole lesiones leves. ¿Cuál es su situación jurídica?',
      opciones: [
        'Homicidio intencional (Art. 405 CP)',
        'Lesiones personales graves (Art. 413 CP)',
        'Legítima defensa eximente (Art. 65.3 CP)',
        'Riña mutua (Art. 424 CP)',
      ],
      respuestaCorrecta: 2,
      dificultad: 1,
    ),
    CasoHipotetico(
      id: 'caso_1_3',
      nivel: 1,
      poolId: 3,
      delitoBase: 'Participación Criminal',
      contextoNarrativo: 'Pedro conduce el vehículo mientras su amigo roba un banco, sin saber los detalles pero consciente del delito. ¿Cuál es su rol?',
      opciones: [
        'Cómplice necesario (Art. 84 CP)',
        'Autor inmediato (Art. 83 CP)',
        'Encubridor (Art. 256 CP)',
        'Sin responsabilidad penal',
      ],
      respuestaCorrecta: 0,
      dificultad: 1,
    ),
    CasoHipotetico(
      id: 'caso_1_4',
      nivel: 1,
      poolId: 4,
      delitoBase: 'Error de Tipo',
      contextoNarrativo: 'Carlos dispara pensando que está cazando un venado, pero resulta ser una persona. No tenía intención de matar. ¿Qué figura aplica?',
      opciones: [
        'Homicidio intencional (Art. 405 CP)',
        'Homicidio culposo (Art. 409 CP)',
        'Error de tipo esencial (Art. 61 CP)',
        'Caso fortuito (Art. 62 CP)',
      ],
      respuestaCorrecta: 2,
      dificultad: 1,
    ),
    CasoHipotetico(
      id: 'caso_1_5',
      nivel: 1,
      poolId: 5,
      delitoBase: 'Autoría Mediata',
      contextoNarrativo: 'Un jefe ordena a su empleado menor de edad cometer un robo, usando su autoridad. ¿Cómo se tipifica la conducta del jefe?',
      opciones: [
        'Instigador (Art. 84 CP)',
        'Autor mediato (Art. 83 CP)',
        'Cómplice (Art. 84 CP)',
        'Sin responsabilidad',
      ],
      respuestaCorrecta: 1,
      dificultad: 1,
    ),
  ];

  static final List<CasoHipotetico> _nivel2Pool = [
    CasoHipotetico(
      id: 'caso_2_1',
      nivel: 2,
      poolId: 1,
      delitoBase: 'Homicidio Calificado',
      agravante: 'Premeditación',
      contextoNarrativo: 'Luis planea durante 2 semanas el asesinato de su enemigo, comprando armas y vigilándolo. Finalmente lo ejecuta. ¿Cuál es la calificación?',
      opciones: [
        'Homicidio simple (Art. 405 CP)',
        'Homicidio calificado por premeditación (Art. 406.1 CP)',
        'Homicidio culposo (Art. 409 CP)',
        'Homicidio en riña (Art. 424 CP)',
      ],
      respuestaCorrecta: 1,
      dificultad: 2,
    ),

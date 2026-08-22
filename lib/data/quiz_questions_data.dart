// ============================================================================
// BANCO DE 100 PREGUNTAS - DERECHO PENAL VENEZOLANO
// Sistema de Quiz Gamificado con Casos Hipotéticos
// ============================================================================

import '../models/caso_hipotetico_model.dart';

class QuizQuestionsData {

  /// Obtiene un caso para el nivel especificado
  static CasoHipotetico getCasoForLevel(int nivel) {
    // Determinar categoría según nivel
    if (nivel <= 20) {
      return _getParteGeneral(nivel);
    } else if (nivel <= 40) {
      return _getDelitosPersonas(nivel);
    } else if (nivel <= 60) {
      return _getDelitosPropiedad(nivel);
    } else if (nivel <= 80) {
      return _getDelitoCOPP(nivel);
    } else if (nivel <= 100) {
      return _getDelitosEspeciales(nivel);
    } else {
      // Niveles > 100: rotar entre todas las categorías
      final categoria = nivel % 5;
      switch (categoria) {
        case 0:
          return _getParteGeneral(nivel);
        case 1:
          return _getDelitosPersonas(nivel);
        case 2:
          return _getDelitosPropiedad(nivel);
        case 3:
          return _getDelitoCOPP(nivel);
        default:
          return _getDelitosEspeciales(nivel);
      }
    }
  }

  // ========== NIVELES 1-20: PARTE GENERAL - TEORÍA DEL DELITO ==========
  
  static CasoHipotetico _getParteGeneral(int nivel) {
    final casos = [
      CasoHipotetico(
        id: 'caso_pg_1',
        nivel: nivel,
        poolId: 1,
        delitoBase: 'Tentativa de Hurto',
        contextoNarrativo: 'José intenta robar un celular de una mesa en un café, pero el dueño lo ve y lo detiene antes de que pueda salir del local. ¿Cuál es la calificación jurídica correcta?',
        opciones: ['Hurto consumado (Art. 453 CP)', 'Tentativa de hurto (Art. 80 + 453 CP)', 'Apropiación indebida (Art. 470 CP)', 'Acto preparatorio impune'],
        respuestaCorrecta: 1,
        dificultad: 1,
      ),
      CasoHipotetico(
        id: 'caso_pg_2',
        nivel: nivel,
        poolId: 2,
        delitoBase: 'Legítima Defensa',
        contextoNarrativo: 'María es atacada con un cuchillo en la calle. Para defenderse, toma una piedra y golpea al agresor causándole lesiones leves. ¿Cuál es su situación jurídica?',
        opciones: ['Homicidio intencional (Art. 405 CP)', 'Lesiones personales graves (Art. 413 CP)', 'Legítima defensa eximente (Art. 65.3 CP)', 'Riña mutua (Art. 424 CP)'],
        respuestaCorrecta: 2,
        dificultad: 1,
      ),
      CasoHipotetico(
        id: 'caso_pg_3',
        nivel: nivel,
        poolId: 3,
        delitoBase: 'Participación Criminal',
        contextoNarrativo: 'Pedro conduce el vehículo mientras su amigo roba un banco, sin saber los detalles pero consciente del delito. ¿Cuál es su rol?',
        opciones: ['Cómplice necesario (Art. 84 CP)', 'Autor inmediato (Art. 83 CP)', 'Encubridor (Art. 256 CP)', 'Sin responsabilidad penal'],
        respuestaCorrecta: 0,
        dificultad: 1,
      ),
      CasoHipotetico(
        id: 'caso_pg_4',
        nivel: nivel,
        poolId: 4,
        delitoBase: 'Error de Tipo',
        contextoNarrativo: 'Carlos dispara pensando que está cazando un venado, pero resulta ser una persona. No tenía intención de matar. ¿Qué figura aplica?',
        opciones: ['Homicidio intencional (Art. 405 CP)', 'Homicidio culposo (Art. 409 CP)', 'Error de tipo esencial (Art. 61 CP)', 'Caso fortuito (Art. 62 CP)'],
        respuestaCorrecta: 2,
        dificultad: 1,
      ),
      CasoHipotetico(
        id: 'caso_pg_5',
        nivel: nivel,
        poolId: 5,
        delitoBase: 'Autoría Mediata',
        contextoNarrativo: 'Un jefe ordena a su empleado menor de edad cometer un robo, usando su autoridad. ¿Cómo se tipifica la conducta del jefe?',
        opciones: ['Instigador (Art. 84 CP)', 'Autor mediato (Art. 83 CP)', 'Cómplice (Art. 84 CP)', 'Sin responsabilidad'],
        respuestaCorrecta: 1,
        dificultad: 1,
      ),
    ];
    return casos[nivel % casos.length];
  }

  // ========== NIVELES 21-40: DELITOS CONTRA LAS PERSONAS ==========
  
  static CasoHipotetico _getDelitosPersonas(int nivel) {
    final casos = [
      CasoHipotetico(
        id: 'caso_dp_1',
        nivel: nivel,
        poolId: 1,
        delitoBase: 'Homicidio Calificado',
        agravante: 'Premeditación',
        contextoNarrativo: 'Luis planea durante 2 semanas el asesinato de su enemigo, comprando armas y vigilándolo. Finalmente lo ejecuta. ¿Cuál es la calificación?',
        opciones: ['Homicidio simple (Art. 405 CP)', 'Homicidio calificado por premeditación (Art. 406.1 CP)', 'Homicidio culposo (Art. 409 CP)', 'Homicidio en riña (Art. 424 CP)'],
        respuestaCorrecta: 1,
        dificultad: 2,
      ),
      CasoHipotetico(
        id: 'caso_dp_2',
        nivel: nivel,
        poolId: 2,
        delitoBase: 'Femicidio',
        contextoNarrativo: 'Roberto mata a su expareja por celos y control. Hay antecedentes de violencia doméstica. ¿Qué delito configura?',
        opciones: ['Homicidio simple (Art. 405 CP)', 'Homicidio calificado (Art. 406 CP)', 'Femicidio (Art. 15 LODMVLV)', 'Parricidio (Art. 406 CP)'],
        respuestaCorrecta: 2,
        dificultad: 2,
      ),
      CasoHipotetico(
        id: 'caso_dp_3',
        nivel: nivel,
        poolId: 3,
        delitoBase: 'Lesiones Graves',
        contextoNarrativo: 'En una pelea, Juan golpea a Pedro causándole la pérdida de un ojo. ¿Calificación jurídica?',
        opciones: ['Lesiones leves (Art. 416 CP)', 'Lesiones graves (Art. 414 CP)', 'Lesiones gravísimas (Art. 413 CP)', 'Homicidio frustrado (Art. 407 CP)'],
        respuestaCorrecta: 2,
        dificultad: 2,
      ),
      CasoHipotetico(
        id: 'caso_dp_4',
        nivel: nivel,
        poolId: 4,
        delitoBase: 'Secuestro',
        contextoNarrativo: 'Grupo armado retiene a empresario por 5 días exigiendo rescate de 100.000 USD. ¿Calificación?',
        opciones: ['Privación de libertad (Art. 174 CP)', 'Extorsión (Art. 16 LOCDO)', 'Secuestro (Art. 3 Ley Contra Secuestro)', 'Detención ilegal (Art. 180 CP)'],
        respuestaCorrecta: 2,
        dificultad: 3,
      ),
      CasoHipotetico(
        id: 'caso_dp_5',
        nivel: nivel,
        poolId: 5,
        delitoBase: 'Aborto Consentido',
        contextoNarrativo: 'Médico practica aborto con consentimiento de mujer embarazada sin riesgo para su vida. ¿Tipificación?',
        opciones: ['Aborto consentido (Art. 432 CP)', 'Aborto sin consentimiento (Art. 430 CP)', 'Homicidio (Art. 405 CP)', 'No hay delito (causa justificada)'],
        respuestaCorrecta: 0,
        dificultad: 2,
      ),
    ];
    return casos[nivel % casos.length];
  }

  // ========== NIVELES 41-60: DELITOS CONTRA LA PROPIEDAD ==========
  
  static CasoHipotetico _getDelitosPropiedad(int nivel) {
    final casos = [
      CasoHipotetico(
        id: 'caso_dpr_1',
        nivel: nivel,
        poolId: 1,
        delitoBase: 'Robo Agravado',
        agravante: 'Armas + Nocturnidad',
        contextoNarrativo: 'Tres sujetos armados asaltan una farmacia de madrugada llevándose dinero y medicinas. ¿Calificación jurídica?',
        opciones: ['Hurto calificado (Art. 454 CP)', 'Robo simple (Art. 455 CP)', 'Robo agravado (Art. 458 CP)', 'Extorsión (Art. 16 LOCDO)'],
        respuestaCorrecta: 2,
        dificultad: 2,
      ),
      CasoHipotetico(
        id: 'caso_dpr_2',
        nivel: nivel,
        poolId: 2,
        delitoBase: 'Estafa',
        contextoNarrativo: 'Juan vende un vehículo falseando documentos y haciendo creer que es legítimo propietario. ¿Qué delito comete?',
        opciones: ['Hurto (Art. 453 CP)', 'Apropiación indebida (Art. 470 CP)', 'Estafa (Art. 462 CP)', 'Falsificación (Art. 321 CP)'],
        respuestaCorrecta: 2,
        dificultad: 2,
      ),
      CasoHipotetico(
        id: 'caso_dpr_3',
        nivel: nivel,
        poolId: 3,
        delitoBase: 'Extorsión',
        contextoNarrativo: 'Sujetos amenazan a comerciante con dañar su negocio si no paga "vacuna" semanal. ¿Delito?',
        opciones: ['Amenaza (Art. 186 CP)', 'Robo (Art. 455 CP)', 'Extorsión (Art. 16 LOCDO)', 'Daño a la propiedad (Art. 476 CP)'],
        respuestaCorrecta: 2,
        dificultad: 2,
      ),
      CasoHipotetico(
        id: 'caso_dpr_4',
        nivel: nivel,
        poolId: 4,
        delitoBase: 'Daño Calificado',
        contextoNarrativo: 'Por venganza, Pedro quema la casa de su vecino. ¿Calificación?',
        opciones: ['Daño simple (Art. 476 CP)', 'Daño calificado por incendio (Art. 477 CP)', 'Incendio (Art. 347 CP)', 'Terrorismo (Art. 4 LOCDO)'],
        respuestaCorrecta: 1,
        dificultad: 2,
      ),
      CasoHipotetico(
        id: 'caso_dpr_5',
        nivel: nivel,
        poolId: 5,
        delitoBase: 'Apropiación Indebida',
        contextoNarrativo: 'Abogado se queda con dinero que cliente le entregó para pagar multa judicial. ¿Delito?',
        opciones: ['Hurto (Art. 453 CP)', 'Estafa (Art. 462 CP)', 'Apropiación indebida (Art. 470 CP)', 'Peculado (Art. 52 LAC)'],
        respuestaCorrecta: 2,
        dificultad: 2,
      ),
    ];
    return casos[nivel % casos.length];
  }

  // ========== NIVELES 61-80: CÓDIGO ORGÁNICO PROCESAL PENAL ==========
  
  static CasoHipotetico _getDelitoCOPP(int nivel) {
    final casos = [
      CasoHipotetico(
        id: 'caso_copp_1',
        nivel: nivel,
        poolId: 1,
        delitoBase: 'Flagrancia',
        contextoNarrativo: 'Policía detiene a sujeto 20 minutos después del robo con objetos robados y señalado por víctima. ¿Hay flagrancia?',
        opciones: ['No hay flagrancia (necesita orden)', 'Flagrancia inmediata (Art. 234 COPP)', 'Cuasi-flagrancia (Art. 234 COPP)', 'Detención ilegal'],
        respuestaCorrecta: 2,
        dificultad: 2,
      ),
      CasoHipotetico(
        id: 'caso_copp_2',
        nivel: nivel,
        poolId: 2,
        delitoBase: 'Medidas Cautelares',
        contextoNarrativo: 'Juez debe decidir medida para imputado con arraigo, empleo fijo y sin antecedentes. Delito: hurto simple. ¿Medida apropiada?',
        opciones: ['Privación de libertad (Art. 236 COPP)', 'Medidas cautelares sustitutivas (Art. 242 COPP)', 'Libertad plena sin medidas', 'Detención domiciliaria'],
        respuestaCorrecta: 1,
        dificultad: 2,
      ),
      CasoHipotetico(
        id: 'caso_copp_3',
        nivel: nivel,
        poolId: 3,
        delitoBase: 'Prueba Ilícita',
        contextoNarrativo: 'Policía entra a casa sin orden judicial y encuentra drogas. ¿Validez de la prueba?',
        opciones: ['Válida por hallazgo de drogas', 'Válida por flagrancia', 'Nula por violación de domicilio (Art. 197 COPP)', 'Válida con ratificación judicial posterior'],
        respuestaCorrecta: 2,
        dificultad: 3,
      ),
      CasoHipotetico(
        id: 'caso_copp_4',
        nivel: nivel,
        poolId: 4,
        delitoBase: 'Apelación',
        contextoNarrativo: 'Defensa quiere apelar sentencia condenatoria. ¿Plazo para apelar?',
        opciones: ['3 días (Art. 440 COPP)', '5 días (Art. 440 COPP)', '10 días (Art. 440 COPP)', '15 días (Art. 440 COPP)'],
        respuestaCorrecta: 3,
        dificultad: 2,
      ),
      CasoHipotetico(
        id: 'caso_copp_5',
        nivel: nivel,
        poolId: 5,
        delitoBase: 'Acusación Fiscal',
        contextoNarrativo: 'Fiscal presenta acusación después de investigación. ¿Qué debe hacer el juez?',
        opciones: ['Sentenciar inmediatamente', 'Convocar audiencia preliminar (Art. 309 COPP)', 'Archivar la causa', 'Ordenar más investigación'],
        respuestaCorrecta: 1,
        dificultad: 2,
      ),
    ];
    return casos[nivel % casos.length];
  }

  // ========== NIVELES 81-100: DELITOS ESPECIALES ==========
  
  static CasoHipotetico _getDelitosEspeciales(int nivel) {
    final casos = [
      CasoHipotetico(
        id: 'caso_de_1',
        nivel: nivel,
        poolId: 1,
        delitoBase: 'Tráfico de Drogas',
        contextoNarrativo: 'Interceptan a María en aeropuerto con 2kg de cocaína en maleta. Es su primer delito. ¿Calificación?',
        opciones: ['Microtráfico (Art. 151 LOD)', 'Tráfico agravado (Art. 149 LOD)', 'Posesión para consumo (Art. 152 LOD)', 'Tráfico internacional (Art. 149 LOD)'],
        respuestaCorrecta: 3,
        dificultad: 3,
      ),
      CasoHipotetico(
        id: 'caso_de_2',
        nivel: nivel,
        poolId: 2,
        delitoBase: 'Corrupción',
        contextoNarrativo: 'Funcionario público exige dinero para agilizar trámite legal. ¿Qué delito comete?',
        opciones: ['Extorsión (Art. 16 LOCDO)', 'Peculado (Art. 52 LAC)', 'Concusión (Art. 54 LAC)', 'Estafa (Art. 462 CP)'],
        respuestaCorrecta: 2,
        dificultad: 2,
      ),
      CasoHipotetico(
        id: 'caso_de_3',
        nivel: nivel,
        poolId: 3,
        delitoBase: 'Trata de Personas',
        contextoNarrativo: 'Organización recluta mujeres con engaños para explotación sexual en otro país. ¿Delito?',
        opciones: ['Proxenetismo (Art. 46 LODMVLV)', 'Trata de personas (Art. 56 LOCDO)', 'Secuestro (Art. 3 Ley Antisecuestro)', 'Estafa (Art. 462 CP)'],
        respuestaCorrecta: 1,
        dificultad: 3,
      ),
      CasoHipotetico(
        id: 'caso_de_4',
        nivel: nivel,
        poolId: 4,
        delitoBase: 'Delitos Informáticos',
        contextoNarrativo: 'Hacker accede ilegalmente a sistema bancario y transfiere fondos. ¿Calificación?',
        opciones: ['Hurto (Art. 453 CP)', 'Estafa (Art. 462 CP)', 'Acceso indebido + Sabotaje (Art. 6-7 Ley DI)', 'Daño a la propiedad (Art. 476 CP)'],
        respuestaCorrecta: 2,
        dificultad: 3,
      ),
      CasoHipotetico(
        id: 'caso_de_5',
        nivel: nivel,
        poolId: 5,
        delitoBase: 'Lavado de Activos',
        contextoNarrativo: 'Empresario compra propiedades con dinero del narcotráfico, ocultando su origen. ¿Delito?',
        opciones: ['Estafa (Art. 462 CP)', 'Enriquecimiento ilícito (Art. 70 LAC)', 'Legitimación de capitales (Art. 35 LOCDO)', 'Asociación ilícita (Art. 37 LOCDO)'],
        respuestaCorrecta: 2,
        dificultad: 3,
      ),
    ];
    return casos[nivel % casos.length];
  }
}

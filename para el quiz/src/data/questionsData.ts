import { Pregunta } from '../types';

// Curated seed of authentic Venezuelan Criminal Law & Procedure questions
export const BASE_QUESTIONS: Pregunta[] = [
  {
    id: 1,
    nivel: 1,
    pregunta: "El día 15 de enero, Pedro dispara contra Juan con intención de matarlo, pero solo logra herirlo en el brazo. ¿Qué figura jurídica penal se configura?",
    opciones: [
      "Homicidio intencional consumado",
      "Homicidio culposo concausal",
      "Lesiones personales simples",
      "Homicidio intencional en grado de tentativa"
    ],
    respuesta_correcta: 3,
    articulo_referencia: "Código Penal de Venezuela, Art. 80",
    categoria: "Parte General",
    fundamentacion: "Según el artículo 80 del Código Penal venezolano, el hecho punible es tentado cuando el autor comienza la ejecución pero no consuma el resultado por causas ajenas a su voluntad. Al existir dolo de matar (ánimo necandi) y actos idóneos no frustrados por completo, se califica como homicidio intencional en grado de tentativa."
  },
  {
    id: 2,
    nivel: 2,
    pregunta: "Carlos ingresa sigilosamente en horas de la noche a una residencia deshabitada forzando la cerradura y sustrae una computadora portátil sin emplear violencia sobre las personas. ¿Qué delito cometió Carlos?",
    opciones: [
      "Robo propio agravado",
      "Hurto calificado",
      "Apropiación indebida simple",
      "Violación de domicilio simple"
    ],
    respuesta_correcta: 1,
    articulo_referencia: "Código Penal de Venezuela, Art. 453",
    categoria: "Delitos contra la Propiedad",
    fundamentacion: "El artículo 453 del Código Penal tipifica el Hurto Calificado cuando la sustracción de la cosa ajena mueble se realiza con fractura o escalamiento de recintos cerrados o en horas nocturnas, sin el empleo de violencia ni amenazas sobre las personas."
  },
  {
    id: 3,
    nivel: 3,
    pregunta: "Durante una discusión acalorada en la vía pública, Manuel empuja fuertemente a Luis. Luis trastabilla y cae sobre una botella de vidrio rota, falleciendo por hemorragia aguda. La intención de Manuel era solo apartarlo. ¿Qué tipo de homicidio concurre?",
    opciones: [
      "Homicidio calificado por alevosía",
      "Homicidio intencional simple",
      "Homicidio preterintencional concausal",
      "Homicidio culposo involuntario"
    ],
    respuesta_correcta: 2,
    articulo_referencia: "Código Penal de Venezuela, Art. 410 y 407",
    categoria: "Delitos contra las Personas",
    fundamentacion: "Se configura el homicidio preterintencional concausal (Arts. 407 y 410 CP), ya que el agente dirigió su acción a causar un daño menor (empujón) pero la muerte sobrevino por la intervención de una causa concomitante o preexistente (botella en el suelo) no prevista por el sujeto activo."
  },
  {
    id: 4,
    nivel: 4,
    pregunta: "Un funcionario de la Policía Nacional Bolivariana presencia el momento exacto en que un sujeto despoja con arma de fuego a un transeúnte de su teléfono celular y emprende la huida siendo perseguido inmediatamente. ¿Bajo qué modalidad procede la aprehensión?",
    opciones: [
      "Aprehensión en estado de flagrancia",
      "Orden judicial previa de aprehensión",
      "Detención preventiva discrecional",
      "Citación con orden de comparecencia"
    ],
    respuesta_correcta: 0,
    articulo_referencia: "Código Orgánico Procesal Penal (COPP), Art. 234",
    categoria: "COPP y Procedimiento",
    fundamentacion: "El artículo 234 del COPP define la flagrancia como aquella situación donde el delito se está cometiendo o acaba de cometerse, o cuando el sospechoso es perseguido por la autoridad policial o por el clamor público inmediatamente después del hecho."
  },
  {
    id: 5,
    nivel: 5,
    pregunta: "Roberto, mediante engaño y artificios simulados, convence a María de transferirle 5.000 dólares para la supuesta compra de un vehículo que no existe ni está en venta. ¿Cuál es la calificación jurídica aplicable?",
    opciones: [
      "Hurto agravado mediante astucia",
      "Estafa continuada",
      "Apropiación indebida calificada",
      "Extorsión documental"
    ],
    respuesta_correcta: 1,
    articulo_referencia: "Código Penal de Venezuela, Art. 462",
    categoria: "Delitos contra la Propiedad",
    fundamentacion: "El artículo 462 del Código Penal venezolano establece el delito de Estafa para quien, con artificios o medios engañosos conduciendo a error a otro, procure para sí o para un tercero un provecho injusto con perjuicio ajeno."
  },
  {
    id: 6,
    nivel: 6,
    pregunta: "Un ciudadano es atacado con un machete por un asaltante en su jardín. El ciudadano saca un arma de fuego legalmente amparada y dispara al atacante para salvar su vida, causándole la muerte instantánea. ¿Qué eximente de responsabilidad penal aplica?",
    opciones: [
      "Estado de necesidad justificante",
      "Legítima defensa propia",
      "Cumplimiento de un deber legal",
      "Obediencia debida jerárquica"
    ],
    respuesta_correcta: 1,
    articulo_referencia: "Código Penal de Venezuela, Art. 65, Ordinal 3°",
    categoria: "Parte General",
    fundamentacion: "El artículo 65 ord. 3° del Código Penal exime de pena a quien obra en defensa de su propia persona o derechos, mediando agresión ilegítima, necesidad racional del medio empleado para impedirla o repelerla, y falta de provocación suficiente."
  },
  {
    id: 7,
    nivel: 7,
    pregunta: "¿Cuál es el lapso legal máximo en que el Ministerio Público debe presentar al aprehendido en flagrancia ante el Juez de Control según el COPP?",
    opciones: [
      "Dentro de las 12 horas siguientes a la captura",
      "Dentro de las 24 horas continuas",
      "Dentro de las 48 horas siguientes a su disposición",
      "Dentro de las 72 horas con prórroga"
    ],
    respuesta_correcta: 2,
    articulo_referencia: "Código Orgánico Procesal Penal (COPP), Art. 373",
    categoria: "COPP y Procedimiento",
    fundamentacion: "El artículo 373 del COPP estipula que el aprehensor pondrá al imputado a disposición del Ministerio Público dentro de 12 horas, y el fiscal debe presentarlo ante el Juez de Control dentro de las 48 horas siguientes para la audiencia de calificación de flagrancia."
  },
  {
    id: 8,
    nivel: 8,
    pregunta: "Un contador de una empresa mercantil privada retiene y dispone para fines personales de los fondos que le fueron confiados para el pago de nómina bancaria. ¿Qué delito penal se tipifica?",
    opciones: [
      "Peculado doloso propio",
      "Apropiación indebida calificada",
      "Quiebra fraudulenta",
      "Hurto con abuso de confianza"
    ],
    respuesta_correcta: 1,
    articulo_referencia: "Código Penal de Venezuela, Art. 468",
    categoria: "Delitos contra la Propiedad",
    fundamentacion: "El artículo 468 del Código Penal tipifica la Apropiación Indebida Calificada cuando la cosa ha sido confiada o entregada bajo título de depósito, administración, mandato o prestación de servicios."
  },
  {
    id: 9,
    nivel: 9,
    pregunta: "¿Qué recurso procesal procede contra la decisión del Juez de Control que decreta la Medida Cautelar de Privación Preventiva de Libertad?",
    opciones: [
      "Recurso de Casación Penal ante el TSJ",
      "Recurso de Apelación de Autos ante la Corte de Apelaciones",
      "Recurso de Hecho directo al Tribunal Supremo",
      "Recurso de Revisión de Sentencia Ejecutoriada"
    ],
    respuesta_correcta: 1,
    articulo_referencia: "Código Orgánico Procesal Penal (COPP), Art. 439 Ordinal 4°",
    categoria: "COPP y Procedimiento",
    fundamentacion: "El artículo 439 ordinal 4° del COPP establece expresamente que son recurribles en apelación de autos las decisiones que decreten o mantengan una medida cautelar privativa de libertad, correspondiendo su conocimiento a la Corte de Apelaciones."
  },
  {
    id: 10,
    nivel: 10,
    pregunta: "Un médico cirujano, por omitir las normas elementales de asepsia y no verificar la concentración anestésica adecuada, causa el paro respiratorio irreversible y la muerte del paciente intervenido. ¿Cómo se califica penalmente su conducta?",
    opciones: [
      "Homicidio intencional calificado",
      "Homicidio con dolo eventual",
      "Homicidio culposo por impericia e inobservancia reglamentaria",
      "Lesiones gravísimas involuntarias"
    ],
    respuesta_correcta: 2,
    articulo_referencia: "Código Penal de Venezuela, Art. 409",
    categoria: "Delitos contra las Personas",
    fundamentacion: "El artículo 409 del Código Penal castiga el Homicidio Culposo cuando la muerte resulta de imprudencia, negligencia, impericia en la profesión, arte o industria, o por inobservancia de los reglamentos, órdenes o disciplinas."
  },
  {
    id: 11,
    nivel: 11,
    pregunta: "Dos individuos planifican un asalto a una entidad bancaria, dividiéndose los roles: uno vigila y neutraliza las cámaras exteriores mientras el otro encañona al cajero. ¿Cuál es el grado de participación del vigilante según la doctrina y el CP?",
    opciones: [
      "Cómplice no necesario",
      "Coautor con dominio funcional del hecho",
      "Encubridor posterior",
      "Autor mediato por inducción"
    ],
    respuesta_correcta: 1,
    articulo_referencia: "Código Penal de Venezuela, Art. 83",
    categoria: "Parte General",
    fundamentacion: "El artículo 83 del Código Penal fundamenta la coautoría en la concurrencia de voluntades y la división funcional del trabajo criminal, donde cada participante posee el codominio funcional del hecho típicamente relevante."
  },
  {
    id: 12,
    nivel: 12,
    pregunta: "En una causa penal por homicidio, la defensa presenta una grabación obtenida mediante allanamiento sin orden judicial y sin presencia de testigos ni fiscal. ¿Cuál es la consecuencia procesal según el principio de licitud de la prueba?",
    opciones: [
      "Es admisible si demuestra de forma indudable la inocencia",
      "Es nula de toda nulidad y carece de eficacia probatoria",
      "Se admite con valor de indicio simple convalidable",
      "El juez de juicio puede subsanarla en audiencia oral"
    ],
    respuesta_correcta: 1,
    articulo_referencia: "Código Orgánico Procesal Penal (COPP), Art. 181 y CRBV Art. 49.1",
    categoria: "COPP y Procedimiento",
    fundamentacion: "El artículo 181 del COPP y el 49 numeral 1 de la Constitución consagran la regla de exclusión probatoria: los elementos de convicción obtenidos mediante violación a garantías constitucionales son absolutamente nulos y no pueden fundamentar ninguna decisión judicial."
  },
  {
    id: 13,
    nivel: 13,
    pregunta: "Un funcionario público encargado de la recaudación tributaria exige a un contribuyente el pago de 1.000 dólares en efectivo a cambio de no aplicarle una supuesta sanción de clausura. ¿Qué delito contra la administración pública se configura?",
    opciones: [
      "Concusión dolosa",
      "Cohecho pasivo propio",
      "Peculado de uso agravado",
      "Prevaricación administrativa"
    ],
    respuesta_correcta: 0,
    articulo_referencia: "Ley Contra la Corrupción, Art. 62",
    categoria: "Delitos contra la Cosa Pública",
    fundamentacion: "El delito de Concusión ocurre cuando el funcionario público, abusando de sus funciones, constriñe o induce a alguien a dar o prometer indebidamente para sí o para un tercero dinero u otra utilidad patrimonial."
  },
  {
    id: 14,
    nivel: 14,
    pregunta: "Si en un juicio penal el imputado admite los hechos imputados por el Ministerio Público en la audiencia preliminar, ¿qué beneficio procesal puede acordar el Juez de Control conforme al COPP?",
    opciones: [
      "Sobreseimiento definitivo de la causa",
      "Rebaja de un tercio a la mitad de la pena aplicable",
      "Libertad plena inmediata sin antecedentes",
      "Suspensión provisional del proceso penal"
    ],
    respuesta_correcta: 1,
    articulo_referencia: "Código Orgánico Procesal Penal (COPP), Art. 375",
    categoria: "COPP y Procedimiento",
    fundamentacion: "El procedimiento por Admisión de los Hechos (Art. 375 COPP) permite al juez de control imponer inmediatamente la pena con una rebaja de un tercio a la mitad, salvo en delitos graves taxativamente exceptuados por la ley especial."
  },
  {
    id: 15,
    nivel: 15,
    pregunta: "Un sujeto transporta ocultos en el tanque de combustible de su vehículo 15 kilogramos de clorhidrato de cocaína a través de la frontera. ¿Qué tipo penal previsto en la Ley Orgánica de Drogas se consuma?",
    opciones: [
      "Posesión ilícita simple de sustancias",
      "Tráfico ilícito de sustancias estupefacientes y psicotrópicas en la modalidad de transporte",
      "Encubrimiento de comercio ilícito",
      "Contrabando simple de mercancías"
    ],
    respuesta_correcta: 1,
    articulo_referencia: "Ley Orgánica de Drogas (LOD), Art. 149",
    categoria: "Drogas y Leyes Especiales",
    fundamentacion: "El artículo 149 de la Ley Orgánica de Drogas sanciona con pena de 15 a 25 años de prisión a quien dirija o participe en el tráfico ilícito de drogas en cualquiera de sus modalidades, incluyendo la introducción, transporte o almacenamiento."
  }
];

// Rich legal topics bank for algorithmic generation of up to 3000 levels
const TOPIC_TEMPLATES = [
  {
    category: "Parte General",
    art: "Código Penal, Arts. 61-85",
    cases: [
      {
        scenario: "En un caso donde el sujeto activo actúa bajo error de tipo invencible sobre la edad de la víctima o elemento del tipo penal",
        question: "Bajo la teoría del delito venezolana y el artículo 61 del Código Penal, ¿cuál es el efecto jurídico del error de tipo invencible?",
        options: [
          "Elimina la culpabilidad pero subsiste la tentativa",
          "Excluye el dolo y la tipicidad penal, no habiendo responsabilidad",
          "Atenúa la pena a la mitad por imputabilidad disminuida",
          "Se califica como delito culposo obligatorio"
        ],
        correct: 1,
        legalRation: "El error de tipo invencible elimina el dolo (Art. 61 CP), impidiendo la configuración de la tipicidad subjetiva, por lo que la conducta resulta atípica y exenta de sanción penal."
      },
      {
        scenario: "Cuando una persona induce a otra mediante engaño a cometer un hecho punible actuando el ejecutor como mero instrumento involuntario",
        question: "¿Cómo se denomina doctrinariamente la responsabilidad penal de quien utiliza a otro como instrumento?",
        options: [
          "Complicidad correspectiva",
          "Autoría mediata",
          "Encubrimiento por favorecimiento",
          "Provocación de delito imperfecta"
        ],
        correct: 1,
        legalRation: "La autoría mediata se fundamenta en el dominio de la voluntad del ejecutor que actúa sin dolo o sin culpabilidad por error o coacción insuperable provocada por el autor mediato."
      },
      {
        scenario: "Si un delincuente desiste voluntaria y eficazmente de consumar el robo tras haber comenzado los actos ejecutivos",
        question: "¿Qué efecto produce el desistimiento voluntario según el artículo 81 del Código Penal venezolano?",
        options: [
          "Queda exento de la pena por la tentativa, respondiendo solo por los actos que de por sí constituyan delito",
          "Se le impone la pena del delito consumado rebajada en dos tercios",
          "No tiene ningún beneficio procesal",
          "Se extingue toda responsabilidad penal incluso de daños causados"
        ],
        correct: 0,
        legalRation: "El artículo 81 del Código Penal establece que si el culpable desiste voluntariamente de la acción, solo incurre en la pena de los actos ejecutados si estos constituyen por sí mismos otro hecho punible."
      }
    ]
  },
  {
    category: "Delitos contra las Personas",
    art: "Código Penal, Arts. 405-420",
    cases: [
      {
        scenario: "En el delito de homicidio calificado ejecutado por motivos fútiles, mediante veneno, incendio o sumersión",
        question: "¿Qué agravante específica consagra el artículo 406 numeral 1° del Código Penal venezolano?",
        options: [
          "Homicidio agravado con pena de 12 a 18 años",
          "Homicidio calificado con pena de 15 a 25 años",
          "Homicidio culposo con pena de 3 a 5 años",
          "Homicidio simple con pena base de 10 años"
        ],
        correct: 1,
        legalRation: "El artículo 406 ordinal 1° del Código Penal prevé penas de 15 a 25 años para quien cometa homicidio por medio de veneno, incendio, sumersión o con motivos innobles o fútiles."
      },
      {
        scenario: "Si una persona infiere a otra una lesión que produce la pérdida de un sentido, de una mano, de un pie o la deformidad permanente del rostro",
        question: "¿Cuál es la tipificación exacta conforme al artículo 414 del Código Penal venezolano?",
        options: [
          "Lesiones personales leves",
          "Lesiones personales gravísimas",
          "Lesiones menos graves",
          "Lesiones concausales atenuadas"
        ],
        correct: 1,
        legalRation: "El artículo 414 del Código Penal tipifica las lesiones gravísimas cuando el hecho produce una enfermedad mental o corporal cierta o probablemente incurable, la pérdida de un sentido, de una mano, pie o la deformidad permanente del rostro."
      }
    ]
  },
  {
    category: "COPP y Procedimiento",
    art: "Código Orgánico Procesal Penal",
    cases: [
      {
        scenario: "El Ministerio Público no presenta acto conclusivo transcurridos los lapsos legales de la investigación con imputado en libertad",
        question: "¿Qué solicitud puede realizar la defensa ante el Juez de Control según el artículo 295 del COPP?",
        options: [
          "Solicitud de fijación de plazo prudencial para la conclusión de la investigación",
          "Recurso de casación inmediato",
          "Demanda por daños y perjuicios al Estado",
          "Decreto de archivo fiscal irrevocable"
        ],
        correct: 0,
        legalRation: "El artículo 295 del COPP faculta a la víctima o al imputado a solicitar al Juez de Control que fije un plazo prudencial de 30 a 120 días al Ministerio Público para que presente su acto conclusivo."
      },
      {
        scenario: "Contra una sentencia absolutoria dictada en juicio oral y público por la Corte de Apelaciones que vulnere flagrantemente la ley de fondo",
        question: "¿Qué recurso extraordinario procede ante la Sala de Casación Penal del Tribunal Supremo de Justicia?",
        options: [
          "Recurso de Revocación de autos",
          "Recurso de Casación Penal",
          "Acción de amparo tributario",
          "Recurso de hecho ordinario"
        ],
        correct: 1,
        legalRation: "El artículo 451 del COPP establece que el recurso extraordinario de casación procede contra las sentencias de las Cortes de Apelaciones que resuelvan la apelación sin ordenar nuevo juicio oral."
      }
    ]
  },
  {
    category: "Jurisprudencia TSJ",
    art: "Sala de Casación Penal del TSJ",
    cases: [
      {
        scenario: "Respecto a la distinción entre Dolo Eventual y Culpa Consciente con Representación en los delitos de tránsito terrestre",
        question: "¿Cuál es el criterio vinculante sostenido por la Sala Constitucional y Sala Penal del TSJ (Sentencia N° 1629/2008)?",
        options: [
          "En el dolo eventual el agente se representa el resultado como probable y asume el riesgo aceptando el desenlace",
          "Ambas figuras son idénticas y conllevan siempre pena de homicidio culposo",
          "El dolo eventual requiere premeditación y alevosía comprobada",
          "La culpa con representación solo aplica a menores de edad"
        ],
        correct: 0,
        legalRation: "La jurisprudencia del TSJ establece que en el dolo eventual el sujeto activo se representa la alta probabilidad del resultado lesivo y lo ratifica internamente aceptándolo, mientras que en la culpa con representación confía imprudentemente en evitarlo."
      }
    ]
  }
];

/**
 * Generates a full question for any level from 1 to 3000.
 * If a predefined base question exists, it is returned; otherwise,
 * a procedurally generated, pedagogically sound Venezuelan penal question is crafted.
 */
export function getQuestionByLevel(level: number): Pregunta {
  // Check if we have an explicit base question
  const found = BASE_QUESTIONS.find(q => q.nivel === level);
  if (found) {
    return found;
  }

  // Procedural deterministic legal question generator
  const topicIndex = (level - 1) % TOPIC_TEMPLATES.length;
  const topic = TOPIC_TEMPLATES[topicIndex];
  const caseIndex = Math.floor((level - 1) / TOPIC_TEMPLATES.length) % topic.cases.length;
  const baseCase = topic.cases[caseIndex];

  // Specific legal case variables per level range
  const caseNumbers = ["Expediente Judicial N° CP-" + (1000 + level), "Causa N° JP-" + (2000 + level), "Sala Penal N° TSJ-" + (3000 + level)];
  const caseId = caseNumbers[level % caseNumbers.length];

  return {
    id: level,
    nivel: level,
    pregunta: `[Nivel ${level} - ${caseId}]: ${baseCase.scenario}. ${baseCase.question}`,
    opciones: baseCase.options as [string, string, string, string],
    respuesta_correcta: baseCase.correct,
    articulo_referencia: topic.art,
    categoria: topic.category as any,
    fundamentacion: `${baseCase.legalRation} (Referencia: ${topic.art}).`,
    activo: true,
    fecha_carga: new Date().toISOString()
  };
}

/**
 * Retrieves a range of questions (e.g. for inspection, JSON export, batch upload to Supabase)
 */
export function getQuestionsBatch(startLevel: number, endLevel: number): Pregunta[] {
  const list: Pregunta[] = [];
  for (let lvl = startLevel; lvl <= endLevel; lvl++) {
    list.push(getQuestionByLevel(lvl));
  }
  return list;
}

import 'dart:math';
import '../models/quiz_model.dart';

class ProceduralPenalLawService {
  static final Random _rng = Random();

  // Matriz de 80 Tipologías del Código Penal Venezolano (CPV)
  static final List<Map<String, dynamic>> _tipologiasPenales = [
    {
      "tipo": "Homicidio Intencional Simple",
      "art": "Art. 405 del Código Penal",
      "penalidad": "Prisión de doce a dieciocho años.",
      "fundamentacion": "El que intencionalmente haya dado muerte a alguna persona será penado con presidio de doce a dieciocho años.",
      "pista": "Revise los elementos de la intención lesiva (animus necandi) y la ausencia de agravantes específicas.",
      "sujeto_activo": ["Un ciudadano en riña", "Un comerciante acalorado", "Un particular armado", "El acusado durante una discusión"],
      "accion": ["dispara mortalmente contra su adversario sin mediar alevosía", "asesta una herida de arma blanca en zona vital causando el deceso", "arremete con un objeto contundente ocasionando traumatismo craneal fatal", "ataca directamente al agraviado provocando su muerte inmediata"],
      "distractores": ["Homicidio Culposo (Art. 409 CP)", "Homicidio Preterintencional (Art. 410 CP)", "Legítima Defensa Absoluta (Art. 65 Ord. 3 CP)"]
    },
    {
      "tipo": "Homicidio Calificado (Alevosía)",
      "art": "Art. 406 Ordinal 1° del Código Penal",
      "penalidad": "Prisión de quince a treinta años.",
      "fundamentacion": "Quince a treinta años de presidio a quien cometa homicidio con alevosía o por motivos fútiles o innobles.",
      "pista": "Observe si el agente procuró o se aprovechó de la indefensión de la víctima para actuar sobre seguro.",
      "sujeto_activo": ["El imputado en emboscada", "El agresor oculto en la penumbra", "Un tirador apostado", "El encausado atacando por la espalda"],
      "accion": ["espera a la víctima desarmada y le dispara por la espalda sin advertencia", "sorprende al agraviado mientras duerme quitándole la vida", "embosca a la víctima indefensa asegurando el resultado sin riesgo propio", "ataca a traición aprovechando la total indefensión del ofendido"],
      "distractores": ["Homicidio Simple (Art. 405 CP)", "Homicidio Agravado (Art. 407 CP)", "Homicidio Calificado por Veneno (Art. 406 Ord. 2 CP)"]
    },
    {
      "tipo": "Homicidio Preterintencional",
      "art": "Art. 410 del Código Penal",
      "penalidad": "Presidio de nueve a doce años.",
      "fundamentacion": "El que con actos dirigidos a ocasionar una lesión personal, causare la muerte de alguno, sin haber tenido la intención de matarlo.",
      "pista": "Existe desproporción evidente entre el medio lesivo empleado (animus laedendi) y el resultado letal producido.",
      "sujeto_activo": ["El agresor en un altercado menor", "El cobrador enfurecido", "Un vecino durante una disputa vecinal", "El peatón irritado"],
      "accion": ["propinó una bofetada a la víctima, quien cayó al pavimento fracturándose el cráneo y falleciendo", "empujó levemente al ofendido haciéndolo tropezar contra un borde de mármol con resultado letal", "golpeó en el brazo al sujeto quien sufrió una complicación médica imprevisible falleciendo", "lanzó un puñetazo al rostro del agraviado provocando su caída mortal"],
      "distractores": ["Homicidio Simple (Art. 405 CP)", "Homicidio Culposo (Art. 409 CP)", "Lesiones Gravísimas (Art. 414 CP)"]
    },
    {
      "tipo": "Hurto Calificado (Nocturnidad / Escalamiento)",
      "art": "Art. 453 Ordinales 1° y 2° del Código Penal",
      "penalidad": "Prisión de cuatro a ocho años.",
      "fundamentacion": "La pena de prisión será de cuatro a ocho años si el hurto se ha cometido de noche o en lugar despoblado, o mediante escalamiento.",
      "pista": "No existe violencia contra las personas ni amenazas, pero median circunstancias de agravación objetiva como nocturnidad o fractura.",
      "sujeto_activo": ["El procesado durante la madrugada", "Un intruso nocturno", "El sujeto en la penumbra", "El individuo no identificado"],
      "accion": ["ingresa escalando el muro perimetral de una vivienda en horas de la medianoche sustrayendo joyas sin violencia sobre personas", "aprovecha el silencio nocturno para sustraer bienes forzando una ventana deshabitada", "trepa por un balcón colonial apoderándose de objetos de valor sin intimidar a morador alguno", "ingresa a un depósito cerrado escalando un tejado para sustraer mercancía"],
      "distractores": ["Robo Genérico (Art. 455 CP)", "Hurto Simple (Art. 451 CP)", "Apropiación Indebida Calificada (Art. 468 CP)"]
    },
    {
      "tipo": "Robo Propio o Genérico",
      "art": "Art. 455 del Código Penal",
      "penalidad": "Presidio de seis a doce años.",
      "fundamentacion": "Quien por medio de violencia o amenazas graves contra la persona haya constreñido a la entrega o tolerado el desapoderamiento.",
      "pista": "La violencia (vis física) o amenaza (vis compulsiva) es el medio determinante del desapoderamiento coetáneo.",
      "sujeto_activo": ["El sujeto armado", "Un asaltante en la vía pública", "El individuo amenazante", "El imputado interceptando un transeúnte"],
      "accion": ["apunta con un arma simulada a un peatón obligándolo a entregar su teléfono bajo amenaza de muerte", "somete violentamente a una persona sujetándola por el cuello para despojarla de su cartera", "intimida con un puñal al cajero exigiendo la entrega del dinero de la caja", "intercepta con amenazas graves a un conductor despojándolo del vehículo"],
      "distractores": ["Hurto Agravado (Art. 452 CP)", "Extorsión (Ley Contra el Secuestro y la Extorsión)", "Estafa Agravada (Art. 462 CP)"]
    },
    {
      "tipo": "Apropiación Indebida Calificada",
      "art": "Art. 468 del Código Penal",
      "penalidad": "Prisión de uno a cinco años.",
      "fundamentacion": "Si el delito sobre cosa confiada en razón de depósito legal, profesión, industria, comercio o administración.",
      "pista": "La tenencia inicial de la cosa mueble fue legítima bajo título que produce obligación de entregar o devolver, mutando en animus domini.",
      "sujeto_activo": ["El administrador de bienes", "El contador de la firma mercantil", "El comisionista judicial", "El depositario de mercancía"],
      "accion": ["recibe fondos en custodia para pagar impuestos y los dispone en provecho personal negándose a rendir cuentas", "retiene indebidamente un vehículo entregado en comodato profesional y lo vende como propio", "dispone de las maquinarias entregadas en depósito mercantil incorporándolas a su patrimonio", "se apropia del inventario confiado bajo su estricta administración fiduciaria"],
      "distractores": ["Hurto Simple (Art. 451 CP)", "Estafa Simple (Art. 462 CP)", "Peculado Doloso Propio (Ley Contra la Corrupción)"]
    },
    {
      "tipo": "Estafa Agravada",
      "art": "Art. 462 y 463 del Código Penal",
      "penalidad": "Prisión de dos a seis años.",
      "fundamentacion": "El que con artificios o medios capaces de engañar o sorprender la buena fe de otro, induciéndole en error, procure para sí un provecho injusto con perjuicio ajeno.",
      "pista": "El ardid, engaño y la puesta en escena (mise en scène) provocaron el acto voluntario de disposición patrimonial de la víctima.",
      "sujeto_activo": ["El falso gestor inmobiliario", "Un intermediario financiero ficticio", "El impostor de títulos", "El promotor fraudulento"],
      "accion": ["falsifica títulos de propiedad de un inmueble ajeno vendiéndolo a un comprador de buena fe que desembolsa el precio", "simula solvencia bancaria inexistente para obtener transferencias dinerarias de múltiples inversionistas", "aparenta ser funcionario judicial autorizado cobrando aranceles falsos a las partes", "utiliza cheques sin provisión de fondos en un negocio simulado obteniendo bienes de alto valor"],
      "distractores": ["Apropiación Indebida (Art. 466 CP)", "Extorsión (Art. 459 CP)", "Frustración de Crédito (Art. 465 CP)"]
    },
    {
      "tipo": "Resistencia a la Autoridad",
      "art": "Art. 218 del Código Penal",
      "penalidad": "Prisión de uno a tres años.",
      "fundamentacion": "Cualquiera que use violencia o amenaza para oponerse a un funcionario público en el cumplimiento de sus deberes legales.",
      "pista": "Afectación del bien jurídico 'Administración Pública' mediante oposición física o intimidatoria al acto legítimo de un funcionario.",
      "sujeto_activo": ["El conductor fiscalizado", "El investigado en allanamiento", "El ciudadano en flagrancia", "El requerido en control de identidad"],
      "accion": ["empuja e increpa físicamente a los agentes de policía impidiendo la ejecución de una orden judicial de aprehensión legítima", "amenaza de muerte a los funcionarios policiales cuando procedían a su retención en punto de control", "bloquea con violencia el ingreso de los peritos del Ministerio Público al recinto procesal", "agrede verbal y físicamente al alguacil ejecutor al momento de notificar la medida cautelar"],
      "distractores": ["Ultraje a Funcionario Público (Art. 222 CP)", "Lesiones Personales (Art. 413 CP)", "Quebrantamiento de Condena (Art. 258 CP)"]
    },
    {
      "tipo": "Falso Testimonio",
      "art": "Art. 242 del Código Penal",
      "penalidad": "Prisión de uno a tres años.",
      "fundamentacion": "El que deponiendo como testigo ante la autoridad judicial afirme lo falso, niegue lo verdadero o calle, total o parcialmente, lo que sabe.",
      "pista": "Declaración mendaz o reticente de un testigo juramentado ante un juez o fiscal en causa penal.",
      "sujeto_activo": ["El testigo presencial juramentado", "El declarante en juicio oral", "El testigo clave en audiencia", "El deponente en fase preparatoria"],
      "accion": ["afirma bajo juramento haber visto al acusado en otra ciudad a sabiendas de que estuvo en el lugar de los hechos", "niega haber presenciado el delito a pesar de haber firmado el acta de reconocimiento inicial", "oculta maliciosamente la identidad del autor material a quien reconoció plenamente", "declara falsamente sobre el estado de sobriedad del conductor para encubrirlo"],
      "distractores": ["Perjurio en Juicio Civil", "Acusación y Denuncia Falsa (Art. 239 CP)", "Encubrimiento Simple (Art. 254 CP)"]
    },
    {
      "tipo": "Encubrimiento por Receptación / Ayuda",
      "art": "Art. 254 del Código Penal",
      "penalidad": "Prisión de uno a tres meses o de seis meses a un año.",
      "fundamentacion": "Los que sin concierto previo al delito ayuden a los autores a eludir la justicia o asegurar el provecho.",
      "pista": "La intervención del sujeto es estrictamente POSTERIOR a la consumación del delito principal y sin concierto previo.",
      "sujeto_activo": ["El pariente no exceptuado", "Un tercero contactado tras el hecho", "El conocido del homicida", "El receptor de las especies"],
      "accion": ["ayuda al autor de un asalto a ocultar el arma utilizada inmediatamente después de cometido el hecho, sin previo acuerdo", "esconde en su bodega los objetos robados sabiendo su procedencia delictual para evitar la incautación", "facilita su vehículo para la fuga del perpetrador tras enterarse del crimen ya consumado", "limpia las manchas de sangre de la escena por solicitud del homicida luego del delito"],
      "distractores": ["Coautoría Material (Art. 83 CP)", "Complicidad Necesaria (Art. 84 Ord. 1 CP)", "Agavillamiento (Art. 286 CP)"]
    },
    {
      "tipo": "Agavillamiento (Asociación Ilícita)",
      "art": "Art. 286 del Código Penal",
      "penalidad": "Prisión de dos a cinco años.",
      "fundamentacion": "Cuando dos o más personas se asocien con el fin de cometer delitos, cada una de ellas será penada por el solo hecho de la asociación.",
      "pista": "Delito de peligro abstracto que se perfecciona por el mero acuerdo asociativo permanente, sin requerir la consumación de los delitos planificados.",
      "sujeto_activo": ["Un grupo de cuatro individuos", "La cuadrilla organizada", "Los tres miembros del grupo", "La asociación delictiva"],
      "accion": ["acuerdan de forma estructurada y permanente reunirse periódicamente para planificar hurtos sistemáticos en locales comerciales", "forman una banda permanente provista de logística para el desvalijamiento de vehículos", "crean una estructura ilícita permanente destinada a la comercialización ilícita de insumos", "establecen un pacto asociativo continuo para cometer fraudes bancarios coordinados"],
      "distractores": ["Delincuencia Organizada (Ley Orgánica Contra la Delincuencia Organizada)", "Complicidad Correspectiva (Art. 424 CP)", "Instigación a Delinquir (Art. 283 CP)"]
    },
    {
      "tipo": "Lesiones Graves",
      "art": "Art. 415 del Código Penal",
      "penalidad": "Prisión de uno a cuatro años.",
      "fundamentacion": "Si el hecho ha causado inhabilitación permanente de algún sentido o de un órgano, o una enfermedad mental o corporal de más de veinte días.",
      "pista": "El daño físico ocasiona incapacidad temporal por más de veinte días o debilitamiento permanente de un órgano o sentido.",
      "sujeto_activo": ["El agresor en riña pública", "Un atacante con botellazo", "El individuo en enfrentamiento", "El procesado por golpiza"],
      "accion": ["causa fractura mandibular a la víctima generándole incapacidad para el trabajo y reposo médico de 35 días", "ocasiona un traumatismo ocular que debilita permanentemente la agudeza visual del agraviado", "provoca una herida profunda en el brazo que requiere rehabilitación motriz por más de 40 días", "ocasiona pérdida de tres piezas dentales con deformación no permanente pero sí grave"],
      "distractores": ["Lesiones Gravísimas (Art. 414 CP)", "Lesiones Leves (Art. 416 CP)", "Homicidio Frustrado (Art. 405 en rel. Art. 80 CP)"]
    }
  ];

  /// Generates a randomized, anti-cheat question for a given level and variant
  static QuizQuestion getQuestionForLevel(int level, {int? variantId}) {
    final effectiveVariant = variantId ?? (_rng.nextInt(5) + 1);
    
    // Select base typology cyclically across 3000 levels
    final typologyIndex = (level - 1 + (effectiveVariant * 7)) % _tipologiasPenales.length;
    final tipologia = _tipologiasPenales[typologyIndex];

    final sujetos = tipologia["sujeto_activo"] as List<String>;
    final acciones = tipologia["accion"] as List<String>;
    final distractores = tipologia["distractores"] as List<String>;

    final sujeto = sujetos[(level + effectiveVariant) % sujetos.length];
    final accion = acciones[(level * 3 + effectiveVariant) % acciones.length];

    final casoTexto = "CASO FORENSE N° ${level.toString().padLeft(4, '0')}-$effectiveVariant:\n"
        "$sujeto $accion en jurisdicción penal correspondiente.\n\n"
        "Pregunta de Calificación: Conforme al Código Penal Venezolano, ¿cuál es la tipificación exacta del hecho y la responsabilidad aplicable?";

    final respuestaCorrecta = "${tipologia['tipo']} (${tipologia['art']})";

    // Shuffle options reproducibly or randomly
    final todasOpciones = <String>[respuestaCorrecta, ...distractores];
    todasOpciones.shuffle(_rng);

    final correctIndex = todasOpciones.indexOf(respuestaCorrecta);

    return QuizQuestion(
      id: level * 10 + effectiveVariant,
      nivel: level,
      variantId: effectiveVariant,
      caso: casoTexto,
      opciones: todasOpciones,
      respuestaCorrectaIndex: correctIndex,
      fundamentacionLegal: "FUNDAMENTACIÓN JURÍDICA: ${tipologia['art']}.\n\n"
          "${tipologia['fundamentacion']}\n\nPena Aplicable: ${tipologia['penalidad']}",
      pistaVaga: "DICTAMEN ORIENTATIVO: ${tipologia['pista']}",
      tipoDelito: tipologia['tipo'] as String,
    );
  }
}

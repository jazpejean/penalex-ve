/// Catálogo de vicios procesales del proceso penal venezolano.
///
/// Base legal verificada:
/// - COPP arts. 174 (licitud), 175 (nulidades absolutas), 176 (renovación),
///   177 (saneamiento), 178 (convalidación), 179 (declaración), 180 (efectos).
/// - COPP arts. 191-193 (inspección de personas y vehículos), 196-198 (allanamiento).
/// - CRBV arts. 25 (nulidad de actos), 44 (libertad personal), 47 (hogar
///   inviolable), 49 (debido proceso).
///
/// El detector es una HERRAMIENTA DE APOYO: identifica indicios y cita la norma
/// para que el profesional verifique siempre contra el expediente y las fuentes.
class VicioProcesal {
  final String id;
  final String titulo;
  final String categoria;
  final String norma;
  final String gravedad;
  final String momentoAlegar;
  final String accion;
  final String descripcion;
  final List<String> patrones;

  const VicioProcesal({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.norma,
    required this.gravedad,
    required this.momentoAlegar,
    required this.accion,
    required this.descripcion,
    required this.patrones,
  });
}

/// Resultado de una detección: el vicio y la evidencia textual encontrada.
class VicioDetectado {
  final VicioProcesal vicio;
  final String evidencia;
  final int coincidencias;

  const VicioDetectado({
    required this.vicio,
    required this.evidencia,
    required this.coincidencias,
  });
}

class CatalogoViciosProcesales {
  CatalogoViciosProcesales._();

  static const List<VicioProcesal> todos = [
    // ---------------- LIBERTAD PERSONAL ----------------
    VicioProcesal(
      id: 'detencion-sin-orden',
      titulo: 'Detención sin orden judicial ni flagrancia',
      categoria: 'Libertad personal',
      norma: 'CRBV art. 44.1 · COPP art. 175',
      gravedad: 'Nulidad absoluta',
      momentoAlegar: 'De inmediato (hábeas corpus) y en la audiencia de presentación',
      accion: 'Solicitar libertad plena y amparo a la libertad (hábeas corpus)',
      descripcion:
          'La libertad personal es inviolable. Nadie puede ser detenido sino '
          'por orden judicial, salvo flagrancia. La detención sin orden ni '
          'flagrancia es nula y el juez debe ordenar la libertad sin '
          'restricciones.',
      patrones: [
        'detenido sin orden',
        'detención arbitraria',
        'sin orden judicial',
        'no estaba cometiendo delito',
        'privado de libertad sin',
        'retenido sin orden',
      ],
    ),
    VicioProcesal(
      id: 'detencion-sin-presentacion',
      titulo: 'Detención sin presentación dentro de las 48 horas',
      categoria: 'Libertad personal',
      norma: 'CRBV art. 44.1',
      gravedad: 'Nulidad absoluta',
      momentoAlegar: 'Al vencer el lapso constitucional',
      accion: 'Solicitar libertad inmediata y responsabilidad del funcionario',
      descripcion:
          'El detenido debe ser llevado ante un juez dentro de las cuarenta y '
          'ocho (48) horas siguientes a su detención. La omisión vulnera la '
          'libertad personal y el debido proceso.',
      patrones: [
        'más de 48 horas',
        'sin presentación',
        'no fue presentado ante el juez',
        'privación prolongada',
        'cuarenta y ocho horas',
      ],
    ),
    VicioProcesal(
      id: 'incomunicacion',
      titulo: 'Incomunicación o negativa de comunicación con abogado o familia',
      categoria: 'Libertad personal',
      norma: 'CRBV art. 44.2',
      gravedad: 'Nulidad absoluta',
      momentoAlegar: 'De inmediato',
      accion: 'Denunciar ante el juez de control y el Ministerio Público',
      descripcion:
          'Toda persona detenida tiene derecho a comunicarse de inmediato con '
          'sus familiares, abogado o persona de confianza. Negar esa '
          'comunicación vicia el procedimiento.',
      patrones: [
        'no pudo comunicarse',
        'incomunicado',
        'se le negó la llamada',
        'sin acceso a abogado',
        'no se le permitió llamar',
      ],
    ),

    // ---------------- DEFENSA ----------------
    VicioProcesal(
      id: 'sin-defensor',
      titulo: 'Falta de defensor técnico o defensa deficiente',
      categoria: 'Derecho a la defensa',
      norma: 'COPP art. 175 · CRBV art. 49.1',
      gravedad: 'Nulidad absoluta',
      momentoAlegar: 'Cualquier estado y grado del proceso',
      accion: 'Solicitar nulidad y reposición; designar defensor',
      descripcion:
          'La intervención, asistencia y representación del imputado es '
          'condición de validez del proceso. Actuar sin defensor, o con un '
          'defensor que no ejerció la defensa, genera nulidad absoluta.',
      patrones: [
        'sin defensor',
        'no contó con defensa',
        'defensa técnica deficiente',
        'no estuvo asistido',
        'sin abogado defensor',
      ],
    ),
    VicioProcesal(
      id: 'sin-notificacion-cargos',
      titulo: 'Imputación sin notificación de los cargos',
      categoria: 'Derecho a la defensa',
      norma: 'CRBV art. 49.1',
      gravedad: 'Nulidad absoluta',
      momentoAlegar: 'Fase preparatoria / audiencia de imputación',
      accion: 'Solicitar nulidad de la imputación y nueva audiencia',
      descripcion:
          'Toda persona tiene derecho a ser notificada de los cargos por los '
          'cuales se le investiga. Imputar sin informar los hechos y su '
          'calificación impide ejercer la defensa.',
      patrones: [
        'no se le informó',
        'sin notificación de cargos',
        'no se le imputó formalmente',
        'no conocía los hechos',
        'sin previa imputación',
      ],
    ),
    VicioProcesal(
      id: 'sin-advertencia-derechos',
      titulo: 'Declaración sin advertencia de derechos (autoincriminación)',
      categoria: 'Derecho a la defensa',
      norma: 'CRBV art. 49.5 · COPP art. 175',
      gravedad: 'Nulidad absoluta',
      momentoAlegar: 'Al momento de la declaración o en la fase que corresponda',
      accion: 'Solicitar nulidad de la declaración y su exclusión',
      descripcion:
          'Nadie puede ser obligado a confesarse culpable ni a declarar contra '
          'sí mismo. La declaración sin advertencia de ese derecho, o bajo '
          'coacción, es nula.',
      patrones: [
        'sin advertir',
        'no se le advirtió',
        'obligado a declarar',
        'coacción',
        'presión para declarar',
        'sin informarle su derecho',
      ],
    ),

    // ---------------- PRUEBA ----------------
    VicioProcesal(
      id: 'allanamiento-sin-orden',
      titulo: 'Allanamiento sin orden judicial',
      categoria: 'Prueba ilícita',
      norma: 'COPP arts. 196-198 · CRBV art. 47',
      gravedad: 'Nulidad absoluta',
      momentoAlegar: 'Fase preparatoria / audiencia preliminar',
      accion: 'Solicitar nulidad absoluta del allanamiento y de los actos derivados',
      descripcion:
          'El hogar y todo recinto privado son inviolables; solo pueden ser '
          'allanados mediante orden judicial. La excepción de urgencia se '
          'restringe a impedir la perpetración de un delito, no a buscar '
          'pruebas de una denuncia previa (Sentencia 512/2004, SCP).',
      patrones: [
        'allanamiento sin orden',
        'entraron a la vivienda sin orden',
        'registro domiciliario sin orden',
        'sin orden de allanamiento',
        'ingresaron a la casa sin',
      ],
    ),
    VicioProcesal(
      id: 'inspeccion-sin-motivo',
      titulo: 'Inspección de persona o vehículo sin motivo suficiente',
      categoria: 'Prueba ilícita',
      norma: 'COPP arts. 191, 192 y 193',
      gravedad: 'Nulidad absoluta',
      momentoAlegar: 'Fase preparatoria / audiencia preliminar',
      accion: 'Solicitar nulidad de la inspección y de lo incautado',
      descripcion:
          'La inspección exige motivo suficiente para presumir que se ocultan '
          'objetos del delito, advertencia previa del objeto buscado, respeto '
          'al pudor y que la practique persona del mismo sexo. Sin estos '
          'requisitos, el acto nace viciado.',
      patrones: [
        'revisión sin motivo',
        'sin motivo suficiente',
        'sin advertirle',
        'revisión arbitraria',
        'inspección sin respetar',
        'requisa sin causa',
      ],
    ),
    VicioProcesal(
      id: 'sin-testigos',
      titulo: 'Registro o incautación sin testigos',
      categoria: 'Prueba ilícita',
      norma: 'COPP art. 187 y ss. · Sentencia 322/2026',
      gravedad: 'Nulidad absoluta',
      momentoAlegar: 'Fase preparatoria / juicio oral',
      accion: 'Solicitar exclusión de la evidencia sin testigos',
      descripcion:
          'El registro debe practicarse con testigos. La falta de testigos y '
          'las fallas en la cadena de custodia afectan la autenticidad e '
          'integridad de la evidencia y su valor probatorio.',
      patrones: [
        'sin testigos',
        'no hubo testigos',
        'sin presencia de testigos',
        'no se levantó testigo',
      ],
    ),
    VicioProcesal(
      id: 'cadena-custodia',
      titulo: 'Fallas en la cadena de custodia de la evidencia',
      categoria: 'Prueba ilícita',
      norma: 'COPP arts. 187 y ss. · Sentencia 322/2026',
      gravedad: 'Nulidad absoluta',
      momentoAlegar: 'Juicio oral',
      accion: 'Impugnar la integridad de la evidencia y pedir exclusión',
      descripcion:
          'Las irregularidades en la cadena de custodia exigen un análisis '
          'específico sobre autenticidad e integridad de las evidencias; su '
          'falta afecta la presunción de inocencia.',
      patrones: [
        'cadena de custodia',
        'no consta la custodia',
        'evidencia alterada',
        'sin registro de custodia',
        'integridad de la evidencia',
      ],
    ),
    VicioProcesal(
      id: 'retencion-documentos',
      titulo: 'Retención de documentos o teléfono sin flagrancia ni orden',
      categoria: 'Prueba ilícita',
      norma: 'Res. Conjunta 047391 y 109 (Gaceta 42.458) · COPP art. 175',
      gravedad: 'Nulidad absoluta',
      momentoAlegar: 'De inmediato / fase preparatoria',
      accion: 'Solicitar devolución y nulidad de la retención',
      descripcion:
          'La retención de documentación y pertenencias, incluido el teléfono, '
          'solo procede ante flagrancia o por orden judicial. Fuera de esos '
          'supuestos es arbitraria.',
      patrones: [
        'le quitaron el teléfono',
        'retuvieron su teléfono',
        'retención de documentos',
        'se quedaron con su cédula',
        'le exigieron el teléfono',
      ],
    ),

    // ---------------- MOTIVACIÓN Y COMPETENCIA ----------------
    VicioProcesal(
      id: 'falta-motivacion',
      titulo: 'Falta de motivación de la decisión',
      categoria: 'Motivación',
      norma: 'COPP art. 157 · CRBV art. 26',
      gravedad: 'Nulidad absoluta',
      momentoAlegar: 'Apelación / casación',
      accion: 'Recurrir por falta de motivación (inmotivación)',
      descripcion:
          'La decisión debe ser motivada: expresar el razonamiento que permite '
          'comprender cómo se integró el acervo probatorio y por qué se '
          'consideró acreditado el hecho. Las fórmulas conclusivas sin '
          'razonamiento no satisfacen el estándar.',
      patrones: [
        'sin motivación',
        'no motivó',
        'se limitó a transcribir',
        'fórmulas conclusivas',
        'inmotivada',
        'no expresó el razonamiento',
      ],
    ),
    VicioProcesal(
      id: 'juez-incompetente',
      titulo: 'Actuación de juez incompetente (juez natural)',
      categoria: 'Competencia',
      norma: 'CRBV arts. 49.3 y 49.4',
      gravedad: 'Nulidad absoluta',
      momentoAlegar: 'Cualquier estado y grado',
      accion: 'Solicitar nulidad de los actos y remisión al juez competente',
      descripcion:
          'Toda persona tiene derecho a ser juzgada por sus jueces naturales. '
          'Los actos del juez sin competencia son nulos de nulidad absoluta '
          '(Sentencia 446/2026, SCP).',
      patrones: [
        'juez incompetente',
        'sin competencia',
        'juez natural',
        'tribunal sin jurisdicción',
      ],
    ),
    VicioProcesal(
      id: 'doble-juzgamiento',
      titulo: 'Doble juzgamiento por los mismos hechos',
      categoria: 'Motivación',
      norma: 'CRBV art. 49.7',
      gravedad: 'Nulidad absoluta',
      momentoAlegar: 'Al momento de la acusación / audiencia preliminar',
      accion: 'Solicitar sobreseimiento o excepción de cosa juzgada',
      descripcion:
          'Ninguna persona puede ser sometida a juicio por los mismos hechos '
          'en virtud de los cuales hubiese sido juzgada anteriormente.',
      patrones: [
        'ya fue juzgado',
        'mismos hechos',
        'cosa juzgada',
        'doble juzgamiento',
      ],
    ),
  ];

  /// Vicios de la Ley Orgánica sobre el Derecho de las Mujeres a una Vida
  /// Libre de Violencia (procedimiento especial).
  static const List<VicioProcesal> violenciaGenero = [
    VicioProcesal(
      id: 'careo-sin-consentimiento',
      titulo: 'Careo a víctima de violencia de género sin su consentimiento',
      categoria: 'Prueba',
      norma: 'Ley Orgánica sobre el Derecho de las Mujeres a una Vida Libre de Violencia, art. 99',
      gravedad: 'Nulidad absoluta del medio probatorio',
      momentoAlegar: 'Fase preparatoria / juicio',
      accion: 'Solicitar nulidad del careo',
      descripcion:
          'En este procedimiento especial el careo solo procede a petición de '
          'la víctima o su representante. Ejecutarlo de oficio o a solicitud '
          'exclusiva del imputado vicia el medio probatorio.',
      patrones: [
        'careo',
        'careo con la víctima',
        'careo sin consentimiento',
      ],
    ),
    VicioProcesal(
      id: 'notificacion-victima',
      titulo: 'Empleo de la víctima para notificaciones o citaciones',
      categoria: 'Procedimiento especial',
      norma: 'Ley Orgánica sobre el Derecho de las Mujeres a una Vida Libre de Violencia, arts. 13.3 y 91',
      gravedad: 'Nulidad del acto de comunicación',
      momentoAlegar: 'Al momento del acto viciado',
      accion: 'Solicitar nulidad del acto y denunciar',
      descripcion:
          'Está prohibido emplear a las víctimas y sus familiares para '
          'realizar notificaciones y citaciones. Usar a la mujer agredida '
          'para citar al agresor vicia el acto.',
      patrones: [
        'la víctima citó',
        'la víctima notificó',
        'usaron a la víctima para',
        'citación por la víctima',
      ],
    ),
    VicioProcesal(
      id: 'omision-interprete',
      titulo: 'Omisión de intérprete bilingüe en imputación o audiencia',
      categoria: 'Procedimiento especial',
      norma: 'Ley Orgánica sobre el Derecho de las Mujeres a una Vida Libre de Violencia, art. 6.2 · COPP art. 151',
      gravedad: 'Nulidad absoluta',
      momentoAlegar: 'Al momento del acto viciado',
      accion: 'Solicitar nulidad de la actuación y reposición con intérprete',
      descripcion:
          'El idioma oficial es el castellano bajo pena de nulidad. Para las '
          'mujeres de pueblos indígenas con dificultad de acceso integral a la '
          'información, el Estado debe proveer traducciones y asistencia de '
          'expertos bilingües. Omitir esa garantía en la imputación o la '
          'audiencia preliminar causa nulidad absoluta.',
      patrones: [
        'sin intérprete',
        'no se le proveyó traducción',
        'no entiende el idioma',
        'pueblo indígena',
        'sin asistencia bilingüe',
      ],
    ),
  ];

  /// Vicios de la fase de juicio oral y de actos con defectos formales.
  static const List<VicioProcesal> juicioYFormales = [
    VicioProcesal(
      id: 'sin-registro-juicio',
      titulo: 'Falta de registro del debate oral y público',
      categoria: 'Juicio oral',
      norma: 'COPP art. 317',
      gravedad: 'Nulidad absoluta',
      momentoAlegar: 'Al cierre del debate / apelación',
      accion: 'Solicitar nulidad del juicio y reposición',
      descripcion:
          'Es obligatorio efectuar el registro del debate oral y público. Su '
          'falta destruye la validez de la sentencia definitiva porque impide '
          'controlar la valoración de la prueba.',
      patrones: [
        'no consta el registro',
        'sin registro del juicio',
        'no se grabó el debate',
        'sin acta del debate',
      ],
    ),
    VicioProcesal(
      id: 'error-material-nombre',
      titulo: 'Error material en la identificación del imputado (vicio relativo)',
      categoria: 'Defectos formales',
      norma: 'COPP arts. 176-178',
      gravedad: 'Nulidad relativa (saneable)',
      momentoAlegar: 'Mientras se realiza el acto o dentro de los 3 días / 24 horas si es oculto',
      accion: 'Solicitar saneamiento (rectificación del error)',
      descripcion:
          'Un error material en la tipografía del nombre del imputado en un '
          'acta es un vicio insustancial: no anula el acto, se sanea '
          'rectificando el error. Distinguirlo de la nulidad absoluta es '
          'clave para no perder la oportunidad procesal.',
      patrones: [
        'error material',
        'nombre mal escrito',
        'error en el nombre',
        'error de tipografía',
      ],
    ),
    VicioProcesal(
      id: 'omision-firma-testigo',
      titulo: 'Omisión de firma de testigo secundario (vicio relativo)',
      categoria: 'Defectos formales',
      norma: 'COPP arts. 176-178',
      gravedad: 'Nulidad relativa (saneable)',
      momentoAlegar: 'Dentro de los 3 días de realizado el acto',
      accion: 'Solicitar saneamiento del acta',
      descripcion:
          'La omisión de la firma de un testigo secundario en una planilla de '
          'fijación de evidencias, estando refrendada por el experto, es un '
          'vicio relativo saneable. No confundirlo con la falta de testigos '
          'en el registro (que sí afecta la prueba).',
      patrones: [
        'sin firma del testigo',
        'omisión de firma',
        'no firmó el testigo',
      ],
    ),
  ];

  static List<VicioProcesal> get completos =>
      [...todos, ...violenciaGenero, ...juicioYFormales];

  static List<String> get categorias {
    final set = <String>{};
    for (final v in completos) {
      set.add(v.categoria);
    }
    final lista = set.toList()..sort();
    return lista;
  }
}

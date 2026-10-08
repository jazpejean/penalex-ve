/// Catálogo de documentos legales venezolanos y su base legal.
///
/// Permite clasificar una petición en lenguaje natural ("redacta una solicitud
/// de medidas cautelares") y ligarla a los artículos (COPP y otras leyes) que
/// establecen los requisitos de cada documento. Solo se usan artículos vigentes.
library;

class ReferenciaLegal {
  final String leySlug;
  final String leyNombre;
  final List<String> articulos;

  const ReferenciaLegal({
    required this.leySlug,
    required this.leyNombre,
    required this.articulos,
  });
}

class TipoDocumentoLegal {
  final String id;
  final String nombre;

  /// 'abogado' | 'juez' | 'ambos'
  final String rol;

  /// Palabras/frases clave para detectar el documento en lenguaje natural.
  final List<String> palabrasClave;

  /// Leyes y artículos que establecen los requisitos del documento.
  final List<ReferenciaLegal> baseLegal;

  /// Datos que se preguntan al usuario antes de redactar.
  final List<String> datosRequeridos;

  /// Destinatario del escrito (opcional; se deduce si está vacío).
  final String destinatario;

  const TipoDocumentoLegal({
    required this.id,
    required this.nombre,
    required this.rol,
    required this.palabrasClave,
    required this.baseLegal,
    required this.datosRequeridos,
    this.destinatario = '',
  });

  /// Destinatario efectivo: el configurado o uno deducido del tipo.
  String get destinatarioEfectivo {
    if (destinatario.isNotEmpty) return destinatario;
    if (rol == 'juez') return ''; // decisión judicial: no lleva destinatario
    final n = nombre.toLowerCase();
    if (n.contains('apelacion') || n.contains('apelación') || n.contains('recurso')) {
      return 'Corte de Apelaciones';
    }
    if (n.contains('amparo')) return 'Tribunal competente en lo Constitucional';
    if (n.contains('juicio')) return 'Tribunal de Primera Instancia en Funciones de Juicio';
    if (n.contains('control') || n.contains('acusacion') || n.contains('acusación') ||
        n.contains('medida') || n.contains('cautelar') || n.contains('sobreseimiento') ||
        n.contains('nulidad') || n.contains('imputacion')) {
      return 'Tribunal de Primera Instancia en Funciones de Control';
    }
    if (n.contains('ejecucion') || n.contains('ejecución')) {
      return 'Tribunal de Ejecución';
    }
    return 'Tribunal competente';
  }

  String get baseLegalResumen => baseLegal
      .map((r) =>
          '${r.leyNombre} (${r.articulos.map((a) => 'art. $a').join(', ')})')
      .join(' · ');
}

class CatalogoDocumentos {
  CatalogoDocumentos._();

  static const _copp = 'copp';
  static const _crbv = 'crbv';
  static const _cp = 'codigo-penal';
  static const _loAmparo =
      'ley-organica-de-amparo-sobre-derechos-y-garantias-constitucionales';
  static const _loAmparoLibertad = 'ley-organica-de-amparo-a-la-libertad';
  static const _loTsj = 'ley-organica-del-tribunal-supremo-de-justicia';
  static const _leyAbogados = 'ley-de-abogados';
  static const _lopnna =
      'ley-organica-para-la-proteccion-de-ninos-ninas-y-adolescentes';

  static const List<TipoDocumentoLegal> tipos = [
    // =========================================================================
    // SOLICITUDES Y ESCRITOS DEL ABOGADO / FISCAL
    // =========================================================================
    TipoDocumentoLegal(
      id: 'medidas_cautelares',
      nombre: 'Solicitud de Medidas Cautelares',
      rol: 'abogado',
      palabrasClave: [
        'medidas cautelares',
        'medida cautelar',
        'medida de coercion',
        'medida preventiva',
        'medida privativa',
      ],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['236', '237', '238', '242', '244', '245', '250']),
        ReferenciaLegal(leySlug: _crbv, leyNombre: 'Constitución', articulos: ['44']),
      ],
      datosRequeridos: [
        'Tribunal al que se dirige', 'Número de causa', 'Identificación del imputado',
        'Fiscalía que conoce', 'Delito(s) imputado(s)', 'Hechos relevantes',
      ],
    ),
    TipoDocumentoLegal(
      id: 'extension_presentaciones',
      nombre: 'Solicitud de Extensión de Presentaciones',
      rol: 'abogado',
      palabrasClave: [
        'extension de presentaciones',
        'ampliacion de presentaciones',
        'regimen de presentaciones',
        'activacion de presentaciones',
      ],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['242', '244']),
      ],
      datosRequeridos: [
        'Tribunal al que se dirige', 'Número de causa', 'Identificación del imputado',
        'Medida vigente y frecuencia de presentación', 'Motivos (trabajo, salud, distancia)',
      ],
    ),
    TipoDocumentoLegal(
      id: 'revision_medida',
      nombre: 'Solicitud de Revisión / Sustitución de Medida',
      rol: 'abogado',
      palabrasClave: [
        'revision de medida', 'examen de medida', 'sustitucion de medida',
        'medida cautelar sustitutiva', 'revision de la medida cautelar',
      ],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['236', '237', '238', '242', '250', '264']),
      ],
      datosRequeridos: [
        'Tribunal al que se dirige', 'Número de causa', 'Identificación del imputado',
        'Medida vigente', 'Nuevos elementos o cambio de circunstancias',
      ],
    ),
    TipoDocumentoLegal(
      id: 'decaimiento_medida',
      nombre: 'Solicitud de Decaimiento de la Medida',
      rol: 'abogado',
      palabrasClave: ['decaimiento de la medida', 'decaimiento de medida', 'cese de la medida'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['230', '236', '256']),
      ],
      datosRequeridos: [
        'Tribunal al que se dirige', 'Número de causa', 'Identificación del imputado',
        'Medida vigente y tiempo transcurrido',
      ],
    ),
    TipoDocumentoLegal(
      id: 'solicitud_libertad',
      nombre: 'Solicitud de Libertad',
      rol: 'abogado',
      palabrasClave: ['libertad plena', 'solicitud de libertad', 'excarcelacion', 'libertad sin restricciones'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['229', '230', '236', '250']),
        ReferenciaLegal(leySlug: _crbv, leyNombre: 'Constitución', articulos: ['44']),
      ],
      datosRequeridos: [
        'Tribunal al que se dirige', 'Número de causa', 'Identificación del imputado',
        'Fiscalía que conoce', 'Delito(s) imputado(s)', 'Fundamento de la solicitud',
      ],
    ),
    TipoDocumentoLegal(
      id: 'escrito_acusacion',
      nombre: 'Escrito de Acusación',
      rol: 'abogado',
      palabrasClave: ['escrito de acusacion', 'acusacion fiscal', 'escrito acusatorio'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['308']),
      ],
      datosRequeridos: [
        'Tribunal competente', 'Identificación del acusado', 'Identificación de la víctima',
        'Relación de los hechos', 'Fundamentos y calificación jurídica', 'Medios de prueba',
      ],
    ),
    TipoDocumentoLegal(
      id: 'recurso_apelacion',
      nombre: 'Recurso de Apelación',
      rol: 'abogado',
      palabrasClave: ['recurso de apelacion', 'apelacion de sentencia', 'apelacion de auto', 'interponer apelacion'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['439', '440', '441', '442', '443', '444', '445']),
      ],
      datosRequeridos: [
        'Tribunal que dictó la decisión', 'Número de causa', 'Decisión recurrida y fecha',
        'Identificación del recurrente', 'Motivos de la apelación', 'Petitorio',
      ],
    ),
    TipoDocumentoLegal(
      id: 'contestacion_apelacion',
      nombre: 'Contestación de Recurso de Apelación',
      rol: 'abogado',
      palabrasClave: ['contestacion', 'contestacion del recurso de apelacion', 'contestacion de apelacion', 'contestacion al recurso'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['440', '441', '442', '446', '449']),
      ],
      datosRequeridos: [
        'Corte de Apelaciones', 'Número de causa', 'Recurso que se contesta',
        'Identificación del recurrente y del contestante', 'Fundamentos de la contestación',
      ],
    ),
    TipoDocumentoLegal(
      id: 'recurso_casacion',
      nombre: 'Recurso de Casación',
      rol: 'abogado',
      palabrasClave: ['recurso de casacion', 'casacion penal', 'recurso de casacion penal'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['451', '452', '453', '454', '455', '456', '457', '459']),
      ],
      datosRequeridos: [
        'Sala de Casación Penal del TSJ', 'Número de causa', 'Decisión recurrida y fecha',
        'Identificación del recurrente', 'Motivos de casación', 'Petitorio',
      ],
    ),
    TipoDocumentoLegal(
      id: 'recurso_revision',
      nombre: 'Recurso de Revisión',
      rol: 'abogado',
      palabrasClave: ['recurso de revision', 'recurso de revisión de sentencia'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['462', '463', '464', '466', '467']),
      ],
      datosRequeridos: [
        'Tribunal competente', 'Número de causa', 'Sentencia firme que se revisa',
        'Causal de revisión', 'Identificación del solicitante',
      ],
    ),
    TipoDocumentoLegal(
      id: 'nulidad',
      nombre: 'Solicitud de Nulidad',
      rol: 'abogado',
      palabrasClave: ['nulidad absoluta', 'solicitud de nulidad', 'nulidad del acto'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['174', '175', '176', '177', '178', '179', '180']),
      ],
      datosRequeridos: [
        'Tribunal al que se dirige', 'Número de causa', 'Acto que se impugna', 'Motivo de nulidad',
      ],
    ),
    TipoDocumentoLegal(
      id: 'oposicion_medida',
      nombre: 'Oposición a Medida Cautelar',
      rol: 'abogado',
      palabrasClave: ['oposicion', 'oposicion a medida', 'oposicion a la medida', 'oposicion a la privativa'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['236', '250']),
      ],
      datosRequeridos: [
        'Tribunal al que se dirige', 'Número de causa', 'Identificación del imputado',
        'Medida impuesta y fecha', 'Fundamentos de la oposición',
      ],
    ),
    TipoDocumentoLegal(
      id: 'sobreseimiento',
      nombre: 'Solicitud de Sobreseimiento',
      rol: 'abogado',
      palabrasClave: ['sobreseimiento', 'sobreseimiento de la causa', 'sobreseimiento por prescripcion'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['300', '301', '302', '304']),
      ],
      datosRequeridos: [
        'Tribunal competente', 'Número de causa', 'Identificación del imputado',
        'Delito(s) imputado(s)', 'Causal de sobreseimiento',
      ],
    ),
    TipoDocumentoLegal(
      id: 'prescripcion',
      nombre: 'Solicitud de Prescripción de la Acción Penal',
      rol: 'abogado',
      palabrasClave: ['prescripcion de la accion penal', 'prescripcion de la accion', 'solicitud de prescripcion'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['49', '300']),
        ReferenciaLegal(leySlug: _cp, leyNombre: 'Código Penal', articulos: ['108', '109', '110']),
      ],
      datosRequeridos: [
        'Tribunal competente', 'Número de causa', 'Identificación del imputado',
        'Delito(s) y fecha de los hechos', 'Tiempo transcurrido',
      ],
    ),
    TipoDocumentoLegal(
      id: 'acuerdo_reparatorio',
      nombre: 'Solicitud de Acuerdo Reparatorio',
      rol: 'abogado',
      palabrasClave: [
        'acuerdo reparatorio', 'celebracion de acuerdo reparatorio',
        'extincion por acuerdo reparatorio', 'cumplimiento de acuerdo reparatorio',
      ],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['40', '41', '42', '120']),
      ],
      datosRequeridos: [
        'Tribunal de control', 'Número de causa', 'Identificación del imputado y la víctima',
        'Delito(s) imputado(s)', 'Términos del acuerdo de reparación',
      ],
    ),
    TipoDocumentoLegal(
      id: 'extincion_accion_penal',
      nombre: 'Solicitud de Extinción de la Acción Penal',
      rol: 'abogado',
      palabrasClave: ['extincion de la accion penal', 'extincion de la accion', 'causas de extincion'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['49', '161', '300']),
      ],
      datosRequeridos: [
        'Tribunal competente', 'Número de causa', 'Identificación del imputado',
        'Causal de extinción (prescripción, muerte, amnistía, cumplimiento de acuerdo)',
      ],
    ),
    TipoDocumentoLegal(
      id: 'solicitud_suspension_condicional',
      nombre: 'Solicitud de Suspensión Condicional del Proceso',
      rol: 'abogado',
      palabrasClave: [
        'solicitud de suspension condicional', 'suspension condicional del proceso',
        'solicito la suspension condicional',
      ],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['43', '44', '45', '47']),
      ],
      datosRequeridos: [
        'Tribunal de control', 'Número de causa', 'Identificación del imputado',
        'Delito(s) imputado(s)', 'Condiciones que ofrece cumplir',
      ],
    ),
    TipoDocumentoLegal(
      id: 'archivo_judicial',
      nombre: 'Solicitud de Archivo Judicial / Fiscal',
      rol: 'abogado',
      palabrasClave: ['archivo judicial', 'archivo fiscal', 'solicitud de archivo'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['295', '296', '297', '298', '364']),
      ],
      datosRequeridos: [
        'Tribunal / Fiscalía', 'Número de causa', 'Identificación del imputado',
        'Motivo del archivo (falta de elementos, vencimiento de lapso)',
      ],
    ),
    TipoDocumentoLegal(
      id: 'caucion_juratoria',
      nombre: 'Solicitud de Caución Juratoria',
      rol: 'abogado',
      palabrasClave: ['caucion juratoria', 'caución juratoria', 'caución personal'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['242', '245', '246', '247', '249']),
      ],
      datosRequeridos: [
        'Tribunal de control', 'Número de causa', 'Identificación del imputado',
        'Datos del fiador (nombre, cédula, domicilio)', 'Capacidad económica',
      ],
    ),
    TipoDocumentoLegal(
      id: 'consignacion_fiadores',
      nombre: 'Consignación de Fiadores',
      rol: 'abogado',
      palabrasClave: ['consignacion de fiadores', 'consignacion de fiador', 'consignacion de recaudos de fiador'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['242', '244']),
      ],
      datosRequeridos: [
        'Tribunal competente', 'Número de causa', 'Identificación del imputado',
        'Datos del(los) fiador(es) y recaudos consignados',
      ],
    ),
    TipoDocumentoLegal(
      id: 'traslado_medico',
      nombre: 'Solicitud de Traslado Médico',
      rol: 'abogado',
      palabrasClave: ['traslado medico', 'traslado médico', 'traslado a centro de salud'],
      baseLegal: [
        ReferenciaLegal(leySlug: _crbv, leyNombre: 'Constitución', articulos: ['43', '83']),
      ],
      datosRequeridos: [
        'Tribunal / centro penitenciario', 'Número de causa', 'Identificación del detenido',
        'Condición médica y centro de salud de destino',
      ],
    ),
    TipoDocumentoLegal(
      id: 'contestacion_acusacion',
      nombre: 'Contestación de Acusación Fiscal',
      rol: 'abogado',
      palabrasClave: ['contestacion', 'contestacion de la acusacion', 'contestacion de acusacion fiscal', 'contestacion de la acusacion penal'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['305', '308', '311', '326', '328', '330', '343']),
      ],
      datosRequeridos: [
        'Tribunal de control', 'Número de causa', 'Identificación del acusado',
        'Fundamentos de la defensa', 'Medios de prueba de la defensa',
      ],
    ),
    TipoDocumentoLegal(
      id: 'promocion_pruebas',
      nombre: 'Escrito de Promoción de Pruebas',
      rol: 'abogado',
      palabrasClave: ['promocion de pruebas', 'escrito de promocion de pruebas', 'promoción de pruebas penales'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['305', '311', '326']),
      ],
      datosRequeridos: [
        'Tribunal competente', 'Número de causa', 'Identificación de la parte promovente',
        'Pruebas a promover (documentales, testimoniales, periciales)',
      ],
    ),
    TipoDocumentoLegal(
      id: 'inspeccion_judicial',
      nombre: 'Solicitud de Inspección Judicial / Ocular',
      rol: 'abogado',
      palabrasClave: ['inspeccion judicial', 'inspección ocular', 'inspeccion ocular', 'solicitud de inspeccion'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['264', '265']),
      ],
      datosRequeridos: [
        'Tribunal al que se dirige', 'Número de causa', 'Identificación del solicitante',
        'Lugar y objeto de la inspección', 'Finalidad de la inspección',
      ],
    ),
    TipoDocumentoLegal(
      id: 'reconocimiento_rueda',
      nombre: 'Solicitud de Reconocimiento en Rueda de Individuos',
      rol: 'abogado',
      palabrasClave: ['reconocimiento en rueda', 'reconocimiento en rueda de individuos', 'rueda de individuos'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['236', '263']),
      ],
      datosRequeridos: [
        'Juez de control', 'Número de causa', 'Identificación del imputado',
        'Identificación del reconocedor', 'Circunstancias del reconocimiento',
      ],
    ),
    TipoDocumentoLegal(
      id: 'reapertura_investigacion',
      nombre: 'Solicitud de Reapertura de la Investigación',
      rol: 'abogado',
      palabrasClave: ['reapertura de la investigacion', 'reapertura de investigacion'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['297', '298']),
      ],
      datosRequeridos: [
        'Juez de control / Fiscalía', 'Número de causa', 'Identificación de la víctima',
        'Nuevos elementos de convicción',
      ],
    ),
    TipoDocumentoLegal(
      id: 'copias_expediente',
      nombre: 'Solicitud de Copias de Expediente',
      rol: 'abogado',
      palabrasClave: ['copia de expediente', 'copias de expediente', 'copia del expediente', 'copias del expediente', 'copia simple', 'copias certificadas'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['295', '296']),
        ReferenciaLegal(leySlug: _crbv, leyNombre: 'Constitución', articulos: ['49']),
      ],
      datosRequeridos: [
        'Tribunal / Fiscalía', 'Número de causa', 'Identificación del solicitante',
        'Tipo de copia (simple o certificada)',
      ],
    ),
    TipoDocumentoLegal(
      id: 'defensor_publico',
      nombre: 'Solicitud de Defensor Público',
      rol: 'abogado',
      palabrasClave: ['defensor publico', 'designacion de defensor publico', 'nombramiento de defensor publico'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['127']),
        ReferenciaLegal(leySlug: _crbv, leyNombre: 'Constitución', articulos: ['49']),
      ],
      datosRequeridos: [
        'Tribunal competente', 'Número de causa', 'Identificación del imputado',
        'Motivo (carencia de defensa privada)',
      ],
    ),
    TipoDocumentoLegal(
      id: 'avocamiento',
      nombre: 'Solicitud de Avocamiento',
      rol: 'abogado',
      palabrasClave: ['avocamiento', 'solicitud de avocamiento', 'avocamiento ante la sala'],
      baseLegal: [
        ReferenciaLegal(leySlug: _loTsj, leyNombre: 'Ley Orgánica del TSJ', articulos: ['107', '108', '109']),
      ],
      datosRequeridos: [
        'Sala del TSJ', 'Número de causa', 'Tribunal que conoce', 'Motivo del avocamiento',
      ],
    ),
    TipoDocumentoLegal(
      id: 'poder_penal',
      nombre: 'Poder Penal (otorgamiento)',
      rol: 'abogado',
      palabrasClave: [
        'poder penal', 'poder especial penal', 'otorgamiento de poder',
        'poder para acusar', 'poder para querella', 'poder para denuncia', 'adherirse a la acusacion',
      ],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['251', '252']),
        ReferenciaLegal(leySlug: _cp, leyNombre: 'Código Penal', articulos: ['292', '464']),
      ],
      datosRequeridos: [
        'Identificación del otorgante', 'Identificación del apoderado',
        'Facultades que se otorgan', 'Tribunal / Fiscalía donde se consignará',
      ],
    ),
    TipoDocumentoLegal(
      id: 'revocatoria_poder',
      nombre: 'Revocatoria de Poder / Defensor',
      rol: 'abogado',
      palabrasClave: ['revocatoria de poder', 'revoca poder', 'revocatoria de defensor', 'revocacion de defensor'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['139', '144']),
      ],
      datosRequeridos: [
        'Identificación del otorgante', 'Defensor/apoderado que se revoca',
        'Nuevo defensor (si aplica)', 'Número de causa',
      ],
    ),
    TipoDocumentoLegal(
      id: 'juramentacion',
      nombre: 'Juramentación de Defensor',
      rol: 'abogado',
      palabrasClave: ['juramentacion', 'acta de juramentacion', 'juramentacion de defensor'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['139', '144']),
      ],
      datosRequeridos: [
        'Tribunal competente', 'Número de causa', 'Identificación del defensor y del imputado',
      ],
    ),
    TipoDocumentoLegal(
      id: 'obstaculos_accion',
      nombre: 'Obstáculos al Ejercicio de la Acción Penal (Excepciones)',
      rol: 'abogado',
      palabrasClave: ['obstaculos al ejercicio de la accion penal', 'excepciones', 'excepcion penal'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['28']),
        ReferenciaLegal(leySlug: _lopnna, leyNombre: 'LOPNNA', articulos: ['615']),
      ],
      datosRequeridos: [
        'Tribunal competente', 'Número de causa', 'Identificación del imputado',
        'Excepción u obstáculo que se opone',
      ],
    ),
    TipoDocumentoLegal(
      id: 'contrato_servicios',
      nombre: 'Contrato de Prestación de Servicios Profesionales',
      rol: 'abogado',
      palabrasClave: ['contrato de servicios profesionales', 'contrato de honorarios', 'contrato de prestacion de servicios'],
      baseLegal: [
        ReferenciaLegal(leySlug: _leyAbogados, leyNombre: 'Ley de Abogados', articulos: ['3', '22']),
      ],
      datosRequeridos: [
        'Identificación del abogado y del cliente', 'Servicios contratados',
        'Honorarios y forma de pago', 'Duración del contrato',
      ],
    ),
    TipoDocumentoLegal(
      id: 'amparo',
      nombre: 'Acción de Amparo Constitucional',
      rol: 'abogado',
      palabrasClave: ['amparo constitucional', 'accion de amparo', 'recurso de amparo', 'amparo'],
      baseLegal: [
        ReferenciaLegal(leySlug: _loAmparo, leyNombre: 'Ley Orgánica de Amparo', articulos: ['6', '18']),
        ReferenciaLegal(leySlug: _crbv, leyNombre: 'Constitución', articulos: ['27']),
      ],
      datosRequeridos: [
        'Tribunal competente', 'Identificación del accionante', 'Presuntos agraviantes',
        'Derechos constitucionales violados', 'Hechos y actos lesivos',
      ],
    ),
    TipoDocumentoLegal(
      id: 'habeas_corpus',
      nombre: 'Amparo a la Libertad y Seguridad Personal (Habeas Corpus)',
      rol: 'abogado',
      palabrasClave: ['habeas corpus', 'amparo a la libertad', 'amparo a la libertad personal'],
      baseLegal: [
        ReferenciaLegal(leySlug: _loAmparoLibertad, leyNombre: 'Ley de Amparo a la Libertad', articulos: ['1', '4', '5']),
        ReferenciaLegal(leySlug: _crbv, leyNombre: 'Constitución', articulos: ['27']),
      ],
      datosRequeridos: [
        'Tribunal competente', 'Identificación del detenido', 'Lugar y fecha de la detención',
        'Autoridad que practicó la detención',
      ],
    ),

    // =========================================================================
    // DOCUMENTOS DEL JUEZ (decisiones)
    // =========================================================================
    TipoDocumentoLegal(
      id: 'sentencia_absolutoria',
      nombre: 'Sentencia Absolutoria',
      rol: 'juez',
      palabrasClave: ['sentencia absolutoria', 'absolutoria'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['348']),
      ],
      datosRequeridos: [
        'Tribunal y juez', 'Número de causa', 'Identificación del acusado y la víctima',
        'Delito(s) y calificación fiscal', 'Hechos probados', 'Análisis y valoración de pruebas',
        'Fundamentos de hecho y de derecho',
      ],
    ),
    TipoDocumentoLegal(
      id: 'sentencia_condenatoria',
      nombre: 'Sentencia Condenatoria',
      rol: 'juez',
      palabrasClave: ['sentencia condenatoria', 'condenatoria'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['349']),
        ReferenciaLegal(leySlug: _cp, leyNombre: 'Código Penal', articulos: ['37']),
      ],
      datosRequeridos: [
        'Tribunal y juez', 'Número de causa', 'Identificación del acusado y la víctima',
        'Delito(s) y calificación fiscal', 'Hechos probados', 'Análisis y valoración de pruebas',
        'Dosimetría de la pena',
      ],
    ),
    TipoDocumentoLegal(
      id: 'suspension_condicional',
      nombre: 'Suspensión Condicional del Proceso (decisión)',
      rol: 'juez',
      palabrasClave: ['decreto de suspension condicional', 'otorgamiento de suspension condicional'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['43', '44', '45']),
      ],
      datosRequeridos: [
        'Tribunal y juez', 'Número de causa', 'Identificación del imputado',
        'Delito(s) imputado(s)', 'Condiciones impuestas',
      ],
    ),
    TipoDocumentoLegal(
      id: 'publicacion_sentencia',
      nombre: 'Publicación de Sentencia',
      rol: 'juez',
      palabrasClave: ['publicacion de sentencia', 'publicacion del fallo', 'publicación de la sentencia'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['159', '348', '349']),
      ],
      datosRequeridos: [
        'Tribunal y juez', 'Número de causa', 'Identificación del acusado',
        'Tipo de sentencia (absolutoria/condenatoria)', 'Hechos probados y fundamentos',
      ],
    ),
    TipoDocumentoLegal(
      id: 'acta_inspeccion',
      nombre: 'Acta de Inspección Judicial',
      rol: 'juez',
      palabrasClave: ['acta de inspeccion judicial', 'acta de inspeccion ocular', 'inspeccion del tribunal'],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: ['264', '265']),
      ],
      datosRequeridos: [
        'Tribunal y juez', 'Número de causa', 'Lugar, fecha y hora de la inspección',
        'Descripción de lo inspeccionado', 'Partes presentes',
      ],
    ),
    TipoDocumentoLegal(
      id: 'auxilio_judicial',
      nombre: 'Auxilio Judicial',
      rol: 'ambos',
      palabrasClave: [
        'auxilio judicial', 'asistencia judicial', 'exhorto', 'rogatoria',
        'comision', 'deprecado',
      ],
      baseLegal: [
        ReferenciaLegal(leySlug: _copp, leyNombre: 'COPP', articulos: const []),
      ],
      datosRequeridos: [
        'Tribunal requerido', 'Tribunal requirente', 'Número de causa',
        'Diligencia solicitada', 'Motivo de la solicitud',
      ],
    ),
  ];

  /// Normaliza texto para comparación (minúsculas y sin acentos).
  static String normalizar(String texto) {
    const acentos = 'áéíóúüñÁÉÍÓÚÜÑ';
    const sinAcento = 'aeiouunAEIOUUN';
    var out = texto.toLowerCase();
    for (var i = 0; i < acentos.length; i++) {
      out = out.replaceAll(acentos[i], sinAcento[i]);
    }
    return out;
  }

  /// Clasifica una petición en lenguaje natural. Devuelve null si no hay
  /// coincidencia clara.
  static TipoDocumentoLegal? clasificar(String texto) {
    final t = normalizar(texto);
    TipoDocumentoLegal? mejor;
    var mejorPuntaje = 0;

    for (final tipo in tipos) {
      var puntaje = 0;
      for (final kw in tipo.palabrasClave) {
        final k = normalizar(kw);
        if (t.contains(k)) {
          // Las frases largas (más específicas) pesan más.
          puntaje += 1 + (k.length >= 12 ? 2 : (k.length >= 8 ? 1 : 0));
        }
      }
      if (puntaje > mejorPuntaje) {
        mejorPuntaje = puntaje;
        mejor = tipo;
      }
    }

    return mejorPuntaje >= 1 ? mejor : null;
  }
}

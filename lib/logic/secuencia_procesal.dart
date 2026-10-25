/// Catálogo de lapsos procesales por vía + generador de secuencia.
///
/// Fuente: "Guía de Lapsos Procesales Penales" (COPP 2021, Ley de
/// Violencia contra la Mujer y Código Orgánico Penitenciario), archivo
/// entregado por el usuario. EXCLUYE la fase de ejecución de la pena
/// (sección 9 de la guía), según decisión del usuario.
///
/// Regla de fidelidad: cada lapso copia EXACTAMENTE el lapso, el tipo de
/// cómputo y la base legal de la guía. Los textos de descripción son
/// redacción propia breve. Los datos que el usuario aportó y que la guía
/// NO contiene se marcan con `pendienteVerificacion` = true.
library;

import '../models/lapso_procesal.dart';
import 'lapsos_engine.dart';

/// Lapso con marca de verificación pendiente (dato aportado por el
/// usuario, aún no cotejado contra el texto de la ley).
class LapsoCatalogo extends LapsoProcesal {
  const LapsoCatalogo({
    required super.via,
    required super.fase,
    required super.acto,
    required super.unidad,
    required super.computo,
    required super.baseLegal,
    super.cantidadMin,
    super.cantidadMax,
    super.antelacion,
    super.gatillo,
    super.descripcion,
    super.consecuencia,
    this.pendienteVerificacion = false,
  });

  /// true si el dato proviene del usuario y falta cotejarlo con la ley.
  final bool pendienteVerificacion;
}

/// Identificadores de gatillos (actos que disparan lapsos posteriores).
class Gatillos {
  static const String acusacion = 'acusacion';
  static const String autoApertura = 'autoApertura';
  static const String recepcionExpediente = 'recepcionExpediente';
  static const String sentencia = 'sentencia';
  static const String preliminar = 'preliminar';
}

/// Catálogo por vía (fases 1-8 de la guía; se EXCLUYE la ejecución).
List<LapsoCatalogo> catalogoPorVia(ViaProcesal via) {
  switch (via) {
    case ViaProcesal.ordinario:
      return _ordinario;
    case ViaProcesal.violencia:
      return _violencia;
    case ViaProcesal.menosGraves:
      return _menosGraves;
  }
}

// ─────────────────────────── ORDINARIO (COPP) ───────────────────────────

const List<LapsoCatalogo> _ordinario = <LapsoCatalogo>[
  // Fase Preparatoria (desde la audiencia de presentación)
  LapsoCatalogo(
    via: ViaProcesal.ordinario,
    fase: 'Preparatoria',
    acto: 'Revisión judicial de medidas de coerción',
    unidad: UnidadLapso.meses,
    computo: TipoComputo.continuo,
    cantidadMin: 3,
    baseLegal: 'Art. 250 COPP',
    descripcion: 'Cada tres meses el juez revisa la necesidad de mantener la medida de coerción personal.',
  ),
  LapsoCatalogo(
    via: ViaProcesal.ordinario,
    fase: 'Preparatoria',
    acto: 'Plazo prudencial de la investigación (delitos ordinarios)',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.continuo,
    cantidadMin: 30,
    baseLegal: 'Art. 295 COPP',
    descripcion: 'Plazo fijado por el juez para la investigación de delitos ordinarios.',
  ),
  LapsoCatalogo(
    via: ViaProcesal.ordinario,
    fase: 'Preparatoria',
    acto: 'Acto conclusivo (con imputado privado de libertad)',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.continuo,
    cantidadMin: 45,
    baseLegal: 'Art. 236 COPP',
    descripcion: 'El Ministerio Público debe presentar el acto conclusivo dentro de este lapso si el imputado está privado de libertad.',
  ),
  // Fase Intermedia (gatillo: acusación)
  LapsoCatalogo(
    via: ViaProcesal.ordinario,
    fase: 'Intermedia',
    acto: 'Convocatoria a la Audiencia Preliminar',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.habiles,
    cantidadMin: 15,
    cantidadMax: 20,
    gatillo: Gatillos.acusacion,
    baseLegal: 'Art. 309 COPP',
    descripcion: 'Desde la acusación, el juez convoca la audiencia preliminar entre 15 y 20 días hábiles.',
  ),
  LapsoCatalogo(
    via: ViaProcesal.ordinario,
    fase: 'Intermedia',
    acto: 'Cargas escritas de las partes (excepciones y pruebas)',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.habiles,
    cantidadMin: 5,
    antelacion: true,
    gatillo: Gatillos.preliminar,
    baseLegal: 'Art. 311 COPP',
    descripcion: 'Las partes pueden oponer excepciones y promover pruebas hasta 5 días hábiles ANTES de la audiencia preliminar.',
  ),
  LapsoCatalogo(
    via: ViaProcesal.ordinario,
    fase: 'Intermedia',
    acto: 'Emplazamiento ante el Juez de Juicio (Auto de Apertura)',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.habiles,
    cantidadMin: 5,
    gatillo: Gatillos.autoApertura,
    baseLegal: 'Art. 314 COPP',
    descripcion: 'Plazo común de 5 días hábiles para emplazar a las partes ante el tribunal de juicio.',
  ),
  // Fase de Juicio (gatillo: recepción del expediente)
  LapsoCatalogo(
    via: ViaProcesal.ordinario,
    fase: 'Juicio',
    acto: 'Fijación del Juicio Oral y Público',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.habiles,
    cantidadMin: 5,
    cantidadMax: 10,
    gatillo: Gatillos.recepcionExpediente,
    baseLegal: 'Art. 325 COPP',
    descripcion: 'Recibidas las actuaciones, el tribunal de juicio fija el debate entre 5 y 10 días hábiles.',
  ),
  LapsoCatalogo(
    via: ViaProcesal.ordinario,
    fase: 'Juicio',
    acto: 'Suspensión máxima permitida del debate',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.continuo,
    cantidadMin: 10,
    baseLegal: 'Art. 318 COPP',
    descripcion: 'El debate puede suspenderse por causa legal hasta 10 días continuos.',
  ),
  LapsoCatalogo(
    via: ViaProcesal.ordinario,
    fase: 'Juicio',
    acto: 'Publicación íntegra de la sentencia (si se difiere la redacción)',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.habiles,
    cantidadMin: 10,
    gatillo: Gatillos.sentencia,
    baseLegal: 'Art. 347 COPP',
    descripcion: 'Si la sentencia no se publica el mismo día, debe publicarse íntegra dentro de 10 días hábiles.',
  ),
  // Recursos (tras sentencia — días de despacho)
  LapsoCatalogo(
    via: ViaProcesal.ordinario,
    fase: 'Recursos',
    acto: 'Apelación de Sentencia Definitiva',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.despacho,
    cantidadMin: 10,
    gatillo: Gatillos.sentencia,
    baseLegal: 'Art. 445 COPP',
    descripcion: 'La sentencia definitiva se apela dentro de 10 días de despacho.',
  ),
  LapsoCatalogo(
    via: ViaProcesal.ordinario,
    fase: 'Recursos',
    acto: 'Contestación de la Apelación de Sentencia',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.despacho,
    cantidadMin: 5,
    gatillo: Gatillos.sentencia,
    baseLegal: 'Art. 446 COPP',
    descripcion: 'La contraparte contesta la apelación dentro de 5 días de despacho.',
  ),
  LapsoCatalogo(
    via: ViaProcesal.ordinario,
    fase: 'Recursos',
    acto: 'Apelación de Autos',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.despacho,
    cantidadMin: 5,
    baseLegal: 'Art. 440 COPP',
    descripcion: 'Las decisiones de mero trámite o definitivas distintas de la sentencia se apelan dentro de 5 días de despacho.',
  ),
  LapsoCatalogo(
    via: ViaProcesal.ordinario,
    fase: 'Recursos',
    acto: 'Contestación de la Apelación de Autos',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.despacho,
    cantidadMin: 3,
    baseLegal: 'Art. 441 COPP',
    descripcion: 'La contraparte contesta la apelación de autos dentro de 3 días de despacho.',
  ),
  LapsoCatalogo(
    via: ViaProcesal.ordinario,
    fase: 'Recursos',
    acto: 'Recurso de Casación',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.despacho,
    cantidadMin: 15,
    gatillo: Gatillos.sentencia,
    baseLegal: 'Art. 454 COPP',
    descripcion: 'Contra la sentencia definitiva cabe casación dentro de 15 días de despacho.',
  ),
  LapsoCatalogo(
    via: ViaProcesal.ordinario,
    fase: 'Recursos',
    acto: 'Contestación del Recurso de Casación',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.despacho,
    cantidadMin: 8,
    gatillo: Gatillos.sentencia,
    baseLegal: 'Art. 456 COPP',
    descripcion: 'La contraparte contesta la casación dentro de 8 días de despacho.',
  ),
];

// ────────────────────────── VIOLENCIA (LEY) ─────────────────────────────

const List<LapsoCatalogo> _violencia = <LapsoCatalogo>[
  LapsoCatalogo(
    via: ViaProcesal.violencia,
    fase: 'Preparatoria',
    acto: 'Investigación fiscal especializada',
    unidad: UnidadLapso.meses,
    computo: TipoComputo.continuo,
    cantidadMin: 4,
    baseLegal: 'Art. 98 LOVMV',
    descripcion: 'Lapso ordinario de la investigación especializada: máximo 4 meses.',
  ),
  LapsoCatalogo(
    via: ViaProcesal.violencia,
    fase: 'Preparatoria',
    acto: 'Acto conclusivo (con imputado privado de libertad)',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.continuo,
    cantidadMin: 30,
    baseLegal: 'Art. 98 LOVMV',
    descripcion: 'Acto conclusivo dentro de 30 días si el imputado está privado de libertad.',
  ),
  LapsoCatalogo(
    via: ViaProcesal.violencia,
    fase: 'Intermedia',
    acto: 'Audiencia Preliminar Especial',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.habiles,
    cantidadMin: 10,
    gatillo: Gatillos.acusacion,
    baseLegal: 'Art. 123 LOVMV',
    descripcion: 'La audiencia preliminar especial se fija dentro de 10 días hábiles.',
  ),
  LapsoCatalogo(
    via: ViaProcesal.violencia,
    fase: 'Juicio',
    acto: 'Fijación del Juicio Oral Especializado',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.habiles,
    cantidadMin: 10,
    cantidadMax: 20,
    gatillo: Gatillos.recepcionExpediente,
    baseLegal: 'Art. 124 LOVMV',
    descripcion: 'El juicio oral especializado se fija entre 10 y 20 días hábiles.',
  ),
  LapsoCatalogo(
    via: ViaProcesal.violencia,
    fase: 'Juicio',
    acto: 'Suspensión máxima del debate especial',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.habiles,
    cantidadMin: 5,
    baseLegal: 'Art. 125 LOVMV',
    descripcion: 'El debate especial puede suspenderse hasta 5 días hábiles.',
  ),
  LapsoCatalogo(
    via: ViaProcesal.violencia,
    fase: 'Juicio',
    acto: 'Publicación íntegra de la sentencia especial',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.habiles,
    cantidadMin: 5,
    gatillo: Gatillos.sentencia,
    baseLegal: 'Art. 126 LOVMV',
    descripcion: 'La sentencia especial se publica íntegra dentro de 5 días hábiles.',
  ),
  LapsoCatalogo(
    via: ViaProcesal.violencia,
    fase: 'Recursos',
    acto: 'Apelación de la sentencia (violencia)',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.despacho,
    cantidadMin: 3,
    gatillo: Gatillos.sentencia,
    baseLegal: 'Ley de Violencia (apelación)',
    descripcion: 'Lapso para apelar la sentencia en materia de violencia: 3 días.',
    pendienteVerificacion: true,
  ),
  LapsoCatalogo(
    via: ViaProcesal.violencia,
    fase: 'Recursos',
    acto: 'Contestación de la apelación (violencia)',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.despacho,
    cantidadMin: 3,
    gatillo: Gatillos.sentencia,
    baseLegal: 'Ley de Violencia (contestación)',
    descripcion: 'Lapso para contestar la apelación en materia de violencia: 3 días.',
    pendienteVerificacion: true,
  ),
];

// ────────────────────── MENOS GRAVES (MUNICIPAL) ────────────────────────

const List<LapsoCatalogo> _menosGraves = <LapsoCatalogo>[
  LapsoCatalogo(
    via: ViaProcesal.menosGraves,
    fase: 'Preparatoria',
    acto: 'Plazo fiscal para concluir investigación',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.continuo,
    cantidadMin: 60,
    baseLegal: 'Arts. 362-363 COPP',
    descripcion: 'Por incumplimiento de fórmulas alternativas, el fiscal tiene 60 días para concluir la investigación.',
  ),
  LapsoCatalogo(
    via: ViaProcesal.menosGraves,
    fase: 'Intermedia',
    acto: 'Convocatoria a la Audiencia Preliminar Municipal',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.habiles,
    cantidadMin: 10,
    cantidadMax: 15,
    gatillo: Gatillos.acusacion,
    baseLegal: 'Art. 365 COPP',
    descripcion: 'La audiencia preliminar municipal se convoca entre 10 y 15 días hábiles.',
  ),
  LapsoCatalogo(
    via: ViaProcesal.menosGraves,
    fase: 'Intermedia',
    acto: 'Presentación de Acusación Particular de la víctima',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.habiles,
    cantidadMin: 3,
    gatillo: Gatillos.acusacion,
    baseLegal: 'Art. 365 COPP',
    descripcion: 'La víctima puede presentar su acusación particular dentro de 3 días hábiles.',
  ),
  LapsoCatalogo(
    via: ViaProcesal.menosGraves,
    fase: 'Intermedia',
    acto: 'Nueva fijación por diferimiento de la preliminar municipal',
    unidad: UnidadLapso.dias,
    computo: TipoComputo.habiles,
    cantidadMin: 10,
    baseLegal: 'Art. 366 COPP',
    descripcion: 'Si la preliminar municipal se difiere, se refija dentro de 10 días hábiles.',
  ),
];

/// Genera los hitos de la secuencia que corren DESDE la fecha base
/// (audiencia de presentación) o que quedan "pendientes de gatillo".
///
/// [excluidos]: fechas normalizadas de feriados judiciales + días sin
/// despacho del usuario (ver [fechasExcluidasDe]).
List<HitoCalculado> generarHitosIniciales({
  required ViaProcesal via,
  required DateTime fechaBase,
  Set<DateTime>? excluidos,
}) {
  final List<HitoCalculado> hitos = <HitoCalculado>[];
  for (final LapsoCatalogo lapso in catalogoPorVia(via)) {
    if (lapso.gatillo != null) {
      // Depende de un acto posterior; se muestra como pendiente.
      hitos.add(HitoCalculado(
        lapso: lapso,
        fechaBase: fechaBase,
        pendienteDe: lapso.gatillo,
      ));
      continue;
    }
    hitos.add(calcularHito(lapso: lapso, fechaBase: fechaBase, excluidos: excluidos));
  }
  // Los hitos con gatillo se ordenan al final, agrupados por fase.
  hitos.sort((a, b) {
    final int porPendiente = (a.pendienteDe == null ? 0 : 1) - (b.pendienteDe == null ? 0 : 1);
    if (porPendiente != 0) {
      return porPendiente;
    }
    return a.lapso.fase.compareTo(b.lapso.fase);
  });
  return hitos;
}

/// Calcula un hito concreto a partir de [lapso] y [fechaBase] (fecha real
/// o tentativa del acto que lo dispara).
HitoCalculado calcularHito({
  required LapsoCatalogo lapso,
  required DateTime fechaBase,
  Set<DateTime>? excluidos,
}) {
  if (lapso.antelacion) {
    // Ej.: "hasta 5 días antes de la preliminar" — corre ANTES de fechaBase.
    final int cantidad = lapso.cantidadMin ?? 1;
    final DateTime limite = restarDiasHabiles(
        base: fechaBase, cantidad: cantidad, excluidos: excluidos);
    return HitoCalculado(lapso: lapso, fechaBase: fechaBase, fechaMin: limite);
  }
  final int cantidad = lapso.cantidadMin ?? 0;
  if (lapso.cantidadMax != null && lapso.cantidadMax != lapso.cantidadMin) {
    final int max = lapso.cantidadMax!;
    final DateTime fMin = calcularFecha(
        base: fechaBase, cantidad: cantidad, unidad: lapso.unidad, computo: lapso.computo, excluidos: excluidos);
    final DateTime fMax = calcularFecha(
        base: fechaBase, cantidad: max, unidad: lapso.unidad, computo: lapso.computo, excluidos: excluidos);
    return HitoCalculado(
      lapso: lapso,
      fechaBase: fechaBase,
      fechaMin: fMin,
      fechaMax: fMax,
    );
  }
  final DateTime fecha = calcularFecha(
      base: fechaBase, cantidad: cantidad, unidad: lapso.unidad, computo: lapso.computo, excluidos: excluidos);
  return HitoCalculado(lapso: lapso, fechaBase: fechaBase, fechaMin: fecha);
}
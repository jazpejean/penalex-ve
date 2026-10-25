/// Modelos del Calendario Judicial de Penalex VE.
///
/// Cada [LapsoProcesal] describe un acto procesal con su lapso legal
/// (fuente: Guía de Lapsos Procesales Penales basada en el COPP 2021,
/// Ley de Violencia contra la Mujer y Código Orgánico Penitenciario —
/// EXCLUYE la fase de ejecución de la pena, según decisión del usuario).
library;

/// Vía / procedimiento procesal. Determina qué tabla de lapsos aplica.
enum ViaProcesal {
  ordinario,
  violencia,
  menosGraves,
}

/// Unidad de medida del lapso.
enum UnidadLapso { horas, dias, meses, anos }

/// Tipo de cómputo según el Art. 156 COPP.
enum TipoComputo {
  /// Corre todos los días (incluye sábados, domingos y feriados).
  /// Fase Preparatoria (investigación): todos los días son continuos.
  continuo,

  /// Se excluyen sábados, domingos, feriados y días sin despacho.
  /// Fases Intermedia y de Juicio.
  habiles,

  /// Se computan estrictamente en días de despacho.
  /// Materia de Recursos (apelación, casación, revisión).
  despacho,
}

/// Un acto procesal con su lapso legal.
class LapsoProcesal {
  const LapsoProcesal({
    required this.via,
    required this.fase,
    required this.acto,
    required this.unidad,
    required this.computo,
    required this.baseLegal,
    this.cantidadMin,
    this.cantidadMax,
    this.antelacion = false,
    this.gatillo,
    this.descripcion,
    this.consecuencia,
  });

  /// Vía en la que aplica este lapso.
  final ViaProcesal via;

  /// Fase procesal (Presentación, Preparatoria, Intermedia, Juicio, Recursos).
  final String fase;

  /// Nombre del acto procesal (ej. "Fijación del Juicio Oral y Público").
  final String acto;

  /// Cantidad mínima del lapso (null si el lapso es solo un máximo).
  final int? cantidadMin;

  /// Cantidad máxima del lapso (null si es un lapso puntual).
  final int? cantidadMax;

  /// Unidad del lapso (horas, días, meses, años).
  final UnidadLapso unidad;

  /// Tipo de cómputo.
  final TipoComputo computo;

  /// Base legal (ej. "Art. 325 COPP").
  final String baseLegal;

  /// true si el lapso corre ANTES de un acto (ej. "hasta 5 días antes
  /// de la preliminar" — Art. 311).
  final bool antelacion;

  /// Nombre del acto que dispara este lapso (null = corre desde la
  /// fecha base o el hito anterior). Ej. "RecepcionExpedienteJuicio".
  final String? gatillo;

  /// Explicación en lenguaje llano (redacción propia, revisada).
  final String? descripcion;

  /// Consecuencia del vencimiento, SOLO si el COPP la fija expresamente.
  final String? consecuencia;
}

/// Hito ya calculado dentro de una secuencia procesal.
class HitoCalculado {
  const HitoCalculado({
    required this.lapso,
    required this.fechaBase,
    this.fechaMin,
    this.fechaMax,
    this.pendienteDe,
  });

  final LapsoProcesal lapso;

  /// Fecha (real o tentativa) desde la que corre este lapso.
  final DateTime fechaBase;

  /// Fecha calculada (puntual) o inicio del rango.
  final DateTime? fechaMin;

  /// Fin del rango (null si el lapso es puntual).
  final DateTime? fechaMax;

  /// Acto del que depende si aún no tiene fecha (ej. "acusación").
  final String? pendienteDe;
}

/// Útil: fecha normalizada a medianoche (para comparar días).
DateTime fechaPura(DateTime d) => DateTime(d.year, d.month, d.day);
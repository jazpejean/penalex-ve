/// Motor de cálculo de prescripción penal (Código Penal venezolano).
///
/// - Prescripción de la acción penal: art. 108 CP (términos según la pena
///   máxima del delito).
/// - Prescripción de la pena: art. 112 CP (tiempo igual a la condena más la
///   mitad, para prisión y arresto).
///
/// Cálculo 100% determinístico: la IA no interviene en fechas ni términos.
library;

enum TipoPenaPrescripcion { prision, arresto, multa }

/// Término de prescripción calculado, con su fundamento textual.
class TerminoPrescripcion {
  const TerminoPrescripcion({
    required this.titulo,
    required this.anios,
    required this.meses,
    required this.fundamento,
    this.ordinal,
    this.textoOrdinal,
  });

  /// "10 años", "3 meses", "7 años 6 meses"...
  final String titulo;
  final int anios;
  final int meses;

  /// "Art. 108, numeral 2 del Código Penal" / "Art. 112, numeral 1 CP".
  final String fundamento;

  /// Numeral del art. 108 aplicado (null para el art. 112).
  final int? ordinal;

  /// Texto literal del numeral aplicado (art. 108).
  final String? textoOrdinal;

  String get tituloLargo {
    final partes = <String>[
      if (anios > 0) '$anios ${anios == 1 ? 'año' : 'años'}',
      if (meses > 0) '$meses ${meses == 1 ? 'mes' : 'meses'}',
    ];
    return partes.join(' ');
  }
}

class PrescripcionService {
  PrescripcionService._();

  // Texto literal de los numerales del art. 108 (CP 2005).
  static const Map<int, String> _textoOrdinal108 = {
    1: 'Por quince años, si el delito mereciere pena de prisión que exceda de '
        'diez años.',
    2: 'Por diez años, si el delito mereciere pena de prisión mayor de siete '
        'años sin exceder de diez.',
    3: 'Por siete años, si el delito mereciere pena de prisión de siete años '
        'o menos.',
    4: 'Por cinco años, si el delito mereciere pena de prisión de más de tres '
        'años.',
    5: 'Por tres años, si el delito mereciere pena de prisión de tres años o '
        'menos, arresto de más de seis meses, relegación a colonia '
        'penitenciaria, confinamiento o expulsión del espacio geográfico de '
        'la República.',
    6: 'Por un año, si el hecho punible sólo acarreare arresto por tiempo de '
        'uno a seis meses, o multa mayor de ciento cincuenta unidades '
        'tributarias (150 U.T.), o suspensión del ejercicio de profesión, '
        'industria o arte.',
    7: 'Por tres meses, si el hecho punible sólo acarreare pena de multa '
        'inferior a ciento cincuenta unidades tributarias (150 U.T.), o '
        'arresto de menos de un mes.',
  };

  /// Término de prescripción de la ACCIÓN penal (art. 108 CP).
  ///
  /// [penaMaxAnios]: pena máxima en abstracto (años) cuando [tipo] es prisión.
  /// [arrestoMeses]: duración del arresto en meses cuando [tipo] es arresto.
  /// [multaUt]: monto de la multa en unidades tributarias cuando [tipo] es multa.
  static TerminoPrescripcion terminoAccionPenal({
    TipoPenaPrescripcion tipo = TipoPenaPrescripcion.prision,
    double penaMaxAnios = 0,
    double arrestoMeses = 0,
    double multaUt = 0,
  }) {
    if (tipo == TipoPenaPrescripcion.arresto) {
      if (arrestoMeses > 6) {
        return _t(5, 3, 0);
      }
      if (arrestoMeses >= 1) {
        return _t(6, 1, 0);
      }
      return _t(7, 0, 3);
    }
    if (tipo == TipoPenaPrescripcion.multa) {
      if (multaUt > 150) {
        return _t(6, 1, 0);
      }
      return _t(7, 0, 3);
    }
    // Prisión: interpretación conforme a la doctrina de la Sala
    // (el 3º comprende penas mayores de tres años hasta siete).
    if (penaMaxAnios > 10) return _t(1, 15, 0);
    if (penaMaxAnios > 7) return _t(2, 10, 0);
    if (penaMaxAnios > 3) return _t(3, 7, 0);
    if (penaMaxAnios > 1) return _t(4, 5, 0);
    return _t(5, 3, 0);
  }

  static TerminoPrescripcion _t(int ordinal, int anios, int meses) {
    return TerminoPrescripcion(
      titulo: anios > 0
          ? '$anios ${anios == 1 ? 'año' : 'años'}'
          : '$meses ${meses == 1 ? 'mes' : 'meses'}',
      anios: anios,
      meses: meses,
      fundamento: 'Art. 108, numeral $ordinal del Código Penal',
      ordinal: ordinal,
      textoOrdinal: _textoOrdinal108[ordinal],
    );
  }

  /// Término de prescripción de la PENA (art. 112, numeral 1 CP):
  /// tiempo igual a la condena más la mitad, para prisión y arresto.
  static TerminoPrescripcion terminoPenaArt112({required double penaAnios}) {
    final total = penaAnios * 1.5; // pena + mitad
    final anios = total.floor();
    final meses = ((total - anios) * 12).round();
    return TerminoPrescripcion(
      titulo: [if (anios > 0) '$anios ${anios == 1 ? 'año' : 'años'}',
               if (meses > 0) '$meses ${meses == 1 ? 'mes' : 'meses'}']
          .join(' '),
      anios: anios,
      meses: meses,
      fundamento: 'Art. 112, numeral 1 del Código Penal '
          '(tiempo igual a la condena más la mitad)',
    );
  }

  /// Fecha en que se completa el término, contado desde [base]
  /// (día de la perpetración / última actuación, art. 109 CP).
  static DateTime fechaPrescripcion(DateTime base, TerminoPrescripcion t) {
    return DateTime(base.year + t.anios, base.month + t.meses, base.day);
  }

  /// Días restantes hasta [fechaPrescripcion] (negativo si ya prescribió).
  static int diasRestantes(DateTime fechaPrescripcion, DateTime hoy) {
    final f = DateTime(fechaPrescripcion.year, fechaPrescripcion.month,
        fechaPrescripcion.day);
    final h = DateTime(hoy.year, hoy.month, hoy.day);
    return f.difference(h).inDays;
  }

  /// Resumen de las reglas de inicio (art. 109 CP).
  static const String reglaInicio109 =
      'La prescripción comienza: desde el día de la perpetración (hechos '
      'consumados); desde el último acto de ejecución (infracciones '
      'intentadas o fracasadas); y desde que cesó la continuación o '
      'permanencia (delitos continuados o permanentes). (Art. 109 CP)';

  /// Resumen de las reglas de interrupción (art. 110 CP).
  static const String reglaInterrupcion110 =
      'Interrumpen la prescripción: la sentencia condenatoria, la requisitoria '
      'por fuga, la citación como imputado practicada por el Ministerio '
      'Público, la instauración de la querella, y las diligencias y '
      'actuaciones procesales que le sigan. Interrumpida, corre nuevamente '
      'desde el día de la interrupción. (Art. 110 CP)';
}
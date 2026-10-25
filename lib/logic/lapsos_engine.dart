/// Motor de cómputo de lapsos procesales (Calendario Judicial).
///
/// Funciones PURAS y testables: dado un lapso y una fecha base, devuelve
/// la fecha (o rango) calculada respetando el tipo de cómputo
/// (Art. 156 COPP) y el calendario de días excluidos.
///
/// Reglas de cómputo (Art. 156 COPP, Guía de Lapsos):
///  - Continuo: todos los días corren (sábados, domingos y feriados).
///  - Hábil: se excluyen sábados, domingos, feriados y días sin despacho.
///  - Despacho: estrictamente días de despacho (excluye feriados judiciales
///    y días sin despacho del calendario del usuario).
library;

import '../models/lapso_procesal.dart';

/// Determina si [d] es un día de calendario excluido para cómputo
/// hábil/despacho. [excluidos] debe contener fechas ya normalizadas
/// (medianoche) de feriados judiciales + días sin despacho del usuario.
bool esDiaExcluido(DateTime d, Set<DateTime> excluidos) {
  final DateTime pura = fechaPura(d);
  return excluidos.contains(pura);
}

/// Suma [cantidad] unidades [unidad] a [base] con cómputo [computo].
///
/// [excluidos]: conjunto de fechas (normalizadas) que NO cuentan para
/// cómputos hábiles/despacho (feriados judiciales + días sin despacho).
/// Se ignora para cómputo continuo.
///
/// Devuelve la fecha final (si [min] == [max], lapso puntual).
DateTime calcularFecha({
  required DateTime base,
  required int cantidad,
  required UnidadLapso unidad,
  required TipoComputo computo,
  Set<DateTime>? excluidos,
}) {
  switch (unidad) {
    case UnidadLapso.horas:
      return base.add(Duration(hours: cantidad));
    case UnidadLapso.meses:
      return _sumarMeses(base, cantidad);
    case UnidadLapso.anos:
      return _sumarMeses(base, cantidad * 12);
    case UnidadLapso.dias:
      switch (computo) {
        case TipoComputo.continuo:
          return base.add(Duration(days: cantidad));
        case TipoComputo.habiles:
        case TipoComputo.despacho:
          return _sumarDiasHabiles(base, cantidad, excluidos ?? <DateTime>{});
      }
  }
}

/// Suma [cantidad] meses a [base] (salta fin de mes correctamente:
/// 31 ene + 1 mes → 28/29 feb).
DateTime _sumarMeses(DateTime base, int cantidad) {
  final int anio = base.year + ((base.month - 1 + cantidad) ~/ 12);
  final int mes = ((base.month - 1 + cantidad) % 12) + 1;
  final int ultimoDia = _diasEnMes(anio, mes);
  final int dia = base.day > ultimoDia ? ultimoDia : base.day;
  return DateTime(anio, mes, dia, base.hour, base.minute, base.second);
}

int _diasEnMes(int anio, int mes) => DateTime(anio, mes + 1, 0).day;

/// Suma [cantidad] días hábiles/despacho a [base], saltando sábados,
/// domingos y fechas en [excluidos].
DateTime _sumarDiasHabiles(
    DateTime base, int cantidad, Set<DateTime> excluidos) {
  DateTime actual = fechaPura(base);
  int contados = 0;
  while (contados < cantidad) {
    actual = actual.add(const Duration(days: 1));
    if (_esHabil(actual, excluidos)) {
      contados++;
    }
  }
  return actual;
}

/// true si [d] es día hábil (no sábado, no domingo, no excluido).
bool _esHabil(DateTime d, Set<DateTime> excluidos) {
  final int wd = d.weekday;
  if (wd == DateTime.saturday || wd == DateTime.sunday) {
    return false;
  }
  return !esDiaExcluido(d, excluidos);
}

/// Resta [cantidad] días hábiles a [base] (para lapsos de antelación,
/// ej. "hasta 5 días antes de la preliminar" — Art. 311).
DateTime restarDiasHabiles({
  required DateTime base,
  required int cantidad,
  Set<DateTime>? excluidos,
}) {
  final Set<DateTime> excl = excluidos ?? <DateTime>{};
  DateTime actual = fechaPura(base);
  int contados = 0;
  while (contados < cantidad) {
    actual = actual.subtract(const Duration(days: 1));
    if (_esHabil(actual, excl)) {
      contados++;
    }
  }
  return actual;
}

/// Convierte [NonWorkingDay]s (de la utilidad existente) en un Set de
/// fechas normalizadas, útiles para [calcularFecha] y [restarDiasHabiles].
Set<DateTime> fechasExcluidasDe(List<DateTime> diasSinDespacho) {
  return diasSinDespacho.map(fechaPura).toSet();
}
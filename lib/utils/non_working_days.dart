/// Modelo para representar días sin despacho en la agenda
class NonWorkingDay {
  NonWorkingDay({required this.date, required this.reason, this.isOptional = false});

  factory NonWorkingDay.fromMap(Map<String, dynamic> map) => NonWorkingDay(
      date: DateTime.parse(map['date'] as String),
      reason: map['reason']?.toString() ?? 'Motivo desconocido',
      isOptional: map['isOptional'] as bool? ?? false,
    );

  final DateTime date;
  final String reason;
  final bool isOptional; // Para días que pueden variar según criterio institucional

  Map<String, dynamic> toMap() => <String, dynamic>{
      "date": date.toIso8601String(),
      "reason": reason,
      "isOptional": isOptional,
    };
}

/// Calcula la fecha del Domingo de Pascua usando el algoritmo de Gauss
DateTime _calculateEaster(int year) {
  final int a = year % 19;
  final int b = year ~/ 100;
  final int c = year % 100;
  final int d = b ~/ 4;
  final int e = b % 4;
  final int f = (b + 8) ~/ 25;
  final int g = (b - f + 1) ~/ 3;
  final int h = (19 * a + b - d - g + 15) % 30;
  final int i = c ~/ 4;
  final int k = c % 4;
  final int l = (32 + 2 * e + 2 * i - h - k) % 7;
  final int m = (a + 11 * h + 22 * l) ~/ 451;
  final int month = (h + l - 7 * m + 114) ~/ 31;
  final int day = ((h + l - 7 * m + 114) % 31) + 1;
  return DateTime(year, month, day);
}

/// Genera la lista de días no laborables para un año específico
List<NonWorkingDay> _generateNonWorkingDaysForYear(int year) {
  final List<NonWorkingDay> days = <NonWorkingDay>[];

  // Días fijos nacionales
  days.add(NonWorkingDay(date: DateTime(year, 1, 1), reason: 'Año Nuevo'));
  days.add(NonWorkingDay(date: DateTime(year, 4, 19), reason: 'Declaración de la Independencia de Venezuela'));
  days.add(NonWorkingDay(date: DateTime(year, 5, 1), reason: 'Día Internacional del Trabajador'));
  days.add(NonWorkingDay(date: DateTime(year, 6, 24), reason: 'Batalla de Carabobo'));
  days.add(NonWorkingDay(date: DateTime(year, 7, 5), reason: 'Firma del Acta de la Independencia de Venezuela'));
  days.add(NonWorkingDay(date: DateTime(year, 7, 24), reason: 'Natalicio del Libertador Simón Bolívar'));
  days.add(NonWorkingDay(date: DateTime(year, 10, 12), reason: 'Día de la Resistencia Indígena'));

  // Días fijos judiciales
  days.add(NonWorkingDay(date: DateTime(year, 5, 29), reason: 'Día del Trabajador Tribunalicio (Feriado Judicial)'));
  days.add(NonWorkingDay(date: DateTime(year, 12, 11), reason: 'Día Nacional del Juez'));

  // Calcular Semana Santa (variables según año)
  final DateTime easter = _calculateEaster(year);
  days.add(NonWorkingDay(date: easter.subtract(const Duration(days: 3)), reason: 'Jueves Santo'));
  days.add(NonWorkingDay(date: easter.subtract(const Duration(days: 2)), reason: 'Viernes Santo'));

  // Calcular Carnaval (47 días antes de Pascua)
  final DateTime carnavalMonday = easter.subtract(const Duration(days: 48));
  final DateTime carnavalTuesday = easter.subtract(const Duration(days: 47));
  days.add(NonWorkingDay(date: carnavalMonday, reason: 'Lunes de Carnaval'));
  days.add(NonWorkingDay(date: carnavalTuesday, reason: 'Martes de Carnaval'));

  // Días opcionales de fin de año (pueden variar según tribunales)
  days.add(NonWorkingDay(date: DateTime(year, 12, 24), reason: 'Feriado Navideño', isOptional: true));
  days.add(NonWorkingDay(date: DateTime(year, 12, 25), reason: 'Natividad del Señor'));
  days.add(NonWorkingDay(date: DateTime(year, 12, 31), reason: 'Fiesta de Fin de Año', isOptional: true));

  return days;
}

/// Días no laborables según el calendario judicial venezolano
/// Se genera automáticamente para múltiples años
final List<NonWorkingDay> nonWorkingDays2026 = _generateNonWorkingDaysForYear(2026);
final List<NonWorkingDay> nonWorkingDays2027 = _generateNonWorkingDaysForYear(2027);
final List<NonWorkingDay> nonWorkingDays2028 = _generateNonWorkingDaysForYear(2028);

/// Obtiene todos los días no laborables para un rango de años
List<NonWorkingDay> getAllNonWorkingDays() {
  return <NonWorkingDay>[
    ...nonWorkingDays2026,
    ...nonWorkingDays2027,
    ...nonWorkingDays2028,
  ];
}

/// Obtiene días no laborables para un año específico
List<NonWorkingDay> getNonWorkingDaysForYear(int year) {
  switch (year) {
    case 2026:
      return nonWorkingDays2026;
    case 2027:
      return nonWorkingDays2027;
    case 2028:
      return nonWorkingDays2028;
    default:
      return _generateNonWorkingDaysForYear(year);
  }
}


class NonWorkingDay {

  NonWorkingDay({required this.date, required this.reason});

  factory NonWorkingDay.fromMap(Map<String, dynamic> map) => NonWorkingDay(
      date: DateTime.parse(map['date'] as String),
      reason: map['reason']?.toString() ?? 'Motivo desconocido',
    );
  final DateTime date;
  final String reason;

  Map<String, dynamic> toMap() => <String, dynamic>{
      "date": date.toIso8601String(),
      "reason": reason,
    };
}

final List<NonWorkingDay> nonWorkingDays2026 = <NonWorkingDay>[
  NonWorkingDay(date: DateTime(2026), reason: 'Año Nuevo'),
  NonWorkingDay(date: DateTime(2026, 2, 16), reason: 'Lunes de Carnaval'),
  NonWorkingDay(date: DateTime(2026, 2, 17), reason: 'Martes de Carnaval'),
  NonWorkingDay(date: DateTime(2026, 4, 2), reason: 'Jueves Santo'),
  NonWorkingDay(date: DateTime(2026, 4, 3), reason: 'Viernes Santo'),
  NonWorkingDay(date: DateTime(2026, 4, 19), reason: 'Declaración de la Independencia de Venezuela'),
  NonWorkingDay(date: DateTime(2026, 5), reason: 'Día Internacional del Trabajador'),
  NonWorkingDay(date: DateTime(2026, 5, 29), reason: 'Día del Trabajador Tribunalicio (Feriado Judicial)'),
  NonWorkingDay(date: DateTime(2026, 6, 24), reason: 'Batalla de Carabobo'),
  NonWorkingDay(date: DateTime(2026, 7, 5), reason: 'Firma del Acta de la Independencia de Venezuela'),
  NonWorkingDay(date: DateTime(2026, 7, 24), reason: 'Natalicio del Libertador Simón Bolívar'),
  NonWorkingDay(date: DateTime(2026, 10, 12), reason: 'Día de la Resistencia Indígena'),
  NonWorkingDay(date: DateTime(2026, 12, 11), reason: 'Día Nacional del Juez'),
  NonWorkingDay(date: DateTime(2026, 12, 24), reason: 'Feriado Navideño'),
  NonWorkingDay(date: DateTime(2026, 12, 25), reason: 'Natividad del Señor'),
  NonWorkingDay(date: DateTime(2026, 12, 31), reason: 'Fiesta de Fin de Año'),
];
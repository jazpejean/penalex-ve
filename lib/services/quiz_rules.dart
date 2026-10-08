/// Reglas del quiz: XP por dificultad y escalera de rangos (carrera judicial).
/// Progresión lenta y con hitos: solo ciertos rangos "significativos" otorgan
/// certificado.
class QuizRules {
  QuizRules._();

  /// XP base por dificultad de la pregunta.
  static int xpPorDificultad(int dificultad) {
    switch (dificultad) {
      case 1:
        return 8;
      case 3:
        return 24;
      default:
        return 14; // dificultad 2
    }
  }

  /// XP total de un acierto (base + bono de racha a partir de 5).
  static int xpPorAcierto({required int dificultad, required int racha}) {
    final base = xpPorDificultad(dificultad);
    final bonus = racha >= 5 ? 4 : 0;
    return base + bonus;
  }

  /// Escalera de rangos (umbral de XP → nombre). Curva lenta y progresiva.
  static const List<({int xp, String nombre})> _rangos = [
    (xp: 0, nombre: 'Alguacil de Sala'),
    (xp: 200, nombre: 'Asistente Jurídico'),
    (xp: 600, nombre: 'Escribiente'),
    (xp: 1500, nombre: 'Secretario de Tribunal de Municipio'),
    (xp: 3500, nombre: 'Secretario de Tribunal de Primera Instancia'),
    (xp: 8000, nombre: 'Juez Accidental de Municipio'),
    (xp: 16000, nombre: 'Juez Suplente de Municipio'),
    (xp: 30000, nombre: 'Juez Provisorio de Municipio'),
    (xp: 50000, nombre: 'Juez Titular de Municipio'),
    (xp: 80000, nombre: 'Juez Accidental de Primera Instancia'),
    (xp: 120000, nombre: 'Juez Suplente de Primera Instancia'),
    (xp: 180000, nombre: 'Juez Provisorio de Primera Instancia'),
    (xp: 260000, nombre: 'Juez Titular de Primera Instancia'),
    (xp: 360000, nombre: 'Juez de Primera Instancia con Competencia Especial'),
    (xp: 480000, nombre: 'Juez de Primera Instancia con Competencia Nacional'),
    (xp: 620000, nombre: 'Juez Provisorio de Corte de Apelaciones'),
    (xp: 780000, nombre: 'Juez Titular de Corte de Apelaciones'),
    (xp: 960000, nombre: 'Juez Presidente del Circuito Judicial Penal'),
    (xp: 1160000, nombre: 'Magistrado Suplente de la Sala de Casación Penal'),
    (xp: 1380000, nombre: 'Magistrado Principal de la Sala de Casación Penal'),
    (xp: 1620000, nombre: 'Vicepresidente de la Sala de Casación Penal'),
    (xp: 1880000, nombre: 'Presidente de la Sala de Casación Penal'),
    (xp: 2160000, nombre: 'Presidente del Tribunal Supremo de Justicia'),
    (xp: 2500000, nombre: 'Presidente Emérito'),
  ];

  /// Rangos que sí otorgan certificado (hitos significativos).
  static const Set<int> _xpConCertificado = {
    1500,
    50000,
    260000,
    780000,
    1380000,
    1880000,
    2160000,
    2500000,
  };

  /// Rango actual según el XP acumulado.
  static String rangoParaXp(int xp) {
    String actual = _rangos.first.nombre;
    for (final r in _rangos) {
      if (xp >= r.xp) actual = r.nombre;
    }
    return actual;
  }

  /// Próximo rango (null si ya es el máximo).
  static ({int xp, String nombre})? siguienteRango(int xp) {
    for (final r in _rangos) {
      if (xp < r.xp) return r;
    }
    return null;
  }

  /// Progreso 0..1 dentro del rango actual hacia el siguiente.
  static double progresoRango(int xp) {
    final sig = siguienteRango(xp);
    if (sig == null) return 1.0;
    int ant = 0;
    for (final r in _rangos) {
      if (r.xp <= xp) ant = r.xp;
    }
    if (sig.xp == ant) return 1.0;
    return ((xp - ant) / (sig.xp - ant)).clamp(0.0, 1.0);
  }

  /// Hito con certificado más alto alcanzado (o null si ninguno).
  static ({int xp, String nombre})? certificadoActual(int xp) {
    ({int xp, String nombre})? actual;
    for (final r in _rangos) {
      if (xp >= r.xp && _xpConCertificado.contains(r.xp)) {
        actual = r;
      }
    }
    return actual;
  }

  /// Todos los hitos que otorgan certificado, en orden ascendente.
  static List<({int xp, String nombre})> get hitosConCertificado =>
      _rangos.where((r) => _xpConCertificado.contains(r.xp)).toList();
}

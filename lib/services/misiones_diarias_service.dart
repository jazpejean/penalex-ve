import 'racha_diaria_service.dart';

/// Misiones diarias del quiz — motor de recurrencia.
///
/// 3 misiones por día, determinísticas según la fecha (mismo día = mismas
/// misiones, testeable). El progreso del día vive en `progreso['dia']`:
/// ```json
/// { "fecha": "2026-04-12", "aciertos": 7, "racha_max": 4, "xp_hoy": 96,
///   "reclamadas": { "m_aciertos_10": true } }
/// ```
/// Las funciones devuelven copias del mapa (patrón del proyecto).
class MisionDiaria {
  const MisionDiaria({
    required this.id,
    required this.tipo,
    required this.meta,
    required this.recompensa,
    required this.descripcion,
    required this.icono,
  });

  final String id;
  final String tipo; // 'aciertos' | 'racha' | 'xp'
  final int meta;
  final int recompensa;
  final String descripcion;
  final String icono;
}

class MisionesDiariasService {
  MisionesDiariasService._();

  static const List<MisionDiaria> _plantillas = [
    MisionDiaria(
      id: 'm_aciertos_10',
      tipo: 'aciertos',
      meta: 10,
      recompensa: 30,
      descripcion: 'Acierta 10 preguntas',
      icono: '🎯',
    ),
    MisionDiaria(
      id: 'm_racha_5',
      tipo: 'racha',
      meta: 5,
      recompensa: 50,
      descripcion: 'Alcanza una racha de 5',
      icono: '🔥',
    ),
    MisionDiaria(
      id: 'm_xp_80',
      tipo: 'xp',
      meta: 80,
      recompensa: 40,
      descripcion: 'Gana 80 XP',
      icono: '⚡',
    ),
    MisionDiaria(
      id: 'm_aciertos_20',
      tipo: 'aciertos',
      meta: 20,
      recompensa: 60,
      descripcion: 'Acierta 20 preguntas',
      icono: '🎯',
    ),
    MisionDiaria(
      id: 'm_racha_8',
      tipo: 'racha',
      meta: 8,
      recompensa: 80,
      descripcion: 'Alcanza una racha de 8',
      icono: '🔥',
    ),
    MisionDiaria(
      id: 'm_xp_150',
      tipo: 'xp',
      meta: 150,
      recompensa: 60,
      descripcion: 'Gana 150 XP',
      icono: '⚡',
    ),
  ];

  /// Índice de día (determinístico) para rotar las misiones.
  static int _indiceDia(DateTime hoy) =>
      hoy.difference(DateTime(hoy.year, 1, 1)).inDays % 6;

  /// Las 3 misiones de hoy (rotación fija: 0, +2, +4 sobre el índice).
  static List<MisionDiaria> misionesDe(DateTime hoy) {
    final i = _indiceDia(hoy);
    return [
      _plantillas[i % 6],
      _plantillas[(i + 2) % 6],
      _plantillas[(i + 4) % 6],
    ];
  }

  static Map<String, dynamic> _diaDe(Map<String, dynamic> p) =>
      (p['dia'] as Map<String, dynamic>?) ?? <String, dynamic>{};

  /// Contadores del día (0 si la fecha guardada no es hoy).
  static ({int aciertos, int rachaMax, int xpHoy}) contadores(
      Map<String, dynamic> p, DateTime hoy) {
    final d = _diaDe(p);
    if (d['fecha'] != RachaDiariaService.claveDia(hoy)) {
      return (aciertos: 0, rachaMax: 0, xpHoy: 0);
    }
    return (
      aciertos: (d['aciertos'] as num?)?.toInt() ?? 0,
      rachaMax: (d['racha_max'] as num?)?.toInt() ?? 0,
      xpHoy: (d['xp_hoy'] as num?)?.toInt() ?? 0,
    );
  }

  /// Progreso 0..meta de una misión hoy (0 si es otro día).
  static int progresoDe(
      Map<String, dynamic> p, MisionDiaria m, DateTime hoy) {
    final c = contadores(p, hoy);
    switch (m.tipo) {
      case 'aciertos':
        return c.aciertos.clamp(0, m.meta);
      case 'racha':
        return c.rachaMax.clamp(0, m.meta);
      case 'xp':
        return c.xpHoy.clamp(0, m.meta);
    }
    return 0;
  }

  static bool estaReclamada(Map<String, dynamic> p, MisionDiaria m, DateTime hoy) {
    final d = _diaDe(p);
    if (d['fecha'] != RachaDiariaService.claveDia(hoy)) return false;
    return (d['reclamadas'] as Map<String, dynamic>?)?[m.id] == true;
  }

  /// Registra un acierto del día (actualiza aciertos, racha máx y XP del día).
  static Map<String, dynamic> registrarAcierto(
    Map<String, dynamic> p,
    DateTime hoy, {
    required int rachaActual,
    required int xpGanado,
  }) {
    final copia = Map<String, dynamic>.from(p);
    final d = Map<String, dynamic>.from(_diaDe(p));
    if (d['fecha'] != RachaDiariaService.claveDia(hoy)) {
      d.clear();
      d['fecha'] = RachaDiariaService.claveDia(hoy);
    }
    d['aciertos'] = ((d['aciertos'] as num?)?.toInt() ?? 0) + 1;
    final rachaMaxActual = (d['racha_max'] as num?)?.toInt() ?? 0;
    d['racha_max'] = rachaMaxActual < rachaActual
        ? rachaActual
        : rachaMaxActual;
    d['xp_hoy'] = ((d['xp_hoy'] as num?)?.toInt() ?? 0) + xpGanado;
    copia['dia'] = d;
    return copia;
  }

  /// Reclama la recompensa de una misión completada (una sola vez).
  static Map<String, dynamic> reclamar(
      Map<String, dynamic> p, MisionDiaria m, DateTime hoy) {
    final copia = Map<String, dynamic>.from(p);
    if (progresoDe(copia, m, hoy) < m.meta) return copia;
    if (estaReclamada(copia, m, hoy)) return copia;

    final d = Map<String, dynamic>.from(_diaDe(copia));
    final reclamadas = Map<String, dynamic>.from(
        (d['reclamadas'] as Map<String, dynamic>?) ?? {});
    reclamadas[m.id] = true;
    d['reclamadas'] = reclamadas;
    copia['dia'] = d;

    copia['xp'] = ((copia['xp'] as num?)?.toInt() ?? 0) + m.recompensa;
    return copia;
  }
}
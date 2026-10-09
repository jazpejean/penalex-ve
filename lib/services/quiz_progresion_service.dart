import 'misiones_diarias_service.dart';
import 'racha_diaria_service.dart';

/// Estado de una misión para la UI.
class MisionEstado {
  const MisionEstado({
    required this.mision,
    required this.progreso,
    required this.reclamada,
    required this.completa,
  });

  final MisionDiaria mision;
  final int progreso;
  final bool reclamada;
  final bool completa;
}

/// Progresión diaria del quiz: prepara el día (racha de días + bono por
/// volver) y entrega los contadores de misiones. Funciones puras sobre el
/// mapa de progreso (patrón del proyecto), testeables.
class QuizProgresionService {
  QuizProgresionService._();

  /// Registra la visita de hoy: actualiza la racha de días y otorga el bono
  /// por volver (una sola vez al día). Devuelve el progreso y el bono dado.
  static ({Map<String, dynamic> progreso, int bono}) prepararDia(
      Map<String, dynamic> p, DateTime hoy) {
    final copia = Map<String, dynamic>.from(p);
    final hoyKey = RachaDiariaService.claveDia(hoy);
    final ultimo = copia['ultimo_dia_jugado'] as String? ?? '';
    final rachaDias = (copia['racha_dias'] as num?)?.toInt() ?? 0;

    final nueva =
        RachaDiariaService.nuevaRacha(ultimoDia: ultimo, racha: rachaDias, hoy: hoy);
    final bono = ultimo == hoyKey ? 0 : RachaDiariaService.bonoPorVolver(nueva);

    copia['racha_dias'] = nueva;
    copia['ultimo_dia_jugado'] = hoyKey;
    copia['xp'] = ((copia['xp'] as num?)?.toInt() ?? 0) + bono;
    return (progreso: copia, bono: bono);
  }

  /// Misiones de hoy con su progreso y estado (para la UI del lobby).
  static List<MisionEstado> estadoMisiones(
      Map<String, dynamic> p, DateTime hoy) {
    return MisionesDiariasService.misionesDe(hoy).map((m) {
      final prog = MisionesDiariasService.progresoDe(p, m, hoy);
      return MisionEstado(
        mision: m,
        progreso: prog,
        reclamada: MisionesDiariasService.estaReclamada(p, m, hoy),
        completa: prog >= m.meta,
      );
    }).toList();
  }
}
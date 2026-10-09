/// Racha diaria (días consecutivos jugando) — estilo Duolingo.
/// Lógica 100% determinística y testeable: recibe fechas, no reloj.
class RachaDiariaService {
  RachaDiariaService._();

  /// Clave de día en formato ISO 'yyyy-MM-dd' (comparable como string).
  static String claveDia(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _ayer(DateTime hoy) =>
      claveDia(hoy.subtract(const Duration(days: 1)));

  /// Nueva racha de días según el último día jugado.
  ///  - Mismo día  -> se mantiene (no suma doble).
  ///  - Día previo -> +1 (racha viva).
  ///  - Cualquier otra cosa (hueco) -> reinicia a 1.
  static int nuevaRacha({
    required String ultimoDia,
    required int racha,
    required DateTime hoy,
  }) {
    final hoyKey = claveDia(hoy);
    if (ultimoDia == hoyKey) return racha;
    if (ultimoDia == _ayer(hoy)) return racha + 1;
    return 1;
  }

  /// Bono XP por racha de días (crece hasta 5 días y se estabiliza).
  static int bonoDia(int rachaDias) => rachaDias.clamp(1, 5) * 2;

  /// Bono total por volver hoy: bienvenida + racha de días.
  static int bonoPorVolver(int rachaDias) => 5 + bonoDia(rachaDias);
}
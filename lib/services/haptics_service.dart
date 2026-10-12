import 'package:flutter/services.dart';

/// Feedback háptico consistente para toda la app.
///
/// Envoltorio de [HapticFeedback] con una escala clara:
/// - `tap()`    → selección sutil (items de lista, chips, tabs)
/// - `light()`  → botones principales (login, guardar, siguiente, enviar)
/// - `medium()` → confirmaciones de éxito (documento, formulario, cálculo)
/// - `heavy()`  → acciones destructivas (eliminar audiencia/documento/cálculo)
/// - `error()`  → errores de validación (doble impacto fuerte)
class Haptics {
  Haptics._();

  /// Selección sutil: items de lista, chips, pestañas.
  static Future<void> tap() => HapticFeedback.selectionClick();

  /// Impacto ligero: botones principales.
  static Future<void> light() => HapticFeedback.lightImpact();

  /// Impacto medio: confirmaciones de éxito.
  static Future<void> medium() => HapticFeedback.mediumImpact();

  /// Impacto fuerte: acciones destructivas.
  static Future<void> heavy() => HapticFeedback.heavyImpact();

  /// Error de validación: impacto fuerte doble con 80ms entre ambos.
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }
}
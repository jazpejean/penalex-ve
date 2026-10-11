import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modo oscuro global de Penalex VE.
///
/// El diseño base es gris claro (0xFFF1F5F9) + azul marino (0xFF0F172A).
/// El suiche activa [oscuro]: las superficies/textos resueltos por
/// [TemaGlobal] cambian a la variante oscura (fondo navy, tarjetas slate,
/// texto claro) sin tocar la identidad de marca.
class TemaGlobal {
  TemaGlobal._();

  /// Notificador del modo: MaterialApp se reconstruye con este valor.
  static final ValueNotifier<bool> oscuro = ValueNotifier<bool>(false);

  static bool get isDark => oscuro.value;
  static const String _prefKey = 'modo_oscuro';

  // --- Semántica unificada (la app debe leer SIEMPRE de aquí) ---
  /// Fondo de página: gris claro (light) / navy profundo (dark).
  static Color get superficie =>
      isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

  /// Tarjetas y paneles: blanco (light) / slate oscuro (dark).
  static Color get tarjeta =>
      isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);

  /// Capa intermedia: gris suave (light) / slate medio (dark).
  static Color get capa =>
      isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  /// Texto principal: azul marino (light) / blanco (dark).
  static Color get texto => isDark ? Colors.white : const Color(0xFF0F172A);

  /// Texto secundario: gris pizarra (light) / gris claro (dark).
  static Color get textoSecundario =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

  /// Texto tenue (hints, etiquetas).
  static Color get textoTenue =>
      isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF);

  /// Relleno de campos de texto.
  static Color get campoTexto =>
      isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

  /// Marca: dorado institucional (igual en ambos modos).
  static Color get dorado => const Color(0xFFC5A059);

  /// Marca: azul marino institucional (igual en ambos modos).
  static Color get azulMarino => const Color(0xFF0F172A);

  // --- Persistencia ---
  static Future<void> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      oscuro.value = prefs.getBool(_prefKey) ?? false;
    } catch (_) {
      oscuro.value = false;
    }
  }

  static Future<void> guardar(bool valor) async {
    oscuro.value = valor;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, valor);
    } catch (_) {
      // sin persistencia disponible: el modo sigue activo en la sesión
    }
  }
}
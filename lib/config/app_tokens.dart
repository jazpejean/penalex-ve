import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Tokens visuales únicos de la app.
///
/// Todas las pantallas deben usar estos valores en lugar de números sueltos,
/// para que el conjunto se vea como un solo producto. Si cambia un radio o un
/// espacio, cambia aquí y se refleja en toda la app.
class AppTokens {
  AppTokens._();

  // ── Radios ──────────────────────────────────────────────────
  /// Tarjetas, paneles y bloques de contenido.
  static const double radioTarjeta = 20;

  /// Inputs, botones, chips y controles.
  static const double radioControl = 12;

  /// Etiquetas tipo píldora.
  static const double radioPildora = 999;

  // ── Espaciado ───────────────────────────────────────────────
  /// Margen lateral estándar de las pantallas.
  static const double margen = 20;

  /// Separación entre elementos dentro de un bloque.
  static const double gap = 16;

  /// Separación entre secciones.
  static const double gapSeccion = 28;

  /// Padding interno estándar de una tarjeta.
  static const EdgeInsets paddingTarjeta =
      EdgeInsets.symmetric(horizontal: 18, vertical: 16);

  // ── Tipografía ──────────────────────────────────────────────
  static final TextStyle tituloPantalla = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.15,
    color: AppColors.azulMarino,
    letterSpacing: -0.3,
  );

  static final TextStyle tituloSeccion = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.azulMarino,
  );

  static final TextStyle cuerpo = TextStyle(
    fontSize: 15,
    height: 1.5,
    color: AppColors.texto,
  );

  static final TextStyle secundario = TextStyle(
    fontSize: 13,
    height: 1.45,
    color: AppColors.textoSecundario,
  );

  static final TextStyle etiqueta = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: AppColors.textoSecundario,
  );

  // ── Botones ─────────────────────────────────────────────────
  static const double altoBoton = 52;
}

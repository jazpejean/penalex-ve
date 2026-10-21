import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Paleta unificada de Penalex VE.
///
/// Desde esta refactorización, [AppColors] es SOLO una capa de compatibilidad:
/// la fuente única de verdad es [TemaGlobal]. Los colores de marca
/// ([primary]/[secondary]/[accent]) son constantes institucionales (iguales en
/// modo claro y oscuro) y los colores de superficie/texto son getters que
/// delegan en [TemaGlobal] para respetar el modo claro/oscuro.
class AppColors {
  // --- Marca (constantes institucionales, iguales en ambos modos) ---
  /// Azul marino institucional (idéntico a [TemaGlobal.azulMarino]).
  static const Color primary = Color(0xFF0F172A);
  /// Dorado institucional (idéntico a [TemaGlobal.dorado]).
  static const Color secondary = Color(0xFFC5A059);
  /// Amarillo dorado de acento.
  static const Color accent = Color(0xFFF4D03F);

  // Alias institucionales
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);

  // --- Fondos (delegan en TemaGlobal → respetan modo claro/oscuro) ---
  /// Fondo de página.
  static Color get background => TemaGlobal.superficie;
  /// Fondo de tarjetas y paneles.
  static Color get surface => TemaGlobal.tarjeta;
  /// Capa intermedia (gris suave).
  static Color get surfaceLight => TemaGlobal.capa;
  /// Fondo de pantalla de splash (siempre azul marino, por diseño de marca).
  static Color get splashBackground => azulMarino;

  // --- Textos (delegan en TemaGlobal) ---
  static Color get textPrimary => TemaGlobal.texto;
  static Color get textSecondary => TemaGlobal.textoSecundario;
  static Color get textMuted => TemaGlobal.textoTenue;

  // Texto sobre superficies oscuras (azul marino)
  static const Color onDarkPrimary = Colors.white;
  static const Color onDarkSecondary = Colors.white70;

  // --- Estados (semánticos, constantes) ---
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // --- Gradientes para efectos premium ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: <Color>[primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static RadialGradient get backgroundGradient => RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 1.1,
        colors: <Color>[surface, background],
        stops: const <double>[0, 1],
      );

  // --- Sombras y efectos ---
  static const BoxShadow primaryShadow = BoxShadow(
    color: secondary,
    blurRadius: 20,
    spreadRadius: 2,
    offset: Offset(0, 4),
  );

  static const BoxShadow surfaceShadow = BoxShadow(
    color: Colors.black26,
    blurRadius: 8,
    offset: Offset(0, 2),
  );
}
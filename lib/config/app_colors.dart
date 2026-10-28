import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Paleta unificada de Penalex VE.
///
/// Fuente única de verdad para colores: los de marca ([azulMarino]/[dorado])
/// son constantes institucionales (iguales en ambos modos) y los de
/// superficie/texto/estado son getters que delegan en [TemaGlobal] para
/// respetar el modo claro/oscuro.
class AppColors {
  // ── Marca (no cambian con el modo) ──────────────────────────
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);

  // ── Superficies (cambian con el modo) ───────────────────────
  static Color get superficie => TemaGlobal.superficie;
  static Color get tarjeta => TemaGlobal.tarjeta;
  static Color get capa => TemaGlobal.capa;
  static Color get campoTexto => TemaGlobal.campoTexto;

  // ── Texto (cambia con el modo) ──────────────────────────────
  static Color get texto => TemaGlobal.texto;
  static Color get textoSecundario => TemaGlobal.textoSecundario;
  static Color get textoTenue => TemaGlobal.textoTenue;

  // ── Acento (navy en claro, dorado en oscuro) ────────────────
  static Color get acento => TemaGlobal.isDark ? dorado : azulMarino;

  // ── Foreground sobre superficies de marca (REGLA DURA) ──────
  /// Texto/iconos sobre fondo `azulMarino`. SIEMPRE blanco.
  static const Color onAzulMarino = Colors.white;
  /// Texto/iconos sobre fondo `dorado`. SIEMPRE navy.
  static const Color onDorado = azulMarino;

  // ── Estados theme-aware ─────────────────────────────────────
  static Color get success => TemaGlobal.isDark
      ? const Color(0xFF4ADE80)
      : const Color(0xFF15803D);
  static Color get error => TemaGlobal.isDark
      ? const Color(0xFFF87171)
      : const Color(0xFFB91C1C);
  static Color get warning => TemaGlobal.isDark
      ? const Color(0xFFFBBF24)
      : const Color(0xFFC2410C);

  static Color get successBg => success.withValues(alpha: 0.15);
  static Color get errorBg => error.withValues(alpha: 0.15);
  static Color get warningBg => warning.withValues(alpha: 0.15);

  // ── Escala de alpha (usar SOLO estos) ───────────────────────
  static const double a06 = 0.06;
  static const double a12 = 0.12;
  static const double a18 = 0.18;
  static const double a24 = 0.24;
  static const double a48 = 0.48;

  // ── Deprecaciones (mantener por compatibilidad, no usar) ────
  @Deprecated('Usar AppColors.azulMarino')
  static const Color primary = azulMarino;
  @Deprecated('Usar AppColors.dorado')
  static const Color secondary = dorado;

  // ── Compatibilidad (tokens históricos, delegan en los nuevos) ──
  /// Fondo de página (alias de [superficie]).
  static Color get background => TemaGlobal.superficie;
  /// Fondo de tarjetas y paneles (alias de [tarjeta]).
  static Color get surface => TemaGlobal.tarjeta;
  /// Capa intermedia (alias de [capa]).
  static Color get surfaceLight => TemaGlobal.capa;
  /// Texto principal (alias de [texto]).
  static Color get textPrimary => TemaGlobal.texto;
  /// Texto secundario (alias de [textoSecundario]).
  static Color get textSecondary => TemaGlobal.textoSecundario;
  /// Texto tenue (alias de [textoTenue]).
  static Color get textMuted => TemaGlobal.textoTenue;

  /// Texto sobre superficies oscuras (azul marino).
  static const Color onDarkPrimary = Colors.white;
  static const Color onDarkSecondary = Colors.white70;

  /// Amarillo dorado de acento (legacy de quiz, fuera de alcance).
  static const Color accent = Color(0xFFF4D03F);

  /// Información (constante, igual en ambos modos).
  static const Color info = Color(0xFF3B82F6);

  /// Dorado brillante (efectos premium / logros).
  static const Color oroBrillante = Color(0xFFE9C86A);

  /// Rojo de marca de Google (botón de login).
  static const Color rojoGoogle = Color(0xFFDB4437);

  /// Fondo de pantalla de splash (siempre azul marino, por diseño de marca).
  static Color get splashBackground => azulMarino;

  // --- Gradientes para efectos premium ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: <Color>[azulMarino, dorado],
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
    color: dorado,
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
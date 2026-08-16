import 'package:flutter/material.dart';

class AppColors {
  // Paleta principal - Gris claro de fondo para la app y azul/dorado en detalles
  static const Color primary = Color(0xFF0F172A); // Azul marino uniforme
  static const Color secondary = Color(0xFFC5A059); // Dorado clásico
  static const Color accent = Color(0xFFF4D03F); // Amarillo dorado

  // Nombres institucionales
  static const Color azulMarino = Color(0xFF0F172A); // Alias para primary
  static const Color dorado = Color(0xFFC5A059); // Alias para secondary

  // Fondos
  static const Color splashBackground = Color(0xFF0F172A); // Azul splash
  static const Color background = Color(0xFFF1F5F9); // Gris claro para la app
  static const Color surface = Color(0xFFFFFFFF); // Fondo de tarjetas y paneles
  static const Color surfaceLight = Color(0xFFE2E8F0); // Gris suave para capas

  // Textos
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Color(0xFF9CA3AF);

  // Estados
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Gradientes para efectos premium
  static const LinearGradient primaryGradient = LinearGradient(
    colors: <Color>[primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient backgroundGradient = RadialGradient(
    center: Alignment(-0.3, -0.4),
    radius: 1.1,
    colors: <Color>[surface, background],
    stops: <double>[0, 1],
  );

  // Sombras y efectos
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
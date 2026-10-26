import 'package:flutter/material.dart';
import 'app_colors.dart';

// ignore: avoid_classes_with_only_static_members
class AppTheme {
  /// Tema claro único de Penalex VE.
  ///
  /// Paleta institucional: azul marino (#0F172A) como primario,
  /// dorado (#C5A059) como acento secundario, fondo gris claro (#F1F5F9).
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ).copyWith(
          // Superficies institucionales: blanco para tarjetas, gris claro para fondo.
          surface: const Color(0xFFFFFFFF),
          onSurface: const Color(0xFF0F172A),
          onSurfaceVariant: const Color(0xFF475569),
          surfaceContainerLowest: const Color(0xFFF1F5F9),
          surfaceContainerLow: const Color(0xFFFFFFFF),
          surfaceContainer: const Color(0xFFFFFFFF),
          surfaceContainerHigh: const Color(0xFFE2E8F0),
          surfaceContainerHighest: const Color(0xFFE2E8F0),
          outline: const Color(0xFFE2E8F0),
          outlineVariant: const Color(0xFFE2E8F0),
        ),
        cardColor: const Color(0xFFFFFFFF),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFFFFFFFF),
          surfaceTintColor: Colors.transparent,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFFFFFFFF),
          surfaceTintColor: Colors.transparent,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE2E8F0),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // Solo radio de borde por defecto: las pantallas definen su propio
        // relleno/fondo de campo, así evitamos sorpresas en campos sin estilizar.
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  /// Tema oscuro de Penalex VE: fondo navy, superficies slate, dorado intacto.
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: const Color(0xFF1E293B),
        ).copyWith(
          // Paleta oscura institucional: navy de fondo, slate para tarjetas.
          surface: const Color(0xFF1E293B),
          onSurface: Colors.white,
          onSurfaceVariant: const Color(0xFF94A3B8),
          surfaceContainerLowest: const Color(0xFF0F172A),
          surfaceContainerLow: const Color(0xFF1E293B),
          surfaceContainer: const Color(0xFF1E293B),
          surfaceContainerHigh: const Color(0xFF334155),
          surfaceContainerHighest: const Color(0xFF334155),
          outline: const Color(0xFF334155),
          outlineVariant: const Color(0xFF334155),
          surfaceTint: Colors.transparent,
        ),
        cardColor: const Color(0xFF1E293B),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1E293B),
          surfaceTintColor: Colors.transparent,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF1E293B),
          surfaceTintColor: Colors.transparent,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF334155),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}
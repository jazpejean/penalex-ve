import 'package:flutter/material.dart';
import 'app_colors.dart';

// ignore: avoid_classes_with_only_static_members
class AppTheme {
  /// Tema claro único de Penalex VE.
  ///
  /// Paleta institucional: azul marino (#0F172A) como primario,
  /// AppColors.dorado (#C5A059) como AppColors.acento secundario, fondo gris claro (#F1F5F9).
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.azulMarino,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.azulMarino,
          primary: AppColors.azulMarino,
          secondary: AppColors.dorado,
        ).copyWith(
          // Superficies institucionales: blanco para tarjetas, gris claro para fondo.
          surface: AppColors.onAzulMarino,
          onSurface: AppColors.azulMarino,
          onSurfaceVariant: AppColors.textoSecundario,
          surfaceContainerLowest: AppColors.superficie,
          surfaceContainerLow: AppColors.onAzulMarino,
          surfaceContainer: AppColors.onAzulMarino,
          surfaceContainerHigh: AppColors.capa,
          surfaceContainerHighest: AppColors.capa,
          outline: AppColors.capa,
          outlineVariant: AppColors.capa,
        ),
        cardColor: AppColors.onAzulMarino,
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.onAzulMarino,
          surfaceTintColor: Colors.transparent,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColors.onAzulMarino,
          surfaceTintColor: Colors.transparent,
        ),
        dividerTheme: DividerThemeData(
          color: AppColors.capa,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.azulMarino,
          foregroundColor: AppColors.dorado,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.dorado,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.azulMarino,
            foregroundColor: AppColors.dorado,
            side: BorderSide(color: AppColors.dorado, width: 1),
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

  /// Tema oscuro de Penalex VE: fondo navy, superficies slate, AppColors.dorado intacto.
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: AppColors.azulMarino,
        scaffoldBackgroundColor: AppColors.azulMarino,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.azulMarino,
          brightness: Brightness.dark,
          primary: AppColors.azulMarino,
          secondary: AppColors.dorado,
          surface: AppColors.tarjeta,
        ).copyWith(
          // Paleta oscura institucional: navy de fondo, slate para tarjetas.
          surface: AppColors.tarjeta,
          onSurface: Colors.white,
          onSurfaceVariant: AppColors.textoSecundario,
          surfaceContainerLowest: AppColors.azulMarino,
          surfaceContainerLow: AppColors.tarjeta,
          surfaceContainer: AppColors.tarjeta,
          surfaceContainerHigh: AppColors.capa,
          surfaceContainerHighest: AppColors.capa,
          outline: AppColors.capa,
          outlineVariant: AppColors.capa,
          surfaceTint: Colors.transparent,
        ),
        cardColor: AppColors.tarjeta,
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.tarjeta,
          surfaceTintColor: Colors.transparent,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColors.tarjeta,
          surfaceTintColor: Colors.transparent,
        ),
        dividerTheme: DividerThemeData(
          color: AppColors.capa,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.azulMarino,
          foregroundColor: AppColors.dorado,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.dorado,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.azulMarino,
            foregroundColor: AppColors.dorado,
            side: BorderSide(color: AppColors.dorado, width: 1),
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
import 'package:flutter/material.dart';
import '../config/app_colors.dart';

/// SnackBars institucionales unificados de Penalex VE.
///
/// Único punto de entrada para avisos: [success] y [error] aplican el color
/// semántico theme-aware de [AppColors] automáticamente.
class AppSnackBar {
  static void success(BuildContext ctx, String msg) =>
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

  static void error(BuildContext ctx, String msg) =>
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
}
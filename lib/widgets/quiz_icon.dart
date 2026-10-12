import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Icono SVG custom del quiz.
///
/// Sustituye a los `Icons.*` de Material en todo el módulo quiz: cada icono
/// vive como un SVG de línea fina en `assets/icons/quiz/<name>.svg`
/// (viewBox 24, trazo 2, oro #C5A059). Se tiñe con [color] (por defecto el
/// oro de la app) vía `BlendMode.srcIn`.
///
/// Con [withGlow] se dibuja una copia desenfocada debajo para crear un halo
/// dorado con la forma exacta del icono (no un cuadrado).
class QuizIcon extends StatelessWidget {
  /// Nombre del SVG en `assets/icons/quiz/` (sin extensión).
  final String name;
  final double size;

  /// Color del trazo. `null` = oro oficial de la app (0xFFC5A059).
  final Color? color;

  /// Halo dorado difuminado detrás del icono.
  final bool withGlow;

  /// El trazo está horneado en cada SVG (2px); se conserva por compatibilidad
  /// con el diseño si algún día se generan SVGs con otro grosor.
  final double strokeWidth;

  const QuizIcon(
    this.name, {
    super.key,
    this.size = 24,
    this.color,
    this.withGlow = false,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFFC5A059);
    final svg = SvgPicture.asset(
      'assets/icons/quiz/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
    );
    if (!withGlow) return svg;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Copia difuminada: halo con la silueta exacta del icono.
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Opacity(opacity: 0.55, child: svg),
        ),
        svg,
      ],
    );
  }
}
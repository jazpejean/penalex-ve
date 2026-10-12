import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Variante del logo de Penalex VE.
enum PenalexLogoVariant { emblema, logo, isotipo }

/// Logo de Penalex VE cargado desde `assets/logos/penalex_<variante>.svg`.
///
/// Los SVG actuales son placeholders vectoriales (balanza en escudo) mientras
/// el equipo aporta el logo oficial; el widget ya queda listo para usarlo.
///
/// - [color]: tiñe el logo (`BlendMode.srcIn`); `null` respeta el color del SVG.
/// - [withGlow]: halo dorado difuminado con la silueta exacta.
/// - [animate]: entrada ceremonial (900 ms, easeOutCubic, escala 0.85→1 + fade).
class PenalexLogo extends StatelessWidget {
  final PenalexLogoVariant variant;
  final double size;
  final Color? color;
  final bool withGlow;
  final bool animate;

  const PenalexLogo({
    super.key,
    this.variant = PenalexLogoVariant.logo,
    this.size = 120,
    this.color,
    this.withGlow = false,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget logo = SvgPicture.asset(
      'assets/logos/penalex_${variant.name}.svg',
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );

    if (withGlow) {
      logo = Stack(
        alignment: Alignment.center,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Opacity(opacity: 0.55, child: logo),
          ),
          logo,
        ],
      );
    }

    if (!animate) return logo;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.scale(scale: 0.85 + 0.15 * v, child: child),
      ),
      child: logo,
    );
  }
}
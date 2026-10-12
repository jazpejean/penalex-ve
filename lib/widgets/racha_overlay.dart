import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Overlay "¡RACHA xN!" que aparece al cruzar múltiplos de 5.
///
/// Entrada elástica (Curves.elasticOut), tipografía Cinzel dorada brillante y
/// desvanecimiento automático a los 1.5 s (se notifica con [onDone]).
/// (Internamente es StatefulWidget: el autodesvanecido necesita un Timer.)
class RachaOverlay extends StatefulWidget {
  final int racha;
  final VoidCallback onDone;

  const RachaOverlay({super.key, required this.racha, required this.onDone});

  @override
  State<RachaOverlay> createState() => _RachaOverlayState();
}

class _RachaOverlayState extends State<RachaOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1500), widget.onDone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, v, child) => Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(scale: v, child: child),
        ),
        child: Text(
          '¡RACHA x${widget.racha}!',
          style: GoogleFonts.cinzel(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: const Color(0xFFE9C86A),
            shadows: [
              Shadow(
                color: const Color(0xFFC5A059).withValues(alpha: 0.9),
                blurRadius: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Fondo "liquid gold": shader GLSL animado (navy + vetas doradas) bajo
/// cualquier contenido.
///
/// - Carga `assets/shaders/liquid_gold.frag` con [ui.FragmentProgram].
/// - Un [AnimationController] de 24 s en loop alimenta `uTime`.
/// - Uniformes: `uSize`, `uTime`, `uGold` (0.776, 0.627, 0.349),
///   `uNavy` (0.058, 0.090, 0.164).
/// - Si el shader no puede cargarse (offline, entorno de tests, GPU sin
///   soporte) cae a un `Container` navy profundo: nunca rompe la UI.
class LiquidGoldBackground extends StatefulWidget {
  final Widget child;

  const LiquidGoldBackground({super.key, required this.child});

  @override
  State<LiquidGoldBackground> createState() => _LiquidGoldBackgroundState();
}

class _LiquidGoldBackgroundState extends State<LiquidGoldBackground>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _program;
  late final AnimationController _reloj;

  @override
  void initState() {
    super.initState();
    _reloj = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final programa = await ui.FragmentProgram.fromAsset(
        'shaders/liquid_gold.frag',
      );
      if (mounted) setState(() => _program = programa);
    } catch (e) {
      debugPrint('⚠️ liquid_gold.frag no cargó (fallback navy): $e');
    }
  }

  @override
  void dispose() {
    _reloj.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final programa = _program;
    if (programa == null) {
      return Container(color: const Color(0xFF0A0E1A), child: widget.child);
    }
    return AnimatedBuilder(
      animation: _reloj,
      builder: (context, child) {
        final shader = programa.fragmentShader();
        shader
          ..setFloat(0, 1)
          ..setFloat(1, 1)
          ..setFloat(2, _reloj.value * 24)
          ..setFloat(3, 0.776)
          ..setFloat(4, 0.627)
          ..setFloat(5, 0.349)
          ..setFloat(6, 0.058)
          ..setFloat(7, 0.090)
          ..setFloat(8, 0.164);
        return CustomPaint(
          painter: _LiquidGoldPainter(shader),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _LiquidGoldPainter extends CustomPainter {
  final ui.FragmentShader _shader;

  _LiquidGoldPainter(this._shader);

  @override
  void paint(Canvas canvas, Size size) {
    _shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = _shader,
    );
  }

  @override
  bool shouldRepaint(_LiquidGoldPainter oldDelegate) => true;
}
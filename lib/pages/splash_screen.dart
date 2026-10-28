import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _textOpacity;

  late final AnimationController _sparkleController;
  late final List<_Sparkle> _sparkles;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0, 0.55, curve: Curves.easeOutCubic),
    );
    _logoScale = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.05, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _textOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.45, 1, curve: Curves.easeOut),
    );

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();

    _sparkles = _SparkleField.generate(28);

    _introController.forward();
    // El SplashScreen ya NO navega: su padre (AuthWrapper) decide qué mostrar.
  }

  @override
  void dispose() {
    _introController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.azulMarino, // Azul medianoche (mismo que usas)
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo suave con un "halo" y destellos sutiles (paleta bandera VE).
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.1),
                radius: 1.2,
                colors: [
                  AppColors.azulMarino.withValues(alpha: 0.70),
                  AppColors.azulMarino,
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _sparkleController,
            builder: (context, _) {
              return CustomPaint(
                painter: _SparkleFieldPainter(
                  t: _sparkleController.value,
                  sparkles: _sparkles,
                ),
              );
            },
          ),
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _introController,
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: const _Logo(
                            size: 118,
                            colorFallback: AppColors.dorado,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Opacity(
                        opacity: _textOpacity.value,
                        child: Text(
                          'Desarrollado por: Jean Jazpe Lizcano',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 12.5,
                            height: 1.25,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Serif',
                            letterSpacing: 0.25,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.size, required this.colorFallback});

  final double size;
  final Color colorFallback;

  @override
  Widget build(BuildContext context) {
    // Usar directamente el icono gavel_rounded (mismo que login)
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: AppColors.azulMarino, // Azul marino
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.gavel_rounded,
        size: size * 0.6,
        color: colorFallback,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('size', size));
    properties.add(ColorProperty('colorFallback', colorFallback));
  }
}

class _Sparkle {
  const _Sparkle({
    required this.x,
    required this.y,
    required this.r,
    required this.phase,
    required this.speed,
    required this.color,
  });

  /// Normalized (0..1) positions.
  final double x;
  final double y;
  final double r;
  final double phase;
  final double speed;
  final Color color;
}

class _SparkleField {
  static List<_Sparkle> generate(int count) {
    // LCG pseudo-random (deterministic) to avoid importing dart:math Random.
    int s = 0xC0FFEE;
    double next() {
      s = (1664525 * s + 1013904223) & 0x7fffffff;
      return s / 0x7fffffff;
    }

    const yellow = AppColors.accent;
    const blue = AppColors.info;
    final red = AppColors.error;
    final palette = <Color>[yellow, blue, red];

    return List<_Sparkle>.generate(count, (i) {
      final x = next();
      final y = next();
      final r = 0.8 + next() * 2.2; // px-ish base radius
      final phase = next();
      final speed = 0.25 + next() * 0.75;
      final c = palette[(next() * palette.length).floor()].withValues(
        alpha: 0,
      );
      return _Sparkle(
        x: x,
        y: y,
        r: r,
        phase: phase,
        speed: speed,
        color: c,
      );
    });
  }
}

class _SparkleFieldPainter extends CustomPainter {
  _SparkleFieldPainter({
    required this.t,
    required this.sparkles,
  });

  final double t;
  final List<_Sparkle> sparkles;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.45);
    final maxR = (size.shortestSide) * 0.62;

    // Suave viñeta / halo para dar sensación "premium".
    final haloPaint = Paint()
      ..shader = RadialGradient(
        radius: 1,
        colors: [
          AppColors.info.withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxR));
    canvas.drawCircle(center, maxR, haloPaint);

    for (final s in sparkles) {
      final tt = (t * s.speed + s.phase) % 1.0;

      // Destellos: "pulse" + deriva muy leve.
      final pulse = _smoothPulse(tt);
      final dx = (s.x - 0.5) * size.width * 0.92;
      final dy = (s.y - 0.5) * size.height * 0.62;
      final drift = (tt - 0.5) * 12.0;

      final pos = Offset(
        center.dx + dx + drift,
        center.dy + dy - drift * 0.35,
      );

      final alpha = (0.02 + pulse * 0.10).clamp(0.0, 0.14);
      final paint = Paint()
        ..color = s.color.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(pos, s.r * (0.85 + pulse * 0.9), paint);

      // Mini "spark" line sutil.
      final linePaint = Paint()
        ..color = s.color.withValues(alpha: (alpha * 0.55).clamp(0.0, 0.08))
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round;
      final l = 6.0 + pulse * 10.0;
      canvas.drawLine(pos.translate(-l * 0.5, 0), pos.translate(l * 0.5, 0), linePaint);
    }
  }

  double _smoothPulse(double x) {
    // 0..1 -> 0..1 with soft peak.
    final a = (x - 0.5).abs() * 2.0; // 0 at center, 1 at edges
    final v = 1.0 - a;
    return Curves.easeInOut.transform(v.clamp(0.0, 1.0));
  }

  @override
  bool shouldRepaint(covariant _SparkleFieldPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.sparkles != sparkles;
  }
}
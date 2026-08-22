import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

enum MedallionVisualState {
  completado,
  actual,
  bloqueado,
  bloqueadoPorFallos
}

class LevelMedallionComponent extends PositionComponent with TapCallbacks {
  final int level;
  final MedallionVisualState visualState;
  final VoidCallback onTap;

  double _pulseTimer = 0;

  LevelMedallionComponent({
    required this.level,
    required this.visualState,
    required this.onTap,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(70, 70),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (visualState == MedallionVisualState.actual) {
      _pulseTimer += dt * 3.5;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2 - 4;

    // 1. Resplandor Pulsante para el Nivel Actual
    if (visualState == MedallionVisualState.actual) {
      final pulseScale = 1.0 + (sin(_pulseTimer) * 0.12);
      final glowPaint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.4 + sin(_pulseTimer) * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(center, (radius + 8) * pulseScale, glowPaint);
    }

    // 2. Sombra base
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center + const Offset(0, 4), radius, shadowPaint);

    // 3. Disco del Medallón Colonial (Mármol / Bronce / Oro)
    final Paint fillPaint = Paint();
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    switch (visualState) {
      case MedallionVisualState.completado:
        // Verde mármol colonial con borde dorado
        fillPaint.color = const Color(0xFF1B4332);
        borderPaint.color = const Color(0xFFD4AF37);
        break;
      case MedallionVisualState.actual:
        // Dorado real brillante
        fillPaint.shader = const LinearGradient(
          colors: [Color(0xFFFFF176), Color(0xFFD4AF37), Color(0xFFAA7C11)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: center, radius: radius));
        borderPaint.color = const Color(0xFFFFFFFF);
        break;
      case MedallionVisualState.bloqueado:
        // Hierro forjado oscuro
        fillPaint.color = const Color(0xFF2B2D42);
        borderPaint.color = const Color(0xFF8D99AE);
        break;
      case MedallionVisualState.bloqueadoPorFallos:
        // Rojo carmesí de advertencia
        fillPaint.color = const Color(0xFF780000);
        borderPaint.color = const Color(0xFFC1121F);
        break;
    }

    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, borderPaint);

    // 4. Anillo interior biselado
    final innerBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withOpacity(0.3);
    canvas.drawCircle(center, radius - 4, innerBorder);

    // 5. Ícono o Número
    if (visualState == MedallionVisualState.bloqueadoPorFallos) {
      // Dibujar Candado
      final lockPaint = Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center + const Offset(0, 4), width: 20, height: 16),
          const Radius.circular(3),
        ),
        lockPaint,
      );
      final shacklePaint = Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawArc(
        Rect.fromCenter(center: center - const Offset(0, 3), width: 12, height: 14),
        pi,
        pi,
        false,
        shacklePaint,
      );
    } else {
      // Dibujar Número de Nivel
      final textPainter = TextPainter(
        text: TextSpan(
          text: "$level",
          style: TextStyle(
            color: (visualState == MedallionVisualState.actual)
                ? const Color(0xFF003893)
                : const Color(0xFFF8F6F0),
            fontSize: level >= 1000 ? 14 : (level >= 100 ? 17 : 20),
            fontWeight: FontWeight.w900,
            fontFamily: 'serif',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // 6. Tres Estrellas Doradas para el Nivel Actual
    if (visualState == MedallionVisualState.actual) {
      final starPaint = Paint()..color = const Color(0xFFFFD700);
      final starPositions = [
        center + const Offset(-18, -26),
        center + const Offset(0, -32),
        center + const Offset(18, -26),
      ];
      for (var pos in starPositions) {
        canvas.drawCircle(pos, 3.5, starPaint);
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    onTap();
  }
}

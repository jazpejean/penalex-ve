import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class LevelMedallion extends PositionComponent with TapCallbacks {
  final int level;
  
  LevelMedallion({
    required this.level,
    required Vector2 position,
  }) : super(position: position, size: Vector2(120, 120), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw gold outer ring
    final paintRing = Paint()..color = const Color(0xFFD4AF37)..style = PaintingStyle.stroke..strokeWidth = 8;
    // Draw white center
    final paintCenter = Paint()..color = Colors.white..style = PaintingStyle.fill;
    
    final radius = size.x / 2;
    final center = Offset(radius, radius);
    
    canvas.drawCircle(center, radius, paintRing);
    canvas.drawCircle(center, radius - 4, paintCenter);
    
    // Draw text
    final textPainter = TextPainter(
      text: TextSpan(
        text: level.toString(),
        style: const TextStyle(color: Color(0xFF003893), fontSize: 40, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - (textPainter.width / 2), center.dy - (textPainter.height / 2)),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    print('Tapped level $level');
  }
}

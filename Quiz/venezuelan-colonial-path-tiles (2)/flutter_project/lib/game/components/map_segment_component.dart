import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class MapSegmentComponent extends PositionComponent {
  final int segmentIndex;
  final String assetPath;
  Sprite? _sprite;

  MapSegmentComponent({
    required this.segmentIndex,
    required this.assetPath,
    required Vector2 position,
    required Vector2 size,
  }) : super(
          position: position,
          size: size,
        );

  Future<void> loadSprite() async {
    try {
      _sprite = await Sprite.load(assetPath);
    } catch (_) {
      _sprite = null;
    }
  }

  void unloadSprite() {
    _sprite = null;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_sprite != null) {
      _sprite!.render(canvas, size: size);
    } else {
      // Fallback Colonial rendering with ambient daylight
      final rect = Rect.fromLTWH(0, 0, size.x, size.y);
      final bgPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFEADBC8), Color(0xFFF8F6F0), Color(0xFFD5C4A1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect);
      canvas.drawRect(rect, bgPaint);
    }
  }
}

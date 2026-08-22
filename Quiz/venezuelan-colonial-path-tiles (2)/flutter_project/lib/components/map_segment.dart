import 'package:flame/components.dart';

class MapSegment extends SpriteComponent with HasGameRef {
  final String spriteName;
  
  MapSegment({
    required this.spriteName,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite(spriteName);
  }
}

import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import '../components/map_segment.dart';
import '../components/level_medallion.dart';

class PenalexGame extends FlameGame with PanDetector, HasCollisionDetection {
  late final CameraComponent cameraComponent;
  late final World world;
  
  double maxScrollY = 0;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    world = World();
    cameraComponent = CameraComponent(world: world)..viewfinder.anchor = Anchor.topLeft;
    addAll([world, cameraComponent]);

    // Constant size for the 1080x1920 images
    final segmentSize = Vector2(1080, 1920);
    
    // We create 3 repeating segments for the demo
    final maps = ['map_venezuela_top.png', 'map_venezuela_middle.png', 'map_venezuela_bottom.png'];
    
    double currentY = 0;
    
    // Create 30 segments (90 levels) as an example
    for (int i = 0; i < 30; i++) {
      final spriteName = maps[i % maps.length];
      
      final mapSegment = MapSegment(
        spriteName: spriteName,
        position: Vector2(0, currentY),
        size: segmentSize,
      );
      
      world.add(mapSegment);
      
      // Add 3 medallions per segment
      final baseLevel = i * 3;
      world.add(LevelMedallion(level: baseLevel + 1, position: Vector2(200, currentY + 1400)));
      world.add(LevelMedallion(level: baseLevel + 2, position: Vector2(700, currentY + 900)));
      world.add(LevelMedallion(level: baseLevel + 3, position: Vector2(400, currentY + 200)));
      
      currentY += segmentSize.y;
    }
    
    maxScrollY = currentY;
    
    // Fit the width of the game to the screen, scale accordingly
    cameraComponent.viewfinder.zoom = size.x / 1080;
    
    // Start at the bottom (level 1)
    cameraComponent.viewfinder.position = Vector2(0, maxScrollY - (size.y / cameraComponent.viewfinder.zoom));
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    // Scroll the camera
    final delta = info.delta.global;
    cameraComponent.viewfinder.position.y -= delta.y / cameraComponent.viewfinder.zoom;
    
    // Clamp scrolling
    if (cameraComponent.viewfinder.position.y < 0) {
      cameraComponent.viewfinder.position.y = 0;
    }
    
    final maxY = maxScrollY - (size.y / cameraComponent.viewfinder.zoom);
    if (cameraComponent.viewfinder.position.y > maxY) {
      cameraComponent.viewfinder.position.y = maxY;
    }
  }
}

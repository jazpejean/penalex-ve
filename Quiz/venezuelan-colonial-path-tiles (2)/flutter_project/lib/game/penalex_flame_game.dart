import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/game_state_model.dart';
import '../models/region_model.dart';
import 'components/level_medallion_component.dart';
import 'components/map_segment_component.dart';

class PenalexFlameGame extends FlameGame with PanDetector, TapCallbacks {
  final GameState initialGameState;
  final Function(int level) onLevelTapped;

  late GameState _gameState;
  late final World _world;
  late final CameraComponent _cam;

  static const double LEVEL_STEP_Y = 100.0;
  static const double ROAD_WIDTH = 300.0;
  static const double MAP_WIDTH = 1080.0;
  static const double TILE_HEIGHT = 1920.0;
  static const int TOTAL_LEVELS = 3000;

  final Map<int, MapSegmentComponent> _loadedSegments = {};
  final Map<int, LevelMedallionComponent> _loadedMedallions = {};

  double _currentCameraY = 0.0;
  double _targetCameraY = 0.0;
  double _velocityY = 0.0;

  PenalexFlameGame({
    required this.initialGameState,
    required this.onLevelTapped,
  }) {
    _gameState = initialGameState;
  }

  void updateGameState(GameState newState) {
    _gameState = newState;
    _refreshVisibleMedallions();
  }

  @override
  Color backgroundColor() => const Color(0xFF0B1528); // Azul noche colonial

  @override
  Future<void> onLoad() async {
    super.onLoad() ;
    _world = World();
    _cam = CameraComponent(world: _world)
      ..viewfinder.anchor = Anchor.center;

    add(_world);
    add(_cam);

    // Initial camera position: Level 1 is at Y = 0 (bottom). Higher levels go UP (-Y)
    final targetY = -((_gameState.nivelActual - 1) * LEVEL_STEP_Y);
    _currentCameraY = targetY;
    _targetCameraY = targetY;
    _cam.viewfinder.position = Vector2(MAP_WIDTH / 2, _currentCameraY);

    _updateVisibleComponents();
  }

  /// S-Curve road Center X calculation
  static double getRoadCenterX(double worldY) {
    // Continuous wave with wavelength of 1920px
    final wave = sin((worldY / TILE_HEIGHT) * 2.0 * pi);
    return (MAP_WIDTH / 2.0) + (wave * (MAP_WIDTH * 0.22));
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Smooth inertia and damping for camera
    if (_velocityY.abs() > 10.0) {
      _targetCameraY += _velocityY * dt;
      _velocityY *= 0.92; // friction
    }

    // Clamp camera limits
    final maxScrollY = 100.0; // slightly below level 1
    final minScrollY = -((TOTAL_LEVELS - 1) * LEVEL_STEP_Y) - 100.0; // above level 3000
    _targetCameraY = _targetCameraY.clamp(minScrollY, maxScrollY);

    // Interpolate camera to target
    _currentCameraY += (_targetCameraY - _currentCameraY) * min(1.0, dt * 10.0);
    _cam.viewfinder.position = Vector2(MAP_WIDTH / 2, _currentCameraY);

    _updateVisibleComponents();
  }

  void _updateVisibleComponents() {
    final viewHeight = size.y > 0 ? size.y : 800.0;
    final topY = _currentCameraY - (viewHeight * 1.2);
    final bottomY = _currentCameraY + (viewHeight * 1.2);

    // 1. Manage Map Segment Tiles
    final minSegment = (topY / TILE_HEIGHT).floor();
    final maxSegment = (bottomY / TILE_HEIGHT).ceil();

    // Remove offscreen segments
    _loadedSegments.keys.where((seg) => seg < minSegment || seg > maxSegment).toList().forEach((seg) {
      final comp = _loadedSegments.remove(seg);
      if (comp != null) {
        comp.unloadSprite();
        _world.remove(comp);
      }
    });

    // Add onscreen segments
    for (int seg = minSegment; seg <= maxSegment; seg++) {
      if (!_loadedSegments.containsKey(seg)) {
        // Calculate corresponding region (1 to 21)
        final approximateLevel = ((-seg * TILE_HEIGHT) / LEVEL_STEP_Y).toInt().clamp(1, TOTAL_LEVELS);
        final region = getRegionForLevel(approximateLevel);
        
        final segmentComp = MapSegmentComponent(
          segmentIndex: seg,
          assetPath: region.assetName,
          position: Vector2(0, seg * TILE_HEIGHT),
          size: Vector2(MAP_WIDTH, TILE_HEIGHT),
        );
        _loadedSegments[seg] = segmentComp;
        _world.add(segmentComp);
        segmentComp.loadSprite();
      }
    }

    // 2. Manage Medallions
    final minLevel = ((-bottomY / LEVEL_STEP_Y).floor() + 1).clamp(1, TOTAL_LEVELS);
    final maxLevel = ((-topY / LEVEL_STEP_Y).ceil() + 1).clamp(1, TOTAL_LEVELS);

    // Remove offscreen medallions
    _loadedMedallions.keys.where((lvl) => lvl < minLevel || lvl > maxLevel).toList().forEach((lvl) {
      final comp = _loadedMedallions.remove(lvl);
      if (comp != null) {
        _world.remove(comp);
      }
    });

    // Add onscreen medallions
    for (int lvl = minLevel; lvl <= maxLevel; lvl++) {
      if (!_loadedMedallions.containsKey(lvl)) {
        final worldY = -((lvl - 1) * LEVEL_STEP_Y);
        final worldX = getRoadCenterX(worldY);

        final visualState = _getMedallionState(lvl);

        final medComp = LevelMedallionComponent(
          level: lvl,
          visualState: visualState,
          position: Vector2(worldX, worldY),
          onTap: () => onLevelTapped(lvl),
        );
        _loadedMedallions[lvl] = medComp;
        _world.add(medComp);
      }
    }
  }

  MedallionVisualState _getMedallionState(int level) {
    if (_gameState.isLevelLocked(level)) {
      return MedallionVisualState.bloqueadoPorFallos;
    }
    if (_gameState.nivelesCompletados.contains(level) || level < _gameState.nivelActual) {
      return MedallionVisualState.completado;
    }
    if (level == _gameState.nivelActual) {
      return MedallionVisualState.actual;
    }
    return MedallionVisualState.bloqueado;
  }

  void _refreshVisibleMedallions() {
    for (var entry in _loadedMedallions.entries) {
      _world.remove(entry.value);
    }
    _loadedMedallions.clear();
    _updateVisibleComponents();
  }

  @override
  void onPanUpdate(PanUpdateInfo info) {
    // Scrolling in Flame (drag upwards scrolls up)
    _targetCameraY -= info.delta.global.y * 1.5;
    _velocityY = -info.delta.global.y * 20.0;
  }

  @override
  void onPanEnd(PanEndInfo info) {
    _velocityY = -info.velocity.global.y;
  }

  void scrollToLevel(int level) {
    final targetY = -((level - 1) * LEVEL_STEP_Y);
    _targetCameraY = targetY;
  }
}

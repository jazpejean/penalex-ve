import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import '../providers/game_provider.dart';
import '../data/venezuela_regions.dart';

/// Colores institucionales venezolanos
class ColoresJusticia {
  static const amarillo = Color(0xFFFCDD09); // Bandera Venezuela
  static const azul = Color(0xFF003893);     // Bandera Venezuela
  static const rojo = Color(0xFFCF142B);     // Bandera Venezuela
  static const dorado = Color(0xFFD4AF37);   // Institucional
  static const marmol = Color(0xFFF5F5DC);   // Elegante
  static const blanco = Color(0xFFFFFFFF);
  static const gris = Color(0xFFCCCCCC);
}

/// Quiz Lobby Game estilo Candy Crush - Profesional con Regiones de Venezuela
class QuizLobbyGame extends FlameGame with ScrollDetector, TapDetector {
  final GameState gameState;
  final Function(int) onLevelSelected;

  QuizLobbyGame({
    required this.gameState,
    required this.onLevelSelected,
  });

  final List<LevelNode> levelNodes = [];
  final List<MonumentComponent> monuments = [];
  final List<RegionBackgroundComponent> regionBackgrounds = [];
  double scrollOffset = 0.0;
  final double levelSpacing = 150.0;
  RegionVenezuela? currentRegion;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.anchor = Anchor.topCenter;

    // Crear fondos de regiones
    await _createRegionBackgrounds();
    
    // Crear camino y niveles
    await _createPath();
    
    // Auto-scroll al nivel actual
    _scrollToCurrentLevel();
  }

  Future<void> _createRegionBackgrounds() async {
    // Crear fondos para cada región de Venezuela
    for (final region in RegionesVenezuela.regiones) {
      final bgComponent = RegionBackgroundComponent(
        region: region,
        startY: region.nivelInicio * levelSpacing,
        endY: region.nivelFin * levelSpacing,
        screenWidth: size.x,
      );
      regionBackgrounds.add(bgComponent);
      add(bgComponent);
    }
  }

  Future<void> _createPath() async {
    final totalLevels = 3000;
    final centerX = size.x / 2;

    for (int i = 1; i <= totalLevels; i++) {
      // Calcular posición ondulada (camino serpenteante estilo Candy Crush)
      final yPos = i * levelSpacing;
      final amplitude = size.x * 0.25;
      final xOffset = math.sin(i * 0.3) * amplitude;
      final xPos = centerX + xOffset;

      // Determinar estado del nivel
      final isCompleted = i < gameState.currentLevel;
      final isCurrent = i == gameState.currentLevel;
      final isLocked = i > gameState.currentLevel;

      // Obtener región actual para el nivel
      final region = _getRegionForLevel(i);

      // Crear medallón de nivel
      final levelNode = LevelNode(
        level: i,
        position: Vector2(xPos, yPos),
        isCompleted: isCompleted,
        isCurrent: isCurrent,
        isLocked: isLocked,
        regionColor: region?.colorPrincipal ?? ColoresJusticia.dorado,
      );
      levelNodes.add(levelNode);
      add(levelNode);

      // Agregar monumentos institucionales cada 100 niveles
      if (i % 100 == 0) {
        final monument = MonumentComponent(
          level: i,
          position: Vector2(xPos, yPos - 120),
        );
        monuments.add(monument);
        add(monument);

        // Agregar bandera venezolana junto al monumento
        add(VenezuelanFlag(
          position: Vector2(xPos - 90, yPos - 120),
        ));
      }

      // Agregar monumentos regionales cada 25 niveles
      if (i % 25 == 0 && i % 100 != 0 && region != null) {
        add(RegionalMonumentMarker(
          level: i,
          position: Vector2(xPos + 70, yPos),
          region: region,
        ));
      }

      // Agregar decoraciones legales cada 50 niveles (si no hay monumento)
      if (i % 50 == 0 && i % 100 != 0) {
        final decorationType = (i ~/ 50) % 3;
        add(LegalDecoration(
          type: decorationType,
          position: Vector2(xPos - 70, yPos),
        ));
      }
    }
  }

  RegionVenezuela? _getRegionForLevel(int level) {
    return RegionesVenezuela.regiones.firstWhere(
      (region) => level >= region.nivelInicio && level <= region.nivelFin,
      orElse: () => RegionesVenezuela.regiones.first,
    );
  }

  void _scrollToCurrentLevel() {
    scrollOffset = gameState.currentLevel * levelSpacing - size.y / 2;
    scrollOffset = scrollOffset.clamp(0.0, 3000 * levelSpacing);
    camera.viewfinder.position = Vector2(0, scrollOffset);
  }

  @override
  void onScroll(PointerScrollInfo info) {
    scrollOffset += info.scrollDelta.global.y;
    scrollOffset = scrollOffset.clamp(0.0, 3000 * levelSpacing);
    camera.viewfinder.position = Vector2(0, scrollOffset);
  }

  @override
  void onTapDown(TapDownInfo info) {
    final tapPos = info.eventPosition.game;
    
    // Verificar si se tocó algún medallón
    for (final node in levelNodes) {
      if (node.containsPoint(tapPos) && !node.isLocked) {
        onLevelSelected(node.level);
        break;
      }
    }
  }
}

/// Fondo de región con monumentos icónicos
class RegionBackgroundComponent extends PositionComponent {
  final RegionVenezuela region;
  final double startY;
  final double endY;
  final double screenWidth;

  RegionBackgroundComponent({
    required this.region,
    required this.startY,
    required this.endY,
    required this.screenWidth,
  }) {
    position = Vector2(0, startY);
    size = Vector2(screenWidth, endY - startY);
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    
    // Gradiente con color de la región
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        region.colorPrincipal.withOpacity(0.15),
        region.colorPrincipal.withOpacity(0.05),
        ColoresJusticia.marmol.withOpacity(0.3),
        region.colorPrincipal.withOpacity(0.05),
        region.colorPrincipal.withOpacity(0.15),
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );
    
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // Nombre de la región en marca de agua
    final textPainter = TextPainter(
      text: TextSpan(
        text: region.estado.toUpperCase(),
        style: TextStyle(
          fontSize: 80,
          fontWeight: FontWeight.bold,
          color: region.colorPrincipal.withOpacity(0.08),
          letterSpacing: 4,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    // Dibujar el nombre rotado en el centro
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(-math.pi / 12);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();

    // Dibujar iconos regionales sutiles
    _drawRegionalIcons(canvas, region);
  }

  void _drawRegionalIcons(Canvas canvas, RegionVenezuela region) {
    final iconPaint = Paint()
      ..color = region.colorPrincipal.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Dibujar símbolos característicos de la región
    // (Ejemplo: para Caracas - edificios gubernamentales, para Zulia - petróleo, etc.)
    canvas.save();
    canvas.translate(size.x * 0.8, size.y * 0.3);
    _drawJusticeBuildingIcon(canvas, iconPaint);
    canvas.restore();

    canvas.save();
    canvas.translate(size.x * 0.2, size.y * 0.7);
    _drawJusticeBuildingIcon(canvas, iconPaint);
    canvas.restore();
  }

  void _drawJusticeBuildingIcon(Canvas canvas, Paint paint) {
    // Dibujar edificio judicial simplificado
    final path = Path()
      ..moveTo(0, 40)
      ..lineTo(-30, 40)
      ..lineTo(-30, -20)
      ..lineTo(-20, -30)
      ..lineTo(20, -30)
      ..lineTo(30, -20)
      ..lineTo(30, 40)
      ..lineTo(0, 40);
    canvas.drawPath(path, paint);
  }
}

/// Medallón de nivel (nodo del camino)
class LevelNode extends PositionComponent {
  final int level;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLocked;
  final Color regionColor;

  double glowAnimation = 0.0;
  final double radius = 45.0;

  LevelNode({
    required this.level,
    required Vector2 position,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLocked,
    required this.regionColor,
  }) {
    this.position = position;
    size = Vector2.all(radius * 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isCurrent) {
      glowAnimation += dt * 2;
    }
  }

  bool containsPoint(Vector2 point) {
    final dx = point.x - position.x;
    final dy = point.y - position.y;
    return (dx * dx + dy * dy) <= (radius * radius);
  }

  @override
  void render(Canvas canvas) {
    final center = Offset.zero;

    // Sombra profunda
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center.translate(0, 6), radius, shadowPaint);

    // Glow pulsante para nivel actual (amarillo venezolano)
    if (isCurrent) {
      final glowRadius = radius + 12 + math.sin(glowAnimation) * 8;
      final glowPaint = Paint()
        ..color = ColoresJusticia.amarillo.withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(center, glowRadius, glowPaint);
    }

    // Medallón base con textura
    Color medallonColor;
    if (isLocked) {
      medallonColor = ColoresJusticia.gris;
    } else if (isCompleted) {
      medallonColor = ColoresJusticia.dorado;
    } else {
      medallonColor = regionColor;
    }

    // Gradiente circular para profundidad
    final medallonGradient = RadialGradient(
      colors: [
        medallonColor.withOpacity(0.9),
        medallonColor,
        medallonColor.withOpacity(0.7),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final medallonPaint = Paint()
      ..shader = medallonGradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );
    canvas.drawCircle(center, radius, medallonPaint);

    // Borde dorado triple (efecto moneda)
    final borderPaint1 = Paint()
      ..color = ColoresJusticia.dorado
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, borderPaint1);

    final borderPaint2 = Paint()
      ..color = ColoresJusticia.dorado.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 5, borderPaint2);

    // Texto del nivel
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$level',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: isLocked ? Colors.white : Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    // Checkmark para completados (estilo elegante)
    if (isCompleted) {
      final checkPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path()
        ..moveTo(-12, 2)
        ..lineTo(-6, 10)
        ..lineTo(14, -10);
      canvas.drawPath(path, checkPaint);
    }

    // Candado para bloqueados
    if (isLocked) {
      final lockPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      // Cuerpo del candado
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-6, 0, 12, 12),
          const Radius.circular(2),
        ),
        lockPaint..style = PaintingStyle.fill,
      );

      // Arco del candado
      canvas.drawArc(
        const Rect.fromLTWH(-6, -8, 12, 12),
        math.pi,
        math.pi,
        false,
        lockPaint..style = PaintingStyle.stroke,
      );
    }
  }
}

/// Monumento institucional (cada 100 niveles)
class MonumentComponent extends PositionComponent {
  final int level;

  MonumentComponent({
    required this.level,
    required Vector2 position,
  }) {
    this.position = position;
    size = Vector2(220, 110);
  }

  String _getMonumentName() {
    switch (level) {
      case 100: return 'Palacio Federal\nLegislativo';
      case 200: return 'Tribunal Supremo\nde Justicia';
      case 300: return 'Ministerio\nPúblico';
      case 400: return 'Defensoría\nPública';
      case 500: return 'Fiscalía\nGeneral';
      case 600: return 'Capitolio\nFederal';
      case 700: return 'Palacio de\nJusticia';
      case 800: return 'Corte de\nApelaciones';
      case 900: return 'Juzgado\nSupremo';
      case 1000: return 'Sala\nConstitucional';
      case 1500: return 'Sala\nPenal';
      case 2000: return 'Sala Casación\nCivil';
      case 2500: return 'Consejo de la\nJudicatura';
      case 3000: return 'Magistrado\nSupremo ⚖️';
      default: return 'Hito\nJudicial';
    }
  }

  @override
  void render(Canvas canvas) {
    // Placa de mármol con relieve
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-110, 0, 220, 110),
      const Radius.circular(12),
    );

    // Sombra profunda
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawRRect(rect.shift(const Offset(0, 6)), shadowPaint);

    // Fondo de mármol con gradiente
    final marbleGradient = LinearGradient(
      colors: [
        ColoresJusticia.marmol,
        ColoresJusticia.blanco,
        ColoresJusticia.marmol,
      ],
    );
    canvas.drawRRect(
      rect,
      Paint()..shader = marbleGradient.createShader(rect.outerRect),
    );

    // Borde dorado grueso (triple capa)
    canvas.drawRRect(
      rect,
      Paint()
        ..color = ColoresJusticia.dorado
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    canvas.drawRRect(
      rect.deflate(4),
      Paint()
        ..color = ColoresJusticia.dorado.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Texto del monumento (centrado)
    final textPainter = TextPainter(
      text: TextSpan(
        text: _getMonumentName(),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: ColoresJusticia.azul,
          height: 1.4,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: 200);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, 15));

    // Número de nivel en dorado
    final levelPainter = TextPainter(
      text: TextSpan(
        text: 'Nivel $level',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: ColoresJusticia.dorado,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    levelPainter.layout();
    levelPainter.paint(canvas, Offset(-levelPainter.width / 2, 80));
  }
}

/// Marcador de monumento regional
class RegionalMonumentMarker extends PositionComponent {
  final int level;
  final RegionVenezuela region;

  RegionalMonumentMarker({
    required this.level,
    required Vector2 position,
    required this.region,
  }) {
    this.position = position;
    size = Vector2(50, 50);
  }

  @override
  void render(Canvas canvas) {
    // Icono circular con color de región
    final paint = Paint()
      ..color = region.colorPrincipal
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = ColoresJusticia.dorado
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset.zero, 25, paint);
    canvas.drawCircle(Offset.zero, 25, borderPaint);

    // Icono de edificio regional
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Dibujar edificio simplificado
    canvas.drawRect(const Rect.fromLTWH(-10, -10, 20, 20), iconPaint);
    canvas.drawLine(const Offset(-10, -15), const Offset(0, -20), iconPaint);
    canvas.drawLine(const Offset(0, -20), const Offset(10, -15), iconPaint);
  }
}

/// Bandera de Venezuela (animada)
class VenezuelanFlag extends PositionComponent {
  double waveAnimation = 0.0;

  VenezuelanFlag({required Vector2 position}) {
    this.position = position;
    size = Vector2(70, 50);
  }

  @override
  void update(double dt) {
    super.update(dt);
    waveAnimation += dt * 3;
  }

  @override
  void render(Canvas canvas) {
    final width = size.x;
    final height = size.y;
    final stripeHeight = height / 3;

    // Efecto de ondulación
    final wave = math.sin(waveAnimation) * 2;

    // Amarillo
    final yellowPath = Path()
      ..moveTo(0, 0)
      ..lineTo(width + wave, 0)
      ..lineTo(width + wave, stripeHeight)
      ..lineTo(0, stripeHeight)
      ..close();
    canvas.drawPath(yellowPath, Paint()..color = ColoresJusticia.amarillo);

    // Azul
    final bluePath = Path()
      ..moveTo(0, stripeHeight)
      ..lineTo(width + wave * 0.5, stripeHeight)
      ..lineTo(width + wave * 0.5, stripeHeight * 2)
      ..lineTo(0, stripeHeight * 2)
      ..close();
    canvas.drawPath(bluePath, Paint()..color = ColoresJusticia.azul);

    // Rojo
    final redPath = Path()
      ..moveTo(0, stripeHeight * 2)
      ..lineTo(width, stripeHeight * 2)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();
    canvas.drawPath(redPath, Paint()..color = ColoresJusticia.rojo);

    // Borde
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Asta de la bandera
    canvas.drawRect(
      const Rect.fromLTWH(-6, 0, 4, 50),
      Paint()..color = const Color(0xFF8B4513),
    );
  }
}

/// Decoraciones legales (balanzas, martillos, escudos)
class LegalDecoration extends PositionComponent {
  final int type; // 0: balanza, 1: martillo, 2: escudo
  double rotationAnimation = 0.0;

  LegalDecoration({
    required this.type,
    required Vector2 position,
  }) {
    this.position = position;
    size = Vector2.all(50);
  }

  @override
  void update(double dt) {
    super.update(dt);
    rotationAnimation += dt * 0.5;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.rotate(math.sin(rotationAnimation) * 0.1);

    final paint = Paint()
      ..color = ColoresJusticia.dorado
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = ColoresJusticia.dorado.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    switch (type) {
      case 0:
        _drawBalance(canvas, paint, fillPaint);
        break;
      case 1:
        _drawGavel(canvas, paint, fillPaint);
        break;
      case 2:
        _drawShield(canvas, paint, fillPaint);
        break;
    }

    canvas.restore();
  }

  void _drawBalance(Canvas canvas, Paint paint, Paint fillPaint) {
    // Platillos
    canvas.drawCircle(const Offset(-15, 0), 10, fillPaint);
    canvas.drawCircle(const Offset(-15, 0), 10, paint);
    canvas.drawCircle(const Offset(15, 0), 10, fillPaint);
    canvas.drawCircle(const Offset(15, 0), 10, paint);
    
    // Barra horizontal
    canvas.drawLine(const Offset(-15, 0), const Offset(15, 0), paint);
    
    // Soporte central
    canvas.drawLine(const Offset(0, 0), const Offset(0, 20), paint);
    
    // Base
    canvas.drawLine(const Offset(-10, 20), const Offset(10, 20), paint);
  }

  void _drawGavel(Canvas canvas, Paint paint, Paint fillPaint) {
    // Mango
    canvas.drawLine(const Offset(-8, 15), const Offset(8, -15), paint);
    
    // Cabeza
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-12, -20, 8, 12),
      const Radius.circular(2),
    );
    canvas.drawRRect(rect, fillPaint);
    canvas.drawRRect(rect, paint);
  }

  void _drawShield(Canvas canvas, Paint paint, Paint fillPaint) {
    final path = Path()
      ..moveTo(0, -20)
      ..lineTo(15, -15)
      ..lineTo(15, 8)
      ..lineTo(0, 20)
      ..lineTo(-15, 8)
      ..lineTo(-15, -15)
      ..close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);
    
    // Cruz en el centro
    canvas.drawLine(const Offset(0, -10), const Offset(0, 10), paint);
    canvas.drawLine(const Offset(-8, 0), const Offset(8, 0), paint);
  }
}

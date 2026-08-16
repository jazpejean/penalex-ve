import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../data/venezuela_regions.dart';
import 'global_ranking_screen.dart';
import 'quiz_game_screen.dart';

class QuizLobbyScreen extends StatefulWidget {
  const QuizLobbyScreen({super.key});

  @override
  State<QuizLobbyScreen> createState() => _QuizLobbyScreenState();
}

class _QuizLobbyScreenState extends State<QuizLobbyScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  double scrollOffset = 0.0;
  int totalNiveles = 3000;
  ui.Image? rioDoradoTexture;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          scrollOffset = _scrollController.offset;
        });
      });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadTextures();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentLevel());
  }

  Future<void> _loadTextures() async {
    try {
      final data = await rootBundle.load('assets/images/rio_dorado_texture.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      setState(() {
        rioDoradoTexture = frame.image;
      });
    } catch (e) {
      // Textura opcional
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _scrollToCurrentLevel() {
    final gameState = Provider.of<GameState>(context, listen: false);
    final currentLevel = gameState.currentLevel;
    if (_scrollController.hasClients && currentLevel > 1) {
      final offset = (currentLevel - 1) * 100.0;
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final userState = Provider.of<UserState>(context, listen: false);
    
    final userName = userState.user?.nombre ?? 'Usuario';
    final currentLevel = gameState.currentLevel;
    final score = gameState.score;
    final apelaciones = gameState.apelaciones;
    
    // Obtener región actual
    final RegionVenezuela? regionActual = gameState.getCurrentRegion();

    return Scaffold(
      body: Stack(
        children: [
          // Fondo gradiente con colores de región
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: regionActual != null 
                    ? [
                        regionActual.colorPrincipal.withValues(alpha: 0.3),
                        const Color(0xFF1a1a2e),
                        const Color(0xFF16213e),
                      ]
                    : const [
                        Color(0xFF0B101B),
                        Color(0xFF1a1a2e),
                        Color(0xFF16213e),
                      ],
                ),
              ),
            ),
          ),
          
          // Camino dorado con decoraciones
          Positioned.fill(
            child: CustomPaint(
              painter: CaminoDoradoPainter(
                scrollOffset: scrollOffset,
                currentLevel: currentLevel,
                totalNiveles: totalNiveles,
                rioTexture: rioDoradoTexture,
              ),
            ),
          ),
          
          // UI
          SafeArea(
            child: Column(
              children: [
                _buildTopBanner(userName, currentLevel, score, apelaciones),
                if (regionActual != null) _buildRegionCard(regionActual, currentLevel),
                const Spacer(),
                _buildPlayButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          // Botón de ranking
          _buildRankingButton(),
        ],
      ),
    );
  }

  Widget _buildTopBanner(String userName, int level, int score, int apelaciones) {
    final inicial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Stack(
        children: [
          // Pergamino de fondo
          Image.asset(
            'assets/images/pergamino.png',
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFE6D5B8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8B7355), width: 2),
              ),
            ),
          ),
          
          // Contenido del banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC5A059), Color(0xFFE6B800)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      inicial,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Rango y barra XP
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nivel $level',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E2723),
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // Barra de XP
                      Stack(
                        children: [
                          // Background de la barra
                          Image.asset(
                            'assets/images/xp_bar_background.png',
                            width: double.infinity,
                            height: 20,
                            fit: BoxFit.fill,
                            errorBuilder: (_, __, ___) => Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          
                          // Progreso
                          FractionallySizedBox(
                            widthFactor: (score % 1000) / 1000,
                            child: Container(
                              height: 20,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFC5A059)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          
                          // Texto XP
                          Positioned.fill(
                            child: Center(
                              child: Text(
                                '$score XP',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Apelaciones
                Column(
                  children: [
                    const Text(
                      'Apelaciones',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        final disponible = index < apelaciones;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          child: Image.asset(
                            disponible
                                ? 'assets/images/mini_pergamino_activo.png'
                                : 'assets/images/mini_pergamino_gris.png',
                            width: 20,
                            height: 20,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.description,
                              color: disponible ? const Color(0xFFC5A059) : Colors.grey,
                              size: 20,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionCard(RegionVenezuela region, int currentLevel) {
    final progresoEnRegion = currentLevel - region.nivelInicio;
    final totalNivelesRegion = region.nivelFin - region.nivelInicio + 1;
    final porcentajeProgreso = (progresoEnRegion / totalNivelesRegion).clamp(0.0, 1.0);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            region.colorPrincipal.withValues(alpha: 0.8),
            region.colorPrincipal.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: region.colorPrincipal,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: region.colorPrincipal.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      region.estado,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Capital: ${region.capital}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            region.descripcion,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 12),
          // Barra de progreso en la región
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progreso: Nivel $currentLevel de ${region.nivelFin}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: porcentajeProgreso,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, child) => Transform.scale(
        scale: _pulseAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, animation, __) => FadeTransition(
                opacity: animation,
                child: const QuizGameScreen(),
              ),
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        },
        child: Container(
          width: 220,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC5A059), Color(0xFFFFD700)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Text(
                  'JUGAR',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankingButton() {
    return Positioned(
      top: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GlobalRankingScreen()),
          );
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC5A059), Color(0xFFE6B800)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC5A059).withValues(alpha: 0.4),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Icon(
            Icons.emoji_events,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

// Painter del camino dorado con decoraciones laterales
class CaminoDoradoPainter extends CustomPainter {
  final double scrollOffset;
  final int currentLevel;
  final int totalNiveles;
  final ui.Image? rioTexture;

  CaminoDoradoPainter({
    required this.scrollOffset,
    required this.currentLevel,
    required this.totalNiveles,
    this.rioTexture,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final amplitude = 130.0;
    final frequency = 0.015;
    
    // Camino dorado con textura
    final pathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 55
      ..strokeCap = StrokeCap.round;

    if (rioTexture != null) {
      pathPaint.shader = ImageShader(
        rioTexture!,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      );
    } else {
      pathPaint.color = const Color(0xFFFFD700);
    }
    
    final path = Path();
    
    for (int i = 0; i <= totalNiveles; i++) {
      final y = (i * 100.0) - scrollOffset;
      if (y < -200) continue;
      if (y > size.height + 200) break;
      
      final x = centerX + (math.sin(i * frequency) * amplitude);
      
      if (i == 0 || y <= -200) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      
      // Líneas divisorias cada 30 píxeles
      if (i % 3 == 0) {
        final divPaint = Paint()
          ..color = const Color(0xFF8B6914)
          ..strokeWidth = 3;
        
        canvas.drawLine(
          Offset(x - 25, y),
          Offset(x + 25, y),
          divPaint,
        );
      }
    }
    
    canvas.drawPath(path, pathPaint);
    
    // Dibujar medallones y decoraciones
    for (int nivel = math.max(1, (scrollOffset / 100).floor() - 5); 
         nivel <= math.min(totalNiveles, (scrollOffset / 100).ceil() + 15); 
         nivel++) {
      final y = (nivel * 100.0) - scrollOffset;
      final x = centerX + (math.sin(nivel * frequency) * amplitude);
      
      // Decoraciones laterales con VARIACIÓN
      _dibujarDecoracionesLaterales(canvas, nivel, x, y);
      
      // Medallones
      _dibujarMedallon(canvas, nivel, x, y);
    }
  }

  void _dibujarDecoracionesLaterales(Canvas canvas, int nivel, double x, double y) {
    // ROTACIÓN: Alterna las decoraciones entre izquierda y derecha cada ciertos niveles
    
    // Cada 5 niveles: Alterna columnas entre izquierda y derecha
    if (nivel % 5 == 0) {
      if (nivel % 10 == 0) {
        // Niveles 10, 20, 30... → Columnas a la DERECHA
        _dibujarImagen(canvas, 'assets/images/columna_griega.png', x + 180, y, 60, 80);
      } else {
        // Niveles 5, 15, 25... → Columnas a la IZQUIERDA
        _dibujarImagen(canvas, 'assets/images/columna_griega.png', x - 180, y, 60, 80);
      }
    }
    
    // Cada 7 niveles: Alterna templos entre izquierda y derecha
    if (nivel % 7 == 0) {
      if (nivel % 14 == 0) {
        // Niveles 14, 28, 42... → Templos a la IZQUIERDA
        _dibujarImagen(canvas, 'assets/images/templo_derecho.png', x - 180, y, 70, 70);
      } else {
        // Niveles 7, 21, 35... → Templos a la DERECHA
        _dibujarImagen(canvas, 'assets/images/templo_derecho.png', x + 180, y, 70, 70);
      }
    }
    
    // Elementos vectoriales ligeros cada 10 niveles, también alternados
    if (nivel % 10 == 0 && nivel % 5 != 0) {
      // Balanza - alterna lado
      if (nivel % 20 == 0) {
        _dibujarBalanza(canvas, x + 180, y - 50);
      } else {
        _dibujarBalanza(canvas, x - 180, y - 50);
      }
    } else if (nivel % 15 == 0 && nivel % 5 != 0) {
      // Martillo - alterna lado
      if (nivel % 30 == 0) {
        _dibujarMartillo(canvas, x - 180, y - 50);
      } else {
        _dibujarMartillo(canvas, x + 180, y - 50);
      }
    }
  }

  void _dibujarImagen(Canvas canvas, String path, double x, double y, double w, double h) {
    // Nota: Las imágenes deben ser pre-cargadas y pasadas como ui.Image
    // Por simplicidad, dibujamos un placeholder
    final paint = Paint()..color = Colors.grey.withValues(alpha: 0.3);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x, y), width: w, height: h),
      paint,
    );
  }

  void _dibujarMartillo(Canvas canvas, double x, double y) {
    final paint = Paint()
      ..color = const Color(0xFF8B7355)
      ..style = PaintingStyle.fill;
    
    // Mango
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x, y + 10), width: 4, height: 30),
      paint,
    );
    
    // Cabeza
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y - 8), width: 20, height: 12),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  void _dibujarBalanza(Canvas canvas, double x, double y) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Poste
    canvas.drawLine(Offset(x, y - 15), Offset(x, y + 15), paint);
    
    // Platos
    canvas.drawCircle(Offset(x - 12, y - 5), 8, paint);
    canvas.drawCircle(Offset(x + 12, y - 5), 8, paint);
    
    // Barra
    canvas.drawLine(Offset(x - 12, y - 5), Offset(x + 12, y - 5), paint);
  }

  void _dibujarMedallon(Canvas canvas, int nivel, double x, double y) {
    bool esActual = nivel == currentLevel;
    
    // Placeholder circular
    final paint = Paint()
      ..color = esActual 
          ? const Color(0xFFFFD700) 
          : (nivel < currentLevel ? const Color(0xFF27AE60) : const Color(0xFF2C3E50))
      ..style = PaintingStyle.fill;
    
    final radius = esActual ? 35.0 : 28.0;
    canvas.drawCircle(Offset(x, y), radius, paint);
    
    // Borde
    final bordePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(x, y), radius, bordePaint);
    
    // Número del nivel
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$nivel',
        style: TextStyle(
          color: Colors.white,
          fontSize: esActual ? 18 : 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(CaminoDoradoPainter oldDelegate) {
    return scrollOffset != oldDelegate.scrollOffset ||
        currentLevel != oldDelegate.currentLevel;
  }
}

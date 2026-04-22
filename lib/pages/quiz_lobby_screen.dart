import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../widgets/animated_path_painter.dart';
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
  late AnimationController _pathController;
  late Animation<double> _pathAnimation;
  late AnimationController _xpController;
  late Animation<double> _xpAnimation;
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  late AnimationController _medallionController;
  late Animation<double> _medallionRotation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _pathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pathAnimation = CurvedAnimation(parent: _pathController, curve: Curves.easeOut);
    _pathController.forward();

    _xpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _xpAnimation = CurvedAnimation(parent: _xpController, curve: Curves.easeOutCubic);

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _breathingAnimation = Tween<double>(begin: 1, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _medallionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _medallionRotation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _medallionController, curve: Curves.linear),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLevel();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pathController.dispose();
    _xpController.dispose();
    _breathingController.dispose();
    _medallionController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _scrollToCurrentLevel() {
    final GameState gameState = Provider.of<GameState>(context, listen: false);
    final int currentLevel = gameState.currentLevel;
    if (_scrollController.hasClients) {
      final double posicion = _calcularPosicionScroll(currentLevel);
      _scrollController.animateTo(
        posicion,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
      );
    }
  }

  double _calcularPosicionScroll(int nivel) {
    const int altoNodo = 90;
    final int offsetNodos = nivel - 10;
    return (offsetNodos * altoNodo).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final GameState gameState = Provider.of<GameState>(context);
    final int currentLevel = gameState.currentLevel;
    final String rangoActual = gameState.getRankForLevel(currentLevel);
    final double progresoXP = currentLevel / 1600;
    final int porcentaje = (progresoXP * 100).toInt();

    if (!_xpController.isAnimating && _xpController.value != progresoXP) {
      _xpController.animateTo(progresoXP, duration: const Duration(milliseconds: 1500));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: <Color>[Color(0xFF1E293B), Color(0xFF0F172A)],
                stops: <double>[0, 0.8],
              ),
            ),
          ),
          const Positioned(
            left: 10,
            top: 100,
            child: Opacity(opacity: 0.15, child: Icon(Icons.account_balance, size: 80, color: Colors.white)),
          ),
          const Positioned(
            right: 10,
            bottom: 150,
            child: Opacity(opacity: 0.15, child: Icon(Icons.account_balance, size: 80, color: Colors.white)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 16),
                  _buildPergaminoHeader(rangoActual, currentLevel, gameState, porcentaje),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFC5A059), width: 1.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: _buildProgressionMap(gameState),
                  ),
                  const SizedBox(height: 24),
                  _buildPlayButton(gameState),
                  const SizedBox(height: 20),
                  _buildCredits(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          _buildRankingButton(),
        ],
      ),
    );
  }

  Widget _buildPergaminoHeader(String rangoActual, int currentLevel, GameState gameState, int porcentaje) => TweenAnimationBuilder(
      tween: Tween<double>(begin: -50, end: 0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) => Transform.translate(offset: Offset(0, value), child: child),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFC5A059), width: 2),
          boxShadow: <BoxShadow>[BoxShadow(color: const Color(0xFFC5A059).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                _buildLogo(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(rangoActual.toUpperCase(),
                          style: const TextStyle(fontFamily: "PlayfairDisplay", fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFC5A059), letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text("Nivel $currentLevel", style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
                _buildApelaciones(gameState),
              ],
            ),
            const SizedBox(height: 16),
            _buildXPBar(gameState),
          ],
        ),
      ),
    );

  Widget _buildLogo() => TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (BuildContext context, double scale, Widget? child) => Transform.scale(scale: scale, child: child),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: <Color>[Color(0xFFC5A059), Color(0xFFE6B800)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: <BoxShadow>[BoxShadow(color: const Color(0xFFC5A059).withValues(alpha: 0.5), blurRadius: 6)],
        ),
        child: const Center(child: Text("JG", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
      ),
    );

  Widget _buildApelaciones(GameState gameState) => Row(
      children: List.generate(5, (int index) => TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.elasticOut,
          builder: (BuildContext context, double scale, Widget? child) => Transform.scale(scale: scale, child: child),
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              index < gameState.apelaciones ? Icons.description_rounded : Icons.description_outlined,
              color: index < gameState.apelaciones ? Colors.red : Colors.grey,
              size: 24,
            ),
          ),
        )),
    );

  Widget _buildXPBar(GameState gameState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text('XP', style: TextStyle(color: Color(0xFFC5A059), fontSize: 12)),
            TweenAnimationBuilder(
              tween: IntTween(begin: 0, end: gameState.score),
              duration: const Duration(milliseconds: 1500),
              builder: (BuildContext context, int value, Widget? child) => Text('$value XP', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _xpAnimation.value,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC5A059)),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressionMap(GameState gameState) {
    final int currentLevel = gameState.currentLevel;
    final int startLevel = currentLevel > 20 ? currentLevel - 20 : 1;
    final int endLevel = currentLevel + 20;
    final List<int> niveles = List<int>.generate(endLevel - startLevel + 1, (int i) => startLevel + i);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pathAnimation,
              builder: (BuildContext context, Widget? child) => CustomPaint(
                painter: AnimatedPathPainter(itemCount: niveles.length, progress: _pathAnimation.value),
              ),
            ),
          ),
          ..._buildLevelNodes(niveles, currentLevel),
        ],
      ),
    );
  }

  List<Widget> _buildLevelNodes(List<int> niveles, int currentLevel) {
    final List<Widget> nodes = <Widget>[];
    const int startY = 80;
    const int stepY = 75;
    final double screenWidth = MediaQuery.of(context).size.width;

    for (int i = 0; i < niveles.length; i++) {
      final int nivel = niveles[i];
      final bool isCurrent = nivel == currentLevel;
      final bool isCompleted = nivel < currentLevel;
      final String rango = Provider.of<GameState>(context, listen: false).getRankForLevel(nivel);
      final double leftOffset = (i % 2 == 0) ? 40.0 : -20.0;

      nodes.add(
        Positioned(
          top: (startY + (i * stepY)).toDouble(),
          left: screenWidth / 2 - 30 + leftOffset,
          child: _buildLevelNode(nivel, rango, isCurrent, isCompleted, i),
        ),
      );
    }
    return nodes;
  }

  Widget _buildLevelNode(int nivel, String rango, bool isCurrent, bool isCompleted, int index) => TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.elasticOut,
      builder: (BuildContext context, double scale, Widget? child) => Transform.scale(scale: scale, child: child),
      child: Column(
        children: <Widget>[
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (BuildContext context, Widget? child) {
              final double glowOpacity = isCurrent ? _glowAnimation.value : 0.0;
              return Container(
                width: isCurrent ? 70 : 52,
                height: isCurrent ? 70 : 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent ? Colors.white : (isCompleted ? const Color(0xFFC5A059) : Colors.grey.shade600),
                  boxShadow: isCurrent
                      ? <BoxShadow>[BoxShadow(color: const Color(0xFFC5A059).withValues(alpha: 0.5 + glowOpacity * 0.5), blurRadius: 20 + glowOpacity * 10, spreadRadius: 6 + glowOpacity * 4)]
                      : null,
                  border: isCurrent ? Border.all(color: const Color(0xFFC5A059), width: 3) : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    if (isCurrent)
                      Positioned(
                        top: -22,
                        child: Row(children: List.generate(3, (int i) => const Icon(Icons.star, color: Color(0xFFC5A059), size: 16))),
                      ),
                    if (isCompleted) const Icon(Icons.scale, color: Colors.white, size: 24),
                    if (isCompleted)
                      Positioned(
                        top: -18,
                        child: Row(children: List.generate(3, (int i) => const Icon(Icons.star, color: Colors.white70, size: 12))),
                      ),
                    if (!isCurrent && !isCompleted) const Icon(Icons.lock, color: Colors.white70, size: 20),
                    if (isCurrent) Text("$nivel", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 500 + (index * 50)),
            builder: (BuildContext context, double opacity, Widget? child) => Opacity(opacity: opacity, child: child),
            child: SizedBox(
              width: 100,
              child: Text(
                rango,
                style: TextStyle(
                  fontSize: 10,
                  color: isCurrent ? const Color(0xFFC5A059) : Colors.white70,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );

  Widget _buildPlayButton(GameState gameState) => Center(
      child: AnimatedBuilder(
        animation: _breathingAnimation,
        builder: (BuildContext context, Widget? child) => Transform.scale(scale: _breathingAnimation.value, child: child),
        child: Container(
          width: 220,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: <Color>[Color(0xFFC5A059), Color(0xFFE6B800)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(30),
            boxShadow: <BoxShadow>[BoxShadow(color: const Color(0xFFC5A059).withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizGameScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text("JUGAR", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 2)),
          ),
        ),
      ),
    );

  Widget _buildCredits() => const Column(
      children: <Widget>[
        Text("Ubicación: Carrizal, Miranda, VE", style: TextStyle(fontSize: 12, color: Colors.white54)),
        SizedBox(height: 4),
        Text("Juego creado por Jean Jazpe Lizcano", style: TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );

  Widget _buildRankingButton() => Positioned(
      top: 20,
      right: 16,
      child: AnimatedBuilder(
        animation: _medallionRotation,
        builder: (BuildContext context, Widget? child) => Transform.rotate(angle: _medallionRotation.value, child: child),
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalRankingScreen())),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: <Color>[Color(0xFFC5A059), Color(0xFFE6B800)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[BoxShadow(color: const Color(0xFFC5A059).withValues(alpha: 0.5), blurRadius: 8)],
            ),
            child: const Icon(Icons.emoji_events, color: Color(0xFF0F172A), size: 28),
          ),
        ),
      ),
    );
}
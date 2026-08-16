import 'dart:async';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../providers/game_provider.dart';
import '../services/audio_service.dart';
import '../services/firestore_service.dart';

class QuizGameScreen extends StatefulWidget {
  const QuizGameScreen({super.key});

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _timerController;
  late Animation<double> _timerAnimation;
  Timer? _questionTimer;
  bool _isAnswered = false;
  bool _showingLevelUp = false;
  Question? _currentQuestion;
  int? _selectedIndex;

  // Confetti
  late ConfettiController _confettiController;
  late ConfettiController _confettiLeft;
  late ConfettiController _confettiRight;
  
  // Level Up Animation
  late AnimationController _levelUpController;
  late Animation<double> _levelUpScale;
  late Animation<double> _levelUpRotation;
  
  // Particle explosion
  late AnimationController _explosionController;
  late Animation<double> _explosionAnimation;
  
  // Button animations
  final List<AnimationController> _buttonControllers = [];
  final List<Animation<double>> _buttonAnimations = [];

  @override
  void initState() {
    super.initState();
    
    // Timer
    _timerController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    _timerAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _timerController, curve: Curves.linear),
    );

    // Confetti
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiLeft = ConfettiController(duration: const Duration(seconds: 3));
    _confettiRight = ConfettiController(duration: const Duration(seconds: 3));

    // Level Up
    _levelUpController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _levelUpScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _levelUpController, curve: Curves.elasticOut),
    );
    _levelUpRotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _levelUpController, curve: Curves.easeInOut),
    );

    // Explosion
    _explosionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _explosionAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _explosionController, curve: Curves.easeOut),
    );

    // Button animations (4 opciones)
    for (int i = 0; i < 4; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );
      _buttonControllers.add(controller);
      _buttonAnimations.add(
        Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: controller, curve: Curves.elasticOut),
        ),
      );
    }

    _loadNextQuestion();
  }

  @override
  void dispose() {
    _timerController.dispose();
    _questionTimer?.cancel();
    _confettiController.dispose();
    _confettiLeft.dispose();
    _confettiRight.dispose();
    _levelUpController.dispose();
    _explosionController.dispose();
    for (final controller in _buttonControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadNextQuestion() async {
    final GameState gameState = Provider.of<GameState>(context, listen: false);
    final int nextLevel = gameState.currentLevel;
    final Question? question = await FirestoreService.loadQuestionByLevel(nextLevel);
    
    if (mounted) {
      setState(() {
        _currentQuestion = question;
        _isAnswered = false;
        _showingLevelUp = false;
        _selectedIndex = null;
      });
      
      if (question != null) {
        _startTimer();
        _animateButtonsIn();
      } else {
        _showNoQuestionDialog();
      }
    }
  }

  void _animateButtonsIn() {
    for (int i = 0; i < _buttonControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 100 * i), () {
        if (mounted) {
          _buttonControllers[i].forward(from: 0);
        }
      });
    }
  }

  void _startTimer() {
    _timerController.reset();
    _timerController.forward();
    _questionTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && !_isAnswered) {
        _onTimeUp();
      }
    });
  }

  void _onAnswerSelected(int selectedIndex) {
    if (_isAnswered || _currentQuestion == null) return;

    setState(() {
      _isAnswered = true;
      _selectedIndex = selectedIndex;
    });
    
    _timerController.stop();
    _questionTimer?.cancel();

    final GameState gameState = Provider.of<GameState>(context, listen: false);
    final bool isCorrect = selectedIndex == _currentQuestion!.respuestaCorrecta;

    // Vibración
    if (isCorrect) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.vibrate();
    }

    final AudioService audioService = AudioService();
    
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      
      if (isCorrect) {
        unawaited(audioService.playCorrectSound());
        _explosionController.forward(from: 0);
        
        final int currentLevelBefore = gameState.currentLevel;
        gameState.answerCorrect();
        final int currentLevelAfter = gameState.currentLevel;
        
        if (currentLevelAfter > currentLevelBefore) {
          _showLevelUpAnimation(currentLevelBefore, currentLevelAfter);
        } else {
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) unawaited(_loadNextQuestion());
          });
        }
      } else {
        unawaited(audioService.playWrongSound());
        gameState.answerWrong();
        
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) unawaited(_loadNextQuestion());
        });
      }
    });
  }

  void _showLevelUpAnimation(int oldLevel, int newLevel) {
    setState(() => _showingLevelUp = true);
    
    // Triple confetti
    _confettiController.play();
    Future.delayed(const Duration(milliseconds: 200), () {
      _confettiLeft.play();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _confettiRight.play();
    });
    
    _levelUpController.forward(from: 0);
    HapticFeedback.heavyImpact();
    
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        unawaited(_loadNextQuestion());
      }
    });
  }

  void _onTimeUp() {
    if (_isAnswered) return;
    setState(() => _isAnswered = true);
    _timerController.stop();
    _questionTimer?.cancel();

    final GameState gameState = Provider.of<GameState>(context, listen: false);
    final AudioService audioService = AudioService();
    unawaited(audioService.playWrongSound());
    gameState.answerWrong();
    HapticFeedback.vibrate();

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) unawaited(_loadNextQuestion());
    });
  }

  void _showNoQuestionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF2C1810),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¡Nivel no disponible!',
          style: TextStyle(color: Color(0xFFC5A059), fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'No hay preguntas disponibles para este nivel aún.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('VOLVER', style: TextStyle(color: Color(0xFFC5A059))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final GameState gameState = Provider.of<GameState>(context);
    
    if (gameState.isLoading || _currentQuestion == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [Color(0xFF1a1a2e), Color(0xFF0B101B)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.gavel,
                    size: 80,
                    color: Color(0xFFC5A059),
                  ),
                ),
                const SizedBox(height: 30),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5A059)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Fondo animado con estrellas
          _buildAnimatedBackground(),
          
          // Contenido principal
          SafeArea(
            child: Column(
              children: <Widget>[
                _buildTopBar(gameState),
                const SizedBox(height: 16),
                _buildProgressBar(gameState),
                const SizedBox(height: 20),
                Expanded(child: _buildQuestionCard()),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          // Explosión de partículas
          if (_isAnswered && _selectedIndex == _currentQuestion!.respuestaCorrecta)
            _buildExplosionEffect(),
          
          // Level up overlay
          if (_showingLevelUp) _buildLevelUpOverlay(gameState),
          
          // Confetti central
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2,
              maxBlastForce: 12,
              minBlastForce: 6,
              emissionFrequency: 0.02,
              numberOfParticles: 40,
              gravity: 0.4,
              colors: const [
                Color(0xFFC5A059),
                Color(0xFFE6B800),
                Color(0xFFF1C40F),
                Color(0xFFFFD700),
              ],
            ),
          ),
          
          // Confetti izquierdo
          Positioned(
            left: 0,
            top: MediaQuery.of(context).size.height * 0.3,
            child: ConfettiWidget(
              confettiController: _confettiLeft,
              blastDirection: 0,
              maxBlastForce: 10,
              minBlastForce: 5,
              emissionFrequency: 0.03,
              numberOfParticles: 25,
              gravity: 0.3,
              colors: const [Color(0xFFC5A059), Color(0xFFE6B800)],
            ),
          ),
          
          // Confetti derecho
          Positioned(
            right: 0,
            top: MediaQuery.of(context).size.height * 0.3,
            child: ConfettiWidget(
              confettiController: _confettiRight,
              blastDirection: math.pi,
              maxBlastForce: 10,
              minBlastForce: 5,
              emissionFrequency: 0.03,
              numberOfParticles: 25,
              gravity: 0.3,
              colors: const [Color(0xFFF1C40F), Color(0xFFFFD700)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 2,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF0B101B),
            Color(0xFF000000),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Estrellas brillantes animadas
          ...List.generate(50, (index) {
            return Positioned(
              left: (index * 37.5) % MediaQuery.of(context).size.width,
              top: (index * 23.7) % MediaQuery.of(context).size.height,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.2, end: 1),
                duration: Duration(milliseconds: 800 + (index % 5) * 200),
                curve: Curves.easeInOut,
                builder: (_, value, __) => Opacity(
                  opacity: value,
                  child: Container(
                    width: 2 + (index % 3),
                    height: 2 + (index % 3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white,
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                onEnd: () {
                  // Repite la animación
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopBar(GameState gameState) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC5A059), Color(0xFFE6B800)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC5A059).withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Apelaciones (pergaminos)
          Row(
            children: List.generate(5, (index) {
              final bool disponible = index < gameState.apelaciones;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: disponible ? 1.0 : 0.5),
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                builder: (_, scale, child) => Transform.scale(
                  scale: scale,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    child: Image.asset(
                      disponible
                          ? 'assets/images/mini_pergamino_activo.png'  // Disponible
                          : 'assets/images/mini_pergamino_gris.png',   // Usado
                      width: 28,
                      height: 28,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.description,
                        color: disponible ? const Color(0xFFC5A059) : Colors.grey,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          
          // Nivel con animación
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (_, scale, child) => Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B101B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD700), width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFD700), size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Nivel ${gameState.currentLevel}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0B101B),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '${gameState.score} XP',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(GameState gameState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Timer circular
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: AnimatedBuilder(
                  animation: _timerAnimation,
                  builder: (_, __) {
                    final progress = _timerAnimation.value;
                    Color color;
                    if (progress > 0.5) {
                      color = const Color(0xFF27AE60);
                    } else if (progress > 0.2) {
                      color = const Color(0xFFF39C12);
                    } else {
                      color = const Color(0xFFE74C3C);
                    }
                    
                    return CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    );
                  },
                ),
              ),
              AnimatedBuilder(
                animation: _timerAnimation,
                builder: (_, __) {
                  final remaining = (_timerAnimation.value * 30).ceil();
                  return Text(
                    '$remaining',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Streak indicator
          if (gameState.streak > 1)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1),
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              builder: (_, scale, child) => Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.6),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '${gameState.streak} RACHA',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    if (_currentQuestion == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Pergamino con pregunta
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFF8DC),
                      Color(0xFFFFFAF0),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFC5A059),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC5A059).withValues(alpha: 0.4),
                      blurRadius: 25,
                      spreadRadius: 3,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFC5A059), Color(0xFFE6B800)],
                        ),
                      ),
                      child: const Icon(
                        Icons.help_outline_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _currentQuestion!.pregunta,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C1810),
                        height: 1.6,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Opciones con animaciones individuales
            ..._currentQuestion!.opciones.asMap().entries.map((entry) {
              return _buildAnimatedOption(entry.key, entry.value);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedOption(int index, String text) {
    final bool isSelected = _selectedIndex == index;
    final bool isCorrect = _isAnswered && index == _currentQuestion!.respuestaCorrecta;
    final bool isWrong = _isAnswered && isSelected && !isCorrect;

    return ScaleTransition(
      scale: _buttonAnimations[index],
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isAnswered ? null : () => _onAnswerSelected(index),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCorrect
                      ? [const Color(0xFF27AE60), const Color(0xFF2ECC71)]
                      : isWrong
                          ? [const Color(0xFFE74C3C), const Color(0xFFC0392B)]
                          : [const Color(0xFFFFF8DC), const Color(0xFFFFFAF0)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCorrect
                      ? const Color(0xFF229954)
                      : isWrong
                          ? const Color(0xFF922B21)
                          : const Color(0xFFC5A059),
                  width: isSelected ? 4 : 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isCorrect
                            ? const Color(0xFF27AE60)
                            : isWrong
                                ? const Color(0xFFE74C3C)
                                : const Color(0xFFC5A059))
                        .withValues(alpha: 0.4),
                    blurRadius: isSelected ? 20 : 12,
                    spreadRadius: isSelected ? 3 : 1,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Letra circular
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isCorrect || isWrong
                            ? [Colors.white, Colors.white]
                            : [const Color(0xFFC5A059), const Color(0xFFE6B800)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isCorrect || isWrong
                              ? (isCorrect ? const Color(0xFF27AE60) : const Color(0xFFE74C3C))
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Texto
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isCorrect || isWrong ? Colors.white : const Color(0xFF2C1810),
                        height: 1.4,
                      ),
                    ),
                  ),
                  
                  // Icono de resultado
                  if (isCorrect)
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 32)
                  else if (isWrong)
                    const Icon(Icons.cancel_rounded, color: Colors.white, size: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExplosionEffect() {
    return AnimatedBuilder(
      animation: _explosionAnimation,
      builder: (_, __) {
        return Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: ExplosionPainter(_explosionAnimation.value),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelUpOverlay(GameState gameState) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Estrella giratoria con el nivel
            AnimatedBuilder(
              animation: _levelUpRotation,
              builder: (_, child) => Transform.rotate(
                angle: _levelUpRotation.value,
                child: child,
              ),
              child: ScaleTransition(
                scale: _levelUpScale,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFC5A059)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                        blurRadius: 40,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${gameState.currentLevel}',
                      style: const TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B101B),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Texto animado
            ScaleTransition(
              scale: _levelUpScale,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFC5A059), Color(0xFFE6B800)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC5A059).withValues(alpha: 0.6),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Text(
                      '¡NIVEL SUPERADO!',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const Text(
                    '¡Increíble trabajo!',
                    style: TextStyle(
                      fontSize: 24,
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Painter para el efecto de explosión
class ExplosionPainter extends CustomPainter {
  ExplosionPainter(this.progress);
  
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final random = math.Random(42);

    for (int i = 0; i < 30; i++) {
      final angle = (i / 30) * 2 * math.pi;
      final distance = progress * 200 * (0.5 + random.nextDouble() * 0.5);
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;
      
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final color = i % 3 == 0
          ? const Color(0xFFFFD700)
          : i % 3 == 1
              ? const Color(0xFFC5A059)
              : const Color(0xFFF1C40F);
      
      paint.color = color.withValues(alpha: opacity);
      
      final size = 8 + random.nextDouble() * 12;
      canvas.drawCircle(Offset(x, y), size, paint);
    }
  }

  @override
  bool shouldRepaint(ExplosionPainter oldDelegate) => progress != oldDelegate.progress;
}

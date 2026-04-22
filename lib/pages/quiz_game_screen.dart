import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../models/question.dart';
import '../providers/game_provider.dart';
import '../providers/user_provider.dart';
import '../services/audio_service.dart';
import '../services/firestore_service.dart';
import '../widgets/quiz_timer_widget.dart';

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

  late ConfettiController _confettiController;
  late AnimationController _levelUpController;
  late Animation<double> _levelUpScaleAnimation;
  late Animation<Offset> _oldLevelSlideAnimation;
  late Animation<Offset> _newLevelSlideAnimation;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    _timerAnimation = Tween<double>(begin: 1, end: 0).animate(_timerController);

    _confettiController = ConfettiController(duration: const Duration(seconds: 1));

    _levelUpController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _levelUpScaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _levelUpController, curve: Curves.elasticOut),
    );
    _oldLevelSlideAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1))
        .animate(CurvedAnimation(parent: _levelUpController, curve: Curves.easeIn));
    _newLevelSlideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _levelUpController, curve: Curves.easeOut));

    _loadNextQuestion();
  }

  @override
  void dispose() {
    _timerController.dispose();
    _questionTimer?.cancel();
    _confettiController.dispose();
    _levelUpController.dispose();
    super.dispose();
  }

  Future<void> _loadNextQuestion() async {
    final GameState gameState = Provider.of<GameState>(context, listen: false);
    final int nextLevel = gameState.currentLevel + 1;
    final Question? question = await FirestoreService.loadQuestionByLevel(nextLevel);
    setState(() {
      _currentQuestion = question;
      _isAnswered = false;
      _showingLevelUp = false;
    });
    if (question != null) {
      _startTimer();
    } else {
      _showGameOverDialog();
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

    setState(() => _isAnswered = true);
    _timerController.stop();
    _questionTimer?.cancel();

    final GameState gameState = Provider.of<GameState>(context, listen: false);
    final int currentLevelBefore = gameState.currentLevel;
    final bool isCorrect = selectedIndex == _currentQuestion!.respuestaCorrecta;

    final AudioService audioService = AudioService();
    if (isCorrect) {
      unawaited(audioService.playCorrectSound());
      gameState.answerCorrect();
      final int currentLevelAfter = gameState.currentLevel;
      if (currentLevelAfter > currentLevelBefore) {
        _showLevelUpAnimation(currentLevelBefore, currentLevelAfter);
      } else {
        unawaited(_loadNextQuestion());
      }
    } else {
      unawaited(audioService.playWrongSound());
      gameState.answerWrong();
      unawaited(_loadNextQuestion());
    }
  }

  void _showLevelUpAnimation(int oldLevel, int newLevel) {
    setState(() => _showingLevelUp = true);
    _confettiController.play();
    _levelUpController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1800), () {
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

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) unawaited(_loadNextQuestion());
    });
  }

  void _showGameOverDialog() {
    final GameState gameState = Provider.of<GameState>(context, listen: false);
    final UserState userState = Provider.of<UserState>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          gameState.apelaciones > 0 ? '¡Nivel Completado!' : 'Juego Terminado',
          style: const TextStyle(color: AppColors.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Puntuación: ${gameState.score}'),
            Text('Racha máxima: ${gameState.streak}'),
            if (gameState.apelaciones <= 0) Text('Apelaciones restantes: ${gameState.apelaciones}'),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              userState.saveProgress(gameState.currentLevel, gameState.score);
            },
            child: const Text('ACEPTAR'),
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
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[AppColors.background, AppColors.surface],
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[AppColors.background, AppColors.surface],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: List.generate(
                            5,
                            (int index) => Icon(
                              index < gameState.apelaciones ? Icons.favorite : Icons.favorite_border,
                              color: index < gameState.apelaciones ? Colors.red : Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                        Text(
                          'Puntuación: ${gameState.score}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Nivel ${gameState.currentLevel}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: QuizTimerWidget(
                      animation: _timerAnimation,
                      controller: _timerController,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                _currentQuestion!.pregunta,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 30),
                              ..._currentQuestion!.opciones.asMap().entries.map(
                                    (MapEntry<int, String> entry) => Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _isAnswered ? null : () => _onAnswerSelected(entry.key),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _getButtonColor(entry.key),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          entry.value,
                                          style: const TextStyle(fontSize: 16),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (gameState.streak > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Racha: ${gameState.streak}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_showingLevelUp) _buildLevelUpOverlay(gameState),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              colors: const <Color>[AppColors.secondary, AppColors.primary, Colors.white],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelUpOverlay(GameState gameState) => Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ScaleTransition(
              scale: _levelUpScaleAnimation,
              child: const Text(
                "¡NIVEL SUPERADO!",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                  shadows: <Shadow>[Shadow(blurRadius: 10, offset: Offset(2, 2))],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SlideTransition(
                  position: _oldLevelSlideAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "${gameState.currentLevel - 1}",
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                const Icon(Icons.arrow_forward, color: AppColors.secondary, size: 40),
                const SizedBox(width: 20),
                SlideTransition(
                  position: _newLevelSlideAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: <BoxShadow>[BoxShadow(color: AppColors.secondary.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5)],
                    ),
                    child: Text(
                      "${gameState.currentLevel}",
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            AnimatedBuilder(
              animation: _levelUpController,
              builder: (BuildContext context, Widget? child) => LinearProgressIndicator(
                  value: _levelUpController.value,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  minHeight: 10,
                ),
            ),
          ],
        ),
      ),
    );

  Color _getButtonColor(int index) {
    if (!_isAnswered) return AppColors.primary;
    if (index == _currentQuestion!.respuestaCorrecta) return Colors.green;
    return Colors.red;
  }
}
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/quiz_lobby_game.dart';
import '../providers/game_provider.dart';
import 'quiz_game_screen.dart';

class QuizLobbyScreen extends StatelessWidget {
  const QuizLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Quiz de Derecho Penal Venezolano',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFD4AF37),
        elevation: 4,
      ),
      body: Consumer<GameState>(
        builder: (context, gameState, child) {
          return GameWidget(
            game: QuizLobbyGame(
              gameState: gameState,
              onLevelSelected: (level) {
                _showLevelDialog(context, level, gameState);
              },
            ),
          );
        },
      ),
    );
  }

  void _showLevelDialog(BuildContext context, int level, GameState gameState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Nivel $level',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD4AF37),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.gavel,
              size: 60,
              color: Color(0xFF003893),
            ),
            const SizedBox(height: 16),
            Text(
              '¿Estás listo para enfrentar este desafío legal?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuizGameScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'JUGAR',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

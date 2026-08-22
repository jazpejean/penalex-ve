import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../game/penalex_flame_game.dart';
import '../../models/region_model.dart';
import '../../services/game_state_service.dart';
import '../widgets/quiz_modal_dialog.dart';
import '../widgets/top_parchment_banner.dart';

class LobbyGameScreen extends StatefulWidget {
  final GameStateService stateService;
  final VoidCallback onBackToDashboard;

  const LobbyGameScreen({
    super.key,
    required this.stateService,
    required this.onBackToDashboard,
  });

  @override
  State<LobbyGameScreen> createState() => _LobbyGameScreenState();
}

class _LobbyGameScreenState extends State<LobbyGameScreen> {
  late PenalexFlameGame _game;

  @override
  void initState() {
    super.initState();
    _game = PenalexFlameGame(
      initialGameState: widget.stateService.state,
      onLevelTapped: _handleLevelTapped,
    );

    widget.stateService.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {
        _game.updateGameState(widget.stateService.state);
      });
    }
  }

  void _handleLevelTapped(int level) {
    final state = widget.stateService.state;
    // Player can open unlocked or current level
    if (level <= state.nivelActual || state.isLevelLocked(level)) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => QuizModalDialog(
          level: level,
          stateService: widget.stateService,
          onDismissed: () {
            Navigator.of(ctx).pop();
            _game.updateGameState(widget.stateService.state);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    widget.stateService.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.stateService.state;
    final region = getRegionForLevel(state.nivelActual);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1528),
      body: Stack(
        children: [
          // 1. Motor de Videojuego Flame (Scroll Infinito & Tiles 21 Regiones)
          Positioned.fill(
            child: GameWidget(game: _game),
          ),

          // 2. Banner Superior Pergamino Colonial
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopParchmentBanner(
              state: state,
              stateService: widget.stateService,
            ),
          ),

          // 3. Botón Flotante para Regresar al Tribunal Central
          Positioned(
            bottom: 24,
            left: 20,
            child: FloatingActionButton(
              heroTag: 'btn_back_dashboard',
              backgroundColor: const Color(0xFF003893),
              foregroundColor: const Color(0xFFFFD700),
              elevation: 8,
              shape: const CircleBorder(
                side: BorderSide(color: Color(0xFFD4AF37), width: 2),
              ),
              onPressed: widget.onBackToDashboard,
              child: const Icon(Icons.arrow_back_rounded, size: 28),
            ),
          ),

          // 4. Indicador de Monumentos de la Región Actual
          Positioned(
            bottom: 24,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1528).withOpacity(0.85),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_city_rounded, color: Color(0xFFFFD700), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    region.capitalOEstado,
                    style: const TextStyle(
                      color: Color(0xFFF8F6F0),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

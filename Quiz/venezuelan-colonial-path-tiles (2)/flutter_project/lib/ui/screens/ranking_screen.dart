import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';
import '../../services/game_state_service.dart';

class RankingScreen extends StatelessWidget {
  final GameStateService stateService;
  final VoidCallback onBack;

  const RankingScreen({
    super.key,
    required this.stateService,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final state = stateService.state;
    final currentRank = getRankForLevel(state.nivelActual);

    // Lista de Magistrados y Juristas Destacados
    final leaderboard = [
      {"pos": 1, "nombre": "Dra. Carmen Mendoza (TSJ)", "rango": "Magistrada Presidente", "xp": 45800, "region": "Caracas"},
      {"pos": 2, "nombre": "Dr. Andrés E. Blanco", "rango": "Magistrado Sala Penal", "xp": 42100, "region": "Zulia"},
      {"pos": 3, "nombre": "Dra. Luisa C. Amengual", "rango": "Presidenta Circuito Penal", "xp": 38900, "region": "Carabobo"},
      {"pos": 4, "nombre": "TÚ (Jurista Activo)", "rango": currentRank.titulo, "xp": state.xp, "region": "Circuito Actual", "isPlayer": true},
      {"pos": 5, "nombre": "Dr. Fernando Peñalver", "rango": "Juez Superior de Apelaciones", "xp": 24500, "region": "Mérida"},
      {"pos": 6, "nombre": "Dra. Teresa de la Parra", "rango": "Juez de Juicio Oral", "xp": 18200, "region": "Lara"},
      {"pos": 7, "nombre": "Dr. Fermín Toro", "rango": "Juez de Control", "xp": 12400, "region": "Aragua"},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B1528),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003893),
        title: const Text(
          "TABLA DE MAGISTRATURA",
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 16,
            fontWeight: FontWeight.w900,
            fontFamily: 'serif',
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFFFD700)),
          onPressed: onBack,
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Divider(color: Color(0xFFD4AF37), height: 2, thickness: 2),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leaderboard.length,
        itemBuilder: (context, index) {
          final item = leaderboard[index];
          final isPlayer = item["isPlayer"] == true;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isPlayer ? const Color(0xFF1B4332) : const Color(0xFF14213D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPlayer ? const Color(0xFF52B788) : const Color(0xFFD4AF37).withOpacity(0.5),
                width: isPlayer ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Posición
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: index == 0
                        ? const Color(0xFFFFD700)
                        : (index == 1 ? const Color(0xFFCFD8DC) : (index == 2 ? const Color(0xFFCD7F32) : const Color(0xFF003893))),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "${item['pos']}",
                      style: TextStyle(
                        color: index < 3 ? const Color(0xFF003893) : const Color(0xFFFFD700),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Datos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['nombre'] as String,
                        style: TextStyle(
                          color: isPlayer ? const Color(0xFFD8F3DC) : const Color(0xFFF8F6F0),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${item['rango']} • ${item['region']}",
                        style: TextStyle(
                          color: isPlayer ? const Color(0xFF95D5B2) : const Color(0xFFD4AF37),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Puntos XP
                Text(
                  "${item['xp']} XP",
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

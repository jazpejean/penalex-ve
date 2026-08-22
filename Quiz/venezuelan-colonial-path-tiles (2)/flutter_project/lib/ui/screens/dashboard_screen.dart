import 'package:flutter/material.dart';
import '../../services/game_state_service.dart';
import '../../services/sound_service.dart';

class DashboardScreen extends StatelessWidget {
  final GameStateService stateService;
  final VoidCallback onPlayClick;
  final VoidCallback onRankingClick;

  const DashboardScreen({
    super.key,
    required this.stateService,
    required this.onPlayClick,
    required this.onRankingClick,
  });

  @override
  Widget build(BuildContext context) {
    final state = stateService.state;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF070C18),
              Color(0xFF0B1528),
              Color(0xFF001F54),
              Color(0xFF070C18),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Escudo / Emblema Colonial del Mazo y Balanza de la Justicia
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFF003893),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD4AF37), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withOpacity(0.35),
                          blurRadius: 25,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.gavel_rounded,
                        color: Color(0xFFFFD700),
                        size: 58,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Título Institucional
                  const Text(
                    "PENALEX VE",
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'serif',
                      letterSpacing: 4.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14213D),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF8C6239), width: 1),
                    ),
                    child: const Text(
                      "QUIZ JURÍDICO DE DERECHO PENAL VENEZOLANO",
                      textAlign: TextAlign.Center,
                      style: TextStyle(
                        color: Color(0xFFF8F6F0),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 3. Botón Principal: JUGAR (INICIAR JUICIO ORAL)
                  _ColonialButton(
                    title: "INICIAR JUICIO ORAL",
                    subtitle: "NIVEL ${state.nivelActual} • 3000 CASOS",
                    icon: Icons.play_arrow_rounded,
                    isPrimary: true,
                    onPressed: () {
                      SoundService().playGavel();
                      onPlayClick();
                    },
                  ),
                  const SizedBox(height: 18),

                  // 4. Botón: TABLA DE MAGISTRATURA (RANKING)
                  _ColonialButton(
                    title: "TABLA DE MAGISTRATURA",
                    subtitle: "CLASIFICACIÓN NACIONAL",
                    icon: Icons.account_balance_rounded,
                    isPrimary: false,
                    onPressed: () {
                      SoundService().playGavel();
                      onRankingClick();
                    },
                  ),
                  const SizedBox(height: 40),

                  // 5. Pie de Página Institucional
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.menu_book_rounded, color: Color(0xFFD4AF37), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "CÓDIGO PENAL DE VENEZUELA • 21 REGIONES",
                        style: TextStyle(
                          color: const Color(0xFFF8F6F0).withOpacity(0.7),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColonialButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _ColonialButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: isPrimary
              ? [const Color(0xFFFFD54F), const Color(0xFFD4AF37), const Color(0xFFAA7C11)]
              : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isPrimary ? Colors.white : const Color(0xFFD4AF37),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isPrimary ? const Color(0xFFD4AF37).withOpacity(0.4) : Colors.black.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isPrimary ? const Color(0xFF003893) : const Color(0xFFD4AF37),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary ? const Color(0xFFFFD700) : const Color(0xFF003893),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isPrimary ? const Color(0xFF003893) : const Color(0xFFFFD700),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'serif',
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isPrimary ? const Color(0xFF5D4037) : const Color(0xFFF8F6F0).withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isPrimary ? const Color(0xFF003893) : const Color(0xFFD4AF37),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

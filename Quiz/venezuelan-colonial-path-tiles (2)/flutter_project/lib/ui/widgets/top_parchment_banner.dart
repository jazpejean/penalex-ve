import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_state_model.dart';
import '../../models/quiz_model.dart';
import '../../models/region_model.dart';
import '../../services/game_state_service.dart';

class TopParchmentBanner extends StatelessWidget {
  final GameState state;
  final GameStateService stateService;
  final VoidCallback? onRankTapped;

  const TopParchmentBanner({
    super.key,
    required this.state,
    required this.stateService,
    this.onRankTapped,
  });

  @override
  Widget build(BuildContext context) {
    final rank = getRankForLevel(state.nivelActual);
    final region = getRegionForLevel(state.nivelActual);
    final nextRankLevel = (rank.nivelRequerido + 100);
    final xpInCurrentTier = state.xp % 100;
    final regenTime = stateService.getTimeUntilNextRegen();

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F6F0), // Blanco roto colonial
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD4AF37), width: 2.5), // Dorado
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // 1. Avatar Colonial Institucional (Mazo / Toga de Magistrado)
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF003893), // Azul noche
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.gavel_rounded,
                      color: Color(0xFFFFD700),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Rango Judicial y Región
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              rank.titulo.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF003893),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'serif',
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "NIVEL ${state.nivelActual}",
                              style: const TextStyle(
                                color: Color(0xFF003893),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${region.nombre} • ${state.xp} XP",
                        style: const TextStyle(
                          color: Color(0xFF5D4037),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Barra de Progreso de XP
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: xpInCurrentTier / 100.0,
                          minHeight: 5,
                          backgroundColor: const Color(0xFFD7CCC8),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Racha si activa
                if (state.racha >= 2) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB71C1C),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFD700), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, color: Color(0xFFFFD700), size: 14),
                        Text(
                          "x${state.racha}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFD7CCC8)),
            const SizedBox(height: 6),

            // 4. Los 5 Pergaminos de Apelación dibujados con Canvas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      "APELACIONES: ",
                      style: TextStyle(
                        color: Color(0xFF003893),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        final isAvailable = index < state.apelaciones;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.5),
                          child: CustomPaint(
                            size: const Size(16, 22),
                            painter: ParchmentScrollPainter(isAvailable: isAvailable),
                          ),
                        );
                      }),
                    ),
                  ],
                ),

                // Tiempo de Regeneración
                if (regenTime != null)
                  Text(
                    "+1 en ${regenTime.inMinutes}:${(regenTime.inSeconds % 60).toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      color: Color(0xFF8B261D),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  const Text(
                    "MÁXIMO (5/5)",
                    style: TextStyle(
                      color: Color(0xFF1B5E20),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter para dibujar los pergaminos coloniales
class ParchmentScrollPainter extends CustomPainter {
  final bool isAvailable;

  const ParchmentScrollPainter({required this.isAvailable});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = isAvailable ? const Color(0xFFFFD54F) : const Color(0xFFB0BEC5)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = isAvailable ? const Color(0xFF8C6239) : const Color(0xFF546E7A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rollPaint = Paint()
      ..color = isAvailable ? const Color(0xFFFFA000) : const Color(0xFF78909C)
      ..style = PaintingStyle.fill;

    // Cuerpo del pergamino
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 3, size.width - 4, size.height - 6),
      const Radius.circular(2),
    );
    canvas.drawRRect(bodyRect, bodyPaint);
    canvas.drawRRect(bodyRect, outlinePaint);

    // Rollos superior e inferior
    canvas.drawOval(Rect.fromLTWH(0, 0, size.width, 4.5), rollPaint);
    canvas.drawOval(Rect.fromLTWH(0, 0, size.width, 4.5), outlinePaint);

    canvas.drawOval(Rect.fromLTWH(0, size.height - 4.5, size.width, 4.5), rollPaint);
    canvas.drawOval(Rect.fromLTWH(0, size.height - 4.5, size.width, 4.5), outlinePaint);

    // Líneas de texto manuscrito
    if (isAvailable) {
      final inkPaint = Paint()
        ..color = const Color(0xFF5D4037).withOpacity(0.6)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(5, size.height * 0.4), Offset(size.width - 5, size.height * 0.4), inkPaint);
      canvas.drawLine(Offset(5, size.height * 0.6), Offset(size.width - 5, size.height * 0.6), inkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ParchmentScrollPainter oldDelegate) {
    return oldDelegate.isAvailable != isAvailable;
  }
}

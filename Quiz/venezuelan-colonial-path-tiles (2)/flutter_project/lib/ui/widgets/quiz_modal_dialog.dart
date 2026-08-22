import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';
import '../../services/game_state_service.dart';
import '../../services/procedural_penal_law_service.dart';
import '../../services/sound_service.dart';

class QuizModalDialog extends StatefulWidget {
  final int level;
  final GameStateService stateService;
  final VoidCallback onDismissed;

  const QuizModalDialog({
    super.key,
    required this.level,
    required this.stateService,
    required this.onDismissed,
  });

  @override
  State<QuizModalDialog> createState() => _QuizModalDialogState();
}

class _QuizModalDialogState extends State<QuizModalDialog> {
  late QuizQuestion _question;
  late DateTime _startTime;
  int? _selectedOptionIndex;
  bool _answered = false;
  bool _isCorrect = false;
  bool _isAntiCheatPenalty = false;
  int _earnedXp = 0;

  @override
  void initState() {
    super.initState();
    // Generar pregunta procedural aleatoria (Anti-trampa: 5 variantes)
    _question = ProceduralPenalLawService.getQuestionForLevel(widget.level);
    _startTime = DateTime.now();
  }

  Future<void> _handleOptionSelected(int index) async {
    if (_answered) return;

    final elapsedSeconds = DateTime.now().difference(_startTime).inMilliseconds / 1000.0;

    setState(() {
      _selectedOptionIndex = index;
      _answered = true;
    });

    // 1. Anti-Trampa: Respuesta en menos de 3.0 segundos
    if (elapsedSeconds < 3.0) {
      _isAntiCheatPenalty = true;
      _isCorrect = false;
      await SoundService().playError();
      await widget.stateService.onAnswerFailed(widget.level, isAntiCheat: true);
      return;
    }

    // 2. Verificación de Acierto o Fallo
    if (index == _question.respuestaCorrectaIndex) {
      _isCorrect = true;
      await SoundService().playCorrect();
      _earnedXp = await widget.stateService.onAnswerCorrect(widget.level);
    } else {
      _isCorrect = false;
      await SoundService().playError();
      await widget.stateService.onAnswerFailed(widget.level);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.stateService.state;
    final isLocked = state.isLevelLocked(widget.level);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1528), // Azul noche colonial
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD4AF37), width: 3), // Borde oro
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.7),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado con Mazo y Nivel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_rounded, color: Color(0xFFFFD700), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        "CASO PENAL • NIVEL ${widget.level}",
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'serif',
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFD4AF37)),
                    onPressed: widget.onDismissed,
                  ),
                ],
              ),
              const Divider(color: Color(0xFF8C6239), thickness: 1.5),
              const SizedBox(height: 10),

              // Caso Bloqueado por 3 fallos
              if (isLocked) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF780000).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFC1121F), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.lock_rounded, color: Color(0xFFFFD700), size: 48),
                      const SizedBox(height: 10),
                      const Text(
                        "EXPEDIENTE BLOQUEADO",
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Has acumulado 3 fallos en este caso. Para desbloquear el expediente y volver a litigar, debes consignar 1 apelación extraordinaria.",
                        textAlign: TextAlign.Center,
                        style: TextStyle(color: Color(0xFFF8F6F0), fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: const Color(0xFF003893),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: state.apelaciones >= 1
                            ? () async {
                                await widget.stateService.unlockLevel(widget.level);
                                setState(() {
                                  _question = ProceduralPenalLawService.getQuestionForLevel(widget.level);
                                  _startTime = DateTime.now();
                                  _answered = false;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.key),
                        label: Text(
                          state.apelaciones >= 1 ? "DESBLOQUEAR (1 APELACIÓN)" : "SIN APELACIONES DISPONIBLES",
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (!_answered) ...[
                // Planteamiento del Caso Forense
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF475569)),
                  ),
                  child: Text(
                    _question.caso,
                    style: const TextStyle(
                      color: Color(0xFFF8F6F0),
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Lista de Opciones
                ...List.generate(_question.opciones.length, (index) {
                  final opcion = _question.opciones[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => _handleOptionSelected(index),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14213D),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.7), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: const Color(0xFF003893),
                              child: Text(
                                String.fromCharCode(65 + index),
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                opcion,
                                style: const TextStyle(
                                  color: Color(0xFFF8F6F0),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ] else ...[
                // Modal de Resultado (Acierto / Fallo / Anti-trampa)
                if (_isAntiCheatPenalty) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF780000).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC1121F), width: 2),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.timer_off_rounded, color: Color(0xFFFFD700), size: 40),
                        SizedBox(height: 8),
                        Text(
                          "ADVERTENCIA DE CELERIDAD INDEBIDA",
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'serif',
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Respuesta emitida en menos de 3.0 segundos sin análisis del tipo penal. Se ha computado como fallo y se descontó 1 apelación sin fundamentación.",
                          textAlign: TextAlign.Center,
                          style: TextStyle(color: Color(0xFFF8F6F0), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ] else if (_isCorrect) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4332).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2D6A4F), width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF52B788), size: 28),
                            const SizedBox(width: 10),
                            Text(
                              "¡CALIFICACIÓN JURÍDICA CORRECTA! (+$_earnedXp XP)",
                              style: const TextStyle(
                                color: Color(0xFFD8F3DC),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'serif',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _question.fundamentacionLegal,
                          style: const TextStyle(
                            color: Color(0xFFF8F6F0),
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF780000).withOpacity(0.35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC1121F), width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.cancel_rounded, color: Color(0xFFE63946), size: 28),
                            SizedBox(width: 10),
                            Text(
                              "CALIFICACIÓN ERRÓNEA (-1 APELACIÓN)",
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'serif',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _question.pistaVaga,
                          style: const TextStyle(
                            color: Color(0xFFF8F6F0),
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF003893),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedCornerShape(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: widget.onDismissed,
                  child: const Text(
                    "CONTINUAR EN EL MAPA",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

extension on ElevatedButton {
  static ButtonStyle styleFromCustom({required Color backgroundColor, required Color foregroundColor, required EdgeInsets padding}) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: padding,
    );
  }
}

class RoundedCornerShape extends RoundedRectangleBorder {
  const RoundedCornerShape({required BorderRadius borderRadius}) : super(borderRadius: borderRadius);
}

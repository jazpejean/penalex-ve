import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/liquid_gold_background.dart';
import '../widgets/quiz_icon.dart';

/// Paleta oficial del quiz (navy + oro).
const _card = Color(0xFF141B2E);
const _oro = Color(0xFFC5A059);
const _oroBrillante = Color(0xFFE9C86A);
const _esmeralda = Color(0xFF10B981);

/// Resumen de la sesión al agotar las apelaciones: anillo de progreso animado,
/// tarjetas de estadísticas y opciones de compartir / volver al lobby.
class QuizResumenScreen extends StatefulWidget {
  final int casosResueltos;
  final int aciertos;
  final int fallos;
  final int xpGanado;
  final int rachaMaxima;
  final int tiempoTotal;

  const QuizResumenScreen({
    super.key,
    required this.casosResueltos,
    required this.aciertos,
    required this.fallos,
    required this.xpGanado,
    required this.rachaMaxima,
    required this.tiempoTotal,
  });

  @override
  State<QuizResumenScreen> createState() => _QuizResumenScreenState();
}

class _QuizResumenScreenState extends State<QuizResumenScreen> {
  final ScreenshotController _shot = ScreenshotController();
  bool _compartiendo = false;

  double get _pctAciertos => widget.casosResueltos == 0
      ? 0
      : (widget.aciertos / widget.casosResueltos).clamp(0.0, 1.0);

  String get _tiempoTexto {
    final s = widget.tiempoTotal;
    final m = s ~/ 60;
    final seg = s % 60;
    return '${m}m ${seg.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: LiquidGoldBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Screenshot(
                controller: _shot,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _card.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: _oro.withValues(alpha: 0.4), width: 1.2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SESIÓN COMPLETADA',
                        style: GoogleFonts.cinzel(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                          color: _oroBrillante,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildAnillo(),
                      const SizedBox(height: 24),
                      _buildStats(),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _oroBrillante,
                                side: BorderSide(
                                    color: _oro.withValues(alpha: 0.6)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('VOLVER AL LOBBY'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _compartiendo ? null : _compartir,
                              icon: const QuizIcon('share_ornate', size: 18),
                              label: const Text('COMPARTIR'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _oro,
                                foregroundColor: const Color(0xFF0F172A),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
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
        ),
      ),
    );
  }

  /// Anillo grande con el porcentaje de aciertos animado (0 → pct).
  Widget _buildAnillo() {
    final pct = _pctAciertos;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: pct),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: v,
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(_oro),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(v * 100).round()}%',
                  style: GoogleFonts.cinzel(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'aciertos',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Column(
      children: [
        Row(
          children: [
            _stat('Casos', '${widget.casosResueltos}', _oroBrillante),
            _stat('Aciertos', '${widget.aciertos}', _esmeralda),
            _stat('Fallos', '${widget.fallos}', const Color(0xFFB91C1C)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _stat('XP ganado', '+${widget.xpGanado}', _oro),
            _stat('Racha máx', 'x${widget.rachaMaxima}', const Color(0xFFF59E0B)),
            _stat('Tiempo', _tiempoTexto, Colors.white70),
          ],
        ),
      ],
    );
  }

  Widget _stat(String label, String valor, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.white60, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Captura el resumen (RepaintBoundary del screenshot) y lo comparte.
  Future<void> _compartir() async {
    try {
      setState(() => _compartiendo = true);
      HapticFeedback.mediumImpact();
      final img = await _shot.capture(pixelRatio: 2.0);
      if (img == null) throw Exception('captura vacía');
      final dir = await getTemporaryDirectory();
      final ruta = '${dir.path}/quiz_resumen.png';
      await File(ruta).writeAsBytes(img);
      await Share.shareXFiles(
        [XFile(ruta)],
        text: 'Mi sesión de Penalex Quiz: ${widget.aciertos}/${widget.casosResueltos} aciertos · +${widget.xpGanado} XP',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo compartir: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _compartiendo = false);
    }
  }
}
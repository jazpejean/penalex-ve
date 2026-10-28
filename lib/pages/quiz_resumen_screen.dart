import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/quiz_icon.dart';

/// Paleta del quiz adaptada del kit "Queezy" (fondo claro, violeta/lavanda/
/// rosa/menta) con acentos navy/oro de Penalex en premios y medallas.
const _fondoKit = Color(0xFFF7F6FF); // fondo del kit
const _primario = Color(0xFF6A5AE0); // violeta primario del kit
const _navyTexto = Color(0xFF0F172A); // texto fuerte = navy de la app
const _grisClaro = Color(0xFF858494); // grey 2 del kit
const _bordeKit = Color(0xFFEFEEFC); // grey 5 del kit (bordes de tarjetas)
const _blanco = Colors.white;
const _oro = Color(0xFFC5A059); // acento app: premios/medallas
const _acierto = Color(0xFF10B981);
const _fallo = Color(0xFFB91C1C);
const _rosaPink = Color(0xFFFF8FA2); // pink del kit

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
      backgroundColor: _fondoKit,
      body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Screenshot(
                controller: _shot,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _blanco,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _bordeKit, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _primario.withValues(alpha: 0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SESIÓN COMPLETADA',
                        style: GoogleFonts.rubik(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                          color: _primario,
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
                                foregroundColor: _navyTexto,
                                side: const BorderSide(
                                    color: _bordeKit, width: 2),
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
                                backgroundColor: _primario,
                                foregroundColor: _blanco,
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
              backgroundColor: _bordeKit,
              valueColor: const AlwaysStoppedAnimation(_primario),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(v * 100).round()}%',
                  style: GoogleFonts.rubik(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: _navyTexto,
                  ),
                ),
                Text(
                  'aciertos',
                  style: GoogleFonts.rubik(
                    fontSize: 13,
                    color: _grisClaro,
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
            _stat('Casos', '${widget.casosResueltos}', _primario),
            _stat('Aciertos', '${widget.aciertos}', _acierto),
            _stat('Fallos', '${widget.fallos}', _fallo),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _stat('XP ganado', '+${widget.xpGanado}', _oro),
            _stat('Racha máx', 'x${widget.rachaMaxima}', _rosaPink),
            _stat('Tiempo', _tiempoTexto, _grisClaro),
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
          color: _fondoKit,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: _grisClaro, fontSize: 11),
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
import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/caso_quiz.dart';
import '../services/quiz_certificate_service.dart';
import '../services/quiz_rules.dart';
import '../services/quiz_ranking_service.dart';
import '../services/quiz_storage_service.dart';
import '../utils/quiz_seed.dart';

const _navy = Color(0xFF0F172A);
const _goldBright = Color(0xFFE9C86A);
const _gold = Color(0xFFC5A059);
const _bg = Color(0xFF1E2536);

class QuizGameScreen extends StatefulWidget {
  const QuizGameScreen({super.key});

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen> {
  final QuizStorageService _service = QuizStorageService();
  final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  Map<String, dynamic> _progreso = {};
  CasoQuiz? _caso;
  bool _cargando = true;
  bool _respondida = false;
  bool _correcta = false;
  int? _seleccionada;
  int _racha = 0;
  int _apelaciones = 5;
  int _xp = 0;
  int _nivelActual = 1;

  int _tiempoRestante = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    await sembrarCasosIniciales();
    final p = await _service.cargarProgreso();
    final regen = _service.regenerarApelaciones(p);
    await _service.guardarProgreso(regen);
    if (!mounted) return;
    setState(() {
      _progreso = regen;
      _xp = (regen['xp'] as num?)?.toInt() ?? 0;
      _racha = (regen['racha_actual'] as num?)?.toInt() ?? 0;
      _apelaciones = (regen['apelaciones'] as num?)?.toInt() ?? 5;
      _nivelActual = (regen['nivel_actual'] as num?)?.toInt() ?? 1;
    });
    await _cargarCaso();
  }

  Future<void> _cargarCaso() async {
    setState(() {
      _cargando = true;
      _respondida = false;
      _seleccionada = null;
      _correcta = false;
      _tiempoRestante = 30;
    });
    _timer?.cancel();

    final excluir = _service.idsExcluidos(_progreso);
    final caso = await _service.obtenerCaso(_nivelActual, excluirIds: excluir);

    if (!mounted) return;
    setState(() {
      _caso = caso;
      _cargando = false;
    });
    if (_apelaciones > 0) _iniciarTimer();
  }

  void _iniciarTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_respondida) {
        t.cancel();
        return;
      }
      setState(() => _tiempoRestante--);
      if (_tiempoRestante <= 0) {
        t.cancel();
        _resolver(tiempoAgotado: true);
      }
    });
  }

  Future<void> _resolver({bool tiempoAgotado = false, int? indice}) async {
    if (_caso == null || _respondida) return;
    final correcta = tiempoAgotado ? false : indice == _caso!.respuestaCorrecta;

    setState(() {
      _respondida = true;
      _seleccionada = tiempoAgotado ? null : indice;
      _correcta = correcta;
    });
    _timer?.cancel();

    var nuevo = Map<String, dynamic>.from(_progreso);
    final rangoAnterior = QuizRules.rangoParaXp(_xp);
    int xpGanado = 0;

    if (correcta) {
      xpGanado = QuizRules.xpPorAcierto(
        dificultad: _caso!.dificultad,
        racha: _racha,
      );
      _racha++;
      _xp += xpGanado;
      nuevo = _service.registrarAcierto(nuevo, _caso!.id);
      _confetti.play();
      await Future.delayed(const Duration(milliseconds: 350));
    } else {
      _apelaciones = (_apelaciones - 1).clamp(0, 999);
      _racha = 0;
      nuevo = _service.registrarFallo(nuevo, _caso!.id);
    }

    nuevo['xp'] = _xp;
    nuevo['racha_actual'] = _racha;
    if (_racha > (nuevo['racha_maxima'] ?? 0)) nuevo['racha_maxima'] = _racha;
    nuevo['apelaciones'] = _apelaciones;
    nuevo['nivel_actual'] = _nivelActual;
    _progreso = nuevo;
    await _service.guardarProgreso(nuevo);
    await QuizRankingService.actualizar(
      xp: _xp,
      nivelActual: _nivelActual,
      rango: QuizRules.rangoParaXp(_xp),
    );

    if (!mounted) return;
    setState(() {});
    if (correcta) {
      final rangoNuevo = QuizRules.rangoParaXp(_xp);
      if (rangoNuevo != rangoAnterior) {
        final hito = QuizRules.certificadoActual(_xp);
        if (hito != null && hito.nombre == rangoNuevo) {
          _mostrarLogro(rangoNuevo, xpGanado);
        } else {
          _mostrarAscenso(rangoNuevo, xpGanado);
        }
      }
    }
  }

  void _mostrarAscenso(String rango, int xpGanado) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('⚖️ ¡Ascenso!', style: TextStyle(color: _gold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.military_tech, size: 64, color: _gold),
            const SizedBox(height: 16),
            Text(
              rango,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+$xpGanado XP',
              style: const TextStyle(color: Colors.greenAccent, fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar', style: TextStyle(color: _gold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                _buildXpBar(),
                Expanded(child: _buildContenido()),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 24,
                gravity: 0.2,
                colors: const [Colors.amber, Colors.greenAccent, Colors.white],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RANGO',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
                Text(
                  QuizRules.rangoParaXp(_xp),
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _stat(Icons.local_fire_department, '$_racha', Colors.orange),
          const SizedBox(width: 12),
          _stat(Icons.balance, '$_apelaciones', _gold),
          const SizedBox(width: 12),
          _stat(Icons.star, '$_xp XP', Colors.amber),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String valor, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(valor,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ],
    );
  }

  Widget _buildXpBar() {
    final sig = QuizRules.siguienteRango(_xp);
    final progreso = QuizRules.progresoRango(_xp);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(_gold),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sig != null
                ? 'Siguiente: ${sig.nombre} (${sig.xp} XP)'
                : 'Rango máximo alcanzado',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: _gold));
    }
    if (_caso == null) {
      return _sinCasos();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTimer(),
          const SizedBox(height: 12),
          _buildPreguntaCard(),
          const SizedBox(height: 16),
          ..._caso!.opciones.asMap().entries.map((e) => _buildOpcion(e.key)),
          if (_respondida) ...[
            const SizedBox(height: 16),
            _buildFundamentacion(),
          ],
          if (_respondida) ...[
            const SizedBox(height: 20),
            _buildSiguiente(),
          ],
        ],
      ),
    );
  }

  Future<void> _mostrarLogro(String rango, int xpGanado) async {
    _confetti.play();
    String? ruta;
    try {
      final user = FirebaseAuth.instance.currentUser;
      final nombre = (user?.displayName?.trim().isNotEmpty == true)
          ? user!.displayName!
          : (user?.email?.split('@').first ?? 'Abogado Penalex');
      final uid = user?.uid ?? 'anon';
      final codigo = QuizCertificateService.generarCodigo(uid, _xp);
      ruta = await QuizCertificateService.generarCertificado(
        nombre: nombre,
        rango: rango,
        xp: _xp,
        codigo: codigo,
      );
      _progreso = _service.registrarLogro(_progreso, {
        'rango': rango,
        'fecha': DateTime.now().toIso8601String(),
        'codigo': codigo,
      });
      await _service.guardarProgreso(_progreso);
    } catch (e) {
      debugPrint('Error generando certificado de logro: $e');
    }
    if (!mounted) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 500),
      transitionBuilder: (context, anim, sec, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (context, _, __) => Dialog(
        backgroundColor: _navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.military_tech, size: 72, color: _goldBright),
              const SizedBox(height: 12),
              const Text(
                '¡LOGRO DESBLOQUEADO!',
                style: TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                rango,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '+$xpGanado XP · $_xp XP totales',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'Certificado generado y guardado en Mis Logros',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Continuar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        if (ruta != null) {
                          await Share.shareXFiles([XFile(ruta)],
                              text: 'Certificado Penalex: $rango');
                        }
                      },
                      icon: const Icon(Icons.ios_share, size: 18),
                      label: const Text('Compartir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: _navy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimer() {
    return Center(
      child: SizedBox(
        width: 54,
        height: 54,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: _tiempoRestante / 30,
              strokeWidth: 4,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(
                  _tiempoRestante <= 8 ? Colors.redAccent : _gold),
            ),
            Text('$_tiempoRestante',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreguntaCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _caso!.delitoBase,
              style: const TextStyle(color: _gold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _caso!.contextoNarrativo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpcion(int idx) {
    final esCorrecta = _respondida && idx == _caso!.respuestaCorrecta;
    final esSeleccionada = _respondida && idx == _seleccionada;

    Color borde = Colors.white12;
    Color fondo = Colors.white.withValues(alpha: 0.04);
    if (_respondida) {
      if (esCorrecta) {
        borde = Colors.greenAccent;
        fondo = Colors.green.withValues(alpha: 0.15);
      } else if (esSeleccionada) {
        borde = Colors.redAccent;
        fondo = Colors.red.withValues(alpha: 0.15);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borde, width: 1.4),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _respondida ? null : () => _resolver(indice: idx),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: _respondida && esCorrecta
                        ? Colors.greenAccent
                        : _gold.withValues(alpha: 0.2),
                    child: Text(
                      String.fromCharCode(65 + idx),
                      style: TextStyle(
                        color:
                            _respondida && esCorrecta ? Colors.black : _gold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _caso!.opciones[idx],
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  if (_respondida && esCorrecta)
                    const Icon(Icons.check_circle, color: Colors.greenAccent)
                  else if (_respondida && esSeleccionada)
                    const Icon(Icons.cancel, color: Colors.redAccent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFundamentacion() {
    return AnimatedOpacity(
      opacity: _respondida ? 1 : 0,
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.gavel, color: Colors.greenAccent, size: 18),
                SizedBox(width: 8),
                Text('FUNDAMENTACIÓN',
                    style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            if (_caso!.fundamentacion.isNotEmpty)
              Text(_caso!.fundamentacion,
                  style: const TextStyle(color: Colors.white, height: 1.5))
            else
              Text(
                'Respuesta correcta: ${_caso!.opciones[_caso!.respuestaCorrecta]}',
                style: const TextStyle(
                  color: Colors.white,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (_caso!.articulos.isNotEmpty) ...[
              const SizedBox(height: 10),
              ..._caso!.articulos.map((a) => Text('📜 $a',
                  style: const TextStyle(
                      color: Color(0xFFBFD7EA), fontSize: 13))),
            ],
            if (_caso!.sentencias.isNotEmpty) ...[
              const SizedBox(height: 10),
              ..._caso!.sentencias.map((s) => Text('⚖️ $s',
                  style: const TextStyle(
                      color: Color(0xFFBFD7EA), fontSize: 13))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSiguiente() {
    final restante = _apelaciones <= 0
        ? QuizStorageService.tiempoSiguienteApelacion(_progreso)
        : null;
    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _gold,
            foregroundColor: Colors.black,
            disabledBackgroundColor: Colors.white12,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _apelaciones <= 0 ? null : _cargarCaso,
          child: Text(
            _apelaciones <= 0 ? 'Sin apelaciones' : 'SIGUIENTE',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        if (restante != null) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, color: _goldBright, size: 18),
              const SizedBox(width: 6),
              Text(
                'Próxima apelación en ${restante.inMinutes}m '
                '${(restante.inSeconds % 60).toString().padLeft(2, '0')}s',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _sinCasos() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text('No hay casos disponibles aún',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'Se están generando preguntas nuevas.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import '../services/haptics_service.dart';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/game.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../game/quiz_effects_game.dart';
import '../models/caso_quiz.dart';
import '../utils/transiciones.dart';
import '../widgets/racha_overlay.dart';
import 'quiz_resumen_screen.dart';
import '../services/misiones_diarias_service.dart';
import '../services/quiz_certificate_service.dart';
import '../services/quiz_rules.dart';
import '../services/quiz_ranking_service.dart';
import '../services/sfx_service.dart';
import '../services/quiz_storage_service.dart';
import '../utils/quiz_seed.dart';
import '../widgets/quiz_icon.dart';
import '../widgets/quiz_pulso_widget.dart';

/// Paleta oficial del quiz: navy + oro (alineada al resto de la app).
/// Paleta del quiz adaptada del kit "Queezy" (fondo claro, violeta/lavanda/
/// rosa/menta) con acentos navy/oro de Penalex en premios y medallas.
const _fondoKit = Color(0xFFF7F6FF); // fondo del kit
const _primario = Color(0xFF6A5AE0); // violeta primario del kit
const _secundario = Color(0xFF9087E5); // violeta claro (featured)
const _lavanda = Color(0xFFC4D0FB); // acento lavanda del kit
const _rosaPink = Color(0xFFFF8FA2); // pink del kit (warning/timer)
const _menta = Color(0xFFC9F2E9); // acento menta del kit (éxito suave)
const _navyTexto = Color(0xFF0F172A); // texto fuerte = navy de la app
const _grisClaro = Color(0xFF858494); // grey 2 del kit
const _bordeKit = Color(0xFFEFEEFC); // grey 5 del kit (bordes de tarjetas)
const _blanco = Colors.white;
const _oro = Color(0xFFC5A059); // acento app: premios/medallas
const _oroBrillante = Color(0xFFE9C86A);
const _acierto = Color(0xFF10B981);
const _fallo = Color(0xFFB91C1C);

class QuizGameScreen extends StatefulWidget {
  const QuizGameScreen({super.key});

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen>
    with TickerProviderStateMixin {
  final QuizStorageService _service = QuizStorageService();
  late final QuizEffectsGame _fx;
  late final AnimationController _arc;
  late final AnimationController _shake;
  late final AnimationController _latido;

  Map<String, dynamic> _progreso = {};
  CasoQuiz? _caso;
  bool _cargando = true;
  bool _respondida = false;
  bool _revelando = false;
  int? _seleccionada;
  int _racha = 0;
  int _apelaciones = 5;
  int _xp = 0;

  // Estadísticas de la sesión (para la pantalla de resumen).
  int _casosResueltos = 0;
  int _aciertosSesion = 0;
  int _fallosSesion = 0;
  int _xpSesion = 0;
  int _rachaMaxSesion = 0;
  int _tiempoTotal = 0;

  int _tiempoRestante = 30;
  Timer? _timer;

  int _xpNonce = 0;
  int _xpFlotante = 0;
  bool _destello = false;
  Timer? _destelloTimer;

  bool get _enCrisis => _tiempoRestante <= 8 && !_respondida;

  @override
  void initState() {
    super.initState();
    _fx = QuizEffectsGame();
    _arc = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _latido = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _inicializar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _destelloTimer?.cancel();
    _arc.dispose();
    _shake.dispose();
    _latido.dispose();
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
    });
    await _cargarCaso();
  }

  Future<void> _cargarCaso() async {
    setState(() {
      _cargando = true;
      _respondida = false;
      _seleccionada = null;
      _tiempoRestante = 30;
    });
    _timer?.cancel();
    _arc.stop();

    final excluir = _service.idsExcluidos(_progreso);
    final caso = await _service.obtenerCaso(excluirIds: excluir);

    if (!mounted) return;
    setState(() {
      _caso = caso;
      _cargando = false;
    });
    if (_apelaciones > 0) {
      _iniciarTimer();
      _arc.reset();
      _arc.forward();
    } else {
      _arc.value = 1;
    }
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
      _revelando = true;
    });
    _timer?.cancel();
    _arc.stop();

    // 1) Marca la opción con borde dorado pulsante + sonido + latido sutil.
    SfxService.instance.tap();
    Haptics.tap();
    _latido.forward(from: 0);

    // 2) Pausa de 400 ms (escala 1 → 1.03 → 1) antes de revelar el resultado.
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _revelando = false);

    var nuevo = Map<String, dynamic>.from(_progreso);
    final rangoAnterior = QuizRules.rangoParaXp(_xp);
    int xpGanado = 0;

    _casosResueltos++;
    _tiempoTotal += (30 - _tiempoRestante).clamp(0, 30);

    if (correcta) {
      xpGanado = QuizRules.xpPorAcierto(
        dificultad: _caso!.dificultad,
        racha: _racha,
      );
      _racha++;
      _aciertosSesion++;
      _xpSesion += xpGanado;
      if (_racha > _rachaMaxSesion) _rachaMaxSesion = _racha;
      if (_racha >= 5 && _racha % 5 == 0) {
        SfxService.instance.racha(_racha);
        _mostrarRacha(_racha);
      }
      _xp += xpGanado;
      nuevo = _service.registrarAcierto(nuevo, _caso!.id);
      // Progresión diaria: alimenta los contadores de las misiones del día.
      nuevo = MisionesDiariasService.registrarAcierto(
        nuevo,
        DateTime.now(),
        rachaActual: _racha,
        xpGanado: xpGanado,
      );

      final c = _fx.size;
      _fx.explosion(centro: Offset(c.x / 2, c.y / 2), cantidad: 80);
      _xpFlotante = xpGanado;
      _xpNonce++;
      _destello = true;
      _destelloTimer?.cancel();
      _destelloTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _destello = false);
      });
      SfxService.instance.correcta();
      Haptics.medium();
      await Future.delayed(const Duration(milliseconds: 300));
    } else {
      _apelaciones = (_apelaciones - 1).clamp(0, 999);
      _fallosSesion++;
      _racha = 0;
      nuevo = _service.registrarFallo(nuevo, _caso!.id);
      _shake.forward(from: 0);
      SfxService.instance.incorrecta();
      Haptics.heavy();
    }

    nuevo['xp'] = _xp;
    nuevo['racha_actual'] = _racha;
    if (_racha > (nuevo['racha_maxima'] ?? 0)) nuevo['racha_maxima'] = _racha;
    nuevo['apelaciones'] = _apelaciones;
    _progreso = nuevo;
    await _service.guardarProgreso(nuevo);
    await QuizRankingService.actualizar(
      xp: _xp,
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

    // Apelaciones agotadas → pantalla de resumen de la sesión.
    if (_apelaciones <= 0 && mounted) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        cortinaDorada(QuizResumenScreen(
          casosResueltos: _casosResueltos,
          aciertos: _aciertosSesion,
          fallos: _fallosSesion,
          xpGanado: _xpSesion,
          rachaMaxima: _rachaMaxSesion,
          tiempoTotal: _tiempoTotal,
        )),
      );
    }
  }

  /// Overlay "¡RACHA xN!" al cruzar múltiplos de 5, con partículas desde el
  /// centro; se desvanece solo a los 1.5 s.
  Future<void> _mostrarRacha(int racha) async {
    final c = _fx.size;
    if (c.x > 0) {
      _fx.explosion(
        centro: Offset(c.x / 2, c.y / 2),
        cantidad: 40,
        fuerza: 520,
        colores: const [
          Color(0xFFE9C86A),
          Color(0xFFC5A059),
          Color(0xFFF59E0B),
        ],
      );
    }
    if (!mounted) return;
    await showGeneralDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, anim, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (context, _, __) => RachaOverlay(
        racha: racha,
        onDone: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _mostrarAscenso(String rango, int xpGanado) {
    SfxService.instance.victoria();
    final c = _fx.size;
    _fx.explosion(centro: Offset(c.x / 2, c.y / 2), cantidad: 150, fuerza: 780);
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      transitionDuration: const Duration(milliseconds: 600),
      transitionBuilder: (context, anim, sec, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
          child: child,
        ),
      ),
      pageBuilder: (context, _, __) => _AscensoOverlay(
        rango: rango,
        xpGanado: xpGanado,
        xpTotal: _xp,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.rubikTextTheme(
            Theme.of(context).textTheme),
      ),
      child: Scaffold(
      backgroundColor: _fondoKit,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            final t = _shake.value;
            var dx = 0.0;
            var dy = 0.0;
            if (t > 0 && t < 1) {
              final amp = 16 * (1 - t);
              dx = sin(t * 26) * amp;
              dy = cos(t * 19) * amp * 0.7;
            }
            return Transform.translate(
              offset: Offset(dx, dy),
              child: child,
            );
          },
          child: Stack(
            children: [
              const Positioned.fill(child: _FondoQuiz()),
              Positioned.fill(
                child: IgnorePointer(
                  child: GameWidget(
                    game: _fx,
                                      ),
                ),
              ),
              // Destello lavanda del kit al acertar
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _destello ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const ColoredBox(color: Color(0xFFC4D0FB)),
                  ),
                ),
              ),
              // Vignette roja en modo crisis (últimos 8s)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _enCrisis ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0, -0.2),
                          radius: 1.1,
                          colors: [
                            Colors.transparent,
                            Color(0x55FF1744),
                          ],
                          stops: [0.55, 1],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  _buildTopBar(),
                  _buildXpBar(),
                  Expanded(child: _buildContenido()),
                ],
              ),
              // "+XP" que vuela al acertar
              if (_xpNonce > 0)
                Positioned(
                  top: 150,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 1000),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.5),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: child,
                        ),
                      ),
                      child: Text(
                        '+$_xpFlotante XP',
                        key: ValueKey(_xpNonce),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _oroBrillante,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: _oro.withValues(alpha: 0.45),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RANGO',
                  style: TextStyle(color: _grisClaro, fontSize: 11),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: Text(
                    QuizRules.rangoParaXp(_xp),
                    key: ValueKey(QuizRules.rangoParaXp(_xp)),
                    style: GoogleFonts.rubik(
                      color: _primario,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildRacha(),
          const SizedBox(width: 16),
          _stat(QuizIcon('scales_calc', size: 18, color: _primario), '$_apelaciones', _primario),
          const SizedBox(width: 16),
          _stat(QuizIcon('star_shield', size: 18, color: _oroBrillante), '$_xp', _oroBrillante),
        ],
      ),
    );
  }

  Widget _buildRacha() {
    final fuerte = _racha >= 5;
    final media = _racha >= 3;
    final color = fuerte ? _oroBrillante : (media ? _rosaPink : _grisClaro);
    return QuizPulso(
      maxScale: fuerte ? 1.18 : (media ? 1.08 : 1.0),
      periodo: fuerte
          ? const Duration(milliseconds: 700)
          : const Duration(milliseconds: 1000),
      child: Row(
        children: [
          QuizIcon(
            'flame_legal',
            color: color,
            size: 22,
            withGlow: media,
          ),
          const SizedBox(width: 4),
          Text(
            'x$_racha',
            style: TextStyle(
              color: _navyTexto,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(Widget icon, String valor, Color color) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 4),
        Text(
          valor,
          style: const TextStyle(
            color: _navyTexto,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildXpBar() {
    final sig = QuizRules.siguienteRango(_xp);
    final progreso = QuizRules.progresoRango(_xp);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progreso.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
                backgroundColor: _bordeKit,
                valueColor: const AlwaysStoppedAnimation(_oro),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sig != null
                ? 'Siguiente: ${sig.nombre} (${sig.xp} XP)'
                : 'Rango máximo alcanzado',
            style: const TextStyle(color: _grisClaro, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: _oro));
    }
    if (_caso == null) {
      return _sinCasos();
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      child: SingleChildScrollView(
        key: ValueKey('q_${_caso!.id}'),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTimer(),
            const SizedBox(height: 12),
            _buildPreguntaCard(),
            const SizedBox(height: 16),
            ..._caso!.opciones.asMap().entries.map(
                  (e) => _OpcionTarjeta(
                    texto: e.value,
                    indice: e.key,
                    respondida: _respondida,
                    revelando: _revelando,
                    esCorrecta: e.key == _caso!.respuestaCorrecta,
                    esSeleccionada: e.key == _seleccionada,
                    onTap:
                        _respondida ? null : () => _resolver(indice: e.key),
                  ),
                ),
            if (_respondida) ...[
              const SizedBox(height: 16),
              _buildFundamentacion(),
              const SizedBox(height: 24),
              _buildSiguiente(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimer() {
    final critico = _enCrisis;
    final color = critico ? _fallo : (_tiempoRestante <= 15 ? _rosaPink : _primario);
    return Center(
      child: AnimatedBuilder(
        animation: _arc,
        builder: (context, _) => AnimatedScale(
          scale: critico ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 350),
          child: SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _arc.value.clamp(0.0, 1.0),
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                  backgroundColor: _bordeKit,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                if (critico)
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _fallo.withValues(alpha: 0.55),
                          blurRadius: 26,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    '$_tiempoRestante',
                    key: ValueKey(_tiempoRestante),
                    style: TextStyle(
                      color: critico ? _fallo : _navyTexto,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreguntaCard() {
    // Latido sutil (escala 1 → 1.03 → 1) durante la pausa de revelación.
    return AnimatedBuilder(
      animation: _latido,
      builder: (context, child) {
        final t = _latido.value;
        return Transform.scale(scale: 1 + 0.03 * sin(t * pi), child: child);
      },
      child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _blanco,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _bordeKit, width: 2),
        boxShadow: [
          BoxShadow(
            color: _primario.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _lavanda.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _caso!.delitoBase,
              style: const TextStyle(
                color: _primario,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _caso!.contextoNarrativo,
            style: const TextStyle(
              color: _navyTexto,
              fontSize: 16.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildFundamentacion() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      child: Container(
        key: const ValueKey('fundamentacion'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _menta.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _menta, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                QuizIcon('gavel_refined', color: _primario, size: 18),
                SizedBox(width: 8),
                Text(
                  'FUNDAMENTACIÓN',
                  style: TextStyle(
                    color: _primario,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_caso!.fundamentacion.isNotEmpty)
              Text(
                _caso!.fundamentacion,
                style: const TextStyle(color: _navyTexto, height: 1.5),
              )
            else
              Text(
                'Respuesta correcta: ${_caso!.opciones[_caso!.respuestaCorrecta]}',
                style: const TextStyle(
                  color: _navyTexto,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (_caso!.articulos.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._caso!.articulos.map((a) => Text(
                    '$a',
                    style: const TextStyle(
                      color: _primario,
                      fontSize: 13,
                    ),
                  )),
            ],
            if (_caso!.sentencias.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._caso!.sentencias.map((s) => Text(
                    '$s',
                    style: const TextStyle(
                      color: _primario,
                      fontSize: 13,
                    ),
                  )),
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
    final habilitado = _apelaciones > 0;

    final boton = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [_primario, _secundario],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primario.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: habilitado ? _cargarCaso : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              habilitado ? 'SIGUIENTE CASO' : 'SIN APELACIONES',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _blanco,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );

    return Column(
      children: [
        QuizPulso(
          maxScale: habilitado ? 1.04 : 1.0,
          child: habilitado ? boton : Opacity(opacity: 0.45, child: boton),
        ),
        if (restante != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const QuizIcon('hourglass_gold', size: 18, color: _primario),
              const SizedBox(width: 8),
              Text(
                'Próxima apelación en ${restante.inMinutes}m '
                '${(restante.inSeconds % 60).toString().padLeft(2, '0')}s',
                style: const TextStyle(color: _grisClaro, fontSize: 13),
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
            const QuizIcon('scroll_seal', size: 64, color: _lavanda),
            const SizedBox(height: 16),
            const Text('No hay casos disponibles aún',
                style: TextStyle(color: _navyTexto, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'Se están generando preguntas nuevas.',
              style: TextStyle(color: _grisClaro, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarLogro(String rango, int xpGanado) async {
    SfxService.instance.victoria();
    final c = _fx.size;
    _fx.explosion(centro: Offset(c.x / 2, c.y / 2), cantidad: 150, fuerza: 820);
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
        backgroundColor: _blanco,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const QuizIcon('medal_ornate', size: 72, color: _oroBrillante),
              const SizedBox(height: 12),
              const Text(
                '¡LOGRO DESBLOQUEADO!',
                style: TextStyle(
                  color: _primario,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                rango,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _navyTexto,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '+$xpGanado XP · $_xp XP totales',
                style: const TextStyle(color: _grisClaro, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'Certificado generado y guardado en Mis Logros',
                style: TextStyle(color: _grisClaro, fontSize: 12),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _navyTexto,
                        side: const BorderSide(color: _bordeKit, width: 2),
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
                      icon: const QuizIcon('share_ornate', size: 18),
                      label: const Text('Compartir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primario,
                        foregroundColor: _blanco,
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
}

/// Fondo del quiz: claro del kit con dos resplandores suaves (lavanda/rosa).
class _FondoQuiz extends StatelessWidget {
  const _FondoQuiz();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _fondoKit,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _lavanda.withValues(alpha: 0.35),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -70,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _rosaPink.withValues(alpha: 0.18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opción de respuesta "jugosa": se hunde al tocar, rebota si es correcta,
/// tiembla si es la incorrecta seleccionada, y se apaga si no fue elegida.
class _OpcionTarjeta extends StatefulWidget {
  final String texto;
  final int indice;
  final bool respondida;
  final bool revelando;
  final bool esCorrecta;
  final bool esSeleccionada;
  final VoidCallback? onTap;

  const _OpcionTarjeta({
    required this.texto,
    required this.indice,
    required this.respondida,
    required this.revelando,
    required this.esCorrecta,
    required this.esSeleccionada,
    this.onTap,
  });

  @override
  State<_OpcionTarjeta> createState() => _OpcionTarjetaState();
}

class _OpcionTarjetaState extends State<_OpcionTarjeta>
    with TickerProviderStateMixin {
  bool _presionada = false;
  AnimationController? _shake;
  AnimationController? _pulso;

  @override
  void didUpdateWidget(covariant _OpcionTarjeta oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.respondida &&
        widget.esSeleccionada &&
        !widget.esCorrecta &&
        _shake == null) {
      _shake = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 520),
      )..forward();
    }
    // Pulso dorado mientras se revela la respuesta seleccionada.
    final quierePulso = widget.respondida &&
        widget.revelando &&
        widget.esSeleccionada;
    if (quierePulso && _pulso == null) {
      _pulso = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      )..repeat(reverse: true);
    } else if (!quierePulso && _pulso != null) {
      _pulso!.dispose();
      _pulso = null;
    }
  }

  @override
  void dispose() {
    _shake?.dispose();
    _pulso?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letra = String.fromCharCode(65 + widget.indice);
    Color borde = _bordeKit;
    Color fondo = _blanco;
    Color letraFondo = _lavanda.withValues(alpha: 0.5);
    Color letraColor = _primario;
    String? iconoFin;

    if (widget.respondida) {
      if (widget.revelando && widget.esSeleccionada) {
        // Borde violeta pulsante durante la pausa de revelación.
        borde = _primario;
        fondo = _lavanda.withValues(alpha: 0.45);
        letraFondo = _primario;
        letraColor = _blanco;
      } else if (widget.esCorrecta) {
        borde = _acierto;
        fondo = _menta.withValues(alpha: 0.45);
        letraFondo = _acierto;
        letraColor = _blanco;
        iconoFin = 'check_seal';
      } else if (widget.esSeleccionada) {
        borde = _fallo;
        fondo = _fallo.withValues(alpha: 0.08);
        letraFondo = _fallo;
        letraColor = _blanco;
        iconoFin = 'close_ornate';
      }
    }

    Widget tarjeta = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borde, width: 1.5),
        boxShadow: widget.esCorrecta && widget.respondida
            ? [
                BoxShadow(
                  color: _acierto.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: letraFondo,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    letra,
                    style: TextStyle(
                      color: letraColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.texto,
                    style: const TextStyle(
                      color: _navyTexto,
                      fontSize: 14.5,
                      height: 1.3,
                    ),
                  ),
                ),
                if (iconoFin != null)
                  QuizIcon(iconoFin, size: 22, color: borde),
              ],
            ),
          ),
        ),
      ),
    );

    // Rebote elástico cuando es la correcta.
    if (widget.respondida && widget.esCorrecta) {
      tarjeta = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.9, end: 1.0),
        curve: Curves.elasticOut,
        duration: const Duration(milliseconds: 700),
        builder: (context, v, child) => Transform.scale(scale: v, child: child),
        child: tarjeta,
      );
    }

    // Temblor cuando es la incorrecta seleccionada.
    if (_shake != null) {
      tarjeta = AnimatedBuilder(
        animation: _shake!,
        builder: (context, child) {
          final t = _shake!.value;
          final dx = sin(t * pi * 4) * 9 * (1 - t);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: tarjeta,
      );
    }

    // Las no elegidas se apagan.
    if (widget.respondida && !widget.esCorrecta && !widget.esSeleccionada) {
      tarjeta = Opacity(opacity: 0.35, child: tarjeta);
    }

    // Escala pulsante (latido) mientras se revela la seleccionada.
    if (widget.respondida && widget.revelando && widget.esSeleccionada) {
      tarjeta = AnimatedBuilder(
        animation: _pulso!,
        builder: (context, child) =>
            Transform.scale(scale: 1 + 0.025 * _pulso!.value, child: child),
        child: tarjeta,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _presionada = true),
        onTapUp: (_) => setState(() => _presionada = false),
        onTapCancel: () => setState(() => _presionada = false),
        child: AnimatedScale(
          scale: _presionada ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: tarjeta,
        ),
      ),
    );
  }
}

/// Overlay épico de ascenso: insignia con rebote elástico y resplandor vivo.
class _AscensoOverlay extends StatefulWidget {
  final String rango;
  final int xpGanado;
  final int xpTotal;

  const _AscensoOverlay({
    required this.rango,
    required this.xpGanado,
    required this.xpTotal,
  });

  @override
  State<_AscensoOverlay> createState() => _AscensoOverlayState();
}

class _AscensoOverlayState extends State<_AscensoOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _glow,
        builder: (context, _) {
          final brillo = 0.3 + 0.25 * _glow.value;
          return Container(
            width: 310,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _blanco,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _lavanda, width: 2),
              boxShadow: [
                BoxShadow(
                  color: _primario.withValues(alpha: brillo),
                  blurRadius: 40,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 1.0),
                  curve: Curves.elasticOut,
                  duration: const Duration(milliseconds: 800),
                  builder: (context, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [_oroBrillante, _oro],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _oro.withValues(alpha: 0.7),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const QuizIcon('medal_ornate',
                        size: 48, color: Color(0xFF0F172A)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '¡ASCENSO!',
                  style: GoogleFonts.rubik(
                    color: _primario,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.rango,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rubik(
                    color: _navyTexto,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '+${widget.xpGanado} XP · ${widget.xpTotal} XP totales',
                  style: const TextStyle(
                    color: _grisClaro,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primario,
                      foregroundColor: _blanco,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'CONTINUAR',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
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

import 'dart:async';
import '../services/haptics_service.dart';
import '../pages/main_screen.dart';
import '../utils/main_tab_controller.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/game.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../game/quiz_effects_game.dart';
import '../services/misiones_diarias_service.dart';
import '../services/quiz_certificate_service.dart';
import '../widgets/main_bottom_bar.dart';
import '../services/quiz_generador_service.dart';
import '../services/quiz_progresion_service.dart';
import '../services/quiz_ranking_service.dart';
import '../services/quiz_rules.dart';
import '../services/quiz_storage_service.dart';
import '../models/caso_quiz.dart';
import '../services/sfx_service.dart';
import '../utils/quiz_seed.dart';
import '../utils/transiciones.dart';
import '../widgets/quiz_insignia_widget.dart';
import '../widgets/quiz_icon.dart';
import '../widgets/quiz_pulso_widget.dart';
import 'quiz_game_screen.dart';
import 'quiz_logros_screen.dart';

/// Paleta del quiz adaptada del kit "Queezy" (fondo claro, violeta/lavanda/
/// rosa/menta) con un pequeño ajuste para armonizar con el resto de Penalex:
/// el texto fuerte usa el navy de la app (#0F172A) y el oro (#C5A059) queda
/// como acento secundario en premios/medallas — sin romper la claridad del kit.
const _fondoKit = Color(0xFFF7F6FF); // fondo del kit
const _primario = Color(0xFF6A5AE0); // violeta primario del kit
const _secundario = Color(0xFF9087E5); // violeta claro (featured card)
const _lavanda = Color(0xFFC4D0FB); // acento lavanda del kit
const _rosaPink = Color(0xFFFF8FA2); // pink del kit
const _menta = Color(0xFFC9F2E9); // acento menta del kit
const _navyTexto = Color(0xFF0F172A); // texto fuerte = navy de la app
const _grisClaro = Color(0xFF858494); // grey 2 del kit
const _bordeKit = Color(0xFFEFEEFC); // grey 5 del kit (bordes de tarjetas)
const _blanco = Colors.white;
const _oro = Color(0xFFC5A059); // acento app: premios/medallas
const _oroBrillante = Color(0xFFE9C86A);

class QuizLobbyScreen extends StatefulWidget {
  const QuizLobbyScreen({super.key});

  @override
  State<QuizLobbyScreen> createState() => _QuizLobbyScreenState();
}

class _QuizLobbyScreenState extends State<QuizLobbyScreen>
    with TickerProviderStateMixin {
  final QuizStorageService _service = QuizStorageService();
  late final QuizEffectsGame _fx;
  late final AnimationController _entrada;

  Map<String, dynamic> _progreso = {};
  int _totalCasos = 0;
  List<CasoQuiz> _casos = [];
  List<Map<String, dynamic>> _ranking = [];
  bool _cargando = true;
  bool _muted = false;
  Timer? _tick;
  Timer? _ambiente;

  int get _xp => (_progreso['xp'] as num?)?.toInt() ?? 0;
  int get _apelaciones => (_progreso['apelaciones'] as num?)?.toInt() ?? 5;
  int get _racha => (_progreso['racha_actual'] as num?)?.toInt() ?? 0;
  int get _rachaDias => (_progreso['racha_dias'] as num?)?.toInt() ?? 0;

  List<MisionEstado> _misiones = [];

  @override
  void initState() {
    super.initState();
    _fx = QuizEffectsGame();
    _entrada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _inicializar();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _ambiente?.cancel();
    _entrada.dispose();
    SfxService.instance.ambienteStop();
    super.dispose();
  }

  Future<void> _inicializar() async {
    await sembrarCasosIniciales();
    QuizGeneradorService.recargarBanco();
    await SfxService.instance.init();
    await SfxService.instance.ambienteStart();
    if (mounted) setState(() => _muted = SfxService.instance.muted);

    final p = await _service.cargarProgreso();
    final casos = await _service.listarCasos();
    final ranking = await QuizRankingService.top(limit: 5);

    if (!mounted) return;
    // Progresión diaria: racha de días + bono por volver (una vez al día).
    final hoy = DateTime.now();
    final preparado = QuizProgresionService.prepararDia(p, hoy);
    final pFinal = preparado.progreso;
    if (preparado.bono > 0) {
      _misiones = QuizProgresionService.estadoMisiones(pFinal, hoy);
      await _service.guardarProgreso(pFinal);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: _navyTexto,
          content: Text(
            '¡Racha de ${pFinal['racha_dias']} días! +${preparado.bono} XP por volver',
            style: const TextStyle(color: _oroBrillante),
          ),
        ));
      }
    } else {
      _misiones = QuizProgresionService.estadoMisiones(pFinal, hoy);
    }

    if (!mounted) return;
    setState(() {
      _progreso = pFinal;
      _totalCasos = casos.length;
      _casos = casos;
      _ranking = ranking;
      _cargando = false;
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _ambiente = Timer.periodic(const Duration(milliseconds: 300), (_) {
      final s = _fx.size;
      if (s.x > 0) _fx.particulaAmbiente(s.x, s.y);
    });
  }

  /// Entrada en cascada: cada sección aparece con retardo escalonado.
  Widget _entradaAnim(int i, Widget child) {
    final start = (0.12 * i).clamp(0.0, 0.7);
    final curve = CurvedAnimation(
      parent: _entrada,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.09), end: Offset.zero)
            .animate(curve),
        child: child,
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
      bottomNavigationBar: const MainBottomBar(),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: GameWidget(
                game: _fx,
                              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: Align(
                alignment: Alignment.topRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMuteToggle(),
                    const SizedBox(width: 10),
                    _buildHomeButton(),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: _oro))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _entradaAnim(0, _buildHeader()),
                        const SizedBox(height: 20),
                        _entradaAnim(1, _buildCasoDestacado()),
                        const SizedBox(height: 20),
                        _entradaAnim(2, _buildRankCard()),
                        const SizedBox(height: 20),
                        _entradaAnim(3, _buildCasosDisponibles()),
                        const SizedBox(height: 20),
                        _entradaAnim(4, _buildMisiones()),
                        const SizedBox(height: 20),
                        _entradaAnim(5, _buildJugar()),
                        const SizedBox(height: 12),
                        _entradaAnim(6, _buildCertificado()),
                        const SizedBox(height: 12),
                        _entradaAnim(7, _buildMisLogros()),
                        const SizedBox(height: 32),
                        _entradaAnim(8, _buildRanking()),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildHomeButton() {
    return Material(
      color: _blanco,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: _primario.withValues(alpha: 0.18),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          mainTabIndex.value = 0;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (r) => false,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.home_outlined,
            size: 22,
            color: _navyTexto,
          ),
        ),
      ),
    );
  }

  Widget _buildMuteToggle() {
    return Material(
      color: _blanco,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: _primario.withValues(alpha: 0.18),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          Haptics.tap();
          final nuevo = !_muted;
          await SfxService.instance.mute(nuevo);
          if (mounted) setState(() => _muted = nuevo);
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: QuizIcon(
            _muted ? 'sound_off_ornate' : 'sound_on_ornate',
            size: 22,
            color: _muted ? _grisClaro : _primario,
          ),
        ),
      ),
    );
  }

  /// Nombre visible del usuario (displayName, email o fallback).
  String get _nombreUsuario {
    final u = FirebaseAuth.instance.currentUser;
    if (u?.displayName?.trim().isNotEmpty == true) return u!.displayName!;
    final email = u?.email ?? '';
    return email.isEmpty ? 'Abogado Penalex' : email.split('@').first;
  }

  /// Saludo según la hora (como el "Good Morning" del kit).
  String get _saludo {
    final h = DateTime.now().hour;
    if (h < 12) return 'BUENOS DÍAS';
    if (h < 19) return 'BUENAS TARDES';
    return 'BUENAS NOCHES';
  }

  /// Header tipo "Greetings" del kit: saludo + nombre + avatar (insignia del
  /// rango judicial en lugar del avatar de persona).
  Widget _buildHeader() {
    final indice = QuizRules.indiceRango(_xp);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _saludo,
                style: TextStyle(
                  color: _grisClaro,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _nombreUsuario,
                style: GoogleFonts.rubik(
                  color: _navyTexto,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${QuizRules.rangoParaXp(_xp)} · $_xp XP',
                style: const TextStyle(
                  color: _primario,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        // Avatar del kit → insignia del rango con anillo violeta del kit.
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_secundario, _primario],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _primario.withValues(alpha: 0.35),
                blurRadius: 22,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: QuizInsignia(
              rango: QuizRules.rangoParaXp(_xp),
              tamano: 46,
              estrellas: (indice / QuizRules.totalRangos * 5).round(),
              brillo: indice >= QuizRules.totalRangos * 0.6,
            ),
          ),
        ),
      ],
    );
  }

  /// Tarjeta destacada estilo "featured" del kit (fondo violeta, botón blanco
  /// con texto violeta): caso del día con botón.
  Widget _buildCasoDestacado() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [_secundario, _primario],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primario.withValues(alpha: 0.35),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              QuizIcon('star_shield', size: 20, color: _blanco),
              SizedBox(width: 8),
              Text(
                'CASO DESTACADO',
                style: TextStyle(
                  color: _blanco,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Dosimetría y cómputo\nde penas',
            style: GoogleFonts.rubik(
              color: _blanco,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '5 casos · ~5 min · hasta +120 XP',
            style: TextStyle(
              color: _blanco.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: _blanco,
            borderRadius: BorderRadius.circular(14),
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Haptics.light();
                Navigator.push(context, cortinaDorada(const QuizGameScreen()));
              },
              child: Ink(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    QuizIcon('play_ornate', color: _primario, size: 24),
                    SizedBox(width: 6),
                    Text(
                      'RESOLVER',
                      style: TextStyle(
                        color: _primario,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Casos hipotéticos del banco personal (sin materias: todo el derecho
    /// penal se mezcla). Cada tarjeta abre el juego. Réplica de la "Live Quiz"
    /// card del kit: blanca, borde gris claro, icono en frame lavanda.
  Widget _buildCasosDisponibles() {
    final delitos = <String>{
      for (final c in _casos)
        if (c.delitoBase.trim().isNotEmpty) c.delitoBase.trim()
    }.toList();
    final visibles = delitos.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CASOS HIPOTÉTICOS',
          style: TextStyle(
            color: _grisClaro,
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: _blanco,
          borderRadius: BorderRadius.circular(20),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Haptics.light();
              Navigator.push(
                  context, cortinaDorada(const QuizGameScreen()));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _bordeKit, width: 2),
              ),
              child: Row(
                children: [
                  // Frame lavanda con el icono (como la card "Live Quiz").
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: _lavanda,
                    ),
                    child: const Center(
                      child: QuizIcon('gavel_refined', size: 22,
                          color: _primario),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Caso hipotético · Derecho Penal',
                          style: TextStyle(
                            color: _navyTexto,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_totalCasos casos en tu banco · todo el penal se mezcla',
                          style: const TextStyle(
                            color: _grisClaro,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const QuizIcon('play_ornate', size: 20, color: _primario),
                ],
              ),
            ),
          ),
        ),
        if (visibles.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in visibles)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _lavanda.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    d,
                    style: const TextStyle(
                      color: _primario,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRankCard() {
    final sig = QuizRules.siguienteRango(_xp);
    final progreso = QuizRules.progresoRango(_xp);
    final indice = QuizRules.indiceRango(_xp);
    final estrellas = (indice / QuizRules.totalRangos * 5).round();
    final brillo = indice >= QuizRules.totalRangos * 0.6;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _blanco,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _bordeKit, width: 2),
        boxShadow: [
          BoxShadow(
            color: _primario.withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progreso.clamp(0.0, 1.0)),
                      duration: const Duration(milliseconds: 1100),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => CircularProgressIndicator(
                        value: v,
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                        backgroundColor: _bordeKit,
                        valueColor: const AlwaysStoppedAnimation(_primario),
                      ),
                    ),
                    QuizInsignia(
                      rango: QuizRules.rangoParaXp(_xp),
                      tamano: 58,
                      estrellas: estrellas,
                      brillo: brillo,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      QuizRules.rangoParaXp(_xp),
                      style: GoogleFonts.rubik(
                        color: _navyTexto,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_xp XP',
                      style: const TextStyle(
                        color: _primario,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sig != null
                          ? 'Próximo: ${sig.nombre} · ${sig.xp} XP'
                          : 'Rango máximo alcanzado',
                      style: const TextStyle(
                        color: _grisClaro,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: _bordeKit),
          const SizedBox(height: 16),
          Row(
            children: [
              _stat(QuizIcon('flame_legal', size: 22,
                  color: _primario), '$_racha', 'Racha'),
              _stat(QuizIcon('calendar_court', size: 22,
                  color: _rosaPink), '$_rachaDias', 'Días'),
              _stat(QuizIcon('scales_calc', size: 22, color: _primario),
                  '$_apelaciones', 'Apelaciones'),
              _stat(QuizIcon('book_law', size: 22,
                  color: _menta), '$_totalCasos', 'Casos'),
            ],
          ),
          if (_apelaciones < 5) ...[
            const SizedBox(height: 16),
            _buildCuentaRegresiva(),
          ],
        ],
      ),
    );
  }

  Widget _buildCuentaRegresiva() {
    final restante = QuizStorageService.tiempoSiguienteApelacion(_progreso);
    if (restante == null) return const SizedBox.shrink();
    final m = restante.inMinutes;
    final seg = restante.inSeconds % 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _lavanda.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const QuizIcon('hourglass_gold', size: 18, color: _primario),
          const SizedBox(width: 8),
          Text(
            'Próxima apelación en ${m}m ${seg.toString().padLeft(2, '0')}s',
            style: const TextStyle(
              color: _navyTexto,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMisiones() {
    if (_misiones.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _blanco,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _bordeKit, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const QuizIcon('flag_ornate', size: 20, color: _primario),
              const SizedBox(width: 8),
              const Text(
                'MISIONES DEL DÍA',
                style: TextStyle(
                  color: _navyTexto,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              const Text(
                'renuevan mañana',
                style: TextStyle(
                  color: _grisClaro,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._misiones.map(_buildMisionCard),
        ],
      ),
    );
  }

  Widget _buildMisionCard(MisionEstado e) {
    final m = e.mision;
    final pct = (e.progreso / m.meta).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _fondoKit,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(m.icono, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.descripcion,
                  style: const TextStyle(
                    color: _navyTexto,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: _bordeKit,
                    valueColor: const AlwaysStoppedAnimation(_primario),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${e.progreso}/${m.meta} · +${m.recompensa} XP',
                  style: const TextStyle(
                    color: _grisClaro,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (e.reclamada)
            const QuizIcon('check_seal', size: 26, color: _menta)
          else if (e.completa)
            GestureDetector(
              onTap: () {
                Haptics.tap();
                _reclamarMision(m);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _primario,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'RECLAMAR',
                  style: TextStyle(
                    color: _blanco,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            Text(
              '${(pct * 100).round()}%',
              style: const TextStyle(
                color: _grisClaro,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _reclamarMision(MisionDiaria m) async {
    final hoy = DateTime.now();
    final antes = _xp;
    final nuevo = MisionesDiariasService.reclamar(_progreso, m, hoy);
    final despues = (nuevo['xp'] as num?)?.toInt() ?? 0;
    if (despues == antes) return; // aún no completada
    setState(() {
      _progreso = nuevo;
      _misiones = QuizProgresionService.estadoMisiones(nuevo, hoy);
    });
    await _service.guardarProgreso(nuevo);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: _navyTexto,
        content: Text(
          '${m.descripcion} — +${m.recompensa} XP',
          style: const TextStyle(color: _oroBrillante),
        ),
      ));
    }
  }

  Widget _stat(Widget icon, String valor, String label) {
    return Expanded(
      child: Column(
        children: [
          icon,
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(
              color: _navyTexto,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: _grisClaro,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJugar() {
    return QuizPulso(
      maxScale: 1.04,
      periodo: const Duration(milliseconds: 1200),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [_primario, _secundario],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _primario.withValues(alpha: 0.4),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Haptics.light();
              Navigator.push(context, cortinaDorada(const QuizGameScreen()));
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  QuizIcon('play_ornate',
                      color: _blanco, size: 32),
                  SizedBox(width: 8),
                  Text(
                    'JUGAR',
                    style: TextStyle(
                      color: _blanco,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCertificado() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: _navyTexto,
        side: const BorderSide(color: _bordeKit, width: 2),
        backgroundColor: _blanco,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: _descargarCertificado,
      icon: const QuizIcon('scroll_seal', color: _primario),
      label: const Text(
        'Descargar certificado',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildMisLogros() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: _navyTexto,
        side: const BorderSide(color: _bordeKit, width: 2),
        backgroundColor: _blanco,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: () =>
          Navigator.push(context, cortinaDorada(const QuizLogrosScreen())),
      icon: const QuizIcon('laurel', color: _primario),
      label: const Text(
        'Mis Logros',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _descargarCertificado() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final nombre = (user?.displayName?.trim().isNotEmpty == true)
          ? user!.displayName!
          : (user?.email?.split('@').first ?? 'Abogado Penalex');
      final uid = user?.uid ?? 'anon';

      final ruta = await QuizCertificateService.generarCertificado(
        nombre: nombre,
        rango: QuizRules.rangoParaXp(_xp),
        xp: _xp,
        codigo: QuizCertificateService.generarCodigo(uid, _xp),
      );

      if (ruta != null) {
        await Share.shareXFiles([XFile(ruta)], text: 'Certificado Penalex');
      } else if (mounted) {
        _snack('No se pudo generar el certificado');
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Widget _buildRanking() {
    if (_ranking.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TOP DEL RANKING',
          style: TextStyle(
            color: _grisClaro,
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _blanco,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _bordeKit, width: 2),
          ),
          child: Column(
            children: _ranking.asMap().entries.map((e) {
              final i = e.key;
              final r = e.value;
              final medalla = i == 0
                  ? const Color(0xFFE9C86A)
                  : i == 1
                      ? const Color(0xFFB0BEC5)
                      : i == 2
                          ? const Color(0xFFBC8F5E)
                          : Colors.transparent;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 400 + i * 90),
                curve: Curves.easeOutCubic,
                builder: (context, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - v)),
                    child: child,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: medalla == Colors.transparent
                        ? _bordeKit
                        : medalla,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: medalla == Colors.transparent
                            ? _navyTexto
                            : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(
                    r['nombre'] ?? 'Usuario',
                    style: const TextStyle(
                      color: _navyTexto,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    r['rango_actual'] ?? '',
                    style: const TextStyle(
                      color: _grisClaro,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Text(
                    '${r['xp'] ?? 0} XP',
                    style: const TextStyle(
                      color: _primario,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

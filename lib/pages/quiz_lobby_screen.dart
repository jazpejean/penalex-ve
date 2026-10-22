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
import '../services/sfx_service.dart';
import '../utils/quiz_seed.dart';
import '../utils/transiciones.dart';
import '../widgets/liquid_gold_background.dart';
import '../widgets/quiz_insignia_widget.dart';
import '../widgets/penalex_logo.dart';
import '../widgets/quiz_icon.dart';
import '../widgets/quiz_pulso_widget.dart';
import 'quiz_game_screen.dart';
import 'quiz_logros_screen.dart';

/// Paleta oficial del quiz: navy profundo + oro (alineada al resto de la app).
const _fondoProfundo = Color(0xFF0A0E1A);
const _card = Color(0xFF141B2E);
const _ambar = Color(0xFFF59E0B);
const _esmeralda = Color(0xFF10B981);
const _oro = Color(0xFFC5A059);
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
          backgroundColor: _card,
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
        textTheme: GoogleFonts.interTextTheme(
            Theme.of(context).textTheme),
      ),
      child: Scaffold(
      backgroundColor: _fondoProfundo,
      bottomNavigationBar: const MainBottomBar(),
      body: Stack(
        children: [
          const Positioned.fill(
            child: LiquidGoldBackground(child: SizedBox.expand()),
          ),
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
                        _entradaAnim(0, _buildHero()),
                        const SizedBox(height: 24),
                        _entradaAnim(1, _buildRankCard()),
                        const SizedBox(height: 24),
                        _entradaAnim(2, _buildMisiones()),
                        const SizedBox(height: 24),
                        _entradaAnim(3, _buildJugar()),
                        const SizedBox(height: 12),
                        _entradaAnim(4, _buildCertificado()),
                        const SizedBox(height: 12),
                        _entradaAnim(5, _buildMisLogros()),
                        const SizedBox(height: 32),
                        _entradaAnim(6, _buildRanking()),
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
      color: _card.withValues(alpha: 0.75),
      shape: const CircleBorder(),
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
            color: _oroBrillante,
          ),
        ),
      ),
    );
  }

  Widget _buildMuteToggle() {
    return Material(
      color: _card.withValues(alpha: 0.75),
      shape: const CircleBorder(),
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
            color: _muted ? Colors.white54 : _oroBrillante,
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        QuizPulso(
          maxScale: 1.06,
          periodo: const Duration(milliseconds: 1600),
          child: Container(
            width: 98,
            height: 98,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_oroBrillante, _oro],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _oro.withValues(alpha: 0.55),
                  blurRadius: 34,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: PenalexLogo(
              variant: PenalexLogoVariant.logo,
              size: 56,
              color: const Color(0xFF0F172A),
              animate: false,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _ShimmerText(
          'PENALEX QUIZ',
          style: GoogleFonts.cinzel(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Asciende en la carrera judicial venezolana',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
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
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _oro.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
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
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation(_oro),
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
                      style: GoogleFonts.cinzel(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_xp XP',
                      style: const TextStyle(
                        color: _oroBrillante,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sig != null
                          ? 'Próximo: ${sig.nombre} · ${sig.xp} XP'
                          : 'Rango máximo alcanzado',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 16),
          Row(
            children: [
              _stat(QuizIcon('flame_legal', size: 22,
                  color: _oroBrillante), '$_racha', 'Racha'),
              _stat(QuizIcon('calendar_court', size: 22,
                  color: _ambar), '$_rachaDias', 'Días'),
              _stat(QuizIcon('scales_calc', size: 22, color: _oroBrillante),
                  '$_apelaciones', 'Apelaciones'),
              _stat(QuizIcon('book_law', size: 22,
                  color: _esmeralda), '$_totalCasos', 'Casos'),
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
        color: _oro.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _oro.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const QuizIcon('hourglass_gold', size: 18, color: _oroBrillante),
          const SizedBox(width: 8),
          Text(
            'Próxima apelación en ${m}m ${seg.toString().padLeft(2, '0')}s',
            style: const TextStyle(
              color: Colors.white,
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
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _oro.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const QuizIcon('flag_ornate', size: 20, color: _oroBrillante),
              const SizedBox(width: 8),
              const Text(
                'MISIONES DEL DÍA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                'renuevan mañana',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
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
        color: _fondoProfundo.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _oro.withValues(alpha: 0.22)),
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
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(_oro),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${e.progreso}/${m.meta} · +${m.recompensa} XP',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (e.reclamada)
            const QuizIcon('check_seal', size: 26, color: _esmeralda)
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
                  gradient: const LinearGradient(
                    colors: [_oroBrillante, _oro],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'RECLAMAR',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
          else
            Text(
              '${(pct * 100).round()}%',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
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
        backgroundColor: _card,
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
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
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
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [_oroBrillante, _oro],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _oro.withValues(alpha: 0.55),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
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
                      color: Color(0xFF0F172A), size: 32),
                  SizedBox(width: 8),
                  Text(
                    'JUGAR',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
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
        foregroundColor: _oroBrillante,
        side: BorderSide(color: _oro.withValues(alpha: 0.6), width: 1.2),
        backgroundColor: _card.withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _descargarCertificado,
      icon: const QuizIcon('scroll_seal'),
      label: const Text(
        'Descargar certificado',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildMisLogros() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white24),
        backgroundColor: _card.withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () =>
          Navigator.push(context, cortinaDorada(const QuizLogrosScreen())),
      icon: const QuizIcon('laurel'),
      label: const Text('Mis Logros'),
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
        Text(
          'TOP DEL RANKING',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _card.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _oro.withValues(alpha: 0.25)),
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
                        ? Colors.white12
                        : medalla,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: medalla == Colors.transparent
                            ? Colors.white
                            : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(
                    r['nombre'] ?? 'Usuario',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    r['rango_actual'] ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  trailing: Text(
                    '${r['xp'] ?? 0} XP',
                    style: const TextStyle(
                      color: _oroBrillante,
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

/// Título con brillo que se desliza (shimmer dorado).
class _ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _ShimmerText(this.text, {required this.style});

  @override
  State<_ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<_ShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final v = _c.value;
        return ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(-1.2 + 2.4 * v, 0),
            end: Alignment(-0.2 + 2.4 * v, 0),
            colors: [_oro, _oroBrillante, _oro],
            stops: const [0.2, 0.5, 0.8],
          ).createShader(rect),
          blendMode: BlendMode.srcIn,
          child: Text(
            widget.text,
            style: widget.style.copyWith(color: Colors.white),
          ),
        );
      },
    );
  }
}

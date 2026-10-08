import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/quiz_certificate_service.dart';
import '../services/quiz_generador_service.dart';
import '../services/quiz_ranking_service.dart';
import '../services/quiz_rules.dart';
import '../services/quiz_storage_service.dart';
import '../utils/quiz_seed.dart';
import 'quiz_game_screen.dart';
import 'quiz_logros_screen.dart';

const _navy = Color(0xFF0A0F1E);
const _navy2 = Color(0xFF16203A);
const _gold = Color(0xFFC5A059);
const _goldBright = Color(0xFFE9C86A);

class QuizLobbyScreen extends StatefulWidget {
  const QuizLobbyScreen({super.key});

  @override
  State<QuizLobbyScreen> createState() => _QuizLobbyScreenState();
}

class _QuizLobbyScreenState extends State<QuizLobbyScreen> {
  final QuizStorageService _service = QuizStorageService();

  Map<String, dynamic> _progreso = {};
  int _totalCasos = 0;
  List<Map<String, dynamic>> _ranking = [];
  bool _cargando = true;
  Timer? _tick;

  int get _xp => (_progreso['xp'] as num?)?.toInt() ?? 0;
  int get _apelaciones => (_progreso['apelaciones'] as num?)?.toInt() ?? 5;
  int get _racha => (_progreso['racha_actual'] as num?)?.toInt() ?? 0;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _inicializar() async {
    await sembrarCasosIniciales();
    QuizGeneradorService.recargarBanco();

    final p = await _service.cargarProgreso();
    final casos = await _service.listarCasos();
    final ranking = await QuizRankingService.top(limit: 5);

    if (!mounted) return;
    setState(() {
      _progreso = p;
      _totalCasos = casos.length;
      _ranking = ranking;
      _cargando = false;
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: Stack(
        children: [
          _buildFondo(),
          SafeArea(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: _gold))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHero(),
                        const SizedBox(height: 24),
                        _buildRankCard(),
                        const SizedBox(height: 24),
                        _buildJugar(),
                        const SizedBox(height: 12),
                        _buildCertificado(),
                        const SizedBox(height: 12),
                        _buildMisLogros(),
                        const SizedBox(height: 30),
                        _buildRanking(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Fondo con gradiente y resplandores dorados
  Widget _buildFondo() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.8),
            radius: 1.2,
            colors: [Color(0xFF24304E), _navy],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - v)),
          child: child,
        ),
      ),
      child: Column(
        children: [
          // Escudo con gradiente dorado
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_goldBright, _gold],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.45),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.balance, size: 44, color: _navy),
          ),
          const SizedBox(height: 18),
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [_goldBright, _gold, _goldBright],
            ).createShader(rect),
            child: const Text(
              'PENALEX QUIZ',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Asciende en la carrera judicial venezolana',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankCard() {
    final sig = QuizRules.siguienteRango(_xp);
    final progreso = QuizRules.progresoRango(_xp);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _gold.withValues(alpha: 0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Anillo de progreso
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: progreso.clamp(0.0, 1.0),
                        strokeWidth: 6,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation(_gold),
                      ),
                    ),
                    const Icon(Icons.military_tech, color: _goldBright, size: 30),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      QuizRules.rangoParaXp(_xp),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_xp XP',
                      style: const TextStyle(color: _goldBright, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sig != null
                          ? 'Próximo: ${sig.nombre} · ${sig.xp} XP'
                          : 'Rango máximo alcanzado',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _stat(Icons.local_fire_department, '$_racha', 'Racha',
                  const Color(0xFFFF8A65)),
              _stat(Icons.balance, '$_apelaciones', 'Apelaciones', _goldBright),
              _stat(Icons.library_books, '$_totalCasos', 'Casos',
                  const Color(0xFF81C784)),
            ],
          ),
          if (_apelaciones < 5) ...[
            const SizedBox(height: 14),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, color: _goldBright, size: 18),
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

  Widget _stat(IconData icon, String valor, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJugar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [_goldBright, _gold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QuizGameScreen()),
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow_rounded, color: _navy, size: 30),
                SizedBox(width: 8),
                Text(
                  'JUGAR',
                  style: TextStyle(
                    color: _navy,
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
    );
  }

  Widget _buildCertificado() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: _goldBright,
        side: const BorderSide(color: _gold, width: 1.2),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: _descargarCertificado,
      icon: const Icon(Icons.workspace_premium_outlined),
      label: const Text('Descargar certificado',
          style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildMisLogros() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white24),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QuizLogrosScreen()),
      ),
      icon: const Icon(Icons.emoji_events_outlined),
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
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _gold.withValues(alpha: 0.2)),
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
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: medalla == Colors.transparent
                      ? Colors.white12
                      : medalla,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: medalla == Colors.transparent
                          ? Colors.white
                          : _navy,
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
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                  ),
                ),
                trailing: Text(
                  '${r['xp'] ?? 0} XP',
                  style: const TextStyle(
                    color: _goldBright,
                    fontWeight: FontWeight.w700,
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

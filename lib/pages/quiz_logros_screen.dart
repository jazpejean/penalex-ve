import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../game/quiz_effects_game.dart';
import '../services/quiz_certificate_service.dart';
import '../services/quiz_rules.dart';
import '../services/quiz_storage_service.dart';
import '../widgets/quiz_icon.dart';
import '../widgets/quiz_pulso_widget.dart';

const _fondoProfundo = Color(0xFF190F38);
const _card = Color(0xFF251A4D);
const _oro = Color(0xFFC5A059);
const _oroBrillante = Color(0xFFE9C86A);

/// Galería de logros: el camino de la carrera judicial como escalones-gema.
class QuizLogrosScreen extends StatefulWidget {
  const QuizLogrosScreen({super.key});

  @override
  State<QuizLogrosScreen> createState() => _QuizLogrosScreenState();
}

class _QuizLogrosScreenState extends State<QuizLogrosScreen>
    with TickerProviderStateMixin {
  final QuizStorageService _service = QuizStorageService();
  late final QuizEffectsGame _fx;
  Map<String, dynamic> _progreso = {};
  bool _cargando = true;
  Timer? _ambiente;

  int get _xp => (_progreso['xp'] as num?)?.toInt() ?? 0;

  @override
  void initState() {
    super.initState();
    _fx = QuizEffectsGame();
    _cargar();
  }

  @override
  void dispose() {
    _ambiente?.cancel();
    super.dispose();
  }

  Future<void> _cargar() async {
    final p = await _service.cargarProgreso();
    if (!mounted) return;
    setState(() {
      _progreso = p;
      _cargando = false;
    });
    _ambiente = Timer.periodic(const Duration(milliseconds: 320), (_) {
      final s = _fx.size;
      if (s.x > 0) _fx.particulaAmbiente(s.x, s.y);
    });
  }

  List<Map<String, dynamic>> get _logros =>
      (_progreso['logros'] as List<dynamic>? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  Map<String, dynamic> _logroDe(String rango) =>
      _logros.firstWhere((l) => l['rango'] == rango, orElse: () => const {});

  @override
  Widget build(BuildContext context) {
    final hitos = QuizRules.hitosConCertificado;
    return Scaffold(
      backgroundColor: _fondoProfundo,
      appBar: AppBar(
        title: const Text(
          'Mis Logros',
          style: TextStyle(fontWeight: FontWeight.bold, color: _oro),
        ),
        backgroundColor: _fondoProfundo,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: GameWidget(
                game: _fx,
                              ),
            ),
          ),
          _cargando
              ? const Center(child: CircularProgressIndicator(color: _oro))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  itemCount: hitos.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) return _buildHeader(hitos);
                    final hito = hitos[i - 1];
                    return _buildEscalon(
                      hito,
                      _logroDe(hito.nombre),
                      esUltimo: i == hitos.length,
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildHeader(List<({int xp, String nombre})> hitos) {
    final ganados = hitos.where((h) => _xp >= h.xp).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - v)),
            child: child,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _oro.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const QuizIcon('scroll_seal',
                      size: 34, color: _oroBrillante),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$ganados de ${hitos.length} logros',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_xp XP acumulados',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ganados / hitos.length),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 10,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(_oro),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEscalon(
    ({int xp, String nombre}) hito,
    Map<String, dynamic> logro, {
    required bool esUltimo,
  }) {
    final desbloqueado = _xp >= hito.xp;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - v)),
          child: child,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Riel con nodo-gema
            SizedBox(
              width: 34,
              child: Column(
                children: [
                  Container(
                    width: 3,
                    height: 12,
                    color: desbloqueado
                        ? _oro.withValues(alpha: 0.7)
                        : Colors.white12,
                  ),
                  Expanded(
                    child: Container(
                      width: 3,
                      color: desbloqueado
                          ? _oro.withValues(alpha: 0.35)
                          : Colors.white10,
                    ),
                  ),
                  if (!esUltimo)
                    Container(
                      width: 3,
                      height: 12,
                      color: desbloqueado
                          ? _oro.withValues(alpha: 0.7)
                          : Colors.white12,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Nodo circular (gema)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: desbloqueado
                  ? QuizPulso(
                      maxScale: 1.12,
                      periodo: const Duration(milliseconds: 1500),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [_oroBrillante, _oro],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _oro.withValues(alpha: 0.6),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const QuizIcon('medal_ornate',
                            size: 18, color: Color(0xFF0F172A)),
                      ),
                    )
                  : Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const QuizIcon('lock_ornate',
                          size: 17, color: Colors.white38),
                    ),
            ),
            const SizedBox(width: 12),
            // Tarjeta del hito
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: desbloqueado
                      ? _card
                      : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: desbloqueado
                        ? _oro.withValues(alpha: 0.55)
                        : Colors.white.withValues(alpha: 0.12),
                    width: desbloqueado ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hito.nombre,
                            style: TextStyle(
                              color:
                                  desbloqueado ? Colors.white : Colors.white54,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            desbloqueado
                                ? (logro['fecha'] != null
                                    ? 'Obtenido el '
                                        '${_fecha(logro['fecha'] as String)}'
                                    : 'Desbloqueado')
                                : '${hito.xp} XP para desbloquear',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (desbloqueado)
                      IconButton(
                        onPressed: () => _compartir(hito, logro),
                        icon: const QuizIcon('share_ornate',
                            size: 20, color: _oroBrillante),
                        tooltip: 'Compartir certificado',
                      )
                    else
                      Text(
                        '${hito.xp} XP',
                        style: TextStyle(
                          color: _oro.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fecha(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day}/${d.month}/${d.year}';
  }

  Future<void> _compartir(
      ({int xp, String nombre}) hito, Map<String, dynamic> logro) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final nombre = (user?.displayName?.trim().isNotEmpty == true)
          ? user!.displayName!
          : (user?.email?.split('@').first ?? 'Abogado Penalex');
      final uid = user?.uid ?? 'anon';
      final codigo = (logro['codigo'] as String?) ??
          QuizCertificateService.generarCodigo(uid, hito.xp);

      final ruta = await QuizCertificateService.generarCertificado(
        nombre: nombre,
        rango: hito.nombre,
        xp: hito.xp,
        codigo: codigo,
      );
      if (ruta != null) {
        await Share.shareXFiles([XFile(ruta)],
            text: 'Certificado Penalex: ${hito.nombre}');
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
}

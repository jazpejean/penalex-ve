import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/quiz_certificate_service.dart';
import '../services/quiz_rules.dart';
import '../services/quiz_storage_service.dart';

const _navy = Color(0xFF0F172A);
const _navy2 = Color(0xFF1E293B);
const _gold = Color(0xFFC5A059);
const _goldBright = Color(0xFFE9C86A);

/// Galería de logros (certificados ganados en el quiz) + camino de hitos.
class QuizLogrosScreen extends StatefulWidget {
  const QuizLogrosScreen({super.key});

  @override
  State<QuizLogrosScreen> createState() => _QuizLogrosScreenState();
}

class _QuizLogrosScreenState extends State<QuizLogrosScreen> {
  final QuizStorageService _service = QuizStorageService();
  Map<String, dynamic> _progreso = {};
  bool _cargando = true;

  int get _xp => (_progreso['xp'] as num?)?.toInt() ?? 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final p = await _service.cargarProgreso();
    if (!mounted) return;
    setState(() {
      _progreso = p;
      _cargando = false;
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
      backgroundColor: _navy,
      appBar: AppBar(
        title: const Text(
          'Mis Logros',
          style: TextStyle(fontWeight: FontWeight.bold, color: _gold),
        ),
        backgroundColor: _navy,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: hitos.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) return _buildHeader(hitos);
                final hito = hitos[i - 1];
                return _buildLogroCard(hito, _logroDe(hito.nombre));
              },
            ),
    );
  }

  Widget _buildHeader(List<({int xp, String nombre})> hitos) {
    final ganados = hitos.where((h) => _xp >= h.xp).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gold.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium, color: _goldBright, size: 34),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: ganados / hitos.length,
                minHeight: 10,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation(_gold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogroCard(
      ({int xp, String nombre}) hito, Map<String, dynamic> logro) {
    final desbloqueado = _xp >= hito.xp;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: desbloqueado ? _navy2 : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: desbloqueado
              ? _gold.withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.12),
          width: desbloqueado ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: desbloqueado
                  ? _gold.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: desbloqueado ? _goldBright : Colors.white24,
                width: 1.5,
              ),
            ),
            child: Icon(
              desbloqueado ? Icons.military_tech : Icons.lock,
              color: desbloqueado ? _goldBright : Colors.white38,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hito.nombre,
                  style: TextStyle(
                    color: desbloqueado ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desbloqueado
                      ? (logro['fecha'] != null
                          ? 'Obtenido el ${_fecha(logro['fecha'] as String)}'
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
              icon: const Icon(Icons.ios_share, color: _goldBright, size: 20),
              tooltip: 'Compartir certificado',
            )
          else
            Text(
              '${hito.xp} XP',
              style: TextStyle(
                color: _gold.withValues(alpha: 0.6),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
        ],
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
      final codigo =
          (logro['codigo'] as String?) ?? QuizCertificateService.generarCodigo(uid, hito.xp);

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

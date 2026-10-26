import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../utils/main_tab_controller.dart';
import 'glosario_screen.dart';
import 'repositorio_jurisprudencia_screen.dart';
import 'repositorio_leyes_screen.dart';

/// Hub de Consulta Jurídica.
///
/// Muestra las tres herramientas de consulta POR SEPARADO: Jurisprudencias,
/// Leyes y Glosario. Cada tarjeta abre su propia herramienta independiente
/// (con su drawer y su AppBar), en lugar de un buscador segmentado único.
class HubConsultaJuridicaScreen extends StatefulWidget {
  const HubConsultaJuridicaScreen({super.key});

  @override
  State<HubConsultaJuridicaScreen> createState() =>
      _HubConsultaJuridicaScreenState();
}

class _HubConsultaJuridicaScreenState extends State<HubConsultaJuridicaScreen> {
  /// Alcance pedido desde fuera (dashboard → pestaña Buscar con corpus).
  /// Si llega un valor, se abre la herramienta correspondiente directamente.
  String? _pendienteAlcance = consultaAlcance.value;

  @override
  void initState() {
    super.initState();
    consultaAlcance.addListener(_onConsultaExterna);
  }

  @override
  void dispose() {
    consultaAlcance.removeListener(_onConsultaExterna);
    super.dispose();
  }

  void _onConsultaExterna() {
    final String? alcance = consultaAlcance.value;
    if (alcance == null || !mounted) return;
    consultaAlcance.value = null;
    _abrirPorAlcance(alcance);
  }

  void _abrirPorAlcance(String alcance) {
    switch (alcance) {
      case 'leyes':
        _abrirLeyes();
      case 'glosario':
        _abrirGlosario();
      default:
        _abrirJurisprudencias();
    }
  }

  void _abrirJurisprudencias() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RepositorioJurisprudenciaScreen(),
      ),
    );
  }

  void _abrirLeyes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RepositorioLeyesScreen(),
      ),
    );
  }

  void _abrirGlosario() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GlosarioScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Alcance pendiente desde el constructor (navegación inicial).
    final String? pendiente = _pendienteAlcance;
    if (pendiente != null) {
      _pendienteAlcance = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _abrirPorAlcance(pendiente);
      });
    }

    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 4),
              Text(
                'Consulta Jurídica',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: TemaGlobal.texto,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tres herramientas por separado: fallos, leyes y términos.',
                style: TextStyle(
                  fontSize: 13,
                  color: TemaGlobal.textoSecundario,
                ),
              ),
              const SizedBox(height: 20),
              _buildHerramienta(
                context,
                icon: Icons.account_balance,
                titulo: 'Jurisprudencias',
                descripcion:
                    'Sentencias y fallos del TSJ con sala, año y favoritas. '
                    'Consulta ratio decidendi y extractos.',
                detalle: 'Sentencias · Jurisprudencias · Favoritas',
                onTap: _abrirJurisprudencias,
              ),
              const SizedBox(height: 14),
              _buildHerramienta(
                context,
                icon: Icons.menu_book,
                titulo: 'Leyes',
                descripcion:
                    'Repositorio con todas las leyes de Venezuela ordenadas: '
                    'Constitución, COPP, Código Penal y más, con su articulado.',
                detalle: 'Listado completo · Artículos · Búsqueda',
                onTap: _abrirLeyes,
              ),
              const SizedBox(height: 14),
              _buildHerramienta(
                context,
                icon: Icons.manage_search,
                titulo: 'Glosario',
                descripcion:
                    'Definiciones claras de los términos y conceptos del '
                    'derecho penal venezolano.',
                detalle: 'Términos · Definiciones · Alfabético',
                onTap: _abrirGlosario,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHerramienta(
    BuildContext context, {
    required IconData icon,
    required String titulo,
    required String descripcion,
    required String detalle,
    required VoidCallback onTap,
  }) {
    final Color acento = TemaGlobal.isDark
        ? TemaGlobal.dorado
        : TemaGlobal.azulMarino;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: TemaGlobal.tarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: acento.withValues(alpha: 0.28),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: acento.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: acento.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: acento, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: TemaGlobal.texto,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        descripcion,
                        style: TextStyle(
                          fontSize: 13,
                          color: TemaGlobal.textoSecundario,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        detalle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: acento,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: acento,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
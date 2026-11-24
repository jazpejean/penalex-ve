import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../utils/main_tab_controller.dart';
import 'glosario_screen.dart';
import 'repositorio_jurisprudencia_screen.dart';
import 'repositorio_leyes_screen.dart';
import '../config/app_colors.dart';
import '../config/app_tokens.dart';
import '../widgets/app_screen_header.dart';

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
              const AppScreenHeader(
                titulo: 'Consulta Jurídica',
                subtitulo:
                    'Tres herramientas por separado: fallos, leyes y términos.',
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: TemaGlobal.tarjeta,
        borderRadius: BorderRadius.circular(AppTokens.radioTarjeta),
        border: Border.all(color: TemaGlobal.capa),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radioTarjeta),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: TemaGlobal.campoTexto,
                    borderRadius: BorderRadius.circular(AppTokens.radioControl),
                    border: Border.all(color: TemaGlobal.capa),
                  ),
                  child: Icon(icon, color: AppColors.azulMarino, size: 24),
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
                          fontWeight: FontWeight.w700,
                          color: TemaGlobal.texto,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        descripcion,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: TemaGlobal.textoSecundario,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        detalle,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: TemaGlobal.textoTenue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: TemaGlobal.textoTenue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'detector_vicios_screen.dart';
import 'escanear_documento_screen.dart';
import 'redactor_documentos_screen.dart';
import 'chat_legal_screen.dart';
import 'buscador_juridico_screen.dart';
import 'package:provider/provider.dart';

import '../services/haptics_service.dart';
import '../services/auth_service.dart';
import '../services/agenda_service.dart';
import '../models/audiencia.dart';
import '../config/app_theme.dart';
import '../utils/main_tab_controller.dart';
import '../config/app_colors.dart';
import '../config/app_tokens.dart';
import '../widgets/app_screen_header.dart';

/// Pantalla principal (tab Inicio) — rediseño premium navy+oro:
/// header con saludo y avatar, stats reales, hero Ulpiano, accesos
/// rápidos asimétricos y próxima audiencia. Datos de audiencias reales
/// desde [AgendaService]; si no hay datos, muestra placeholders elegantes.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Audiencia> _audiencias = const [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final ahora = DateTime.now();
    try {
      final audiencias = await AgendaService.cargarAudiencias(
        DateTime(ahora.year, ahora.month),
      );
      if (!mounted) return;
      setState(() {
        _audiencias = audiencias;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  /// Navega desde el dashboard manteniendo la bottom bar siempre visible:
  /// - rutas-pestaña (agenda, asistente) cambian el tab del MainScreen;
  /// - las 3 rutas de consulta abren la pestaña "Buscar" (hub) y este abre
  ///   la herramienta correspondiente (Jurisprudencias / Leyes / Glosario);
  /// - herramientas externas (calculadora, mapa, quiz) se apilan con la barra.
  void _navegar(BuildContext context, String route) {
    Haptics.tap();
    switch (route) {
      case '/repositorio_jurisprudencia':
      case '/repositorio_leyes':
      case '/glosario':
      case '/prescripcion':
      case '/escaner':
        Navigator.pushNamed(context, route);
      default:
        navegarDesdeMain(context, route);
    }
  }

  List<Audiencia> get _proximas {
    final hoy = DateTime.now();
    final lista = _audiencias.where((a) => !a.fecha.isBefore(hoy)).toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    return lista;
  }

  List<Audiencia> get _proximas7Dias {
    final hoy = DateTime.now();
    final limite = hoy.add(const Duration(days: 7));
    return _audiencias
        .where((a) => !a.fecha.isBefore(hoy) && !a.fecha.isAfter(limite))
        .toList();
  }

  Audiencia? get _siguiente => _proximas.isEmpty ? null : _proximas.first;

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return 'U';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    final String nombreUsuario = user?.displayName ?? 'Usuario';

    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildHeader(context, nombreUsuario),
              const SizedBox(height: 14),
              _buildBuscadorGlobal(context),
              const SizedBox(height: 20),
              _buildStats(),
              const SizedBox(height: 20),
              _buildHeroUlpiano(context),
              const SizedBox(height: 16),
              _buildAccionesRapidas(context),
              const SizedBox(height: 24),
              _buildSeccionTitulo(context, 'Herramientas de Cálculo'),
              const SizedBox(height: 12),
              _buildHerramientasCalculo(context),
              const SizedBox(height: 24),
              _buildSeccionTitulo(context, 'Tu Despacho Digital'),
              const SizedBox(height: 12),
              _buildDespacho(context),
              const SizedBox(height: 24),
              _buildSeccionTitulo(context, 'Próxima Audiencia'),
              const SizedBox(height: 12),
              _buildProximaAudiencia(context),
              const SizedBox(height: 24),
              _buildSeccionTitulo(context, 'Explorar'),
              const SizedBox(height: 12),
              _buildExplorar(context),
              const SizedBox(height: 20),
              _buildDetectorVicios(context),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Header
  String _capitalizar(String texto) {
    return texto
        .split(' ')
        .map((String p) => p.isEmpty
            ? p
            : p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }

  Widget _buildBuscadorGlobal(BuildContext context) {
    return InkWell(
      onTap: () => _abrir(context, const BuscadorJuridicoScreen()),
      borderRadius: BorderRadius.circular(AppTokens.radioControl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: TemaGlobal.tarjeta,
          borderRadius: BorderRadius.circular(AppTokens.radioControl),
          border: Border.all(color: TemaGlobal.capa),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.search, size: 20, color: TemaGlobal.textoSecundario),
            const SizedBox(width: 10),
            Text(
              'Buscar sentencias, leyes o artículos',
              style: TextStyle(fontSize: 14, color: TemaGlobal.textoTenue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccionesRapidas(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _accionRapida(
            context,
            Icons.auto_awesome,
            'Consultar',
            () => _abrir(context, const ChatLegalScreen()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _accionRapida(
            context,
            Icons.edit_document,
            'Redactar',
            () => _abrir(context, const RedactorDocumentosScreen()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _accionRapida(
            context,
            Icons.document_scanner_outlined,
            'Escanear',
            () => _abrir(context, const EscanearDocumentoScreen()),
          ),
        ),
      ],
    );
  }

  Widget _accionRapida(
    BuildContext context,
    IconData icono,
    String texto,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radioControl),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: TemaGlobal.tarjeta,
          borderRadius: BorderRadius.circular(AppTokens.radioControl),
          border: Border.all(color: TemaGlobal.capa),
        ),
        child: Column(
          children: <Widget>[
            Icon(icono, size: 22, color: AppColors.azulMarino),
            const SizedBox(height: 6),
            Text(
              texto,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: TemaGlobal.texto,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrir(BuildContext context, Widget pantalla) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => pantalla),
    );
  }

  Widget _buildHeader(BuildContext context, String nombreUsuario) {
    final iniciales = _iniciales(nombreUsuario);
    return AppScreenHeader(
      titulo: 'Hola, ${_capitalizar(nombreUsuario)}',
      subtitulo: 'Tu resumen de hoy',
      acciones: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.azulMarino,
            borderRadius: BorderRadius.circular(AppTokens.radioControl),
            border: Border.all(color: AppColors.dorado, width: 2),
          ),
          child: Center(
            child: Text(
              iniciales,
              style: const TextStyle(
                color: AppColors.dorado,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- Stats
  Widget _buildStats() {
    final audienciasMes = _audiencias.length;
    final proximas7 = _proximas7Dias.length;
    final hayCritico = proximas7 > 0;
    return Row(
      children: <Widget>[
        Expanded(
          child: _buildStatCard(
            icon: Icons.folder_open,
            valor: _cargando ? '…' : '$audienciasMes',
            etiqueta: 'Audiencias este mes',
            color: AppColors.azulMarino,
            bg: TemaGlobal.campoTexto,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.gavel,
            valor: _cargando ? '…' : '$proximas7',
            etiqueta: 'Próximos 7 días',
            color: hayCritico ? AppColors.error : AppColors.azulMarino,
            bg: hayCritico
                ? AppColors.error.withValues(alpha: AppColors.a12)
                : TemaGlobal.campoTexto,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String valor,
    required String etiqueta,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaGlobal.tarjeta,
        borderRadius: BorderRadius.circular(AppTokens.radioTarjeta),
        border: Border.all(color: TemaGlobal.capa),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppTokens.radioControl),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: TemaGlobal.texto,
                  ),
                ),
                Text(
                  etiqueta,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: TemaGlobal.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------- Hero Ulpiano
  Widget _buildHeroUlpiano(BuildContext context) {
    return GestureDetector(
      onTap: () => _navegar(context, '/asistente_legal'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.azulMarino,
          borderRadius: BorderRadius.circular(24),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.azulMarino.withValues(alpha: 0.35),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.dorado.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTokens.radioTarjeta),
              ),
              child: const Text(
                'ASISTENTE IA',
                style: TextStyle(
                  color: AppColors.dorado,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ulpiano',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Consulta jurisprudencia, redacta escritos y analiza tu caso en segundos.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.dorado,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.forum, color: AppColors.onDorado, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Hablar con Ulpiano',
                    style: TextStyle(
                      color: AppColors.onDorado,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------- Sección genérica
  Widget _buildSeccionTitulo(BuildContext context, String titulo) {
    return Text(titulo, style: AppTokens.tituloSeccion);
  }

  // ------------------------------------------- Herramientas de Cálculo
  Widget _buildHerramientasCalculo(BuildContext context) {
    return Column(
      children: <Widget>[
        // Dosimetría Penal: motor completo + informe PDF
        _buildToolWide(
          context,
          icon: Icons.calculate,
          titulo: 'Dosimetría Penal',
          subtitulo: 'Pena individualizada, concurso y cómputo — con informe PDF detallado',
          route: '/calculadora',
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _buildToolSmall(
                context,
                icon: Icons.hourglass_empty,
                titulo: 'Prescripción',
                subtitulo: '¿Cuándo prescribe la causa? Lapsos exactos',
                route: '/prescripcion',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildToolSmall(
                context,
                icon: Icons.menu_book,
                titulo: 'Leyes',
                subtitulo: 'Código Penal, COPP y leyes vigentes',
                route: '/repositorio_leyes',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------- Tu Despacho Digital
  Widget _buildDespacho(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _buildToolSmall(
            context,
            icon: Icons.document_scanner,
            titulo: 'Escáner',
            subtitulo: 'Digitaliza documentos y guárdalos en tu expediente',
            route: '/escaner',
            alto: 150,
            maxLinesSub: 2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildToolSmall(
            context,
            icon: Icons.calendar_month,
            titulo: 'Agenda',
            subtitulo: 'Audiencias, lapsos y días sin despacho',
            route: '/agenda',
            alto: 150,
            maxLinesSub: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildToolWide(BuildContext context, {
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => _navegar(context, route),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: TemaGlobal.tarjeta,
          borderRadius: BorderRadius.circular(AppTokens.radioTarjeta),
          border: Border.all(color: TemaGlobal.capa),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            _buildIconBox(icon),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: TemaGlobal.texto,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      fontSize: 12,
                      color: TemaGlobal.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: TemaGlobal.textoSecundario,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolSmall(BuildContext context, {
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required String route,
    double? alto,
    int maxLinesSub = 1,
  }) {
    return GestureDetector(
      onTap: () => _navegar(context, route),
      child: Container(
        width: double.infinity,
        height: alto,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TemaGlobal.tarjeta,
          borderRadius: BorderRadius.circular(AppTokens.radioTarjeta),
          border: Border.all(color: TemaGlobal.capa),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildIconBox(icon),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: TemaGlobal.texto,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitulo,
              maxLines: maxLinesSub,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.35,
                color: TemaGlobal.textoSecundario,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBox(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: TemaGlobal.campoTexto,
        borderRadius: BorderRadius.circular(AppTokens.radioControl),
        border: Border.all(color: TemaGlobal.capa),
      ),
      child: Icon(icon, size: 24, color: AppColors.azulMarino),
    );
  }

  // ------------------------------------------------- Próxima audiencia
  Widget _buildProximaAudiencia(BuildContext context) {
    final siguiente = _siguiente;
    if (_cargando) {
      return _buildAudienciaCardPlaceholder();
    }
    if (siguiente == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: TemaGlobal.tarjeta,
          borderRadius: BorderRadius.circular(AppTokens.radioTarjeta),
          border: Border.all(color: TemaGlobal.capa),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.dorado.withValues(alpha: AppColors.a12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.event_available,
                  color: AppColors.dorado, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Sin audiencias próximas',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: TemaGlobal.texto,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Agenda una audiencia para verla aquí',
                    style: TextStyle(
                      fontSize: 12,
                      color: TemaGlobal.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final dia = siguiente.fecha.day;
    final mes = _mesAbrev(siguiente.fecha);
    final tipo = siguiente.tipo?.isNotEmpty == true
        ? siguiente.tipo!
        : 'Audiencia';
    final hora = siguiente.hora.isNotEmpty
        ? '${siguiente.hora} • '
        : '';
    final tribunal = siguiente.tribunal?.isNotEmpty == true
        ? siguiente.tribunal!
        : 'Sin tribunal';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TemaGlobal.tarjeta,
        borderRadius: BorderRadius.circular(AppTokens.radioTarjeta),
        border: Border.all(color: TemaGlobal.capa),
      ),
      child: Row(
        children: <Widget>[
          // Fecha en bloque dorado
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.dorado.withValues(alpha: AppColors.a12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: <Widget>[
                Text(
                  '$dia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dorado,
                  ),
                ),
                Text(
                  mes,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dorado,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  tipo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: TemaGlobal.texto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$hora$tribunal',
                  style: TextStyle(
                    fontSize: 12,
                    color: TemaGlobal.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: TemaGlobal.textoSecundario,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildAudienciaCardPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TemaGlobal.tarjeta,
        borderRadius: BorderRadius.circular(AppTokens.radioTarjeta),
        border: Border.all(color: TemaGlobal.capa),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.dorado.withValues(alpha: AppColors.a12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.event_available,
                color: AppColors.dorado, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 140,
                  height: 12,
                  decoration: BoxDecoration(
                    color: TemaGlobal.capa,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 90,
                  height: 10,
                  decoration: BoxDecoration(
                    color: TemaGlobal.capa,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _mesAbrev(DateTime fecha) {
    const meses = <String>[
      'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
    ];
    return meses[fecha.month - 1];
  }

  // ------------------------------------------------------------ Explorar
  Widget _buildExplorar(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            children: <Widget>[
              _buildToolSmall(
                context,
                icon: Icons.account_balance,
                titulo: 'Jurisprudencia',
                subtitulo: 'Sentencias de la Sala de Casación Penal y Constitucional',
                route: '/repositorio_jurisprudencia',
                alto: 150,
                maxLinesSub: 2,
              ),
              const SizedBox(height: 12),
              _buildToolSmall(
                context,
                icon: Icons.map,
                titulo: 'Tribunales',
                subtitulo: 'Mapa con tribunales por estado y materia',
                route: '/mapa_tribunales',
                alto: 150,
                maxLinesSub: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: <Widget>[
              _buildToolSmall(
                context,
                icon: Icons.menu_book,
                titulo: 'Glosario',
                subtitulo: 'Términos jurídicos en lenguaje claro',
                route: '/glosario',
                alto: 150,
                maxLinesSub: 2,
              ),
              const SizedBox(height: 12),
              _buildToolSmall(
                context,
                icon: Icons.quiz,
                titulo: 'Desafío Penal',
                subtitulo: 'Rangos, rachas y XP: demuestra tu estrategia',
                route: '/quiz_lobby',
                alto: 150,
                maxLinesSub: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------- Detector de Vicios
  Widget _buildDetectorVicios(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const DetectorViciosScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.azulMarino, Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTokens.radioTarjeta),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.azulMarino.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.dorado.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTokens.radioTarjeta),
              ),
              child: const Icon(Icons.gavel, color: AppColors.dorado, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Text(
                        'Detector de Vicios',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dorado,
                          borderRadius: BorderRadius.circular(AppTokens.radioControl),
                        ),
                        child: const Text(
                          'PROXIMAMENTE',
                          style: TextStyle(
                            color: AppColors.onDorado,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Procesales: detecta vicios y nulidades en tu expediente con IA',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.6),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../models/audiencia.dart';
import '../models/documento_escaneado.dart';
import '../models/expediente.dart';
import '../services/documentos_service.dart';
import '../services/expediente_service.dart';
import '../services/haptics_service.dart';
import '../widgets/app_bar_institucional.dart';
import '../widgets/app_snackbar.dart';
import 'calendario_judicial_screen.dart';
import 'escanear_documento_screen.dart';
import 'redactor_documentos_screen.dart';

/// Workspace del Expediente (portafolio de una causa penal).
///
/// Muestra el resumen de la causa (hero navy), la alerta de lapso
/// crítico, el portafolio de documentos (subir + ver) y las acciones
/// de IA (Detector de Vicios y Redactor). Se abre desde la tarjeta de
/// la audiencia en la Agenda. El expediente se asegura en Supabase al
/// agendar la audiencia ([ExpedienteService.asegurarExpediente]).
class ExpedienteScreen extends StatefulWidget {
  const ExpedienteScreen({super.key, required this.audiencia});

  final Audiencia audiencia;

  @override
  State<ExpedienteScreen> createState() => _ExpedienteScreenState();
}

class _ExpedienteScreenState extends State<ExpedienteScreen> {
  final DocumentosService _documentosService = DocumentosService();
  Expediente? _expediente;
  List<DocumentoEscaneado> _documentos = <DocumentoEscaneado>[];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    unawaited(_cargar());
  }

  Future<void> _cargar() async {
    final aud = widget.audiencia;
    final Expediente? exp = await ExpedienteService.asegurarExpediente(
      numeroExpediente: aud.expediente,
      imputado: aud.imputado,
      cedula: aud.cedula,
      delitos: aud.delitos,
      tribunalId: aud.tribunalId,
      tribunalNombre: aud.tribunal,
      fechaAudiencia: aud.fecha,
    );
    final List<DocumentoEscaneado> docs =
        await _documentosService.obtenerDocumentos();
    if (!mounted) return;
    setState(() {
      _expediente = exp;
      _documentos = docs
          .where((DocumentoEscaneado d) => d.expedienteId == exp?.id)
          .toList();
      _cargando = false;
    });
  }

  void _abrirLapsos() {
    Haptics.tap();
    final aud = widget.audiencia;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CalendarioJudicialScreen(
          expediente: aud.expediente,
          imputado: aud.imputado,
          fechaBase: aud.fecha,
          tribunalId: aud.tribunalId,
        ),
      ),
    );
  }

  void _subirDocumento() async {
    Haptics.tap();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const EscanearDocumentoScreen(),
      ),
    );
    // Al volver, refresca el portafolio (el escáner guarda con
    // expediente_id cuando se abrió desde aquí; si no pudo vincularlo,
    // se muestra en "Sin vincular").
    await _cargar();
  }

  void _redactarEscrito() {
    Haptics.tap();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const RedactorDocumentosScreen(),
      ),
    );
  }

  void _detectorVicios() {
    Haptics.tap();
    AppSnackBar.success(context, 'Detector de Vicios: próximamente');
  }

  @override
  Widget build(BuildContext context) {
    final aud = widget.audiencia;
    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
      appBar: AppBarInstitucional(
        title: 'Expediente',
        mostrarBack: true,

      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildCaseHero(aud),
                  const SizedBox(height: 24),
                  _buildSeccionTitulo(context, 'Lapsos Procesales'),
                  const SizedBox(height: 12),
                  _buildLapsoCard(),
                  const SizedBox(height: 24),
                  _buildSeccionTitulo(context, 'Portafolio del Caso',
                      accion: 'Subir', onAccion: _subirDocumento),
                  const SizedBox(height: 12),
                  if (_documentos.isEmpty)
                    _buildPortafolioVacio()
                  else
                    ..._documentos.map(_buildDocItem),
                  const SizedBox(height: 24),
                  _buildSeccionTitulo(context, 'Inteligencia Artificial'),
                  const SizedBox(height: 12),
                  _buildAiGrid(),
                ],
              ),
            ),
      floatingActionButton: _buildFabUlpiano(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ------------------------------------------------------ Hero del caso
  Widget _buildCaseHero(Audiencia aud) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.azulMarino, Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.azulMarino.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Badge de estado: solo si el usuario definió uno; si no,
          // badge neutral de portafolio (no se inventa estado procesal).
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.dorado.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _expediente?.estadoProcesal?.isNotEmpty == true
                  ? _expediente!.estadoProcesal!.toUpperCase()
                  : 'EXPEDIENTE ACTIVO',
              style: const TextStyle(
                color: AppColors.dorado,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            aud.expediente,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            aud.imputado,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: <Widget>[
              if (aud.delitos?.isNotEmpty == true)
                _buildHeroMeta(Icons.gavel, aud.delitos!),
              if (aud.tribunal?.isNotEmpty == true)
                _buildHeroMeta(Icons.account_balance, aud.tribunal!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMeta(IconData icon, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 16),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------- Lapso crítico
  Widget _buildLapsoCard() {
    // La alerta de lapso crítico se calcula en el Calendario Judicial
    // (motor de lapsos); aquí se muestra la tarjeta que lleva a él.
    return GestureDetector(
      onTap: _abrirLapsos,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TemaGlobal.tarjeta,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TemaGlobal.capa),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),
            Icon(Icons.timer, color: AppColors.error, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Lapsos de la causa',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: TemaGlobal.texto,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Cómputo según la vía procesal (continuo, hábil o de '
                    'despacho). Toca para ver el calendario judicial.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
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

  // ------------------------------------------------------- Portafolio
  Widget _buildPortafolioVacio() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TemaGlobal.tarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaGlobal.capa),
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.folder_open,
              color: TemaGlobal.textoSecundario, size: 40),
          const SizedBox(height: 8),
          Text(
            'Sin documentos todavía',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: TemaGlobal.texto,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Sube fotos o PDFs del expediente físico',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: TemaGlobal.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocItem(DocumentoEscaneado doc) {
    final bool esPdf = doc.titulo.toLowerCase().contains('pdf') ||
        doc.paginasUrls.any((String u) => u.toLowerCase().endsWith('.pdf'));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaGlobal.tarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaGlobal.capa),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.dorado.withValues(alpha: AppColors.a12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              esPdf ? Icons.picture_as_pdf : Icons.image,
              color: AppColors.dorado,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  doc.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TemaGlobal.texto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${doc.paginasUrls.length} página(s) · '
                  '${_fechaAmigable(doc.fechaCreacion)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: TemaGlobal.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.visibility,
              color: TemaGlobal.textoSecundario, size: 20),
        ],
      ),
    );
  }

  String _fechaAmigable(DateTime fecha) {
    final DateTime ahora = DateTime.now();
    final DateTime inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final DateTime hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final int dias = hoy.difference(inicio).inDays;
    if (dias == 0) return 'hoy';
    if (dias == 1) return 'ayer';
    if (dias < 7) return 'hace $dias días';
    const meses = <String>[
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${fecha.day} ${meses[fecha.month - 1]}';
  }

  // ------------------------------------------------- Acciones de IA
  Widget _buildAiGrid() {
    return Row(
      children: <Widget>[
        Expanded(
          child: _buildAiButton(
            icon: Icons.policy,
            titulo: 'Detector de Vicios',
            descripcion: 'Analizar nulidades',
            onTap: _detectorVicios,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAiButton(
            icon: Icons.edit_document,
            titulo: 'Redactar Escrito',
            descripcion: 'Borrador con contexto',
            onTap: _redactarEscrito,
          ),
        ),
      ],
    );
  }

  Widget _buildAiButton({
    required IconData icon,
    required String titulo,
    required String descripcion,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TemaGlobal.tarjeta,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TemaGlobal.capa),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.dorado.withValues(alpha: AppColors.a12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.dorado, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: TemaGlobal.texto,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              descripcion,
              style: TextStyle(
                fontSize: 11,
                color: TemaGlobal.textoSecundario,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------- FAB Ulpiano
  Widget _buildFabUlpiano() {
    return FloatingActionButton.extended(
      backgroundColor: AppColors.dorado,
      foregroundColor: AppColors.onDorado,
      elevation: 6,
      onPressed: () {
        Haptics.tap();
        AppSnackBar.success(
            context, 'Ulpiano sobre este caso: próximamente');
      },
      icon: const Icon(Icons.forum, size: 22),
      label: const Text(
        'Preguntar a Ulpiano',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    );
  }

  // ----------------------------------------------------- Secciones
  Widget _buildSeccionTitulo(BuildContext context, String titulo,
      {String? accion, VoidCallback? onAccion}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          titulo,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: TemaGlobal.texto,
          ),
        ),
        if (accion != null)
          GestureDetector(
            onTap: onAccion,
            child: Text(
              accion,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.dorado,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../services/haptics_service.dart';
import 'redactor_documentos_screen.dart';
import '../config/app_theme.dart';
import '../widgets/main_bottom_bar.dart';
import '../data/catalogo_vicios_procesales.dart';
import '../models/chat_message.dart';
import '../services/detector_vicios_service.dart';
import '../services/documentos_service.dart';
import '../services/deepseek_vision_service.dart';
import '../models/documento_escaneado.dart';
import '../providers/expediente_activo_provider.dart';
import '../widgets/selector_expediente_sheet.dart';
import 'package:provider/provider.dart';
import '../config/app_tokens.dart';
import '../widgets/app_screen_header.dart';

/// Detector de vicios procesales para autos, actas y sentencias.
///
/// Motor determinístico (catálogo + patrones) y análisis profundo con Ulpiano.
/// Herramienta de apoyo: el profesional verifica siempre contra el expediente.
class DetectorViciosScreen extends StatefulWidget {
  const DetectorViciosScreen({super.key});

  @override
  State<DetectorViciosScreen> createState() => _DetectorViciosScreenState();
}

class _DetectorViciosScreenState extends State<DetectorViciosScreen> {
  final _textoController = TextEditingController();
  final _scrollController = ScrollController();

  List<VicioDetectado> _detectados = const [];
  String? _analisisIA;
  List<VicioIA> _viciosIA = const [];
  String _resumenIA = '';
  String _prioridadIA = '';
  List<MessageSource> _fuentesIA = const [];
  bool _detectando = false;
  bool _analizandoIA = false;
  List<DocumentoEscaneado> _documentosExpediente = const [];
  bool _transcribiendo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final prov = context.read<ExpedienteActivoProvider>();
      if (!prov.tieneExpediente) {
        await SelectorExpedienteSheet.mostrar(context);
        if (!mounted) return;
      }
      _cargarDocumentosExpediente();
    });
  }

  Future<void> _cargarDocumentosExpediente() async {
    final prov = context.read<ExpedienteActivoProvider>();
    final exp = prov.expediente;
    if (exp == null) {
      if (mounted) setState(() => _documentosExpediente = const []);
      return;
    }
    try {
      final docs = await DocumentosService().obtenerDocumentos();
      if (!mounted) return;
      setState(() {
        _documentosExpediente = docs
            .where((d) => d.expedienteId == exp.id)
            .toList();
      });
    } catch (e) {
      debugPrint('⚠️ Docs del expediente: $e');
    }
  }

  /// Construye el contexto del expediente + sus documentos para la IA.
  String _contextoExpedienteParaIA() {
    final exp = context.read<ExpedienteActivoProvider>().expediente;
    if (exp == null) return '';
    final b = StringBuffer();
    b.writeln('Expediente: ${exp.numeroExpediente}');
    b.writeln('Imputado: ${exp.imputado}');
    if (exp.delitos != null && exp.delitos!.isNotEmpty) {
      b.writeln('Delitos: ${exp.delitos}');
    }
    if (exp.tribunalNombre != null && exp.tribunalNombre!.isNotEmpty) {
      b.writeln('Tribunal: ${exp.tribunalNombre}');
    }
    if (exp.estadoProcesal != null && exp.estadoProcesal!.isNotEmpty) {
      b.writeln('Estado procesal: ${exp.estadoProcesal}');
    }
    if (_documentosExpediente.isNotEmpty) {
      b.writeln('Documentos del portafolio (${_documentosExpediente.length}):');
      for (final d in _documentosExpediente.take(8)) {
        final txt = (d.textoOcr ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
        b.writeln('- ${d.titulo}${txt.isNotEmpty ? ': ${txt.length > 600 ? '${txt.substring(0, 600)}…' : txt}' : ''}');
      }
    }
    return b.toString();
  }

  @override
  void dispose() {
    _textoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _detectar() {
    final texto = _textoController.text.trim();
    if (texto.length < 40) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pega el texto del auto, acta o sentencia (mínimo 40 caracteres).'),
        ),
      );
      return;
    }
    setState(() {
      _detectando = true;
      _analisisIA = null;
      _fuentesIA = const [];
    });
    final resultados = DetectorViciosService.detectarDeterministico(texto);
    setState(() {
      _detectados = resultados;
      _detectando = false;
    });
    if (resultados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se detectaron patrones de vicios. Prueba el análisis profundo con IA.',
          ),
        ),
      );
    }
  }

  /// Toma o elige una foto del documento y la transcribe con el modelo de
  /// visión de DeepSeek (deepseek-flash), rellenando el campo de texto.
  Future<void> _adjuntarFoto() async {
    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: TemaGlobal.tarjeta,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radioTarjeta)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera,
                  color: TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino),
              title: Text('Tomar foto', style: TextStyle(color: TemaGlobal.texto)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library,
                  color: TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino),
              title: Text('Elegir de galería',
                  style: TextStyle(color: TemaGlobal.texto)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (origen == null || !mounted) return;

    final picker = ImagePicker();
    final List<XFile> fotos;
    if (origen == ImageSource.camera) {
      final foto = await picker.pickImage(source: origen, imageQuality: 92);
      fotos = foto == null ? <XFile>[] : <XFile>[foto];
    } else {
      fotos = await picker.pickMultiImage(imageQuality: 92);
    }
    if (fotos.isEmpty) return;

    setState(() => _transcribiendo = true);
    final rutas = fotos.map((f) => f.path).toList();
    final texto = await DeepSeekVisionService.transcribirDocumento(
      rutasImagenes: rutas,
    );
    if (!mounted) return;
    setState(() {
      _transcribiendo = false;
      if (!texto.startsWith('⚠️') && !texto.startsWith('❌')) {
        final actual = _textoController.text.trim();
        _textoController.text =
            actual.isEmpty ? texto : '$actual\n\n$texto';
      }
    });
    if (texto.startsWith('⚠️') || texto.startsWith('❌')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento transcrito. Revisa el texto y pulsa «Detectar vicios».')),
      );
    }
  }

  Future<void> _analizarIA() async {
    final texto = _textoController.text.trim();
    if (texto.length < 40) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pega el texto del documento primero.')),
      );
      return;
    }
    setState(() {
      _analizandoIA = true;
      _viciosIA = const [];
      _resumenIA = '';
      _prioridadIA = '';
    });
    final r = await DetectorViciosService.analizarConIAEstructurado(
      texto,
      contextoExpediente: _contextoExpedienteParaIA(),
    );
    if (!mounted) return;
    if (r.ok) {
      setState(() {
        _viciosIA = r.vicios;
        _resumenIA = r.resumen;
        _prioridadIA = r.prioridad;
        _analisisIA = null;
        _fuentesIA = const [];
        _analizandoIA = false;
      });
      return;
    }
    // Fallback: análisis profundo (RAG) si el JSON estructurado falló
    final textoIA = await DetectorViciosService.analizarConIA(
      texto,
      contextoExpediente: _contextoExpedienteParaIA(),
    );
    if (!mounted) return;
    setState(() {
      _analisisIA = textoIA.analisis;
      _fuentesIA = textoIA.fuentes;
      _analizandoIA = false;
    });
  }

  void _limpiar() {
    setState(() {
      _textoController.clear();
      _detectados = const [];
      _analisisIA = null;
      _viciosIA = const [];
      _resumenIA = '';
      _prioridadIA = '';
      _fuentesIA = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
      bottomNavigationBar: const MainBottomBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppTokens.margen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              _buildExpedienteChip(),
              const SizedBox(height: 12),
              _buildIntroCard(),
              const SizedBox(height: 18),
              _buildEntradaTexto(),
              const SizedBox(height: 10),
              _buildBotonFoto(),
              const SizedBox(height: 14),
              _buildBotones(),
              const SizedBox(height: 22),
              if (_detectando) const Center(child: CircularProgressIndicator()),
              if (_detectados.isNotEmpty) _buildResultadosDeterministicos(),
              if (_detectados.isNotEmpty || _viciosIA.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildAcciones(),
              ],
              if (_analizandoIA)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (_viciosIA.isNotEmpty || _resumenIA.isNotEmpty || _analisisIA != null) _buildResultadoIA(),
              if (_detectados.isEmpty && _viciosIA.isEmpty && _analisisIA == null && !_detectando && !_analizandoIA)
                _buildEstadoVacio(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        IconButton(
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.arrow_back, color: TemaGlobal.texto),
        ),
        Expanded(
          child: AppScreenHeader(
            titulo: 'Detector de vicios',
            subtitulo: 'Analiza autos y detecta nulidades',
          ),
        ),
        IconButton(
          tooltip: 'Limpiar',
          onPressed: _limpiar,
          icon: Icon(Icons.refresh, color: TemaGlobal.textoSecundario),
        ),
      ],
    );
  }

  Widget _buildExpedienteChip() {
    final prov = context.watch<ExpedienteActivoProvider>();
    final exp = prov.expediente;
    final activo = exp != null;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await SelectorExpedienteSheet.mostrar(context);
        if (!mounted) return;
        _cargarDocumentosExpediente();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: TemaGlobal.capa,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino)
                .withValues(alpha: activo ? 0.45 : 0.20),
          ),
        ),
        child: Row(
          children: [
            Icon(
              activo ? Icons.folder_special : Icons.folder_off_outlined,
              size: 20,
              color: activo
                  ? (TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino)
                  : TemaGlobal.textoTenue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activo ? prov.etiqueta : 'Consulta aislada (sin expediente)',
                    style: TextStyle(
                      color: TemaGlobal.texto,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    activo
                        ? '${_documentosExpediente.length} documento(s) en el portafolio · toca para cambiar'
                        : 'Toca para seleccionar un expediente',
                    style: TextStyle(
                      color: TemaGlobal.textoTenue,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.swap_horiz, size: 18, color: TemaGlobal.textoTenue),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TemaGlobal.tarjeta,
        borderRadius: BorderRadius.circular(AppTokens.radioTarjeta),
        border: Border.all(
          color: (TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino)
              .withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.gavel,
                color: TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pega el auto, acta o sentencia y detecta los vicios',
                  style: TextStyle(
                    color: TemaGlobal.texto,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'El detector cruza el texto con un catálogo de vicios del proceso '
            'penal venezolano (COPP arts. 174-180, 191-198; CRBV arts. 25, 44, '
            '47 y 49) e indica la norma, la gravedad y la acción procesal.',
            style: TextStyle(
              color: TemaGlobal.textoSecundario,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Herramienta de apoyo: verifica siempre contra el expediente y las '
            'fuentes oficiales.',
            style: TextStyle(
              color: TemaGlobal.textoTenue,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntradaTexto() {
    return TextField(
      controller: _textoController,
      maxLines: 10,
      minLines: 6,
      style: TextStyle(color: TemaGlobal.texto, fontSize: 14, height: 1.4),
      decoration: InputDecoration(
        hintText:
            'Ej.: «Se practicó la detención sin orden judicial… el acta no '
            'consta de testigos… se le negó la comunicación con su abogado…»',
        hintStyle: TextStyle(color: TemaGlobal.textoTenue, fontSize: 13),
        filled: true,
        fillColor: TemaGlobal.campoTexto,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radioTarjeta),
          borderSide: BorderSide(color: TemaGlobal.textoTenue.withValues(alpha: 0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radioTarjeta),
          borderSide: BorderSide(color: TemaGlobal.textoTenue.withValues(alpha: 0.25)),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildBotonFoto() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _transcribiendo ? null : _adjuntarFoto,
            icon: _transcribiendo
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.document_scanner, size: 18),
            label: Text(_transcribiendo
                ? 'Transcribiendo con IA de visión…'
                : 'Foto del documento (IA visión)'),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino,
              side: BorderSide(
                color: (TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino)
                    .withValues(alpha: 0.45),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotones() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _detectando || _analizandoIA ? null : _detectar,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Detectar vicios'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino,
              foregroundColor: TemaGlobal.isDark ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _detectando || _analizandoIA ? null : _analizarIA,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Análisis con IA'),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino,
              side: BorderSide(
                color: (TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino)
                    .withValues(alpha: 0.5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultadosDeterministicos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vicios detectados (${_detectados.length})',
          style: TextStyle(
            color: TemaGlobal.texto,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._detectados.map(_buildVicioCard),
      ],
    );
  }

  Widget _buildVicioCard(VicioDetectado d) {
    final esAbsoluta = d.vicio.gravedad.toLowerCase().contains('absoluta');
    final colorGravedad = esAbsoluta ? const Color(0xFFDC2626) : const Color(0xFFD97706);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: TemaGlobal.tarjeta,
        borderRadius: BorderRadius.circular(AppTokens.radioTarjeta),
        border: Border.all(color: colorGravedad.withValues(alpha: 0.35)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: TemaGlobal.textoSecundario,
          collapsedIconColor: TemaGlobal.textoSecundario,
          title: Text(
            d.vicio.titulo,
            style: TextStyle(
              color: TemaGlobal.texto,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _chip(d.vicio.gravedad, colorGravedad),
                _chip(d.vicio.categoria, TemaGlobal.textoSecundario),
                if (d.coincidencias > 1)
                  _chip('${d.coincidencias} indicios', TemaGlobal.textoSecundario),
              ],
            ),
          ),
          children: [
            _fila('Norma', d.vicio.norma),
            _fila('Cuándo alegar', d.vicio.momentoAlegar),
            _fila('Acción', d.vicio.accion),
            const SizedBox(height: 8),
            Text(
              d.vicio.descripcion,
              style: TextStyle(
                color: TemaGlobal.textoSecundario,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            if (d.evidencia.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TemaGlobal.capa,
                  borderRadius: BorderRadius.circular(AppTokens.radioControl),
                  border: Border(
                    left: BorderSide(
                      color: TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  '«${d.evidencia}»',
                  style: TextStyle(
                    color: TemaGlobal.textoSecundario,
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTokens.radioTarjeta),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        texto,
        style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _fila(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              etiqueta,
              style: TextStyle(
                color: TemaGlobal.textoTenue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(color: TemaGlobal.texto, fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultadoIA() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 20,
              color: TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino,
            ),
            const SizedBox(width: 8),
            Text(
              _viciosIA.isNotEmpty
                  ? 'Vicios detectados por IA (${_viciosIA.length})'
                  : 'Análisis con IA',
              style: TextStyle(
                color: TemaGlobal.texto,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (_resumenIA.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TemaGlobal.capa,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: TemaGlobal.textoTenue.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              _resumenIA,
              style: TextStyle(
                color: TemaGlobal.textoSecundario,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        ..._viciosIA.map(_buildVicioIACard),
        if (_prioridadIA.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TemaGlobal.tarjeta,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino)
                    .withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prioridad de ataque',
                  style: TextStyle(
                    color: TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _prioridadIA,
                  style: TextStyle(
                    color: TemaGlobal.texto,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_analisisIA != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TemaGlobal.tarjeta,
              borderRadius: BorderRadius.circular(AppTokens.radioTarjeta),
              border: Border.all(
                color: (TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino)
                    .withValues(alpha: 0.30),
              ),
            ),
            child: MarkdownBody(
              data: _analisisIA!,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: TemaGlobal.texto, fontSize: 14, height: 1.5),
                strong: TextStyle(
                  color: TemaGlobal.texto,
                  fontWeight: FontWeight.bold,
                ),
                h1: TextStyle(
                  color: TemaGlobal.texto,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                h2: TextStyle(
                  color: TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                h3: TextStyle(
                  color: TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                listBullet:
                    TextStyle(color: TemaGlobal.texto, fontSize: 14, height: 1.5),
              ),
            ),
          ),
        ],
        if (_fuentesIA.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Fuentes citadas (${_fuentesIA.length})',
            style: TextStyle(
              color: TemaGlobal.textoSecundario,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ..._fuentesIA.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    f.type == SourceType.jurisprudencia
                        ? Icons.account_balance
                        : Icons.menu_book,
                    size: 14,
                    color: TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${f.title}${f.reference.isNotEmpty ? ' — ${f.reference}' : ''}',
                      style: TextStyle(
                        color: TemaGlobal.textoSecundario,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVicioIACard(VicioIA v) {
    final esAbsoluta = v.gravedad.toLowerCase().contains('absoluta');
    final colorGravedad =
        esAbsoluta ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final colorConfianza = switch (v.confianza) {
      'alta' => const Color(0xFF059669),
      'baja' => const Color(0xFF6B7280),
      _ => const Color(0xFFD97706),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: TemaGlobal.tarjeta,
        borderRadius: BorderRadius.circular(AppTokens.radioTarjeta),
        border: Border.all(color: colorGravedad.withValues(alpha: 0.35)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: TemaGlobal.textoSecundario,
          collapsedIconColor: TemaGlobal.textoSecundario,
          title: Text(
            v.titulo,
            style: TextStyle(
              color: TemaGlobal.texto,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _chip(v.gravedad, colorGravedad),
                _chip('IA · ${v.confianza}', colorConfianza),
              ],
            ),
          ),
          children: [
            if (v.norma.isNotEmpty) _fila('Norma', v.norma),
            if (v.momento.isNotEmpty) _fila('Cuándo alegar', v.momento),
            if (v.accion.isNotEmpty) _fila('Acción', v.accion),
            if (v.evidencia.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TemaGlobal.capa,
                  borderRadius: BorderRadius.circular(AppTokens.radioControl),
                  border: Border(
                    left: BorderSide(
                      color: TemaGlobal.isDark
                          ? TemaGlobal.dorado
                          : TemaGlobal.azulMarino,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  '«${v.evidencia}»',
                  style: TextStyle(
                    color: TemaGlobal.textoSecundario,
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============ ACCIONES "JOYA" DEL DETECTOR ============

  /// Envía los vicios detectados al REDACTOR DE DOCUMENTOS (que tiene el
  /// editor). El detector solo detecta; la redacción del escrito corresponde
  /// al redactor.
  void _enviarAlRedactor() {
    final exp = context.read<ExpedienteActivoProvider>().expediente;
    final vicios = <String>[];
    for (final v in _detectados) {
      vicios.add(
          '- ${v.vicio.titulo} | ${v.vicio.norma} | ${v.vicio.gravedad} | Acción: ${v.vicio.accion}');
    }
    for (final v in _viciosIA) {
      vicios.add('- ${v.titulo} | ${v.norma} | ${v.gravedad} | Acción: ${v.accion}');
    }
    if (vicios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero detecta los vicios.')),
      );
      return;
    }

    final extracto = _textoController.text.trim();
    final instruccion = '''
Redacta un ESCRITO DE SOLICITUD DE NULIDAD ABSOLUTA ante el Juez de Control,
con fundamento en el artículo 179 del COPP y la Constitución.

DATOS DEL EXPEDIENTE:
${exp != null ? 'Expediente: ${exp.numeroExpediente}\nImputado: ${exp.imputado}\nDelitos: ${exp.delitos ?? 'no indicados'}\nTribunal: ${exp.tribunalNombre ?? 'no indicado'}' : 'Usa placeholders [EXPEDIENTE] y [IMPUTADO].'}

VICIOS DETECTADOS:
${vicios.join('\n')}

EXTRACTO DEL DOCUMENTO IMPUGNADO:
"""
${extracto.length > 4000 ? extracto.substring(0, 4000) : extracto}
"""

Estructura: encabezado con ciudadano y tribunal, I. DE LOS HECHOS, II. DEL DERECHO
(cada vicio con su norma y el fundamento de nulidad), III. PETITORIO (nulidad del
acto y de los actos consecutivos, artículo 180 del COPP), y cierre con firma.
Español jurídico venezolano sobrio; no inventes hechos distintos a los dados.
''';

    Haptics.tap();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RedactorDocumentosScreen(initialPrompt: instruccion),
      ),
    );
  }

  /// Exporta el análisis de vicios a PDF y lo comparte.
  Future<void> _exportarPdf() async {
    final exp = context.read<ExpedienteActivoProvider>().expediente;
    final pdf = pw.Document();
    final vicios = <(String, String, String, String)>[];
    for (final v in _detectados) {
      vicios.add((v.vicio.titulo, v.vicio.norma, v.vicio.gravedad, v.vicio.accion));
    }
    for (final v in _viciosIA) {
      vicios.add((v.titulo, v.norma, v.gravedad, v.accion));
    }
    if (vicios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay vicios detectados para exportar.')),
      );
      return;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text('Reporte de vicios procesales'),
          ),
          pw.Text(
            exp != null
                ? 'Expediente: ${exp.numeroExpediente} · Imputado: ${exp.imputado}'
                : 'Consulta aislada (sin expediente)',
            style: pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 12),
          for (final v in vicios) ...[
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(v.$1,
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 3),
                  pw.Text('Norma: ${v.$2}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Gravedad: ${v.$3}',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Acción: ${v.$4}',
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ],
          pw.SizedBox(height: 8),
          pw.Text(
            'Herramienta de apoyo. Verificar contra el expediente y las fuentes oficiales.',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final archivo = File(
        '${dir.path}/reporte_vicios_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await archivo.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(archivo.path)],
        text: 'Reporte de vicios procesales');
  }

  Widget _buildAcciones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Acciones sobre los vicios',
          style: TextStyle(
            color: TemaGlobal.texto,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _enviarAlRedactor,
                icon: const Icon(Icons.edit_document, size: 18),
                label: const Text('Enviar al redactor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino,
                  foregroundColor:
                      TemaGlobal.isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _exportarPdf,
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text('PDF'),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino,
                side: BorderSide(
                  color: (TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino)
                      .withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEstadoVacio() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(
            Icons.fact_check_outlined,
            size: 44,
            color: TemaGlobal.textoTenue.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'Pega un auto, acta o sentencia y pulsa «Detectar vicios».\n'
            'El catálogo cubre ${CatalogoViciosProcesales.completos.length} '
            'vicios típicos con su norma y acción procesal.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: TemaGlobal.textoTenue,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: CatalogoViciosProcesales.categorias
                .map(
                  (c) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: TemaGlobal.capa,
                      borderRadius: BorderRadius.circular(AppTokens.radioTarjeta),
                      border: Border.all(
                        color: TemaGlobal.textoTenue.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      c,
                      style: TextStyle(color: TemaGlobal.textoSecundario, fontSize: 11),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

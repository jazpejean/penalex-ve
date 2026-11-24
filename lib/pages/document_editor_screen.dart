import 'dart:io';

import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import 'package:provider/provider.dart';
import '../providers/expediente_activo_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../config/app_theme.dart';
import '../services/documentos_service.dart';
import '../services/deepseek_vision_service.dart';
import '../services/document_scanner_service_pro.dart';
import '../services/escaneo_service.dart';
import '../services/image_filter_service.dart';
import 'crop_adjust_screen.dart';
import '../config/app_tokens.dart';

/// Editor de documento escaneado, estilo CamScanner:
/// vista previa grande, tira de miniaturas, filtros, recorte manual,
/// rotar, reordenar, lectura con IA de visión y guardado.
class DocumentEditorScreen extends StatefulWidget {
  final List<String> paginas;
  final DocumentosService documentosService;

  const DocumentEditorScreen({
    super.key,
    required this.paginas,
    required this.documentosService,
  });

  @override
  State<DocumentEditorScreen> createState() => _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends State<DocumentEditorScreen> {


  final EscaneoService _escaneoService = EscaneoService();

  late List<String> _paginas;
  late List<String> _originales;
  int _paginaActual = 0;

  final TextEditingController _tituloController = TextEditingController();
  final PageController _pageController = PageController();

  bool _procesando = false;
  bool _guardando = false;
  String? _textoOcr;

  @override
  void initState() {
    super.initState();
    _paginas = List.from(widget.paginas);
    _originales = List.from(widget.paginas);
    final now = DateTime.now();
    _tituloController.text =
        'Documento ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------

  Future<void> _agregarPaginas() async {
    setState(() => _procesando = true);
    final nuevas = await _escaneoService.escanear();
    if (mounted) setState(() => _procesando = false);
    if (nuevas.isNotEmpty && mounted) {
      setState(() {
        _paginas.addAll(nuevas);
        _originales.addAll(nuevas);
        _paginaActual = _paginas.length - 1;
      });
      _pageController.jumpToPage(_paginaActual);
    }
  }

  Future<void> _rotar() async {
    if (_procesando) return;
    setState(() => _procesando = true);
    final nueva =
        await ImageFilterService.rotarImagen(_paginas[_paginaActual], 90);
    if (mounted) setState(() => _procesando = false);
    if (nueva != null && mounted) {
      setState(() => _paginas[_paginaActual] = nueva);
    }
  }

  Future<void> _aplicarFiltro(_Filtro filtro) async {
    Navigator.pop(context);
    if (_procesando) return;
    setState(() => _procesando = true);

    final original = _originales[_paginaActual];
    String? resultado;
    switch (filtro) {
      case _Filtro.original:
        resultado = original;
        break;
      case _Filtro.mejora:
        resultado = await ImageFilterService.optimizarParaDocumento(original);
        break;
      case _Filtro.blancoNegro:
        resultado = await ImageFilterService.aplicarBlancoYNegro(original);
        break;
      case _Filtro.nitidez:
        resultado = await ImageFilterService.aumentarNitidez(original);
        break;
    }

    if (mounted) setState(() => _procesando = false);
    if (resultado != null && mounted) {
      final r = resultado;
      setState(() => _paginas[_paginaActual] = r);
    }
  }

  Future<void> _recortar() async {
    if (_procesando) return;
    final corners = await DocumentScannerServicePro.detectEdgesManual(
      _paginas[_paginaActual],
    );
    if (corners == null || !mounted) return;

    final file = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (_) => CropAdjustScreen(
          imagePath: _paginas[_paginaActual],
          detectedCorners: corners,
        ),
      ),
    );

    if (file != null && mounted) {
      setState(() => _paginas[_paginaActual] = file.path);
    }
  }

  void _eliminarPagina() {
    if (_paginas.length <= 1) return;
    setState(() {
      _paginas.removeAt(_paginaActual);
      _originales.removeAt(_paginaActual);
      if (_paginaActual >= _paginas.length) {
        _paginaActual = _paginas.length - 1;
      }
    });
  }

  Future<void> _reordenar() async {
    final reordenadas = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: TemaGlobal.tarjeta,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radioTarjeta)),
      ),
      builder: (_) => _ReordenarPaginasSheet(paginas: _paginas),
    );

    if (reordenadas != null && mounted) {
      setState(() => _paginas = reordenadas);
    }
  }

  Future<void> _procesarOCR() async {
    if (_procesando) return;
    setState(() => _procesando = true);

    String texto = '';
    try {
      texto = await DeepSeekVisionService.transcribirDocumento(
        rutasImagenes: _paginas,
      );
      if (texto.startsWith('⚠️') || texto.startsWith('❌')) {
        texto = '';
      }
    } catch (e) {
      debugPrint('❌ Error con IA de visión: $e');
    }

    if (mounted) {
      setState(() {
        _textoOcr = texto.trim().isEmpty ? null : texto.trim();
        _procesando = false;
      });
      _mostrarTextoExtraido();
    }
  }

  void _mostrarTextoExtraido() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TemaGlobal.tarjeta,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radioTarjeta)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.text_fields, color: AppColors.acento),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Texto extraído (OCR)',
                      style: TextStyle(
                        color: TemaGlobal.texto,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: TemaGlobal.texto),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: TemaGlobal.capa, height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _textoOcr ?? 'No se extrajo texto',
                  style: TextStyle(
                    color: TemaGlobal.texto,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _descargarPdf() async {
    if (_paginas.isEmpty || _procesando) return;
    setState(() => _procesando = true);
    try {
      final pdf = pw.Document();
      final String fecha = DateTime.now().toIso8601String().substring(0, 10);
      for (int i = 0; i < _paginas.length; i++) {
        final bytes = File(_paginas[i]).readAsBytesSync();
        final bool ultima = i == _paginas.length - 1;
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (_) => pw.Column(
              children: <pw.Widget>[
                pw.Expanded(
                  child: pw.Image(pw.MemoryImage(bytes),
                      fit: pw.BoxFit.contain),
                ),
                if (ultima) ...<pw.Widget>[
                  pw.SizedBox(height: 18),
                  pw.Container(
                    width: 200,
                    padding: const pw.EdgeInsets.only(top: 4),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        top: pw.BorderSide(width: 0.6),
                      ),
                    ),
                    child: pw.Text('Firma del abogado',
                        style: pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey700)),
                  ),
                ],
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: <pw.Widget>[
                    pw.Text('Penalex VE',
                        style: pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey700)),
                    pw.Text('Generado el $fecha',
                        style: pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
          ),
        );
      }
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/documento_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      if (mounted) setState(() => _procesando = false);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Documento escaneado (PDF)');
    } catch (e) {
      debugPrint('❌ Error generando PDF: $e');
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _descargarImagen() async {
    if (_paginas.isEmpty) return;
    final archivos = _paginas.map((p) => XFile(p)).toList();
    await Share.shareXFiles(archivos, text: 'Imágenes escaneadas');
  }

  /// Galería con selección múltiple (ESC-11).
  Future<void> _agregarDeGaleria() async {
    final List<XFile> archivos =
        await ImagePicker().pickMultiImage(imageQuality: 90);
    if (archivos.isEmpty || !mounted) return;
    setState(() => _procesando = true);
    final List<String> nuevas = <String>[];
    for (final XFile f in archivos) {
      final int tamano = await File(f.path).length();
      // Compresión: páginas de más de 2 MB se reducen para el expediente.
      final String? optimizada = tamano > 2 * 1024 * 1024
          ? await ImageFilterService.comprimirImagen(f.path, quality: 82)
          : null;
      nuevas.add(optimizada ?? f.path);
    }
    if (!mounted) return;
    setState(() {
      _procesando = false;
      for (final String ruta in nuevas) {
        _paginas.add(ruta);
        _originales.add(ruta);
      }
      _paginaActual = _paginas.length - 1;
    });
    _pageController.jumpToPage(_paginaActual);
  }

  /// Mejora de imagen por página: binarización adaptativa Sauvola (ESC-12).
  Future<void> _mejorarPagina() async {
    if (_procesando) return;
    setState(() => _procesando = true);
    final String? mejorada =
        await ImageFilterService.binarizarDocumento(_paginas[_paginaActual]);
    if (!mounted) return;
    setState(() {
      _procesando = false;
      if (mejorada != null) _paginas[_paginaActual] = mejorada;
    });
  }

  /// Aplica un filtro a la página actual (ESC-12).
  Future<void> _aplicarFiltroDocumento(String modo) async {
    if (_procesando) return;
    final String rutaActual = _paginas[_paginaActual];
    if (modo == 'original') {
      setState(() => _paginas[_paginaActual] = _originales[_paginaActual]);
      return;
    }
    setState(() => _procesando = true);
    final String? resultado = modo == 'documento'
        ? await ImageFilterService.binarizarDocumento(rutaActual)
        : await ImageFilterService.aplicarBlancoYNegro(rutaActual);
    if (!mounted) return;
    setState(() {
      _procesando = false;
      if (resultado != null) _paginas[_paginaActual] = resultado;
    });
  }

  /// Reordenar páginas (ESC-03).
  Future<void> _abrirGestorPaginas() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TemaGlobal.tarjeta,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setSheet) {
            return SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.7,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: <Widget>[
                        Text('Páginas', style: AppTokens.tituloSeccion),
                        const Spacer(),
                        Text('${_paginas.length}',
                            style: TextStyle(color: TemaGlobal.textoSecundario)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      itemCount: _paginas.length,
                      onReorder: (int oldIndex, int newIndex) {
                        setSheet(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final String pagina = _paginas.removeAt(oldIndex);
                          _paginas.insert(newIndex, pagina);
                        });
                        setState(() => _paginaActual = newIndex.clamp(0, _paginas.length - 1));
                      },
                      itemBuilder: (BuildContext c, int i) {
                        return ListTile(
                          key: ValueKey<String>('${_paginas[i]}-$i'),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(AppTokens.radioControl),
                            child: Image.file(File(_paginas[i]),
                                width: 40, height: 52, fit: BoxFit.cover),
                          ),
                          title: Text('Página ${i + 1}'),
                          trailing: const Icon(Icons.drag_handle),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    setState(() => _guardando = true);

    final expedienteId =
        context.read<ExpedienteActivoProvider>().expediente?.id;
    final documento = await widget.documentosService.guardarDocumento(
      titulo: _tituloController.text.trim().isEmpty
          ? 'Documento'
          : _tituloController.text.trim(),
      rutasImagenesLocales: _paginas,
      textoOcr: _textoOcr,
      expedienteId: expedienteId,
    );

    if (!mounted) return;
    setState(() => _guardando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          documento != null
              ? '✅ Documento guardado'
              : '❌ Error guardando documento',
        ),
        backgroundColor: documento != null ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (documento != null) {
      Navigator.pop(context, {'guardado': true});
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.superficie,
      appBar: AppBar(
        backgroundColor: TemaGlobal.superficie,
        elevation: 0,
        iconTheme: IconThemeData(color: TemaGlobal.texto),
        title: TextField(
          controller: _tituloController,
          style: TextStyle(
              color: TemaGlobal.texto, fontSize: 18, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: 'Nombre del documento',
            hintStyle: TextStyle(color: TemaGlobal.textoTenue),
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Galería (varias páginas)',
            onPressed: _agregarDeGaleria,
          ),
          IconButton(
            icon: Icon(Icons.auto_fix_high, color: TemaGlobal.textoSecundario),
            tooltip: 'Mejorar documento (blanco y negro)',
            onPressed: _mejorarPagina,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.tune, color: TemaGlobal.textoSecundario),
            tooltip: 'Filtro de la página',
            onSelected: _aplicarFiltroDocumento,
            itemBuilder: (_) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'original', child: Text('Original')),
              PopupMenuItem<String>(
                  value: 'gris', child: Text('Escala de grises')),
              PopupMenuItem<String>(
                  value: 'documento', child: Text('Documento (blanco y negro)')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.view_carousel_outlined),
            tooltip: 'Reordenar páginas',
            onPressed: _abrirGestorPaginas,
          ),
          if (_guardando || _procesando)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.dorado),
                ),
              ),
            )
          else ...[
            IconButton(
              icon: Icon(Icons.picture_as_pdf, color: TemaGlobal.textoSecundario),
              tooltip: 'Descargar como PDF',
              onPressed: _descargarPdf,
            ),
            IconButton(
              icon: Icon(Icons.image, color: TemaGlobal.textoSecundario),
              tooltip: 'Descargar como imagen',
              onPressed: _descargarImagen,
            ),
            IconButton(
              icon: Icon(Icons.cloud_upload, color: TemaGlobal.textoSecundario),
              tooltip: 'Guardar en la nube',
              onPressed: _guardar,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildVistaPrevia()),
          _buildTiraMiniaturas(),
          _buildBarraAcciones(),
        ],
      ),
    );
  }

  Widget _buildVistaPrevia() {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: _paginas.length,
          onPageChanged: (i) => setState(() => _paginaActual = i),
          itemBuilder: (context, index) {
            return Center(
              child: InteractiveViewer(
                maxScale: 5,
                child: Image.file(
                  File(_paginas[index]),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, color: AppColors.dorado, size: 64),
                  ),
                ),
              ),
            );
          },
        ),
        if (_procesando)
          Positioned.fill(
            child: Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.dorado),
              ),
            ),
          ),
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppTokens.radioTarjeta),
            ),
            child: Text(
              '${_paginaActual + 1} / ${_paginas.length}',
              style: const TextStyle(
                color: AppColors.onAzulMarino,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTiraMiniaturas() {
    return Container(
      height: 96,
      color: AppColors.tarjeta,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _paginas.length + 1,
        itemBuilder: (context, index) {
          if (index == _paginas.length) {
            return _buildAgregarTile();
          }
          return _buildMiniatura(index);
        },
      ),
    );
  }

  Widget _buildMiniatura(int index) {
    final seleccionada = index == _paginaActual;
    return GestureDetector(
      onTap: () {
        _pageController.jumpToPage(index);
        setState(() => _paginaActual = index);
      },
      child: Container(
        width: 64,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: seleccionada ? AppColors.dorado : AppColors.capa,
            width: seleccionada ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            File(_paginas[index]),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.description, color: AppColors.textoSecundario),
          ),
        ),
      ),
    );
  }

  Widget _buildAgregarTile() {
    return GestureDetector(
      onTap: _agregarPaginas,
      child: Container(
        width: 64,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.dorado.withValues(alpha: AppColors.a48)),
          color: AppColors.azulMarino,
        ),
        child: const Icon(Icons.add, color: AppColors.dorado, size: 28),
      ),
    );
  }

  Widget _buildBarraAcciones() {
    return Container(
      color: AppColors.tarjeta,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _accion(Icons.add_photo_alternate_outlined, 'Agregar', _agregarPaginas),
          _accion(Icons.rotate_right, 'Rotar', _rotar),
          _accion(Icons.tune, 'Filtros', _mostrarFiltros),
          _accion(Icons.crop, 'Recortar', _recortar),
          _accion(Icons.swap_vert, 'Orden', _reordenar),
          _accion(Icons.text_fields, 'OCR', _procesarOCR),
          if (_paginas.length > 1)
            _accion(Icons.delete_outline, 'Quitar', _eliminarPagina),
        ],
      ),
    );
  }

  Widget _accion(IconData icono, String etiqueta, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: AppColors.acento, size: 24),
            const SizedBox(height: 2),
            Text(
              etiqueta,
              style: TextStyle(color: TemaGlobal.textoSecundario, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      backgroundColor: TemaGlobal.tarjeta,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radioTarjeta)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filtros',
                style: TextStyle(
                  color: TemaGlobal.texto,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _filtro(Icons.photo, 'Original', _Filtro.original),
                  _filtro(Icons.auto_fix_high, 'Mejora', _Filtro.mejora),
                  _filtro(Icons.filter_b_and_w, 'B/N', _Filtro.blancoNegro),
                  _filtro(Icons.blur_on, 'Nitidez', _Filtro.nitidez),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filtro(IconData icono, String etiqueta, _Filtro filtro) {
    return InkWell(
      onTap: () => _aplicarFiltro(filtro),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: AppColors.acento, size: 32),
            const SizedBox(height: 8),
            Text(etiqueta, style: TextStyle(color: TemaGlobal.textoSecundario)),
          ],
        ),
      ),
    );
  }
}

enum _Filtro { original, mejora, blancoNegro, nitidez }

/// Bottom sheet para reordenar páginas arrastrando.
class _ReordenarPaginasSheet extends StatefulWidget {
  final List<String> paginas;
  const _ReordenarPaginasSheet({required this.paginas});

  @override
  State<_ReordenarPaginasSheet> createState() => _ReordenarPaginasSheetState();
}

class _ReordenarPaginasSheetState extends State<_ReordenarPaginasSheet> {
  late List<String> _paginas;

  @override
  void initState() {
    super.initState();
    _paginas = List.from(widget.paginas);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Reordenar páginas',
                  style: TextStyle(
                    color: TemaGlobal.texto,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context, _paginas),
                  child: const Text(
                    'Listo',
                    style: TextStyle(
                      color: AppColors.dorado,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              itemCount: _paginas.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _paginas.removeAt(oldIndex);
                  _paginas.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                return Container(
                  key: ValueKey(_paginas[index]),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TemaGlobal.capa,
                    borderRadius: BorderRadius.circular(AppTokens.radioControl),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(_paginas[index]),
                          width: 48,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.description,
                            color: TemaGlobal.textoTenue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Página ${index + 1}',
                          style: TextStyle(color: TemaGlobal.texto),
                        ),
                      ),
                      Icon(Icons.drag_handle, color: TemaGlobal.textoTenue),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

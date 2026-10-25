import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_theme.dart';

import '../models/documento_escaneado.dart';
import '../services/documentos_service.dart';
import '../services/escaneo_service.dart';
import '../services/pdf_export_service.dart';
import '../widgets/main_bottom_bar.dart';
import 'document_editor_screen.dart';

/// Lista de documentos escaneados (repositorio del escáner).
class EscanearDocumentoScreen extends StatefulWidget {
  const EscanearDocumentoScreen({super.key});

  @override
  State<EscanearDocumentoScreen> createState() =>
      _EscanearDocumentoScreenState();
}

class _EscanearDocumentoScreenState extends State<EscanearDocumentoScreen> {
  final DocumentosService _documentosService = DocumentosService();
  final EscaneoService _escaneoService = EscaneoService();

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  /// Acento de marca: azul marino en modo claro, dorado en modo oscuro.
  static Color get acento => TemaGlobal.isDark ? dorado : azulMarino;
  static Color get fondoGris => TemaGlobal.superficie;

  List<DocumentoEscaneado> _documentos = [];
  bool _cargando = true;
  bool _escaneando = false;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _inicializarYCargar();
  }

  Future<void> _inicializarYCargar() async {
    await _documentosService.inicializarStorage();
    await _cargarDocumentos();
  }

  Future<void> _cargarDocumentos() async {
    setState(() => _cargando = true);
    final documentos = await _documentosService.obtenerDocumentos();
    if (mounted) {
      setState(() {
        _documentos = documentos;
        _cargando = false;
      });
    }
  }

  List<DocumentoEscaneado> get _documentosFiltrados {
    if (_busqueda.trim().isEmpty) return _documentos;
    final q = _busqueda.toLowerCase();
    return _documentos
        .where((d) => d.titulo.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _iniciarEscaneo() async {
    if (_escaneando) return;
    setState(() => _escaneando = true);

    final paginas = await _escaneoService.escanear();
    if (mounted) setState(() => _escaneando = false);

    if (paginas.isEmpty) return;

    if (!mounted) return;
    final resultado = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentEditorScreen(
          paginas: paginas,
          documentosService: _documentosService,
        ),
      ),
    );

    if (resultado != null && resultado['guardado'] == true && mounted) {
      await _cargarDocumentos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondoGris,
      bottomNavigationBar: const MainBottomBar(),
      appBar: AppBar(
        title: const Text(
          'Mis Documentos',
          style: TextStyle(
            color: dorado,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: azulMarino,
        elevation: 0,
        iconTheme: const IconThemeData(color: dorado),
      ),
      body: Column(
        children: [
          _buildBuscador(),
          Expanded(
            child: _cargando
                ? Center(child: CircularProgressIndicator(color: acento))
                : _documentosFiltrados.isEmpty
                    ? _buildEmptyState()
                    : _buildGrid(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _escaneando ? null : _iniciarEscaneo,
        backgroundColor: dorado,
        icon: _escaneando
            ? SizedBox(                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: azulMarino,
                ),
              )
            : Icon(Icons.document_scanner, color: azulMarino),
        label: Text(
          _escaneando ? 'Abriendo...' : 'Escanear',
          style: TextStyle(
            color: azulMarino,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBuscador() {
    if (_documentos.isEmpty) return const SizedBox.shrink();
    return Container(
      color: TemaGlobal.superficie,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        style: TextStyle(color: TemaGlobal.texto),
        decoration: InputDecoration(
          hintText: 'Buscar documento...',
          hintStyle: TextStyle(color: TemaGlobal.textoTenue),
          prefixIcon: Icon(Icons.search, color: acento, size: 20),
          filled: true,
          fillColor: TemaGlobal.campoTexto,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (v) => setState(() => _busqueda = v),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.68,
      ),
      itemCount: _documentosFiltrados.length,
      itemBuilder: (context, index) =>
          _buildDocumentCard(_documentosFiltrados[index]),
    );
  }

  Widget _buildDocumentCard(DocumentoEscaneado doc) {
    return Material(
      color: TemaGlobal.tarjeta,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: azulMarino.withOpacity(0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _abrirDocumento(doc),
        onLongPress: () => _mostrarOpciones(doc),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: doc.thumbnailUrl != null
                    ? Image.network(
                        doc.thumbnailUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) =>
                            progress == null
                                ? child
                                : Container(
                                    color: TemaGlobal.superficie,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: acento,
                                      ),
                                    ),
                                  ),
                        errorBuilder: (_, __, ___) => Container(
                          color: TemaGlobal.superficie,
                          child: Icon(                            Icons.description,
                            size: 40,
                            color: TemaGlobal.texto,
                          ),
                        ),
                      )
                    : Container(
                        color: TemaGlobal.superficie,
                        child: Icon(                          Icons.description,
                          size: 40,
                          color: TemaGlobal.texto,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(                      color: TemaGlobal.texto,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${doc.numeroPaginas} pág${doc.numeroPaginas != 1 ? 's' : ''} · '
                    '${_fechaCorta(doc.fechaCreacion)}',
                    style: TextStyle(
                      color: TemaGlobal.textoSecundario,
                      fontSize: 11,
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

  String _fechaCorta(DateTime fecha) {
    final ahora = DateTime.now();
    if (fecha.year == ahora.year &&
        fecha.month == ahora.month &&
        fecha.day == ahora.day) {
      return 'Hoy';
    }
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: TemaGlobal.tarjeta,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: acento.withOpacity(0.25),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.document_scanner,
                size: 56,
                color: acento,
              ),
            ),
            SizedBox(height: 28),
            Text(              'No tienes documentos escaneados',
              style: TextStyle(
                color: TemaGlobal.texto,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Toca "Escanear" para digitalizar tu primer documento.\n'
              'Detección automática, filtros y OCR incluidos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TemaGlobal.textoSecundario,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirDocumento(DocumentoEscaneado doc) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentViewerScreen(
          documento: doc,
          documentosService: _documentosService,
        ),
      ),
    );
    await _cargarDocumentos();
  }

  void _mostrarOpciones(DocumentoEscaneado doc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TemaGlobal.tarjeta,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.visibility_outlined, color: acento),
              title: Text('Ver documento', style: TextStyle(color: TemaGlobal.texto)),
              onTap: () {
                Navigator.pop(context);
                _abrirDocumento(doc);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: acento),
              title: Text('Renombrar', style: TextStyle(color: TemaGlobal.texto)),
              onTap: () {
                Navigator.pop(context);
                _renombrar(doc);
              },
            ),
            ListTile(
              leading: Icon(Icons.picture_as_pdf_outlined, color: acento),
              title: Text('Exportar PDF', style: TextStyle(color: TemaGlobal.texto)),
              onTap: () {
                Navigator.pop(context);
                PdfExportService.exportarYAbrir(doc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _eliminar(doc);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _renombrar(DocumentoEscaneado doc) async {
    final controller = TextEditingController(text: doc.titulo);
    final nuevo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar documento'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nuevo nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevo != null && nuevo.isNotEmpty) {
      await _documentosService.renombrarDocumento(doc.id, nuevo);
      await _cargarDocumentos();
    }
  }

  Future<void> _eliminar(DocumentoEscaneado doc) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar documento'),
        content: Text('¿Eliminar "${doc.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final ok = await _documentosService.eliminarDocumento(doc.id);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento eliminado'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _cargarDocumentos();
      }
    }
  }
}

/// Visualizador de documento: página por página con zoom y exportación.
class DocumentViewerScreen extends StatefulWidget {
  final DocumentoEscaneado documento;
  final DocumentosService documentosService;

  const DocumentViewerScreen({
    super.key,
    required this.documento,
    required this.documentosService,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);

  int _pagina = 0;
  bool _exportando = false;

  @override
  Widget build(BuildContext context) {
    final doc = widget.documento;
    return Scaffold(
      backgroundColor: azulMarino,
      appBar: AppBar(
        title: Text(
          doc.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: dorado,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: azulMarino,
        elevation: 0,
        iconTheme: const IconThemeData(color: dorado),
        actions: [
          if (_exportando)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: dorado,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.ios_share),
              onPressed: _exportar,
              tooltip: 'Exportar PDF',
            ),
        ],
      ),
      body: doc.paginasUrls.isEmpty
          ? const Center(
              child: Text(
                'Sin páginas',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : Stack(
              children: [
                PageView.builder(
                  itemCount: doc.paginasUrls.length,
                  onPageChanged: (i) => setState(() => _pagina = i),
                  itemBuilder: (context, index) {
                    return Center(
                      child: InteractiveViewer(
                        maxScale: 5,
                        child: Image.network(
                          doc.paginasUrls[index],
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                                  ? child
                                  : const Center(
                                      child: CircularProgressIndicator(
                                        color: dorado,
                                      ),
                                    ),
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                              size: 56,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_pagina + 1} / ${doc.numeroPaginas}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _exportar() async {
    setState(() => _exportando = true);
    final success = await PdfExportService.exportarYAbrir(widget.documento);
    if (mounted) {
      setState(() => _exportando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '✅ PDF generado y abierto' : '❌ Error generando PDF',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }
}

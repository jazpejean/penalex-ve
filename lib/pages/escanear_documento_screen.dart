import 'dart:io';
import 'package:flutter/material.dart';
import 'package:edge_detection/edge_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/documentos_service.dart';
import '../services/pdf_export_service.dart';
import '../models/documento_escaneado.dart';

class EscanearDocumentoScreen extends StatefulWidget {
  const EscanearDocumentoScreen({super.key});

  @override
  State<EscanearDocumentoScreen> createState() => _EscanearDocumentoScreenState();
}

class _EscanearDocumentoScreenState extends State<EscanearDocumentoScreen> {
  final DocumentosService _documentosService = DocumentosService();
  List<DocumentoEscaneado> _documentos = [];
  bool _cargando = false;

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color grisOscuro = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _inicializarYCargar();
  }

  Future<void> _inicializarYCargar() async {
    // Inicializar storage de Supabase
    await _documentosService.inicializarStorage();
    // Cargar documentos
    await _cargarDocumentos();
  }

  Future<void> _cargarDocumentos() async {
    setState(() => _cargando = true);
    try {
      final documentos = await _documentosService.obtenerDocumentos();
      setState(() {
        _documentos = documentos;
        _cargando = false;
      });
      debugPrint('✅ ${documentos.length} documentos cargados');
    } catch (e) {
      debugPrint('❌ Error cargando documentos: $e');
      setState(() => _cargando = false);
    }
  }

  Future<void> _iniciarEscaneo() async {
    // Verificar permisos
    bool isCameraGranted = await Permission.camera.request().isGranted;
    if (!isCameraGranted) {
      isCameraGranted = await Permission.camera.request() == PermissionStatus.granted;
    }

    if (!isCameraGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se necesita permiso de cámara')),
        );
      }
      return;
    }

    try {
      // Generar ruta para guardar la imagen
      final directory = await getApplicationSupportDirectory();
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();
      final imagePath = path.join(directory.path, "$timestamp.jpeg");

      // Abrir cámara con detección de bordes
      bool success = await EdgeDetection.detectEdge(
        imagePath,
        canUseGallery: true,
        androidScanTitle: 'Escanear Documento',
        androidCropTitle: 'Recortar',
        androidCropBlackWhiteTitle: 'Blanco y Negro',
        androidCropReset: 'Reiniciar',
      );
      
      if (!success || !mounted) {
        return;
      }

      // Navegar a editor de documento con la imagen escaneada
      final resultado = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentEditorScreen(
            imagePath: imagePath,
            documentosService: _documentosService,
          ),
        ),
      );

      // Si se guardó, recargar lista
      if (resultado != null && resultado['guardado'] == true) {
        await _cargarDocumentos();
      }
    } catch (e) {
      debugPrint('Error escaneando: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: azulMarino,
      appBar: AppBar(
        title: const Text(
          'Mis Documentos',
          style: TextStyle(color: dorado, fontWeight: FontWeight.bold),
        ),
        backgroundColor: azulMarino,
        elevation: 0,
        iconTheme: const IconThemeData(color: dorado),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Búsqueda
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Más opciones
            },
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: dorado),
            )
          : _documentos.isEmpty
              ? _buildEmptyState()
              : _buildDocumentGrid(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _iniciarEscaneo,
        backgroundColor: dorado,
        icon: const Icon(Icons.camera_alt, color: azulMarino),
        label: const Text(
          'Escanear',
          style: TextStyle(
            color: azulMarino,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: grisOscuro,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dorado.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.document_scanner,
              size: 60,
              color: dorado,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay documentos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Toca el botón para escanear tu primer documento',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          _buildFeatureRow(Icons.auto_fix_high, 'Detección automática de bordes'),
          _buildFeatureRow(Icons.tune, 'Filtros profesionales'),
          _buildFeatureRow(Icons.text_fields, 'OCR para extraer texto'),
          _buildFeatureRow(Icons.picture_as_pdf, 'Exportar como PDF'),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: dorado, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: _documentos.length,
      itemBuilder: (context, index) {
        final doc = _documentos[index];
        return _buildDocumentCard(doc);
      },
    );
  }

  Widget _buildDocumentCard(DocumentoEscaneado doc) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentViewerScreen(
              documento: doc,
              documentosService: _documentosService,
            ),
          ),
        );
      },
      onLongPress: () => _mostrarOpcionesDocumento(doc),
      child: Container(
        decoration: BoxDecoration(
          color: grisOscuro,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: doc.thumbnailUrl != null
                    ? Image.network(
                        doc.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: azulMarino,
                          child: const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: dorado,
                          ),
                        ),
                      )
                    : Container(
                        color: azulMarino,
                        child: const Icon(
                          Icons.description,
                          size: 48,
                          color: dorado,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${doc.numeroPaginas} página${doc.numeroPaginas != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
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

  void _mostrarOpcionesDocumento(DocumentoEscaneado doc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: grisOscuro,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmar eliminación'),
                    content: Text('¿Eliminar "${doc.titulo}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );

                if (confirmar == true && mounted) {
                  final success = await _documentosService.eliminarDocumento(doc.id);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Documento eliminado')),
                    );
                    await _cargarDocumentos();
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// Modelo local legacy (ya no se usa, migrado a DocumentoEscaneado)
class ScannedDocument {
  final String id;
  final String titulo;
  final int paginas;
  final DateTime fecha;
  final String? thumbnailPath;
  final List<String> imagePaths;
  final String? extractedText;

  ScannedDocument({
    required this.id,
    required this.titulo,
    required this.paginas,
    required this.fecha,
    this.thumbnailPath,
    required this.imagePaths,
    this.extractedText,
  });
}

// Pantalla de edición de documento
class DocumentEditorScreen extends StatefulWidget {
  final String imagePath;
  final DocumentosService documentosService;

  const DocumentEditorScreen({
    super.key,
    required this.imagePath,
    required this.documentosService,
  });

  @override
  State<DocumentEditorScreen> createState() => _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends State<DocumentEditorScreen> {
  late List<String> _paginas;
  bool _procesandoOCR = false;
  bool _guardando = false;
  String? _textoExtraido;
  final TextEditingController _tituloController = TextEditingController();

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color grisOscuro = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _paginas = [widget.imagePath];
    _tituloController.text = 'Documento ${DateTime.now().day}/${DateTime.now().month}';
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  Future<void> _agregarPagina() async {
    try {
      // Verificar permisos
      bool isCameraGranted = await Permission.camera.request().isGranted;
      if (!isCameraGranted) {
        isCameraGranted = await Permission.camera.request() == PermissionStatus.granted;
      }

      if (!isCameraGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Se necesita permiso de cámara')),
          );
        }
        return;
      }

      // Generar ruta para la nueva página
      final directory = await getApplicationSupportDirectory();
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();
      final imagePath = path.join(directory.path, "page_$timestamp.jpeg");

      // Escanear nueva página
      bool success = await EdgeDetection.detectEdge(
        imagePath,
        canUseGallery: true,
        androidScanTitle: 'Escanear Página',
        androidCropTitle: 'Recortar',
        androidCropBlackWhiteTitle: 'Blanco y Negro',
        androidCropReset: 'Reiniciar',
      );

      if (success) {
        setState(() {
          _paginas.add(imagePath);
        });
      }
    } catch (e) {
      debugPrint('Error agregando página: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _procesarOCR() async {
    setState(() => _procesandoOCR = true);

    try {
      final textRecognizer = TextRecognizer();
      final StringBuffer textoCompleto = StringBuffer();

      for (final imagePath in _paginas) {
        final inputImage = InputImage.fromFilePath(imagePath);
        final recognizedText = await textRecognizer.processImage(inputImage);
        textoCompleto.writeln(recognizedText.text);
        textoCompleto.writeln('\n---\n');
      }

      await textRecognizer.close();

      setState(() {
        _textoExtraido = textoCompleto.toString();
        _procesandoOCR = false;
      });

      if (mounted) {
        _mostrarTextoExtraido();
      }
    } catch (e) {
      debugPrint('Error en OCR: $e');
      setState(() => _procesandoOCR = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en OCR: $e')),
        );
      }
    }
  }

  void _mostrarTextoExtraido() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: grisOscuro,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: azulMarino,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.text_fields, color: dorado),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Texto Extraído',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _textoExtraido ?? 'No se extrajo texto',
                  style: const TextStyle(
                    color: Colors.white,
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

  Future<void> _guardarDocumento() async {
    if (_guardando) return;

    setState(() => _guardando = true);

    try {
      final documento = await widget.documentosService.guardarDocumento(
        titulo: _tituloController.text,
        rutasImagenesLocales: _paginas,
        textoOcr: _textoExtraido,
      );

      if (documento != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Documento guardado en la nube'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Retornar indicador de éxito
        Navigator.pop(context, {'guardado': true});
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error guardando documento'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error guardando: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: azulMarino,
      appBar: AppBar(
        title: const Text(
          'Editar Documento',
          style: TextStyle(color: dorado, fontWeight: FontWeight.bold),
        ),
        backgroundColor: azulMarino,
        elevation: 0,
        iconTheme: const IconThemeData(color: dorado),
        actions: [
          if (_guardando)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(dorado),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.cloud_upload),
              onPressed: _guardarDocumento,
              tooltip: 'Guardar en la nube',
            ),
        ],
      ),
      body: Column(
        children: [
          // Título
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _tituloController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nombre del documento',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                filled: true,
                fillColor: grisOscuro,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.edit, color: dorado),
              ),
            ),
          ),

          // Páginas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _paginas.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: grisOscuro,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_paginas[index]),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Botones de acción sobre la imagen
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Row(
                              children: [
                                // Botón editar (filtros)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.tune, color: dorado),
                                    onPressed: () async {
                                      final filteredPath = await Navigator.push<String>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DocumentEditorScreen(
                                            imagePath: _paginas[index],
                                            documentosService: widget.documentosService,
                                          ),
                                        ),
                                      );
                                      
                                      // Si retorna una ruta, actualizar la página
                                      if (filteredPath != null && filteredPath != _paginas[index]) {
                                        setState(() {
                                          _paginas[index] = filteredPath;
                                        });
                                      }
                                    },
                                    tooltip: 'Editar con filtros',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Botón eliminar
                                if (_paginas.length > 1)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          _paginas.removeAt(index);
                                        });
                                      },
                                      tooltip: 'Eliminar página',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'Página ${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Botones
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: grisOscuro,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _agregarPagina,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azulMarino,
                      foregroundColor: dorado,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _procesandoOCR ? null : _procesarOCR,
                    icon: _procesandoOCR
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.text_fields),
                    label: const Text('OCR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dorado,
                      foregroundColor: azulMarino,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Pantalla de visualización de documento
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
  bool _exportando = false;

  Future<void> _exportarPDF() async {
    setState(() => _exportando = true);

    final success = await PdfExportService.exportarYAbrir(widget.documento);

    if (mounted) {
      setState(() => _exportando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '✅ PDF generado y abierto' : '❌ Error generando PDF',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _compartirPDF() async {
    setState(() => _exportando = true);

    final success = await PdfExportService.exportarYCompartir(widget.documento);

    if (mounted) {
      setState(() => _exportando = false);

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error compartiendo PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarOpcionesExportar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: azulMarino,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: dorado),
              title: const Text('Exportar a PDF', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Solo imágenes',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _exportarPDF();
              },
            ),
            if (widget.documento.textoOcr != null)
              ListTile(
                leading: const Icon(Icons.text_fields, color: dorado),
                title: const Text('Exportar PDF con texto', style: TextStyle(color: Colors.white)),
                subtitle: const Text(
                  'Incluye texto OCR extraído',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  setState(() => _exportando = true);

                  final pdfPath = await PdfExportService.exportarAPdfConTexto(widget.documento);

                  if (mounted) {
                    setState(() => _exportando = false);

                    if (pdfPath != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ PDF con texto generado'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.share, color: dorado),
              title: const Text('Compartir PDF', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Enviar por WhatsApp, email, etc.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _compartirPDF();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: azulMarino,
      appBar: AppBar(
        title: Text(
          widget.documento.titulo,
          style: const TextStyle(color: dorado, fontWeight: FontWeight.bold),
        ),
        backgroundColor: azulMarino,
        elevation: 0,
        iconTheme: const IconThemeData(color: dorado),
        actions: [
          if (_exportando)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(dorado),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.ios_share),
              onPressed: _mostrarOpcionesExportar,
              tooltip: 'Exportar y compartir',
            ),
        ],
      ),
      body: PageView.builder(
        itemCount: widget.documento.paginasUrls.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Center(
                child: Image.network(
                  widget.documento.paginasUrls[index],
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: dorado,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Cargando página ${index + 1}...',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error cargando página ${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Indicador de número de página
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${index + 1} / ${widget.documento.numeroPaginas}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

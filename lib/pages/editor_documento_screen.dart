import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_theme.dart';
import '../models/documento_legal.dart';
import '../services/documento_legal_service.dart';
import '../services/pdf_service.dart';
import '../services/word_service.dart';

class EditorDocumentoScreen extends StatefulWidget {
  final DocumentoLegal documento;

  const EditorDocumentoScreen({
    super.key,
    required this.documento,
  });

  @override
  State<EditorDocumentoScreen> createState() => _EditorDocumentoScreenState();
}

class _EditorDocumentoScreenState extends State<EditorDocumentoScreen> {
  late TextEditingController _tituloController;
  late TextEditingController _contenidoController;
  late DocumentoLegal _documentoActual;
  bool _modificado = false;
  bool _guardando = false;
  bool _vistaPrevia = false; // Toggle entre edición y vista previa

  @override
  void initState() {
    super.initState();
    _documentoActual = widget.documento;
    _tituloController = TextEditingController(text: _documentoActual.titulo);
    
    // Limpiar marcadores markdown del contenido para edición
    final contenidoLimpio = _limpiarMarkdown(_documentoActual.contenido);
    _contenidoController = TextEditingController(text: contenidoLimpio);
    
    _tituloController.addListener(_marcarModificado);
    _contenidoController.addListener(_marcarModificado);
  }

  /// Limpia marcadores markdown básicos para edición
  String _limpiarMarkdown(String texto) {
    return texto
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1') // **negrita**
        .replaceAll(RegExp(r'__(.*?)__'), r'$1')      // __subrayado__
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1')       // *cursiva*
        .replaceAll(RegExp(r'_(.*?)_'), r'$1');         // _cursiva_
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }

  void _marcarModificado() {
    if (!_modificado) {
      setState(() => _modificado = true);
    }
  }

  Future<void> _guardar() async {
    if (_guardando) return;

    setState(() => _guardando = true);

    try {
      final documentoActualizado = _documentoActual.copyWith(
        titulo: _tituloController.text,
        contenido: _contenidoController.text,
        updatedAt: DateTime.now(),
      );

      await DocumentoLegalService.guardarDocumento(documentoActualizado);

      if (mounted) {
        setState(() {
          _documentoActual = documentoActualizado;
          _modificado = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Documento guardado'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  Future<void> _exportarPDF() async {
    try {
      final pdfFile = await PDFService.generarDocumentoLegal(
        titulo: _tituloController.text,
        contenido: _contenidoController.text,
        tipo: _documentoActual.tipo.nombre,
        caso: _documentoActual.caso,
        tribunal: _documentoActual.tribunal,
        expediente: _documentoActual.expediente,
      );

      if (mounted) {
        // Compartir PDF
        await Share.shareXFiles(
          [XFile(pdfFile.path)],
          subject: _tituloController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDF generado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cambiarEstado() async {
    final nuevoEstado = await showModalBottomSheet<EstadoDocumento>(
      context: context,
      backgroundColor: TemaGlobal.tarjeta,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Cambiar estado',
              style: TextStyle(
                color: Color(0xFFC5A059),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...EstadoDocumento.values.map((estado) {
              return ListTile(
                leading: Icon(
                  Icons.flag,
                  color: _getEstadoColor(estado),
                ),
                title: Text(
                  estado.nombre,
                  style: TextStyle(color: TemaGlobal.texto),
                ),
                selected: estado == _documentoActual.estado,
                onTap: () => Navigator.pop(context, estado),
              );
            }),
          ],
        ),
      ),
    );

    if (nuevoEstado != null && nuevoEstado != _documentoActual.estado) {
      setState(() {
        _documentoActual = _documentoActual.copyWith(estado: nuevoEstado);
        _modificado = true;
      });
    }
  }

  Future<bool> _confirmarSalida() async {
    if (!_modificado) return true;

    final salir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TemaGlobal.tarjeta,
        title: Text(
          '¿Guardar cambios?',
          style: TextStyle(color: TemaGlobal.texto),
        ),
        content: Text(
          'Tienes cambios sin guardar',
          style: TextStyle(color: TemaGlobal.textoSecundario),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _guardar();
              if (mounted) Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC5A059),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    return salir ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final shouldPop = await _confirmarSalida();
        if (context.mounted && shouldPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: TemaGlobal.superficie,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _modificado ? 'Editor (sin guardar)' : 'Editor de Documentos',
                style: const TextStyle(
                  color: Color(0xFFC5A059),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (_modificado)
                Text(
                  'Cambios pendientes',
                  style: TextStyle(
                    color: Colors.orange.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          iconTheme: const IconThemeData(color: Color(0xFFC5A059)),
          elevation: 0,
          actions: [
            // Toggle Vista Previa / Edición
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: _vistaPrevia 
                    ? Colors.green.withValues(alpha: 0.2)
                    : const Color(0xFFC5A059).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _vistaPrevia ? Colors.green : const Color(0xFFC5A059),
                ),
              ),
              child: IconButton(
                icon: Icon(
                  _vistaPrevia ? Icons.edit : Icons.visibility,
                  color: _vistaPrevia ? Colors.green : const Color(0xFFC5A059),
                ),
                onPressed: () {
                  setState(() => _vistaPrevia = !_vistaPrevia);
                },
                tooltip: _vistaPrevia ? 'Modo Edición' : 'Vista Previa',
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Estado badge
            GestureDetector(
              onTap: _cambiarEstado,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getEstadoColor(_documentoActual.estado).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getEstadoColor(_documentoActual.estado),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag,
                      color: _getEstadoColor(_documentoActual.estado),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _documentoActual.estado.nombre,
                      style: TextStyle(
                        color: _getEstadoColor(_documentoActual.estado),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 8),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [TemaGlobal.superficie, TemaGlobal.tarjeta],
            ),
          ),
          child: Column(
            children: [
              // Metadatos
              if (_documentoActual.generadoPorIA || _documentoActual.creadoDesdeImagen)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _documentoActual.creadoDesdeImagen
                            ? Icons.document_scanner
                            : Icons.auto_awesome,
                        color: Colors.purple,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _documentoActual.creadoDesdeImagen
                                  ? 'Creado desde imagen escaneada'
                                  : 'Generado con IA',
                              style: TextStyle(
                                color: TemaGlobal.texto.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_documentoActual.modeloIA != null)
                              Text(
                                'Modelo: ${_documentoActual.modeloIA}',
                                style: TextStyle(
                                  color: TemaGlobal.textoSecundario
                                      .withValues(alpha: 0.6),
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Título
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _tituloController,
                  style: TextStyle(
                    color: TemaGlobal.texto,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Título del documento',
                    labelStyle: TextStyle(
                      color: const Color(0xFFC5A059).withValues(alpha: 0.7),
                    ),
                    filled: true,
                    fillColor: TemaGlobal.campoTexto,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Contenido - Vista Previa o Edición
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TemaGlobal.tarjeta,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: TemaGlobal.capa,
                      ),
                    ),
                    child: _vistaPrevia
                        ? _buildVistaPrevia()
                        : _buildEditor(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildStat(
                      Icons.text_fields,
                      '${_contenidoController.text.split(' ').length} palabras',
                    ),
                    const SizedBox(width: 16),
                    _buildStat(
                      Icons.text_snippet,
                      '${_contenidoController.text.length} caracteres',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón Exportar PDF
            FloatingActionButton.extended(
              onPressed: _exportarPDF,
              backgroundColor: Colors.red.shade700,
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: const Text(
                'Exportar PDF',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              heroTag: 'pdf',
            ),
            const SizedBox(height: 12),
            // Botón Exportar Word
            FloatingActionButton.extended(
              onPressed: _exportarWord,
              backgroundColor: Colors.blue.shade700,
              icon: const Icon(Icons.description, color: Colors.white),
              label: const Text(
                'Exportar Word',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              heroTag: 'word',
            ),
            const SizedBox(height: 12),
            // Botón Guardar (principal)
            FloatingActionButton.extended(
              onPressed: _guardando ? null : _guardar,
              backgroundColor: const Color(0xFFC5A059),
              icon: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save, color: Color(0xFF0F172A)),
              label: Text(
                _guardando ? 'Guardando...' : 'Guardar',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              heroTag: 'save',
            ),
          ],
        ),
      ),
    );
  }

  // Método para exportar a Word
  Future<void> _exportarWord() async {
    try {
      final wordFile = await WordService.generarDocumentoLegal(
        titulo: _tituloController.text,
        contenido: _contenidoController.text,
        tipo: _documentoActual.tipo.nombre,
        caso: _documentoActual.caso,
        tribunal: _documentoActual.tribunal,
        expediente: _documentoActual.expediente,
      );

      if (mounted) {
        // Compartir Word
        await Share.shareXFiles(
          [XFile(wordFile.path)],
          subject: _tituloController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Documento Word generado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al generar Word: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Widget de edición (TextField)
  Widget _buildEditor() {
    return Column(
      children: [
        // Indicador de modo edición
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFC5A059).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFC5A059).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit, color: Color(0xFFC5A059), size: 16),
              const SizedBox(width: 8),
              Text(
                'Modo Edición',
                style: TextStyle(
                  color: TemaGlobal.texto.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'Presiona 👁️ para ver formato',
                style: TextStyle(
                  color: TemaGlobal.textoSecundario.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TextField(
            controller: _contenidoController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: TextStyle(
              color: TemaGlobal.texto,
              fontSize: 14,
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: 'Contenido del documento...',
              hintStyle: TextStyle(
                color: TemaGlobal.textoTenue,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  /// Widget de vista previa (Markdown)
  Widget _buildVistaPrevia() {
    // Reconstruir markdown básico para la vista previa
    String contenidoConFormato = _contenidoController.text;
    
    // Detectar y aplicar formato automático básico
    // Líneas en mayúsculas = títulos
    contenidoConFormato = contenidoConFormato.replaceAllMapped(
      RegExp(r'^([A-ZÁÉÍÓÚÑ\s]+)$', multiLine: true),
      (match) => '## ${match.group(1)}',
    );
    
    // Detectar listas numeradas
    contenidoConFormato = contenidoConFormato.replaceAllMapped(
      RegExp(r'^\d+\.\s+(.+)$', multiLine: true),
      (match) => '${match.group(0)}',
    );
    
    return Column(
      children: [
        // Indicador de vista previa
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.visibility, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Text(
                'Vista Previa',
                style: TextStyle(
                  color: TemaGlobal.texto.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'Presiona ✏️ para editar',
                style: TextStyle(
                  color: TemaGlobal.textoSecundario.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Markdown(
              data: contenidoConFormato,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              styleSheet: MarkdownStyleSheet(
                h1: TextStyle(
                  color: TemaGlobal.texto,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
                h2: const TextStyle(
                  color: Color(0xFFC5A059),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
                h3: TextStyle(
                  color: TemaGlobal.texto.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
                p: TextStyle(
                  color: TemaGlobal.texto.withValues(alpha: 0.9),
                  fontSize: 14,
                  height: 1.6,
                ),
                strong: TextStyle(
                  color: TemaGlobal.texto,
                  fontWeight: FontWeight.bold,
                ),
                em: const TextStyle(
                  fontStyle: FontStyle.italic,
                ),
                listBullet: const TextStyle(
                  color: Color(0xFFC5A059),
                ),
                code: TextStyle(
                  backgroundColor: TemaGlobal.capa,
                  color: const Color(0xFFC5A059),
                  fontFamily: 'monospace',
                ),
                blockquote: TextStyle(
                  color: TemaGlobal.textoSecundario,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: TemaGlobal.textoTenue,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: TemaGlobal.textoTenue,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Color _getEstadoColor(EstadoDocumento estado) {
    switch (estado) {
      case EstadoDocumento.borrador:
        return Colors.grey;
      case EstadoDocumento.revision:
        return Colors.orange;
      case EstadoDocumento.finalizado:
        return Colors.green;
      case EstadoDocumento.enviado:
        return Colors.blue;
    }
  }
}

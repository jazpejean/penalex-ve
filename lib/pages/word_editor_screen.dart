import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../services/chat_legal_export_service.dart';
import '../services/membrete_service.dart';
import '../services/word_export_service.dart';
import '../utils/quill_conversion.dart';
import '../widgets/app_bar_institucional.dart';

/// Editor de documentos estilo Word (básico) integrado al Redactor.
///
/// Recibe el documento generado por la IA (Markdown), lo carga en un editor
/// enriquecido (Quill) con toolbar de formato básico, y permite:
///  • Guardar: devuelve el texto editado (Markdown) al chat.
///  • Word: exporta un .docx REAL (Open XML) con membrete.
///  • PDF: exporta un PDF con membrete.
class WordEditorScreen extends StatefulWidget {
  /// Contenido inicial en Markdown (lo que generó la IA en el chat).
  final String contenidoInicial;

  /// Título del documento (usado en el Word/PDF).
  final String titulo;

  const WordEditorScreen({
    super.key,
    required this.contenidoInicial,
    this.titulo = 'Documento Legal',
  });

  @override
  State<WordEditorScreen> createState() => _WordEditorScreenState();
}

class _WordEditorScreenState extends State<WordEditorScreen> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    _controller = QuillController(
      document: Document.fromDelta(
        QuillConversion.markdownToDelta(widget.contenidoInicial),
      ),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Toolbar básica: negrita, cursiva, subrayado, títulos, viñetas/
  /// numeración, alineación y citas (lo que pediste).
  Widget _buildToolbar() {
    return QuillSimpleToolbar(
      controller: _controller,
      config: const QuillSimpleToolbarConfig(
        showFontFamily: false,
        showFontSize: false,
        showBoldButton: true,
        showItalicButton: true,
        showUnderLineButton: true,
        showStrikeThrough: false,
        showInlineCode: false,
        showColorButton: false,
        showBackgroundColorButton: false,
        showClearFormat: true,
        showAlignmentButtons: true,
        showLeftAlignment: true,
        showCenterAlignment: true,
        showRightAlignment: true,
        showJustifyAlignment: true,
        showHeaderStyle: true,
        showListNumbers: true,
        showListBullets: true,
        showListCheck: false,
        showCodeBlock: false,
        showQuote: true,
        showIndent: false,
        showLink: false,
        showUndo: true,
        showRedo: true,
        showDirection: false,
        showSearchButton: false,
        showSubscript: false,
        showSuperscript: false,
        showSmallButton: false,
        showLineHeightButton: false,
        multiRowsDisplay: true,
      ),
    );
  }

  Future<void> _guardar() async {
    if (_ocupado) return;
    _ocupado = true;
    final markdown =
        QuillConversion.deltaToMarkdown(_controller.document.toDelta());
    Navigator.of(context).pop(markdown);
  }

  Future<void> _exportarWord() async {
    setState(() => _ocupado = true);
    try {
      final config = await MembreteService.obtenerConfig();
      final ruta = await WordExportService.exportarDeltaADocx(
        _controller.document.toDelta(),
        titulo: widget.titulo,
        membreteUrl: config.url,
        alineacion: config.alineacion,
        tamano: config.tamano,
      );
      if (ruta == null) {
        throw Exception('No se pudo generar el Word');
      }
      await Share.shareXFiles([XFile(ruta)], text: 'Documento Legal (Word)');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Word (.docx) generado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al generar Word: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _exportarPDF() async {
    setState(() => _ocupado = true);
    try {
      final markdown =
          QuillConversion.deltaToMarkdown(_controller.document.toDelta());
      final config = await MembreteService.obtenerConfig();
      final ruta = await ChatLegalExportService.exportarTextoAPDF(
        markdown,
        titulo: widget.titulo,
        membreteUrl: config.url,
        alineacion: config.alineacion,
        tamano: config.tamano,
      );
      if (ruta == null) {
        throw Exception('No se pudo generar el PDF');
      }
      await Share.shareXFiles([XFile(ruta)], text: 'Documento Legal (PDF)');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ PDF generado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al generar PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
            appBar: AppBarInstitucional(
        title: '✏️ Editar documento',
        mostrarBack: true,

        actions: [
          IconButton(
            onPressed: _ocupado ? null : _exportarWord,
            icon: const Icon(Icons.description),
            tooltip: 'Exportar Word (.docx)',
          ),
          IconButton(
            onPressed: _ocupado ? null : _exportarPDF,
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
          ),
          TextButton.icon(
            onPressed: _ocupado ? null : _guardar,
            icon: const Icon(Icons.check, color: AppColors.onAzulMarino),
            label: const Text(
              'Guardar',
              style: TextStyle(color: AppColors.onAzulMarino, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildToolbar(),
          const Divider(height: 1),
          Expanded(
            child: QuillEditor.basic(
              controller: _controller,
              focusNode: _focusNode,
              config: const QuillEditorConfig(
                expands: true,
                padding: EdgeInsets.all(16),
                placeholder: 'Escribe o corrige el documento aquí…',
                scrollable: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
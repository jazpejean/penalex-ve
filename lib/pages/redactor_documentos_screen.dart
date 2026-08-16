import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/document_chat_service.dart';
import '../services/template_service.dart';
import '../services/ocr_service.dart';
import '../models/document_template.dart';
import '../models/chat_attachment.dart';

class RedactorDocumentosScreen extends StatefulWidget {
  const RedactorDocumentosScreen({Key? key}) : super(key: key);

  @override
  State<RedactorDocumentosScreen> createState() => _RedactorDocumentosScreenState();
}

class _RedactorDocumentosScreenState extends State<RedactorDocumentosScreen> {
  final DocumentChatService _chatService = DocumentChatService();
  final TemplateService _templateService = TemplateService();
  final OCRService _ocrService = OCRService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  final List<ChatAttachment> _attachments = []; // ✅ Sistema unificado
  bool _isLoading = false;
  bool _isProcessingAttachments = false;
  String? _generatedDocument;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _templateService.initialize();
    _addMessage(
      '¡Hola! Soy tu asistente de redacción de documentos penales.\n\n'
      '📄 ¿Qué documento deseas redactar?\n\n'
      'Ejemplos:\n'
      '• Escrito acusatorio\n'
      '• Recurso de apelación\n'
      '• Solicitud de libertad\n'
      '• Amparo constitucional\n'
      '• Oposición a medida cautelar\n'
      '• Solicitud de nulidad',
      isUser: false,
    );
  }

  void _addMessage(String content, {required bool isUser}) {
    setState(() {
      _messages.add(ChatMessage(
        content: content,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;

    // Crear mensaje con texto y adjuntos
    String messageContent = text;
    if (_attachments.isNotEmpty) {
      messageContent += '\n\n📎 Adjuntos (${_attachments.length}): ';
      messageContent += _attachments.map((a) => a.fileName).join(', ');
    }

    _addMessage(messageContent, isUser: true);
    _messageController.clear();

    setState(() => _isLoading = true);

    try {
      String response;
      
      // Si hay archivos adjuntos, procesarlos primero con OCR
      if (_attachments.isNotEmpty) {
        setState(() => _isProcessingAttachments = true);
        
        _addMessage(
          '📸 Analizando ${_attachments.length} documento(s) adjunto(s)...\n'
          'Extrayendo texto con OCR...',
          isUser: false,
        );

        String extractedText = '';
        for (final attachment in _attachments) {
          try {
            if (attachment.type == AttachmentType.image) {
              final ocrText = await OCRService.extractTextFromImage(attachment.filePath);
              extractedText += '\n\n=== ${attachment.fileName} ===\n$ocrText';
            } else if (attachment.type == AttachmentType.pdf) {
              // TODO: Implementar extracción de texto de PDF
              extractedText += '\n\n=== ${attachment.fileName} ===\n📄 Archivo PDF adjunto';
            } else if (attachment.type == AttachmentType.document) {
              extractedText += '\n\n=== ${attachment.fileName} ===\n📝 Documento adjunto';
            }
          } catch (e) {
            extractedText += '\n\n=== ${attachment.fileName} ===\n⚠️ No se pudo extraer texto: $e';
          }
        }

        // Enviar texto extraído + mensaje original a la IA
        final combinedMessage = '''$text

DOCUMENTOS ADJUNTOS (texto extraído con OCR):
$extractedText

Analiza los documentos adjuntos y extrae información relevante para el documento legal que estamos redactando (fechas, nombres, tribunal, delito, decisión, etc.). Si encuentras datos útiles, úsalos para prellenar campos automáticamente.''';

        response = await _chatService.processUserResponse(combinedMessage);
        
        setState(() => _isProcessingAttachments = false);
        
        // Limpiar adjuntos después de procesar
        setState(() => _attachments.clear());
      } else {
        response = await _chatService.processUserResponse(text);
      }

      _addMessage(response, isUser: false);

      // Si el documento fue generado, guardarlo
      if (response.contains('Documento generado:')) {
        _generatedDocument = response;
      }
    } catch (e) {
      _addMessage(
        '❌ Error: $e\n\nPor favor, intenta de nuevo.',
        isUser: false,
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isProcessingAttachments = false;
      });
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultipleMedia(
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          for (final image in images) {
            _attachments.add(ChatAttachment(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              fileName: image.name,
              filePath: image.path,
              fileSize: File(image.path).lengthSync(),
              type: _getFileType(image.path),
            ));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al seleccionar imágenes: $e')),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          for (final file in result.files) {
            if (file.path != null) {
              _attachments.add(ChatAttachment(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                fileName: file.name,
                filePath: file.path!,
                fileSize: file.size,
                type: _getFileType(file.path!),
              ));
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al seleccionar archivo: $e')),
        );
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  AttachmentType _getFileType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return AttachmentType.pdf;
      case 'doc':
      case 'docx':
        return AttachmentType.document;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return AttachmentType.image;
      default:
        return AttachmentType.other;
    }
  }

  IconData _getFileIcon(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return Icons.image;
      case AttachmentType.pdf:
        return Icons.picture_as_pdf;
      case AttachmentType.document:
        return Icons.description;
      case AttachmentType.audio:
        return Icons.audiotrack;
      case AttachmentType.video:
        return Icons.videocam;
      case AttachmentType.other:
        return Icons.attach_file;
    }
  }

  Color _getFileColor(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return Colors.green;
      case AttachmentType.pdf:
        return Colors.red;
      case AttachmentType.document:
        return Colors.blue;
      case AttachmentType.audio:
        return Colors.purple;
      case AttachmentType.video:
        return Colors.orange;
      case AttachmentType.other:
        return Colors.grey;
    }
  }

  Future<void> _exportToPDF(String content) async {
    try {
      final pdf = pw.Document();
      
      // Limpiar el contenido para PDF
      final cleanContent = content
          .replaceAll('✅ Documento generado:', '')
          .replaceAll(RegExp(r'━+'), '')
          .replaceAll(RegExp(r'⚠️.*'), '')
          .trim();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(50),
          build: (context) => [
            pw.Text(
              cleanContent,
              style: pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
            ),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/documento_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], text: 'Documento Legal');

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
    }
  }

  Future<void> _copyToClipboard(String content) async {
    final cleanContent = content
        .replaceAll('✅ Documento generado:', '')
        .replaceAll(RegExp(r'━+'), '')
        .replaceAll(RegExp(r'⚠️.*'), '')
        .trim();

    await Clipboard.setData(ClipboardData(text: cleanContent));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📋 Copiado al portapapeles')),
      );
    }
  }

  void _showTemplateSelector() {
    final templates = _templateService.getAllTemplates();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.description, color: Colors.white),
                  const SizedBox(width: 10),
                  const Text(
                    'Seleccionar Template',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.grey),
            Expanded(
              child: templates.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay templates disponibles.\nAgrega templates en assets/templates/',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getCategoryColor(template.category),
                            child: Icon(
                              _getCategoryIcon(template.category),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            template.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (template.description != null)
                                Text(
                                  template.description!,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                '${template.fields.length} campos • Fase: ${template.category}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _startTemplateConversation(template);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _startTemplateConversation(DocumentTemplate template) {
    _chatService.reset();
    _messageController.text = 'Quiero redactar un ${template.name}';
    _sendMessage();
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'control':
        return Colors.blue;
      case 'juicio':
        return Colors.orange;
      case 'ejecucion':
      case 'ejecución':
        return Colors.green;
      default:
        return Colors.purple;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'control':
        return Icons.shield;
      case 'juicio':
        return Icons.gavel;
      case 'ejecucion':
      case 'ejecución':
        return Icons.check_circle;
      default:
        return Icons.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Redactor de Documentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_list),
            onPressed: _showTemplateSelector,
            tooltip: 'Ver templates',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _chatService.reset();
                _messages.clear();
                _generatedDocument = null;
              });
              _initializeServices();
            },
            tooltip: 'Nueva conversación',
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicador de progreso
          StreamBuilder<Map<String, dynamic>>(
            stream: Stream.periodic(const Duration(milliseconds: 500))
                .map((_) => _chatService.getCurrentState()),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              
              final state = snapshot.data!;
              final progress = state['progress'] as int;
              final total = state['total'] as int;
              
              if (total == 0) return const SizedBox.shrink();
              
              return Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF1E1E1E),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_document, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Completando documento: $progress/$total campos',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress / total,
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ],
                ),
              );
            },
          ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Procesando...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // ✅ Chips de adjuntos (estilo ChatGPT)
                if (_attachments.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _attachments.map((attachment) {
                        return Chip(
                          backgroundColor: const Color(0xFF2C2C2C),
                          deleteIconColor: Colors.white,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getFileIcon(attachment.type),
                                size: 16,
                                color: _getFileColor(attachment.type),
                              ),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 150),
                                child: Text(
                                  attachment.fileName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onDeleted: () {
                            setState(() {
                              _attachments.remove(attachment);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),

                // Input row
                Row(
                  children: [
                    // ✅ Botón de adjuntar (clip)
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.grey),
                      onPressed: _pickFiles,
                      tooltip: 'Adjuntar archivos',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Escribe tu respuesta...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      backgroundColor: Colors.blue,
                      mini: true,
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isDocument = message.content.contains('Documento generado:');
    
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Colors.blue
                    : const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            if (isDocument) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _copyToClipboard(message.content),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copiar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _exportToPDF(message.content),
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes}m';
    if (diff.inDays < 1) return 'Hace ${diff.inHours}h';
    return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // ✅ Método para seleccionar archivos múltiples (SIN diálogos)
  Future<void> _pickFiles() async {
    // Mostrar modal con opciones
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Text(
                    'Adjuntar archivo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.grey, height: 1),
            
            // Archivos externos
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
              title: const Text(
                'Archivo Externo',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'PDF, DOC, TXT, imágenes',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _seleccionarArchivosExternos();
              },
            ),
            
            const Divider(color: Colors.grey, height: 1),
            
            // ✨ Documentos guardados
            ListTile(
              leading: const Icon(Icons.folder_special, color: Colors.blue),
              title: const Text(
                'Documentos Guardados',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Escaneados, reportes, comparaciones, favoritos',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              onTap: () {
                Navigator.pop(context);
                _mostrarDocumentosGuardados();
              },
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Seleccionar archivos externos del dispositivo
  Future<void> _seleccionarArchivosExternos() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'txt'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final file in result.files) {
            if (file.path != null) {
              final extension = file.extension?.toLowerCase() ?? '';
              AttachmentType type;

              if (extension == 'pdf') {
                type = AttachmentType.pdf;
              } else if (['jpg', 'jpeg', 'png'].contains(extension)) {
                type = AttachmentType.image;
              } else if (['doc', 'docx'].contains(extension)) {
                type = AttachmentType.document;
              } else {
                type = AttachmentType.other;
              }

              _attachments.add(ChatAttachment(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                fileName: file.name,
                filePath: file.path!,
                fileSize: file.size,
                type: type,
              ));
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result.files.length} archivo(s) adjuntado(s)'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al adjuntar archivos: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  // ✨ Mostrar documentos guardados en la app
  Future<void> _mostrarDocumentosGuardados() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF2C2C2C),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_special, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Documentos Guardados',
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
            
            // Lista de categorías
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCategoriaDocumentosRedactor(
                    icon: Icons.document_scanner,
                    title: 'Documentos Escaneados',
                    subtitle: 'Textos extraídos con OCR',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _cargarDocumentosEscaneados();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildCategoriaDocumentosRedactor(
                    icon: Icons.calculate,
                    title: 'Reportes de Calculadora',
                    subtitle: 'Dosimetrías y cómputos guardados',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _cargarReportesCalculadora();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildCategoriaDocumentosRedactor(
                    icon: Icons.chat,
                    title: 'Conversaciones del Chat Legal',
                    subtitle: 'Historial de consultas',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _cargarConversacionesChatLegal();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildCategoriaDocumentosRedactor(
                    icon: Icons.compare_arrows,
                    title: 'Comparaciones de Estrategias',
                    subtitle: 'Análisis comparativos guardados',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      _cargarComparaciones();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildCategoriaDocumentosRedactor(
                    icon: Icons.star,
                    title: 'Sentencias Favoritas',
                    subtitle: 'Jurisprudencias marcadas',
                    color: Colors.amber,
                    onTap: () {
                      Navigator.pop(context);
                      _cargarSentenciasFavoritas();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriaDocumentosRedactor({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[600],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Métodos para cargar documentos (placeholders)
  Future<void> _cargarDocumentosEscaneados() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📝 Función en desarrollo...')),
    );
  }

  Future<void> _cargarReportesCalculadora() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📊 Función en desarrollo...')),
    );
  }

  Future<void> _cargarConversacionesChatLegal() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('💬 Función en desarrollo...')),
    );
  }

  Future<void> _cargarComparaciones() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⚖️ Función en desarrollo...')),
    );
  }

  Future<void> _cargarSentenciasFavoritas() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⭐ Función en desarrollo...')),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

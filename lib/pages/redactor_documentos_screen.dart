import 'package:flutter/material.dart';
import '../services/haptics_service.dart';
import '../pages/main_screen.dart';
import '../utils/main_tab_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/document_chat_service.dart';
import '../services/template_service.dart';
import '../services/ocr_service.dart';
import '../services/redactor_service.dart';
import '../services/chat_legal_export_service.dart';
import '../services/membrete_service.dart';
import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../models/chat_attachment.dart';
import '../widgets/main_bottom_bar.dart';
import 'word_editor_screen.dart';

class RedactorDocumentosScreen extends StatefulWidget {
  /// Instrucción inicial (en lenguaje natural) que se envía automáticamente
  /// desde otras herramientas de la app.
  final String? initialPrompt;

  const RedactorDocumentosScreen({super.key, this.initialPrompt});

  @override
  State<RedactorDocumentosScreen> createState() => _RedactorDocumentosScreenState();
}

class _RedactorDocumentosScreenState extends State<RedactorDocumentosScreen> {
  final DocumentChatService _chatService = DocumentChatService();
  final TemplateService _templateService = TemplateService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  final List<ChatAttachment> _attachments = []; // ✅ Sistema unificado
  bool _isLoading = false;
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _templateService.initialize();
    // ✅ Creación perezosa: la conversación se crea en Supabase solo cuando
    // el usuario envía su primer mensaje real (evita historial lleno de
    // conversaciones vacías).
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
      persist: false,
    );

    // Si viene una instrucción inicial desde otra herramienta, se envía
    // automáticamente.
    if (widget.initialPrompt != null && widget.initialPrompt!.trim().isNotEmpty) {
      _messageController.text = widget.initialPrompt!.trim();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _sendMessage();
      });
    }
  }

  void _addMessage(String content, {required bool isUser, bool persist = true}) {
    setState(() {
      _messages.add(ChatMessage(
        content: content,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();

    if (persist) {
      _persistirMensaje(content, isUser);
    }
  }

  /// ✅ Persiste un mensaje creando la conversación en Supabase en el primer
  /// mensaje real (creación perezosa: no hay conversaciones vacías).
  Future<void> _persistirMensaje(String content, bool isUser) async {
    if (_conversationId == null) {
      try {
        _conversationId = await RedactorService.crearConversacion();
      } catch (e) {
        debugPrint('⚠️ No se pudo crear conversación del redactor: $e');
      }
    }
    if (_conversationId != null) {
      RedactorService.guardarMensaje(
        conversationId: _conversationId!,
        role: isUser ? 'user' : 'assistant',
        contenido: content,
      );
    }
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
        
        // Limpiar adjuntos después de procesar
        setState(() => _attachments.clear());
      } else {
        response = await _chatService.processUserResponse(text);
      }

      _addMessage(response, isUser: false);

      // Si se generó un documento, guardarlo en el historial
      final doc = _chatService.ultimoDocumento;
      if (doc != null && doc.isNotEmpty) {
        RedactorService.guardarDocumento(
          titulo: _chatService.ultimoTitulo ?? 'Documento',
          tipo: _chatService.ultimoTitulo,
          contenido: doc,
        );
        Haptics.medium();
      }
    } catch (e) {
      _addMessage(
        '❌ Error: $e\n\nPor favor, intenta de nuevo.',
        isUser: false,
      );
    } finally {
      setState(() => _isLoading = false);
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
    // Acentos unificados en dorado institucional (uniformidad TemaGlobal).
    return const AppColors.secondary;
  }

  Future<void> _exportToPDF(String content, {bool compartir = true}) async {
    try {
      final cleanContent = content
          .replaceAll('✅ Documento generado:', '')
          .replaceAll(RegExp(r'━+'), '')
          .replaceAll(RegExp(r'⚠️.*'), '')
          .trim();

      final config = await MembreteService.obtenerConfig();
      final ruta = await ChatLegalExportService.exportarTextoAPDF(
        cleanContent,
        titulo: 'Documento Legal',
        membreteUrl: config.url,
        alineacion: config.alineacion,
        tamano: config.tamano,
      );
      if (ruta == null) throw Exception('No se pudo generar el PDF');

      if (compartir) {
        await Share.shareXFiles([XFile(ruta)], text: 'Documento Legal');
      } else {
        await ChatLegalExportService.abrir(ruta);
      }

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

  Future<void> _exportToWord(String content, {bool compartir = true}) async {
    try {
      final cleanContent = content
          .replaceAll('✅ Documento generado:', '')
          .replaceAll(RegExp(r'━+'), '')
          .replaceAll(RegExp(r'⚠️.*'), '')
          .trim();

      final config = await MembreteService.obtenerConfig();
      final ruta = await ChatLegalExportService.exportarTextoAWord(
        cleanContent,
        titulo: 'Documento Legal',
        membreteUrl: config.url,
        alineacion: config.alineacion,
        tamano: config.tamano,
      );
      if (ruta == null) throw Exception('No se pudo generar el Word');

      if (compartir) {
        await Share.shareXFiles([XFile(ruta)], text: 'Documento Legal (Word)');
      } else {
        await ChatLegalExportService.abrir(ruta);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Word generado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al generar Word: $e')),
        );
      }
    }
  }

  /// Extrae el Markdown limpio del documento generado (sin los adornos del
  /// mensaje: "✅ Documento generado:", líneas ━━━ y el aviso final).
  String _limpiarContenidoDocumento(String content) {
    return content
        .replaceAll('✅ Documento generado:', '')
        .replaceAll(RegExp(r'━+'), '')
        .replaceAll(RegExp(r'⚠️.*'), '')
        .trim();
  }

  /// Abre el editor Word (Quill) con el documento generado; al guardar,
  /// actualiza el mensaje en el chat y persiste la versión editada.
  Future<void> _editarDocumento(ChatMessage message) async {
    final contenido = _limpiarContenidoDocumento(message.content);
    if (contenido.isEmpty) return;

    final editado = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => WordEditorScreen(
          contenidoInicial: contenido,
          titulo: 'Documento Legal',
        ),
      ),
    );

    if (editado == null || !mounted) return;

    // Reconstruir el mensaje del chat con el documento editado.
    final nuevoContenido = '✅ Documento generado:\n\n'
        '━━━━━━━━━━━━━━━━━━━━━━\n\n'
        '$editado\n\n'
        '━━━━━━━━━━━━━━━━━━━━━━\n\n'
        '✏️ Editado en el redactor.';

    setState(() {
      final idx = _messages.indexWhere(
        (m) => identical(m, message),
      );
      if (idx != -1) {
        _messages[idx] = ChatMessage(
          content: nuevoContenido,
          isUser: message.isUser,
          timestamp: message.timestamp,
        );
      }
    });

    // Persistir la versión editada en el historial de la conversación.
    if (_conversationId != null) {
      RedactorService.guardarMensaje(
        conversationId: _conversationId!,
        role: 'assistant',
        contenido: nuevoContenido,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Documento actualizado')),
      );
    }
  }

  Future<void> _mostrarMembrete() async {
    final config = await MembreteService.obtenerConfig();
    if (!mounted) return;

    var alineacion = config.alineacion;
    var tamano = config.tamano;

    showModalBottomSheet(
      context: context,
      backgroundColor: TemaGlobal.tarjeta,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Membrete / Logo',
                    style: TextStyle(
                      color: TemaGlobal.texto,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (config.url != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(config.url!, height: 100, fit: BoxFit.contain),
                    )
                  else
                    Text(
                      'Aún no has cargado un membrete.',
                      style: TextStyle(color: TemaGlobal.textoSecundario),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'Alineación',
                    style: TextStyle(color: TemaGlobal.texto, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _chip('Izquierda', 'izquierda', alineacion, (v) => setModalState(() => alineacion = v)),
                      _chip('Centro', 'centro', alineacion, (v) => setModalState(() => alineacion = v)),
                      _chip('Derecha', 'derecha', alineacion, (v) => setModalState(() => alineacion = v)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tamaño',
                    style: TextStyle(color: TemaGlobal.texto, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _chip('Pequeño', 'pequeno', tamano, (v) => setModalState(() => tamano = v)),
                      _chip('Medio', 'medio', tamano, (v) => setModalState(() => tamano = v)),
                      _chip('Grande', 'grande', tamano, (v) => setModalState(() => tamano = v)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _seleccionarMembrete();
                        },
                        icon: const Icon(Icons.upload),
                        label: Text(config.url == null ? 'Subir' : 'Reemplazar'),
                      ),
                      if (config.url != null)
                        OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            Haptics.heavy();
                            await MembreteService.eliminarMembrete();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✅ Membrete eliminado')),
                              );
                            }
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Quitar'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await MembreteService.guardarAjustes(
                          alineacion: alineacion,
                          tamano: tamano,
                        );
                        Haptics.medium();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Ajustes guardados')),
                          );
                        }
                      },
                      child: const Text('Guardar ajustes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(
    String label,
    String value,
    String seleccionado,
    ValueChanged<String> onTap,
  ) {
    final activo = value == seleccionado;
    return ChoiceChip(
      label: Text(label),
      selected: activo,
      onSelected: (_) => onTap(value),
      selectedColor: const AppColors.secondary,
      backgroundColor: TemaGlobal.capa,
      labelStyle: TextStyle(color: activo ? Colors.black : TemaGlobal.texto),
    );
  }

  Future<void> _seleccionarMembrete() async {
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final url = await MembreteService.subirMembrete(File(picked.path));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(url != null ? '✅ Membrete guardado' : '❌ Error al guardar el membrete'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
      bottomNavigationBar: const MainBottomBar(),
      appBar: AppBar(
        backgroundColor: TemaGlobal.azulMarino,
        title: const Text('Redactor de Documentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.badge_outlined),
            onPressed: _mostrarMembrete,
            tooltip: 'Membrete / logo',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _mostrarHistorial,
            tooltip: 'Historial',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _chatService.reset();
                _messages.clear();
                _conversationId = null;
              });
              _initializeServices();
            },
            tooltip: 'Nueva conversación',
          ),
            IconButton(
              icon: const Icon(Icons.home_outlined, color: AppColors.secondary),
              tooltip: 'Ir al inicio',
              onPressed: () {
                mainTabIndex.value = 0;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                  (r) => false,
                );
              },
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
                color: TemaGlobal.tarjeta,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_document, color: AppColors.secondary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Completando documento: $progress/$total campos',
                          style: TextStyle(color: TemaGlobal.texto),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress / total,
                      backgroundColor: TemaGlobal.capa,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Procesando...',
                    style: TextStyle(color: TemaGlobal.textoTenue),
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TemaGlobal.tarjeta,
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
                          backgroundColor: TemaGlobal.capa,
                          deleteIconColor: TemaGlobal.textoSecundario,
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
                                  style: TextStyle(
                                    color: TemaGlobal.texto,
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
                      icon: Icon(Icons.attach_file, color: TemaGlobal.textoTenue),
                      onPressed: _pickFiles,
                      tooltip: 'Adjuntar archivos',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(color: TemaGlobal.texto),
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Escribe tu respuesta...',
                          hintStyle: TextStyle(color: TemaGlobal.textoSecundario),
                          filled: true,
                          fillColor: TemaGlobal.campoTexto,
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
                      backgroundColor: const AppColors.secondary,
                      mini: true,
                      child: const Icon(Icons.send, color: Color(0xFF0F172A)),
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
                    ? const Color(0xFF0F172A)
                    : TemaGlobal.tarjeta,
                borderRadius: BorderRadius.circular(16),
              ),
              child: message.isUser
                  ? Text(
                      message.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    )
                  : MarkdownBody(
                      data: message.content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: TemaGlobal.texto,
                          fontSize: 15,
                          height: 1.5,
                        ),
                        strong: TextStyle(
                          color: TemaGlobal.texto,
                          fontWeight: FontWeight.bold,
                        ),
                        h1: TextStyle(
                          color: TemaGlobal.texto,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        h2: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        h3: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        listBullet: const TextStyle(color: AppColors.secondary),
                        blockquote: TextStyle(
                          color: TemaGlobal.textoSecundario,
                          fontStyle: FontStyle.italic,
                        ),
                        code: const TextStyle(
                          color: AppColors.secondary,
                          backgroundColor: Color(0xFF0F172A),
                        ),
                      ),
                    ),
            ),
            if (isDocument) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _editarDocumento(message),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _copyToClipboard(message.content),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copiar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TemaGlobal.capa,
                      foregroundColor: TemaGlobal.texto,
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
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _exportToWord(message.content),
                    icon: const Icon(Icons.description, size: 16),
                    label: const Text('Word'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        _exportToWord(message.content, compartir: false),
                    icon: Icon(Icons.download, color: TemaGlobal.textoTenue),
                    tooltip: 'Descargar',
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                color: TemaGlobal.textoSecundario,
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
      backgroundColor: TemaGlobal.tarjeta,
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
                  const Icon(Icons.attach_file, color: AppColors.secondary),
                  const SizedBox(width: 12),
                  Text(
                    'Adjuntar archivo',
                    style: TextStyle(
                      color: TemaGlobal.texto,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: TemaGlobal.capa, height: 1),
            
            // Archivos externos
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: AppColors.secondary),
              title: Text(
                'Archivo Externo',
                style: TextStyle(color: TemaGlobal.texto),
              ),
              subtitle: Text(
                'PDF, DOC, TXT, imágenes',
                style: TextStyle(color: TemaGlobal.textoSecundario, fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _seleccionarArchivosExternos();
              },
            ),
            
            Divider(color: TemaGlobal.capa, height: 1),
            
            // ✨ Documentos guardados
            ListTile(
              leading: const Icon(Icons.folder_special, color: AppColors.secondary),
              title: Text(
                'Documentos Guardados',
                style: TextStyle(color: TemaGlobal.texto, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Escaneados, reportes, escritos, favoritos',
                style: TextStyle(color: TemaGlobal.textoSecundario, fontSize: 12),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: TemaGlobal.textoTenue, size: 16),
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
  Future<void> _mostrarHistorial() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: TemaGlobal.tarjeta,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return FutureBuilder<Map<String, dynamic>>(
            future: _cargarHistorial(),
            builder: (context, snapshot) {
              final docs = (snapshot.data?['docs'] as List<DocumentoRedactado>?) ?? [];
              final convs = (snapshot.data?['convs'] as List<Map<String, dynamic>>?) ?? [];

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.history, color: AppColors.secondary),
                        const SizedBox(width: 12),
                        Text(
                          'Historial del Redactor',
                          style: TextStyle(
                            color: TemaGlobal.texto,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: TemaGlobal.capa, height: 1),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'DOCUMENTOS GENERADOS',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (docs.isEmpty)
                          Text(
                            'Aún no has generado documentos.',
                            style: TextStyle(
                              color: TemaGlobal.textoSecundario,
                            ),
                          ),
                        ...docs.map((d) => Card(
                              color: TemaGlobal.capa,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.description,
                                  color: AppColors.secondary,
                                ),
                                title: Text(
                                  d.titulo,
                                  style: TextStyle(color: TemaGlobal.texto),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  _formatTimestamp(d.fechaCreacion),
                                  style: TextStyle(
                                    color: TemaGlobal.textoTenue,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: PopupMenuButton(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: TemaGlobal.textoSecundario,
                                  ),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'ver',
                                      child: Text('Ver / copiar / PDF'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'eliminar',
                                      child: Text('Eliminar'),
                                    ),
                                  ],
                                  onSelected: (v) {
                                    if (v == 'eliminar') {
                                      Haptics.heavy();
                                      RedactorService.eliminarDocumento(d.id);
                                      Navigator.pop(context);
                                    } else {
                                      _mostrarDocumentoGuardado(d);
                                    }
                                  },
                                ),
                                onTap: () => _mostrarDocumentoGuardado(d),
                              ),
                            )),
                        const SizedBox(height: 20),
                        const Text(
                          'CONVERSACIONES',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (convs.isEmpty)
                          Text(
                            'No hay conversaciones guardadas.',
                            style: TextStyle(
                              color: TemaGlobal.textoSecundario,
                            ),
                          ),
                        ...convs.map((c) => ListTile(
                              leading: const Icon(
                                Icons.chat_outlined,
                                color: AppColors.secondary,
                              ),
                              title: Text(
                                c['title'] as String? ?? 'Redacción',
                                style: TextStyle(color: TemaGlobal.texto),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'Conversación guardada',
                                style: TextStyle(
                                  color: TemaGlobal.textoTenue,
                                  fontSize: 12,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _cargarConversacion(c['id'] as String);
                              },
                            )),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _cargarHistorial() async {
    final docs = await RedactorService.obtenerDocumentos();
    final convs = await RedactorService.obtenerConversaciones();
    return {'docs': docs, 'convs': convs};
  }

  Future<void> _cargarConversacion(String conversationId) async {
    final mensajes = await RedactorService.obtenerMensajes(conversationId);
    if (!mounted) return;
    setState(() {
      _conversationId = conversationId;
      _messages = mensajes
          .map((m) => ChatMessage(
                content: m['content'] as String? ?? '',
                isUser: m['role'] == 'user',
                timestamp: DateTime.tryParse(m['timestamp'] as String? ?? '') ?? DateTime.now(),
              ))
          .toList();
    });
    _scrollToBottom();
  }

  Future<void> _mostrarDocumentoGuardado(DocumentoRedactado doc) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: TemaGlobal.tarjeta,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      doc.titulo,
                      style: TextStyle(
                        color: TemaGlobal.texto,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppColors.secondary),
                    tooltip: 'Copiar',
                    onPressed: () => _copyToClipboard(doc.contenido),
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                    tooltip: 'Exportar PDF',
                    onPressed: () => _exportToPDF(doc.contenido),
                  ),
                  IconButton(
                    icon: const Icon(Icons.description, color: AppColors.secondary),
                    tooltip: 'Exportar Word',
                    onPressed: () => _exportToWord(doc.contenido),
                  ),
                ],
              ),
            ),
            Divider(color: TemaGlobal.capa, height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: MarkdownBody(
                  data: doc.contenido,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(color: TemaGlobal.texto, fontSize: 15, height: 1.5),
                    strong: TextStyle(color: TemaGlobal.texto, fontWeight: FontWeight.bold),
                    h1: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 20),
                    h2: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 18),
                    listBullet: const TextStyle(color: AppColors.secondary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDocumentosGuardados() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: TemaGlobal.tarjeta,
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
              decoration: BoxDecoration(
                color: TemaGlobal.capa,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_special, color: AppColors.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Documentos Guardados',
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
                    color: const AppColors.secondary,
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
                    color: const AppColors.secondary,
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
                    color: const AppColors.secondary,
                    onTap: () {
                      Navigator.pop(context);
                      _cargarConversacionesChatLegal();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildCategoriaDocumentosRedactor(
                    icon: Icons.star,
                    title: 'Sentencias Favoritas',
                    subtitle: 'Jurisprudencias marcadas',
                    color: const AppColors.secondary,
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
            color: TemaGlobal.capa,
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
                      style: TextStyle(
                        color: TemaGlobal.texto,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: TemaGlobal.textoTenue,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: TemaGlobal.textoSecundario,
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

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../services/ai_service.dart';
import '../services/document_text_extraction_service.dart';
import '../services/chat_export_service.dart';

class AsistenteLegalScreen extends StatefulWidget {
  const AsistenteLegalScreen({super.key});

  @override
  State<AsistenteLegalScreen> createState() => _AsistenteLegalScreenState();
}

class _AsistenteLegalScreenState extends State<AsistenteLegalScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  
  // Archivos adjuntos
  final List<AttachedFile> _attachedFiles = [];

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static Color get grisOscuro => TemaGlobal.tarjeta;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      text: '''¡Hola! Soy tu **Asistente Legal con IA**.

Puedo ayudarte a:
• Redactar documentos legales (escritos, recursos, demandas)
• Analizar sentencias y documentos
• Buscar jurisprudencia relevante
• Responder consultas legales

**¿En qué te puedo ayudar hoy?**''',
      isUser: false,
      timestamp: DateTime.now(),
    ));
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
    if (text.isEmpty && _attachedFiles.isEmpty) return;

    // Agregar mensaje del usuario
    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      attachedFiles: List.from(_attachedFiles),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _attachedFiles.clear();
    });

    _messageController.clear();
    _scrollToBottom();

    // Generar respuesta con IA
    try {
      await AIService.inicializar();
      
      // Extraer texto de archivos adjuntos
      String contextoArchivos = '';
      if (userMessage.attachedFiles.isNotEmpty) {
        debugPrint('📎 Extrayendo texto de ${userMessage.attachedFiles.length} archivo(s)...');
        
        final paths = userMessage.attachedFiles.map((f) => f.path).toList();
        final textosExtraidos = await DocumentTextExtractionService.extraerTextoDeMultiplesArchivos(paths);
        
        if (textosExtraidos.isNotEmpty) {
          contextoArchivos = '\n\n${DocumentTextExtractionService.generarResumenExtraccion(textosExtraidos)}';
          debugPrint('✅ Texto extraído de ${textosExtraidos.length} archivo(s)');
        } else {
          contextoArchivos = '\n\n[Archivos adjuntos: ${userMessage.attachedFiles.map((f) => f.name).join(', ')} - No se pudo extraer texto]';
          debugPrint('⚠️ No se pudo extraer texto de los archivos');
        }
      }

      // Construir prompt completo
      String contexto = text + contextoArchivos;

      final response = await AIService.chatLegalConversacional(
        pregunta: contexto,
        contexto: null,
      );

      final aiMessage = ChatMessage(
        text: response.interpretacion,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error generando respuesta: $e');
      setState(() {
        _messages.add(ChatMessage(
          text: '❌ Error: No pude generar una respuesta. Por favor intenta de nuevo.\n\nDetalle: $e',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> _attachImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _attachedFiles.add(AttachedFile(
          name: image.name,
          path: image.path,
          type: FileType.image,
        ));
      });
    }
  }

  Future<void> _attachDocument() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      setState(() {
        _attachedFiles.add(AttachedFile(
          name: result.files.single.name,
          path: result.files.single.path!,
          type: FileType.document,
        ));
      });
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  void _showAttachmentOptions() {
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
              leading: const Icon(Icons.image, color: dorado),
              title: Text('Imagen', style: TextStyle(color: TemaGlobal.texto)),
              onTap: () {
                Navigator.pop(context);
                _attachImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: dorado),
              title: Text('Documento', style: TextStyle(color: TemaGlobal.texto)),
              onTap: () {
                Navigator.pop(context);
                _attachDocument();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _exportConversation(ChatMessage message) {
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
              leading: const Icon(Icons.picture_as_pdf, color: dorado),
              title: Text('Exportar mensaje como PDF', style: TextStyle(color: TemaGlobal.texto)),
              onTap: () {
                Navigator.pop(context);
                _exportarMensajeAPDF(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: dorado),
              title: Text('Exportar conversación completa', style: TextStyle(color: TemaGlobal.texto)),
              subtitle: Text(
                'Todos los mensajes en un PDF',
                style: TextStyle(color: TemaGlobal.textoSecundario, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _exportarConversacionCompletaAPDF();
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: dorado),
              title: Text('Exportar mensaje como Word', style: TextStyle(color: TemaGlobal.texto)),
              onTap: () {
                Navigator.pop(context);
                _exportAsWord(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: dorado),
              title: Text('Exportar conversación completa Word', style: TextStyle(color: TemaGlobal.texto)),
              subtitle: Text(
                'Todos los mensajes en formato Word',
                style: TextStyle(color: TemaGlobal.textoSecundario, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _exportarConversacionCompletaAWord();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: dorado),
              title: Text('Compartir texto', style: TextStyle(color: TemaGlobal.texto)),
              onTap: () {
                Navigator.pop(context);
                Share.share(message.text);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _exportarMensajeAPDF(ChatMessage message) async {
    final success = await ChatExportService.exportarMensajeYAbrir(message);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '✅ PDF generado y abierto' : '❌ Error generando PDF',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _exportarConversacionCompletaAPDF() async {
    if (_messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay mensajes para exportar'),
        ),
      );
      return;
    }

    final success = await ChatExportService.exportarYAbrir(
      mensajes: _messages,
      titulo: 'Conversación Legal - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '✅ Conversación exportada a PDF' : '❌ Error exportando',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _exportarConversacionCompletaAWord() async {
    if (_messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay mensajes para exportar'),
        ),
      );
      return;
    }

    final success = await ChatExportWordService.exportarYAbrir(
      mensajes: _messages,
      titulo: 'Conversación Legal - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '✅ Conversación exportada a Word' : '❌ Error exportando',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _exportAsWord(ChatMessage message) async {
    final success = await ChatExportWordService.exportarMensajeYAbrir(message);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '✅ Documento Word generado' : '❌ Error generando documento',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
      appBar: AppBar(
        title: const Text(
          'Asistente Legal IA',
          style: TextStyle(color: dorado, fontWeight: FontWeight.bold),
        ),
        backgroundColor: azulMarino,
        elevation: 0,
        iconTheme: const IconThemeData(color: dorado),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _messages.length > 1 ? _exportarConversacionCompletaAPDF : null,
            tooltip: 'Exportar conversación completa',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
            tooltip: 'Nueva conversación',
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner informativo
          Container(
            padding: const EdgeInsets.all(12),
            color: TemaGlobal.capa,
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: dorado, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'IA integrada con Ulpiano • Adjunta documentos para análisis',
                    style: TextStyle(
                      color: TemaGlobal.textoSecundario,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mensajes
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildLoadingMessage();
                }
                return _buildMessage(_messages[index]);
              },
            ),
          ),

          // Archivos adjuntos
          if (_attachedFiles.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: TemaGlobal.tarjeta,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adjuntos:',
                    style: TextStyle(
                      color: TemaGlobal.textoSecundario,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _attachedFiles.asMap().entries.map((entry) {
                      final index = entry.key;
                      final file = entry.value;
                      return Chip(
                        avatar: Icon(
                          file.type == FileType.image ? Icons.image : Icons.insert_drive_file,
                          size: 16,
                          color: dorado,
                        ),
                        label: Text(
                          file.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeAttachment(index),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: TemaGlobal.tarjeta,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: dorado),
                  onPressed: _showAttachmentOptions,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(color: TemaGlobal.texto),
                      decoration: InputDecoration(
                        hintText: 'Escribe tu consulta o solicitud...',
                        hintStyle: TextStyle(
                          color: TemaGlobal.textoTenue,
                        ),
                        filled: true,
                        fillColor: TemaGlobal.campoTexto,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
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
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [dorado, Color(0xFFC5A059)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dorado.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded),
                    color: azulMarino,
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: dorado,
              radius: 20,
              child: const Icon(Icons.smart_toy, color: azulMarino, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser ? dorado : grisOscuro,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Archivos adjuntos
                  if (message.attachedFiles.isNotEmpty) ...[
                    ...message.attachedFiles.map((file) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                file.type == FileType.image
                                    ? Icons.image
                                    : Icons.insert_drive_file,
                                size: 16,
                                color: message.isUser
                                    ? azulMarino
                                    : TemaGlobal.textoSecundario,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  file.name,
                                  style: TextStyle(
                                    color: message.isUser
                                        ? azulMarino
                                        : TemaGlobal.textoSecundario,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    const Divider(),
                  ],
                  // Texto con formato Markdown
                  MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: message.isUser
                            ? azulMarino
                            : TemaGlobal.texto,
                        fontSize: 15,
                        height: 1.4,
                      ),
                      h2: TextStyle(
                        color: message.isUser ? azulMarino : dorado,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      strong: TextStyle(
                        color: message.isUser ? azulMarino : dorado,
                        fontWeight: FontWeight.bold,
                      ),
                      listBullet: TextStyle(
                        color: message.isUser ? azulMarino : dorado,
                      ),
                    ),
                  ),
                  // Botones de acción para mensajes de IA
                  if (!message.isUser && message.text.length > 100) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: () => _exportConversation(message),
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Exportar'),
                          style: TextButton.styleFrom(
                            foregroundColor: dorado,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: TemaGlobal.capa,
              radius: 20,
              child: const Icon(Icons.person, color: dorado, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: dorado,
            radius: 20,
            child: const Icon(Icons.smart_toy, color: azulMarino, size: 20),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TemaGlobal.tarjeta,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(dorado),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Generando respuesta...',
                  style: TextStyle(
                    color: TemaGlobal.textoSecundario,
                    fontSize: 14,
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

// Modelos
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<AttachedFile> attachedFiles;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.attachedFiles = const [],
  });
}

class AttachedFile {
  final String name;
  final String path;
  final FileType type;

  AttachedFile({
    required this.name,
    required this.path,
    required this.type,
  });
}

enum FileType { image, document }

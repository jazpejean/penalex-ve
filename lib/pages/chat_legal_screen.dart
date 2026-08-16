import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/ai_service.dart';

/// Modelo para archivos adjuntos
class AttachedFile {
  final File file;
  final String name;
  final String type; // 'image/png', 'application/pdf', etc.
  
  AttachedFile({
    required this.file,
    required this.name,
    required this.type,
  });
  
  bool get isImage => type.startsWith('image/');
  bool get isPdf => type.contains('pdf');
  
  IconData get icon {
    if (isImage) return Icons.image;
    if (isPdf) return Icons.picture_as_pdf;
    if (type.contains('word') || type.contains('document')) return Icons.description;
    return Icons.insert_drive_file;
  }
}

class ChatLegalScreen extends StatefulWidget {
  final String? conversationId;

  const ChatLegalScreen({super.key, this.conversationId});

  @override
  State<ChatLegalScreen> createState() => _ChatLegalScreenState();
}

class _ChatLegalScreenState extends State<ChatLegalScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<ChatMessage> _messages = [];
  String? _currentConversationId;
  bool _isLoading = false;
  bool _isGeneratingResponse = false;
  
  // ✨ MÚLTIPLES archivos adjuntos estilo IA moderna
  final List<AttachedFile> _attachedFiles = [];

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color grisOscuro = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ✨ NUEVO: Mostrar documentos guardados en la app
  Future<void> _mostrarDocumentosGuardados() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: grisOscuro,
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
                color: azulMarino,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_special, color: dorado),
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
                  _buildCategoriaDocumentos(
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
                  _buildCategoriaDocumentos(
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
                  _buildCategoriaDocumentos(
                    icon: Icons.edit_document,
                    title: 'Documentos del Redactor',
                    subtitle: 'Escritos legales generados',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _cargarDocumentosRedactor();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildCategoriaDocumentos(
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
                  _buildCategoriaDocumentos(
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

  Widget _buildCategoriaDocumentos({
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
            color: azulMarino,
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

  // Métodos para cargar documentos de cada categoría (TODO: desde Supabase)
  Future<void> _cargarDocumentosEscaneados() async {
    // TODO: Implementar carga desde Supabase Storage + Database
    // final client = Supabase.instance.client;
    // 1. Obtener lista de documentos escaneados del usuario desde tabla 'documentos_escaneados'
    // 2. Para cada documento, obtener URL pública desde Storage bucket 'documentos_escaneados/{userId}/'
    // 3. Mostrar lista para seleccionar y adjuntar al chat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📝 Cargando documentos escaneados desde Supabase...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _cargarReportesCalculadora() async {
    // TODO: Implementar carga desde Supabase Storage + Database
    // final client = Supabase.instance.client;
    // 1. Obtener lista de reportes desde tabla 'reportes_calculadora'
    // 2. Para cada reporte, obtener URL desde Storage bucket 'reportes_calculadora/{userId}/'
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📊 Cargando reportes desde Supabase...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _cargarDocumentosRedactor() async {
    // TODO: Implementar carga desde Supabase Storage + Database
    // final client = Supabase.instance.client;
    // 1. Obtener lista desde tabla 'documentos_redactor'
    // 2. Para cada documento, obtener URL desde Storage bucket 'documentos_redactor/{userId}/'
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✍️ Cargando documentos del redactor desde Supabase...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _cargarComparaciones() async {
    // TODO: Implementar carga desde Supabase Storage + Database
    // final client = Supabase.instance.client;
    // 1. Obtener lista desde tabla 'comparaciones'
    // 2. Para cada comparación, obtener URL desde Storage bucket 'comparaciones/{userId}/'
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚖️ Cargando comparaciones desde Supabase...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _cargarSentenciasFavoritas() async {
    // TODO: Implementar carga desde Supabase Database + Storage
    // final client = Supabase.instance.client;
    // 1. Obtener lista desde tabla 'sentencias_favoritas' (metadatos: título, fecha, delito, etc.)
    // 2. Para cada sentencia, si tiene PDF, obtener URL desde Storage bucket 'sentencias_favoritas/{userId}/'
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⭐ Cargando sentencias favoritas desde Supabase...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _inicializar() async {
    setState(() => _isLoading = true);

    try {
      if (widget.conversationId != null) {
        _currentConversationId = widget.conversationId;
        // TODO: Cuando Supabase esté configurado, descomentar:
        // _messages = await ChatService.obtenerMensajes(widget.conversationId!);
        _messages = []; // Por ahora, iniciar vacío
      } else {
        // Generar ID local temporal hasta que Supabase esté configurado
        _currentConversationId = 'local_${DateTime.now().millisecondsSinceEpoch}';
        _messages = [];
        
        // Agregar mensaje de bienvenida
        _messages.add(ChatMessage(
          id: 'welcome',
          conversationId: _currentConversationId!,
          content: '¡Hola! Soy tu asistente legal especializado en derecho penal venezolano.\n\n'
                   '¿En qué puedo ayudarte hoy?\n\n'
                   '📝 Ejemplos:\n'
                   '• Consultar sobre un delito específico\n'
                   '• Calcular penas y atenuantes\n'
                   '• Interpretar artículos del código penal\n'
                   '• Analizar estrategias de defensa',
          isUser: false,
          timestamp: DateTime.now(),
          attachmentUrls: [],
        ));
      }
    } catch (e) {
      debugPrint('❌ Error inicializando: $e');
      // En caso de error, inicializar vacío
      _currentConversationId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      _messages = [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _scrollToBottom();
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

  /// ✨ Widget moderno de chip de archivo (estilo ChatGPT/Claude)
  Widget _buildFileChip(AttachedFile file, int index) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      decoration: BoxDecoration(
        color: azulMarino,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dorado.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // TODO: Preview del archivo en futuro
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono del tipo de archivo
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: dorado.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    file.icon,
                    size: 16,
                    color: dorado,
                  ),
                ),
                const SizedBox(width: 8),
                // Nombre del archivo
                Flexible(
                  child: Text(
                    file.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                // Botón para eliminar
                InkWell(
                  onTap: () {
                    setState(() {
                      _attachedFiles.removeAt(index);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _enviarMensaje() async {
    final contenido = _messageController.text.trim();
    if (contenido.isEmpty || _currentConversationId == null) {
      debugPrint('⚠️ No se puede enviar: contenido vacío o sin conversación');
      return;
    }

    debugPrint('📤 Enviando mensaje: "$contenido"');
    _messageController.clear();

    // Limpiar adjuntos (por ahora sin soporte de archivos hasta Supabase esté configurado)
    if (_attachedFiles.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Adjuntos temporalmente deshabilitados hasta configurar Supabase'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      setState(() {
        _attachedFiles.clear();
      });
    }

    // Agregar mensaje del usuario localmente
    final userMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _currentConversationId!,
      content: contenido,
      isUser: true,
      timestamp: DateTime.now(),
      attachmentUrls: [],
    );

    setState(() {
      _messages.add(userMessage);
      _isGeneratingResponse = true;
    });

    _scrollToBottom();

    // Generar respuesta del asistente con IA
    try {
      debugPrint('🤖 Generando respuesta con IA...');
      
      // TODO: Cuando Supabase esté configurado, usar ChatService.generarRespuestaAsistente()
      // Por ahora, generar respuesta directamente con AIService
      final respuesta = await _generarRespuestaConIA(contenido);

      final assistantMessage = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: _currentConversationId!,
        content: respuesta,
        isUser: false,
        timestamp: DateTime.now(),
        attachmentUrls: [],
      );

      setState(() {
        _messages.add(assistantMessage);
        _isGeneratingResponse = false;
      });

      debugPrint('✅ Respuesta generada');
      _scrollToBottom();
    } catch (e) {
      debugPrint('❌ Error generando respuesta: $e');
      
      setState(() => _isGeneratingResponse = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar respuesta: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Método temporal para generar respuestas hasta que Supabase esté configurado
  Future<String> _generarRespuestaConIA(String consulta) async {
    try {
      await AIService.inicializar();
      
      // Construir contexto con últimos mensajes
      String contexto = '';
      if (_messages.length > 1) {
        final ultimosMensajes = _messages.length > 10 
          ? _messages.sublist(_messages.length - 10)
          : _messages;
        
        for (final msg in ultimosMensajes) {
          contexto += '${msg.isUser ? "Usuario" : "Asistente"}: ${msg.content}\n\n';
        }
      }
      
      final prompt = '''Eres un asistente legal especializado en derecho penal venezolano.

Contexto de la conversación:
$contexto

Nueva consulta del usuario:
$consulta

Responde de manera clara, profesional y basándote en el derecho penal venezolano vigente. Si mencionas artículos, cita la ley correspondiente.''';

      return await AIService.procesarConsultaGeneral(prompt);
    } catch (e) {
      debugPrint('❌ Error llamando a IA: $e');
      return '❌ Lo siento, ocurrió un error al procesar tu consulta. Por favor, intenta de nuevo.\n\nError: $e';
    }
  }

  Future<void> _mostrarOpcionesAdjunto() async {
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
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, color: dorado),
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
              leading: const Icon(Icons.photo_library, color: dorado),
              title: const Text(
                'Galería',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Seleccionar imagen de galería',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: dorado),
              title: const Text(
                'Cámara',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Tomar foto con cámara',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: dorado),
              title: const Text(
                'Documento',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Archivo PDF, DOC, TXT externo',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _seleccionarDocumento();
              },
            ),
            
            const Divider(color: Colors.grey, height: 1),
            
            // ✨ NUEVO: Documentos guardados en la app
            ListTile(
              leading: const Icon(Icons.folder_special, color: dorado),
              title: const Text(
                'Documentos Guardados',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Escaneados, reportes, escritos, comparaciones',
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

  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _attachedFiles.add(AttachedFile(
            file: File(image.path),
            name: image.name,
            type: 'image/${image.path.split('.').last}',
          ));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error seleccionando imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _seleccionarDocumento() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        allowMultiple: true, // ✨ Permitir múltiples archivos
      );

      if (result != null) {
        setState(() {
          for (final file in result.files) {
            if (file.path != null) {
              _attachedFiles.add(AttachedFile(
                file: File(file.path!),
                name: file.name,
                type: file.extension != null 
                    ? 'application/${file.extension}' 
                    : 'application/octet-stream',
              ));
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error seleccionando documento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: azulMarino,
      appBar: AppBar(
        title: const Text(
          'Chat Legal',
          style: TextStyle(color: dorado, fontWeight: FontWeight.bold),
        ),
        backgroundColor: azulMarino,
        elevation: 0,
        iconTheme: const IconThemeData(color: dorado),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _mostrarHistorial,
            tooltip: 'Ver conversaciones',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmarEliminarConversacion,
            tooltip: 'Eliminar conversación',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner informativo
            Container(
              padding: const EdgeInsets.all(12),
              color: grisOscuro,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: dorado, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Asistente legal con IA. Las respuestas son orientativas.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Mensajes
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: dorado),
                    )
                  : _messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length + (_isGeneratingResponse ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length && _isGeneratingResponse) {
                              return _buildLoadingMessage();
                            }
                            return _buildMessage(_messages[index]);
                          },
                        ),
            ),

            // Input de mensaje
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              child: Column(
                children: [
                  // ✨ Preview moderno de archivos adjuntos (múltiples chips)
                  if (_attachedFiles.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _attachedFiles.asMap().entries.map((entry) {
                          final index = entry.key;
                          final file = entry.value;
                          return _buildFileChip(file, index);
                        }).toList(),
                      ),
                    ),
                  ],
                  // Input y botones
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Botón de adjuntar
                      IconButton(
                        icon: const Icon(Icons.attach_file, color: dorado),
                        onPressed: _mostrarOpcionesAdjunto,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 120),
                          child: TextField(
                            controller: _messageController,
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Escribe tu consulta legal...',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              filled: true,
                              fillColor: azulMarino,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _enviarMensaje(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [dorado, Color(0xFFD4AF37)],
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
                          onPressed: _isGeneratingResponse ? null : _enviarMensaje,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
              Icons.chat_bubble_outline,
              size: 60,
              color: dorado,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Hola! Soy tu asistente legal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pregúntame sobre derecho penal venezolano',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip('¿Qué es el homicidio calificado?'),
              _buildSuggestionChip('Explica la legítima defensa'),
              _buildSuggestionChip('¿Cuándo aplica la tentativa?'),
              _buildSuggestionChip('Diferencia entre hurto y robo'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
      backgroundColor: grisOscuro,
      side: BorderSide(color: dorado.withValues(alpha: 0.3)),
      onPressed: () {
        _messageController.text = text;
        _enviarMensaje();
      },
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
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
                color: isUser ? dorado : grisOscuro,
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
                  // Adjunto (si existe)
                  if (message.hasAttachment) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isUser
                            ? azulMarino.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            message.attachmentType?.startsWith('image/') == true
                                ? Icons.image
                                : Icons.insert_drive_file,
                            color: isUser ? azulMarino : dorado,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message.attachmentType?.startsWith('image/') == true
                                  ? 'Imagen adjunta'
                                  : 'Documento adjunto',
                              style: TextStyle(
                                color: isUser ? azulMarino : Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? azulMarino : Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          color: isUser
                              ? azulMarino.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                      if (!isUser && message.hasSources) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.link,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ],
                    ],
                  ),
                  if (!isUser && message.hasSources) ...[
                    const SizedBox(height: 12),
                    _buildSources(message.sources),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: grisOscuro,
              radius: 20,
              child: const Icon(Icons.person, color: dorado, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSources(List<MessageSource> sources) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fuentes:',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...sources.map((source) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _getSourceIcon(source.type),
                    size: 14,
                    color: dorado,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${source.title} - ${source.reference}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  IconData _getSourceIcon(SourceType type) {
    switch (type) {
      case SourceType.ley:
        return Icons.gavel;
      case SourceType.jurisprudencia:
        return Icons.account_balance;
      case SourceType.articulo:
        return Icons.article;
      case SourceType.doctrina:
        return Icons.book;
    }
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
              color: grisOscuro,
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
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Analizando...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
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

  void _mostrarHistorial() async {
    // ✅ Usar await para recibir el conversationId seleccionado (o marcador para nueva)
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatHistoryScreen(),
      ),
    );

    if (!mounted) return;

    // ✅ Nueva conversación solicitada
    if (result == '__NEW_CONVERSATION__') {
      setState(() => _isLoading = true);
      
      final newConv = await ChatService.crearConversacion();
      
      setState(() {
        _currentConversationId = newConv.id;
        _messages = [];
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    // ✅ Conversación existente seleccionada
    if (result != null && result.isNotEmpty) {
      setState(() {
        _currentConversationId = result;
        _isLoading = true;
      });

      _messages = await ChatService.obtenerMensajes(result);
      
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _confirmarEliminarConversacion() async {
    if (_currentConversationId == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar conversación'),
        content:
            const Text('¿Estás seguro de eliminar esta conversación completa?'),
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

    if (confirmar == true) {
      await ChatService.eliminarConversacion(_currentConversationId!);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}

/// Pantalla de historial de conversaciones
class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key});

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color grisOscuro = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: azulMarino,
      appBar: AppBar(
        title: const Text(
          'Conversaciones',
          style: TextStyle(color: dorado, fontWeight: FontWeight.bold),
        ),
        backgroundColor: azulMarino,
        elevation: 0,
        iconTheme: const IconThemeData(color: dorado),
      ),
      body: StreamBuilder<List<ChatConversation>>(
        stream: ChatService.streamConversaciones(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: dorado),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 64, color: dorado),
                  const SizedBox(height: 16),
                  Text(
                    'No hay conversaciones',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return _buildConversationCard(context, conv);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // ✅ Retornar marcador especial para nueva conversación
          Navigator.pop(context, '__NEW_CONVERSATION__');
        },
        backgroundColor: dorado,
        icon: const Icon(Icons.add, color: azulMarino),
        label: const Text(
          'Nueva conversación',
          style: TextStyle(color: azulMarino, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildConversationCard(BuildContext context, ChatConversation conv) {
    return Card(
      color: grisOscuro,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          // ✅ Retornar el conversationId seleccionado (no apilar pantallas)
          Navigator.pop(context, conv.id);
        },
        leading: CircleAvatar(
          backgroundColor: dorado.withValues(alpha: 0.2),
          child: Icon(
            conv.isPinned ? Icons.push_pin : Icons.chat_bubble_outline,
            color: dorado,
          ),
        ),
        title: Text(
          conv.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${conv.messageCount} mensajes · ${_formatDate(conv.updatedAt)}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, color: Colors.white.withValues(alpha: 0.7)),
          color: grisOscuro,
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: () => ChatService.togglePin(conv.id, conv.isPinned),
              child: Row(
                children: [
                  Icon(
                    conv.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                    color: dorado,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    conv.isPinned ? 'Desfijar' : 'Fijar',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => _renombrar(context, conv),
              child: const Row(
                children: [
                  Icon(Icons.edit, color: dorado),
                  SizedBox(width: 12),
                  Text('Renombrar', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => _eliminar(context, conv.id),
              child: const Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Hoy ${DateFormat('HH:mm').format(date)}';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} días';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  Future<void> _renombrar(BuildContext context, ChatConversation conv) async {
    final controller = TextEditingController(text: conv.title);

    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar conversación'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nuevo nombre',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ChatService.renombrarConversacion(conv.id, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminar(BuildContext context, String convId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!context.mounted) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar conversación'),
        content: const Text('Esta acción no se puede deshacer.'),
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

    if (confirmar == true) {
      await ChatService.eliminarConversacion(convId);
    }
  }
}

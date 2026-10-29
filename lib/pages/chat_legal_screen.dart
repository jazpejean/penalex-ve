import 'dart:io';
import '../services/haptics_service.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';
import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../services/chat_service.dart';
import '../services/ocr_service.dart';
import '../services/chat_legal_export_service.dart';
import '../services/ulpiano_service.dart';
import '../widgets/main_bottom_bar.dart';
import 'redactor_documentos_screen.dart' show RedactorDocumentosScreen;
import '../widgets/app_bar_institucional.dart';

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

  // Marca institucional (fija en ambos modos; idéntica a TemaGlobal.dorado/
  // AppColors.azulMarino). El resto de superficies/textos leen de TemaGlobal.
  
  
  static Color get grisOscuro => TemaGlobal.tarjeta;
  /// Acento de marca: azul marino en modo claro, AppColors.dorado en modo oscuro.
  

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
                color: AppColors.azulMarino,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_special, color: AppColors.dorado),
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
                    color: AppColors.acento,
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
                    color: AppColors.acento,
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
                    color: AppColors.acento,
                    onTap: () {
                      Navigator.pop(context);
                      _cargarDocumentosRedactor();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildCategoriaDocumentos(
                    icon: Icons.star,
                    title: 'Sentencias Favoritas',
                    subtitle: 'Jurisprudencias marcadas',
                    color: AppColors.acento,
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
            color: TemaGlobal.tarjeta,
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
                        color: TemaGlobal.textoSecundario,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: TemaGlobal.textoTenue,
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
        _messages = await ChatService.obtenerMensajes(widget.conversationId!);
      } else {
        // ✅ Creación perezosa: NO se crea la conversación en Supabase hasta
        // que el usuario envíe su primer mensaje real. Esto evita que el
        // historial se llene de conversaciones vacías.
        _currentConversationId = null;
        _messages = [];

        // Mensaje de bienvenida (solo local, no se persiste para no duplicarlo)
        _messages.add(ChatMessage(
          id: 'welcome',
          role: MessageRole.assistant,
          content: '¡Hola! Soy **Ulpiano**, tu asistente jurídico especializado '
              'en derecho penal venezolano.\n\n'
              'Puedo **consultar** la ley y la jurisprudencia con fuentes '
              'verificables, **redactar** escritos con estilo forense, '
              '**analizar** documentos, **calcular** penas y **citar** '
              'sentencias.\n\n'
              '**Ejemplos:**\n'
              '- ¿Qué ha dicho la Sala sobre el art. 457 del COPP?\n'
              '- Redacta una solicitud de medida cautelar sustitutiva\n'
              '- Analiza este auto y dime sus debilidades\n'
              '- ¿Cuántos años le corresponden por robo agravado?',
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      debugPrint('❌ Error inicializando: $e');
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
        color: TemaGlobal.tarjeta,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.acento.withValues(alpha: 0.3),
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
                    color: AppColors.acento.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    file.icon,
                    size: 16,
                    color: AppColors.acento,
                  ),
                ),
                const SizedBox(width: 8),
                // Nombre del archivo
                Flexible(
                  child: Text(
                    file.name,
                    style: TextStyle(
                      color: TemaGlobal.texto,
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
                      color: TemaGlobal.textoTenue,
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
    Haptics.light();
    final contenido = _messageController.text.trim();
    if ((contenido.isEmpty && _attachedFiles.isEmpty) ||
        _currentConversationId == null) {
      debugPrint('⚠️ No se puede enviar: contenido vacío o sin conversación');
      return;
    }

    debugPrint('📤 Enviando mensaje: "$contenido"');
    _messageController.clear();

    // Procesar adjuntos con OCR y combinarlos con el mensaje
    String contenidoFinal = contenido;
    if (_attachedFiles.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔍 Extrayendo texto de los adjuntos con OCR...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      final buffer = StringBuffer();
      for (final adj in _attachedFiles) {
        try {
          if (adj.isImage) {
            final texto = await OCRService.extractTextFromImage(adj.file.path);
            buffer.writeln('=== ${adj.name} ===');
            buffer.writeln(texto.isEmpty ? '(sin texto detectado)' : texto);
          } else {
            buffer.writeln('=== ${adj.name} ===');
            buffer.writeln('(Documento adjunto)');
          }
        } catch (e) {
          buffer.writeln('=== ${adj.name} === (no se pudo extraer texto)');
        }
      }
      final extraido = buffer.toString().trim();
      if (extraido.isNotEmpty) {
        contenidoFinal = contenido.isEmpty
            ? 'Analiza el siguiente documento adjunto:\n\n$extraido'
            : '$contenido\n\nDocumento adjunto (texto extraído con OCR):\n$extraido';
      }
      setState(() => _attachedFiles.clear());
    }

    // Agregar mensaje del usuario localmente
    final userMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: contenido.isEmpty ? '📎 Documento adjunto' : contenido,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isGeneratingResponse = true;
    });

    _scrollToBottom();

    // ✅ Creación perezosa: si aún no hay conversación real en Supabase,
    // se crea en este momento (primer mensaje real del usuario). Así el
    // historial nunca guarda conversaciones vacías.
    if (_currentConversationId == null) {
      try {
        final conv = await ChatService.crearConversacion();
        _currentConversationId = conv.id;
        debugPrint('✅ Conversación creada al primer mensaje: ${conv.id}');
      } catch (e) {
        debugPrint('⚠️ No se pudo crear conversación en Supabase: $e');
      }
    }

    // Persistir el mensaje del usuario en Supabase
    if (_currentConversationId != null &&
        !_currentConversationId!.startsWith('local_')) {
      try {
        await ChatService.enviarMensajeUsuario(
          conversationId: _currentConversationId!,
          contenido: contenidoFinal,
        );
      } catch (e) {
        debugPrint('⚠️ No se pudo guardar el mensaje del usuario: $e');
      }
    }

    // Generar respuesta del asistente con IA
    try {
      debugPrint('🤖 Generando respuesta con IA...');
      
      // Respuesta generada por el orquestador de Ulpiano
      // (clasifica el modo y usa RAG de jurisprudencia + normas con citas)
      final resultado = await _generarRespuestaConIA(contenidoFinal);

      final assistantMessage = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        role: MessageRole.assistant,
        content: resultado.respuesta,
        sources: resultado.fuentes,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(assistantMessage);
        _isGeneratingResponse = false;
      });
      Haptics.tap();

      debugPrint('✅ Respuesta generada');
      _scrollToBottom();

      // Persistir la respuesta del asistente en Supabase
      if (_currentConversationId != null &&
          !_currentConversationId!.startsWith('local_')) {
        try {
          await ChatService.enviarMensajeAsistente(
            conversationId: _currentConversationId!,
            contenido: resultado.respuesta,
            sources: resultado.fuentes,
          );
        } catch (e) {
          debugPrint('⚠️ No se pudo guardar la respuesta del asistente: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error generando respuesta: $e');
      
      setState(() => _isGeneratingResponse = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar respuesta: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Genera la respuesta con el orquestador de Ulpiano (modo + RAG + citas).
  Future<({String respuesta, List<MessageSource> fuentes})> _generarRespuestaConIA(
      String consulta) async {
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

    return UlpianoService().generarRespuesta(
      consulta: consulta,
      contextoConversacion: contexto,
    );
  }

  Future<void> _mostrarOpcionesAdjunto() async {
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
                  Icon(Icons.attach_file, color: AppColors.acento),
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
              leading: Icon(Icons.photo_library, color: AppColors.acento),
              title: Text(
                'Galería',
                style: TextStyle(color: TemaGlobal.texto),
              ),
              subtitle: Text(
                'Seleccionar imagen de galería',
                style: TextStyle(color: TemaGlobal.textoSecundario, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.acento),
              title: Text(
                'Cámara',
                style: TextStyle(color: TemaGlobal.texto),
              ),
              subtitle: Text(
                'Tomar foto con cámara',
                style: TextStyle(color: TemaGlobal.textoSecundario, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.insert_drive_file, color: AppColors.acento),
              title: Text(
                'Documento',
                style: TextStyle(color: TemaGlobal.texto),
              ),
              subtitle: Text(
                'Archivo PDF, DOC, TXT externo',
                style: TextStyle(color: TemaGlobal.textoSecundario, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _seleccionarDocumento();
              },
            ),
            
            Divider(color: TemaGlobal.capa, height: 1),
            
            // ✨ NUEVO: Documentos guardados en la app
            ListTile(
              leading: Icon(Icons.folder_special, color: AppColors.acento),
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
            backgroundColor: AppColors.error,
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
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: TemaGlobal.superficie,
      bottomNavigationBar: const MainBottomBar(),
            appBar: AppBarInstitucional(
        title: 'Ulpiano',
        mostrarBack: true,

        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _mostrarHistorial,
            tooltip: 'Ver conversaciones',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download, color: AppColors.dorado),
            tooltip: 'Exportar conversación',
            onSelected: _exportarConversacion,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'pdf', child: Text('Exportar PDF')),
              PopupMenuItem(value: 'word', child: Text('Exportar Word')),
            ],
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
              color: TemaGlobal.capa,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.acento, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Asistente legal con IA. Las respuestas son orientativas.',
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
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: AppColors.acento),
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
                color: TemaGlobal.tarjeta,
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
                        icon: Icon(Icons.attach_file, color: AppColors.acento),
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
                            style: TextStyle(color: TemaGlobal.texto),
                            decoration: InputDecoration(
                              hintText: 'Escribe tu consulta legal...',
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
                            onSubmitted: (_) => _enviarMensaje(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.dorado, AppColors.dorado],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.dorado.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded),
                          color: AppColors.azulMarino,
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
              color: TemaGlobal.tarjeta,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.acento.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: AppColors.acento,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '¡Hola! Soy tu asistente legal',
            style: TextStyle(
              color: TemaGlobal.texto,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pregúntame sobre derecho penal venezolano',
            style: TextStyle(
              color: TemaGlobal.textoSecundario,
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
      labelStyle: TextStyle(color: TemaGlobal.texto, fontSize: 12),
      backgroundColor: TemaGlobal.tarjeta,
      side: BorderSide(color: AppColors.acento.withValues(alpha: 0.3)),
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
              backgroundColor: AppColors.dorado,
              radius: 20,
              child: const Icon(Icons.smart_toy, color: AppColors.azulMarino, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? AppColors.dorado : grisOscuro,
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
                            ? AppColors.azulMarino.withValues(alpha: 0.2)
                            : TemaGlobal.capa.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            message.attachmentType?.startsWith('image/') == true
                                ? Icons.image
                                : Icons.insert_drive_file,
                            color: isUser ? AppColors.azulMarino : AppColors.acento,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message.attachmentType?.startsWith('image/') == true
                                  ? 'Imagen adjunta'
                                  : 'Documento adjunto',
                              style: TextStyle(
                                color: isUser ? AppColors.azulMarino : TemaGlobal.texto,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isUser)
                    Text(
                      message.content,
                      style: const TextStyle(
                        color: AppColors.azulMarino,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    )
                  else
                    MarkdownBody(
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
                        em: TextStyle(
                          color: TemaGlobal.texto,
                          fontStyle: FontStyle.italic,
                        ),
                        h1: TextStyle(
                          color: TemaGlobal.texto,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        h2: TextStyle(
                          color: AppColors.acento,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        h3: TextStyle(
                          color: AppColors.acento,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        listBullet: TextStyle(color: AppColors.acento),
                        blockquote: TextStyle(
                          color: TemaGlobal.textoSecundario,
                          fontStyle: FontStyle.italic,
                        ),
                        code: const TextStyle(
                          color: AppColors.dorado,
                          backgroundColor: AppColors.azulMarino,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          color: isUser
                              ? AppColors.azulMarino.withValues(alpha: 0.6)
                              : TemaGlobal.textoTenue,
                          fontSize: 11,
                        ),
                      ),
                      if (!isUser && message.hasSources) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.link,
                          size: 14,
                          color: TemaGlobal.textoTenue,
                        ),
                      ],
                      const Spacer(),
                      _buildAccionesMensaje(message),
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
              backgroundColor: TemaGlobal.capa,
              radius: 20,
              child: Icon(Icons.person, color: AppColors.acento, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccionesMensaje(ChatMessage message) {
    final colorBase = message.isUser
        ? AppColors.azulMarino.withValues(alpha: 0.5)
        : TemaGlobal.textoSecundario;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _copiarMensaje(message),
          icon: Icon(Icons.copy, size: 16, color: colorBase),
          tooltip: 'Copiar texto',
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
        ),
        if (!message.isUser)
          IconButton(
            onPressed: () => _abrirEnRedactor(message),
            icon: Icon(Icons.edit_document, size: 16, color: colorBase),
            tooltip: 'Redactar con esta respuesta',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        PopupMenuButton<String>(
          icon: Icon(Icons.download, size: 16, color: colorBase),
          tooltip: 'Descargar',
          padding: const EdgeInsets.all(4),
          onSelected: (opcion) => _descargarMensaje(message, opcion),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'pdf', child: Text('Descargar PDF')),
            PopupMenuItem(value: 'word', child: Text('Descargar Word')),
          ],
        ),
      ],
    );
  }

  Future<void> _copiarMensaje(ChatMessage message) async {
    await Clipboard.setData(
      ClipboardData(
        text: ChatLegalExportService.markdownAPlano(message.content),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Texto copiado'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  /// Abre la respuesta del asistente en el Redactor como borrador editable.
  void _abrirEnRedactor(ChatMessage message) {
    final buffer = StringBuffer(message.content);
    if (message.hasSources) {
      buffer.write('\n\n**Fuentes citadas:**\n');
      for (final s in message.sources) {
        buffer.write('- ${s.title} — ${s.reference}\n');
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RedactorDocumentosScreen(
          initialPrompt: buffer.toString().trim(),
        ),
      ),
    );
  }

  /// Copia una fuente en formato de cita verificable.
  Future<void> _copiarFuente(MessageSource source) async {
    final cita = source.url != null && source.url!.isNotEmpty
        ? '${source.title} — ${source.reference}\n${source.url}'
        : '${source.title} — ${source.reference}';
    await Clipboard.setData(ClipboardData(text: cita));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Cita copiada'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _descargarMensaje(ChatMessage message, String formato) async {
    String? ruta;
    if (formato == 'pdf') {
      ruta = await ChatLegalExportService.exportarAPDF(
        [message],
        titulo: 'Mensaje Legal',
      );
    } else {
      ruta = await ChatLegalExportService.exportarAWord(
        [message],
        titulo: 'Mensaje Legal',
      );
    }
    final abierto = await ChatLegalExportService.abrir(ruta);
    if (mounted && !abierto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No se pudo generar el archivo'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildSources(List<MessageSource> sources) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fuentes:',
          style: TextStyle(
            color: TemaGlobal.textoSecundario,
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
                    color: AppColors.acento,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${source.title} - ${source.reference}',
                      style: TextStyle(
                        color: TemaGlobal.textoSecundario,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _copiarFuente(source),
                    icon: Icon(
                      Icons.content_copy,
                      size: 13,
                      color: TemaGlobal.textoTenue,
                    ),
                    tooltip: 'Copiar cita',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(2),
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
            backgroundColor: AppColors.dorado,
            radius: 20,
            child: const Icon(Icons.smart_toy, color: AppColors.azulMarino, size: 20),
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
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.acento),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Analizando...',
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

  Future<void> _exportarConversacion(String formato) async {
    final mensajes = _messages.where((m) => m.id != 'welcome').toList();
    if (mensajes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay mensajes para exportar'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String? ruta;
    if (formato == 'pdf') {
      ruta = await ChatLegalExportService.exportarAPDF(
        mensajes,
        titulo: 'Conversación Legal',
      );
    } else {
      ruta = await ChatLegalExportService.exportarAWord(
        mensajes,
        titulo: 'Conversación Legal',
      );
    }

    final abierto = await ChatLegalExportService.abrir(ruta);
    if (mounted && abierto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Conversación exportada'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No se pudo exportar'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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

    // ✅ Nueva conversación solicitada (creación perezosa: se creará en
    // Supabase solo cuando el usuario envíe su primer mensaje).
    if (result == '__NEW_CONVERSATION__') {
      setState(() {
        _currentConversationId = null;
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
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
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
class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  // Marca institucional (fija; idéntica a TemaGlobal). Superficies/textos
  // leen de TemaGlobal.
  
  
  /// Acento de marca: azul marino en modo claro, AppColors.dorado en modo oscuro.
  

  late Future<List<ChatConversation>> _future;

  @override
  void initState() {
    super.initState();
    _future = ChatService.obtenerConversaciones();
  }

  void _recargar() {
    setState(() => _future = ChatService.obtenerConversaciones());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
            appBar: AppBarInstitucional(
        title: 'Conversaciones',
        mostrarBack: true,

      ),
      body: FutureBuilder<List<ChatConversation>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.acento),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.acento),
                  const SizedBox(height: 16),
                  Text(
                    'No hay conversaciones',
                    style: TextStyle(
                      color: TemaGlobal.textoSecundario,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              return _buildConversationCard(context, conversations[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context, '__NEW_CONVERSATION__'),
        backgroundColor: AppColors.dorado,
        icon: Icon(Icons.add, color: AppColors.azulMarino),
        label: Text(
          'Nueva conversación',
          style: TextStyle(color: AppColors.azulMarino, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildConversationCard(BuildContext context, ChatConversation conv) {
    return Card(
      color: TemaGlobal.tarjeta,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => Navigator.pop(context, conv.id),
        leading: CircleAvatar(
          backgroundColor: AppColors.acento.withValues(alpha: 0.2),
          child: Icon(
            conv.isPinned ? Icons.push_pin : Icons.chat_bubble_outline,
            color: AppColors.acento,
          ),
        ),
        title: Text(
          conv.title,
          style: TextStyle(
            color: TemaGlobal.texto,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${conv.messageCount} mensajes · ${_formatDate(conv.updatedAt)}',
          style: TextStyle(
            color: TemaGlobal.textoSecundario,
            fontSize: 12,
          ),
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, color: TemaGlobal.textoSecundario),
          color: TemaGlobal.tarjeta,
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: () => _togglePin(conv),
              child: Row(
                children: [
                  Icon(
                    conv.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                    color: AppColors.acento,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    conv.isPinned ? 'Desfijar' : 'Fijar',
                    style: TextStyle(color: TemaGlobal.texto),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => _renombrar(conv),
              child: Row(
                children: [
                  Icon(Icons.edit, color: AppColors.acento),
                  const SizedBox(width: 12),
                  Text('Renombrar', style: TextStyle(color: TemaGlobal.texto)),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => _eliminar(conv.id),
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColors.error),
                  const SizedBox(width: 12),
                  Text('Eliminar', style: TextStyle(color: AppColors.error)),
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

  Future<void> _togglePin(ChatConversation conv) async {
    await ChatService.togglePin(conv.id, conv.isPinned);
    _recargar();
  }

  Future<void> _renombrar(ChatConversation conv) async {
    final controller = TextEditingController(text: conv.title);

    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar conversación'),
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
            onPressed: () async {
              final nuevo = controller.text.trim();
              Navigator.pop(context);
              if (nuevo.isNotEmpty) {
                await ChatService.renombrarConversacion(conv.id, nuevo);
                _recargar();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminar(String convId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

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
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await ChatService.eliminarConversacion(convId);
      _recargar();
    }
  }
}

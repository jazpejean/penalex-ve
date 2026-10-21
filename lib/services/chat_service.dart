import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message.dart';
import 'ai_service.dart';
import 'ai_analytics_service.dart';

class ChatService {
  static final _supabase = Supabase.instance.client;
  static final _firebaseAuth = firebase_auth.FirebaseAuth.instance;

  /// Obtiene el user ID actual de Firebase (ya sincronizado con Supabase)
  static String? get _currentUserId => _firebaseAuth.currentUser?.uid;

  /// Crea una nueva conversación
  static Future<ChatConversation> crearConversacion({String? titulo}) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('Usuario no autenticado');

      final response = await _supabase.from('chat_conversaciones').insert({
        'user_id': userId,
        'title': titulo ?? 'Nueva conversación',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'message_count': 0,
        'is_pinned': false,
      }).select().single();

      debugPrint('✅ Conversación creada: ${response['id']}');
      return ChatConversation.fromMap(response);
    } catch (e) {
      debugPrint('❌ Error creando conversación: $e');
      rethrow;
    }
  }

  /// Stream de conversaciones en tiempo real
  static Stream<List<ChatConversation>> streamConversaciones() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('chat_conversaciones')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .map((data) => data.map((item) => ChatConversation.fromMap(item)).toList());
  }

  /// Obtiene las conversaciones del usuario (fetch único, sin realtime).
  static Future<List<ChatConversation>> obtenerConversaciones() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return [];

      final response = await _supabase
          .from('chat_conversaciones')
          .select()
          .eq('user_id', userId)
          .filter('message_count', 'gt', 0)
          .order('updated_at', ascending: false);

      return response
          .map((item) => ChatConversation.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo conversaciones: $e');
      return [];
    }
  }

  /// Obtiene mensajes de una conversación
  static Future<List<ChatMessage>> obtenerMensajes(String conversationId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('timestamp', ascending: true);

      return response.map((item) => ChatMessage.fromMap(item)).toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo mensajes: $e');
      return [];
    }
  }

  /// Stream de mensajes en tiempo real
  static Stream<List<ChatMessage>> streamMensajes(String conversationId) {
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('timestamp', ascending: true)
        .map((data) => data.map((item) => ChatMessage.fromMap(item)).toList());
  }

  /// Sube un archivo adjunto a Supabase Storage
  static Future<String> subirArchivo({
    required String filePath,
    required String fileName,
    required String conversationId,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('Usuario no autenticado');

      // Ruta en Storage: chat_attachments/{userId}/{conversationId}/{fileName}
      final storagePath = 'chat_attachments/$userId/$conversationId/$fileName';

      // Leer archivo
      final file = await File(filePath).readAsBytes();

      // Subir a Storage
      await _supabase.storage
          .from('chat-files')
          .uploadBinary(storagePath, file);

      // Obtener URL pública
      final publicUrl = _supabase.storage
          .from('chat-files')
          .getPublicUrl(storagePath);

      debugPrint('✅ Archivo subido: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error subiendo archivo: $e');
      rethrow;
    }
  }

  /// Envía un mensaje del usuario con archivo adjunto opcional
  static Future<ChatMessage> enviarMensajeUsuario({
    required String conversationId,
    required String contenido,
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('Usuario no autenticado');

      final messageData = {
        'conversation_id': conversationId,
        'user_id': userId,
        'role': 'user',
        'content': contenido,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (attachmentUrl != null) {
        messageData['attachment_url'] = attachmentUrl;
        messageData['attachment_type'] = attachmentType ?? 'unknown';
      }

      final response = await _supabase
          .from('chat_messages')
          .insert(messageData)
          .select()
          .single();

      await _actualizarConversacion(conversationId, contenido);

      debugPrint('✅ Mensaje enviado');
      return ChatMessage.fromMap(response);
    } catch (e) {
      debugPrint('❌ Error enviando mensaje: $e');
      rethrow;
    }
  }

  /// Guarda un mensaje del asistente (ya generado) en la conversación,
  /// incluyendo las fuentes/jurisprudencia citadas.
  static Future<ChatMessage> enviarMensajeAsistente({
    required String conversationId,
    required String contenido,
    List<MessageSource> sources = const [],
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('Usuario no autenticado');

      final messageData = {
        'conversation_id': conversationId,
        'user_id': userId,
        'role': 'assistant',
        'content': contenido,
        'timestamp': DateTime.now().toIso8601String(),
        'model_used': 'deepseek-chat',
        'sources': sources.map((s) => s.toMap()).toList(),
      };

      final response = await _supabase
          .from('chat_messages')
          .insert(messageData)
          .select()
          .single();

      await _actualizarConversacion(conversationId, null);

      debugPrint('✅ Respuesta del asistente guardada');
      return ChatMessage.fromMap(response);
    } catch (e) {
      debugPrint('❌ Error guardando respuesta del asistente: $e');
      rethrow;
    }
  }

  /// Genera respuesta del asistente con DeepSeek
  static Future<ChatMessage> generarRespuestaAsistente({
    required String conversationId,
    required List<ChatMessage> historial,
  }) async {
    return await AIAnalyticsService.trackOperation(
      toolName: AIAnalyticsService.chatLegal,
      actionType: AIAnalyticsService.query,
      metadata: {
        'conversation_id': conversationId,
        'messages_in_history': historial.length,
      },
      operation: () async {
        try {
          final userId = _currentUserId;
          if (userId == null) throw Exception('Usuario no autenticado');

          debugPrint('🤖 Generando respuesta con DeepSeek...');

          // Inicializar AIService con DeepSeek API key
          await AIService.inicializar();

          // Construir contexto
          final contexto = _construirContexto(historial);
          final ultimoMensaje = historial.lastWhere((m) => m.isUser).content;

          // Generar respuesta
          final response = await AIService.chatLegalConversacional(
            pregunta: ultimoMensaje,
            contexto: contexto,
          );

          // Guardar respuesta del asistente
          final messageResponse = await _supabase.from('chat_messages').insert({
            'conversation_id': conversationId,
            'user_id': userId,
            'role': 'assistant',
            'content': response.interpretacion,
            'timestamp': DateTime.now().toIso8601String(),
            'model_used': 'deepseek-chat',
          }).select().single();

          await _actualizarConversacion(conversationId, null);

          debugPrint('✅ Respuesta generada');
          return ChatMessage.fromMap(messageResponse);
        } catch (e) {
          debugPrint('❌ Error generando respuesta: $e');
          rethrow;
        }
      },
    );
  }

  /// Construye contexto del historial
  static String _construirContexto(List<ChatMessage> historial) {
    final mensajesRecientes = historial.length > 10
        ? historial.sublist(historial.length - 10)
        : historial;

    final buffer = StringBuffer();
    for (final mensaje in mensajesRecientes) {
      if (mensaje.isUser) {
        buffer.writeln('Usuario: ${mensaje.content}');
      } else if (mensaje.isAssistant) {
        buffer.writeln('Asistente: ${mensaje.content}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Actualiza la conversación
  static Future<void> _actualizarConversacion(
    String conversationId,
    String? ultimoMensaje,
  ) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Si es el primer mensaje, generar título
      if (ultimoMensaje != null) {
        final conv = await _supabase
            .from('chat_conversaciones')
            .select('message_count')
            .eq('id', conversationId)
            .single();

        if (conv['message_count'] == 0) {
          updates['title'] = _generarTitulo(ultimoMensaje);
        }
      }

      // Incrementar contador de mensajes
      await _supabase.rpc('increment_message_count', params: {
        'conv_id': conversationId,
      });

      await _supabase
          .from('chat_conversaciones')
          .update(updates)
          .eq('id', conversationId);
    } catch (e) {
      debugPrint('⚠️ Error actualizando conversación: $e');
    }
  }

  /// Genera título automático
  static String _generarTitulo(String mensaje) {
    if (mensaje.length <= 50) return mensaje;
    return '${mensaje.substring(0, 47)}...';
  }

  /// Elimina una conversación
  static Future<void> eliminarConversacion(String conversationId) async {
    try {
      await _supabase
          .from('chat_messages')
          .delete()
          .eq('conversation_id', conversationId);

      await _supabase
          .from('chat_conversaciones')
          .delete()
          .eq('id', conversationId);

      debugPrint('✅ Conversación eliminada');
    } catch (e) {
      debugPrint('❌ Error eliminando conversación: $e');
      rethrow;
    }
  }

  /// Fija/desfija una conversación
  static Future<void> togglePin(String conversationId, bool isPinned) async {
    try {
      await _supabase
          .from('chat_conversaciones')
          .update({'is_pinned': !isPinned})
          .eq('id', conversationId);

      debugPrint('✅ Pin actualizado');
    } catch (e) {
      debugPrint('❌ Error toggle pin: $e');
      rethrow;
    }
  }

  /// Renombra una conversación
  static Future<void> renombrarConversacion(
    String conversationId,
    String nuevoTitulo,
  ) async {
    try {
      await _supabase
          .from('chat_conversaciones')
          .update({'title': nuevoTitulo})
          .eq('id', conversationId);

      debugPrint('✅ Conversación renombrada');
    } catch (e) {
      debugPrint('❌ Error renombrando: $e');
      rethrow;
    }
  }
}

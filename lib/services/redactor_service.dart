import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Documento redactado guardado en el historial.
class DocumentoRedactado {
  final String id;
  final String titulo;
  final String? tipo;
  final String contenido;
  final DateTime fechaCreacion;

  const DocumentoRedactado({
    required this.id,
    required this.titulo,
    this.tipo,
    required this.contenido,
    required this.fechaCreacion,
  });

  factory DocumentoRedactado.fromMap(Map<String, dynamic> map) =>
      DocumentoRedactado(
        id: map['id'] as String,
        titulo: map['titulo'] as String? ?? 'Documento',
        tipo: map['tipo'] as String?,
        contenido: map['contenido'] as String? ?? '',
        fechaCreacion: DateTime.parse(map['fecha_creacion'] as String),
      );
}

/// Persistencia del Redactor de Documentos (conversaciones + documentos) en
/// Supabase. Usa el UID de Firebase como user_id (estrategia de la app).
class RedactorService {
  static final _supabase = Supabase.instance.client;
  static final _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  static String? get _currentUserId => _firebaseAuth.currentUser?.uid;

  // ---------------------------------------------------------------------------
  // Conversaciones
  // ---------------------------------------------------------------------------

  static Future<String?> crearConversacion({String titulo = 'Redacción'}) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return null;
      final response = await _supabase.from('redactor_conversaciones').insert({
        'user_id': userId,
        'title': titulo,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();
      return response['id'] as String;
    } catch (e) {
      debugPrint('❌ Error creando conversación de redactor: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerConversaciones() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return [];
      final response = await _supabase
          .from('redactor_conversaciones')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);
      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Error obteniendo conversaciones del redactor: $e');
      return [];
    }
  }

  static Future<void> guardarMensaje({
    required String conversationId,
    required String role, // 'user' | 'assistant'
    required String contenido,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;
      await _supabase.from('redactor_mensajes').insert({
        'conversation_id': conversationId,
        'user_id': userId,
        'role': role,
        'content': contenido,
        'timestamp': DateTime.now().toIso8601String(),
      });
      await _supabase.from('redactor_conversaciones').update({
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', conversationId);
    } catch (e) {
      debugPrint('❌ Error guardando mensaje del redactor: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> obtenerMensajes(
    String conversationId,
  ) async {
    try {
      final response = await _supabase
          .from('redactor_mensajes')
          .select()
          .eq('conversation_id', conversationId)
          .order('timestamp', ascending: true);
      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Error obteniendo mensajes del redactor: $e');
      return [];
    }
  }

  static Future<void> eliminarConversacion(String conversationId) async {
    try {
      await _supabase
          .from('redactor_mensajes')
          .delete()
          .eq('conversation_id', conversationId);
      await _supabase
          .from('redactor_conversaciones')
          .delete()
          .eq('id', conversationId);
    } catch (e) {
      debugPrint('❌ Error eliminando conversación del redactor: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Documentos generados
  // ---------------------------------------------------------------------------

  static Future<DocumentoRedactado?> guardarDocumento({
    required String titulo,
    String? tipo,
    required String contenido,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return null;
      final response = await _supabase.from('documentos_redactados').insert({
        'user_id': userId,
        'titulo': titulo,
        'tipo': tipo,
        'contenido': contenido,
        'fecha_creacion': DateTime.now().toIso8601String(),
      }).select().single();
      return DocumentoRedactado.fromMap(response);
    } catch (e) {
      debugPrint('❌ Error guardando documento redactado: $e');
      return null;
    }
  }

  static Future<List<DocumentoRedactado>> obtenerDocumentos() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return [];
      final response = await _supabase
          .from('documentos_redactados')
          .select()
          .eq('user_id', userId)
          .order('fecha_creacion', ascending: false);
      return response
          .map((item) => DocumentoRedactado.fromMap(item))
          .toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo documentos redactados: $e');
      return [];
    }
  }

  static Future<void> eliminarDocumento(String id) async {
    try {
      await _supabase.from('documentos_redactados').delete().eq('id', id);
    } catch (e) {
      debugPrint('❌ Error eliminando documento redactado: $e');
    }
  }
}

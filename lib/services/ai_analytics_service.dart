import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Telemetría OCULTA de uso de IA (sin pantalla, sin RPC, sin reporte).
///
/// Registra silenciosamente cada operación de IA (herramienta, acción, tiempo,
/// éxito, error) en la tabla `ai_tool_usage` para métricas de tracción y
/// depuración. NUNCA rompe el flujo principal: cualquier fallo se ignora.
/// La tabla solo la escribe/lee el service role (RLS sin políticas públicas).
class AIAnalyticsService {
  static final _supabase = Supabase.instance.client;
  static final _firebaseAuth = FirebaseAuth.instance;

  /// Nombre de las herramientas que registra la app.
  static const chatLegal = 'chat_legal';
  static const redactorDocumentos = 'redactor_documentos';

  /// Acciones.
  static const query = 'query';
  static const generation = 'generation';

  /// Ejecuta [operation], mide su duración y registra el resultado en
  /// `ai_tool_usage`. Devuelve el resultado de [operation] sin cambios.
  /// Cualquier error interno de registro se ignora (debugPrint).
  static Future<T> trackOperation<T>({
    required String toolName,
    required String actionType,
    Map<String, dynamic>? metadata,
    required Future<T> Function() operation,
  }) async {
    final stopwatch = Stopwatch()..start();
    var success = true;
    String? errorMessage;
    try {
      final result = await operation();
      return result;
    } catch (e) {
      success = false;
      errorMessage = e.toString();
      rethrow;
    } finally {
      stopwatch.stop();
      await _guardar({
        'tool_name': toolName,
        'action_type': actionType,
        'response_time_seconds':
            (stopwatch.elapsedMilliseconds / 1000.0).toStringAsFixed(3),
        'success': success,
        'error_message': errorMessage,
        'metadata': metadata ?? {},
      });
    }
  }

  static Future<void> _guardar(Map<String, dynamic> fila) async {
    try {
      final userId = _firebaseAuth.currentUser?.uid;
      if (userId == null) return; // sin sesión: no registrar
      await _supabase.from('ai_tool_usage').insert({
        ...fila,
        'user_id': userId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      // Telemetría silenciosa: nunca debe afectar al usuario.
      debugPrint('⚠️ telemetría omitida: $e');
    }
  }
}
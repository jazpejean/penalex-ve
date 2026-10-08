import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuración completa del membrete (URL + alineación + tamaño).
class MembreteConfig {
  final String? url;
  final String alineacion; // 'izquierda' | 'centro' | 'derecha'
  final String tamano; // 'pequeno' | 'medio' | 'grande'

  const MembreteConfig({
    this.url,
    this.alineacion = 'centro',
    this.tamano = 'medio',
  });

  bool get tieneMembrete => url != null && url!.isNotEmpty;
}

/// Servicio para el membrete/logo del abogado (aplicado a los documentos).
class MembreteService {
  static final _supabase = Supabase.instance.client;
  static final _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  static String? get _currentUserId => _firebaseAuth.currentUser?.uid;

  static String _contentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  /// Sube (o reemplaza) el membrete del usuario y guarda su URL pública.
  static Future<String?> subirMembrete(File archivo) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return null;

      final ext = archivo.path.split('.').last.toLowerCase();
      final path = '$userId/membrete.$ext';
      final bytes = await archivo.readAsBytes();

      await _supabase.storage.from('membretes').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _contentType(ext),
            ),
          );

      final url = _supabase.storage.from('membretes').getPublicUrl(path);

      await _supabase.from('configuracion_usuario').upsert({
        'user_id': userId,
        'membrete_url': url,
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Membrete guardado: $url');
      return url;
    } catch (e) {
      debugPrint('❌ Error subiendo membrete: $e');
      return null;
    }
  }

  /// Devuelve la URL del membrete del usuario (o null si no tiene).
  static Future<String?> obtenerMembreteUrl() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return null;
      final response = await _supabase
          .from('configuracion_usuario')
          .select('membrete_url')
          .eq('user_id', userId)
          .maybeSingle();
      if (response == null) return null;
      final url = response['membrete_url'] as String?;
      return (url == null || url.isEmpty) ? null : url;
    } catch (e) {
      debugPrint('❌ Error obteniendo membrete: $e');
      return null;
    }
  }

  /// Devuelve la configuración completa del membrete (url + alineación + tamaño).
  static Future<MembreteConfig> obtenerConfig() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return const MembreteConfig();
      final response = await _supabase
          .from('configuracion_usuario')
          .select('membrete_url, membrete_alineacion, membrete_tamano')
          .eq('user_id', userId)
          .maybeSingle();
      if (response == null) return const MembreteConfig();
      final url = response['membrete_url'] as String?;
      return MembreteConfig(
        url: (url == null || url.isEmpty) ? null : url,
        alineacion: response['membrete_alineacion'] as String? ?? 'centro',
        tamano: response['membrete_tamano'] as String? ?? 'medio',
      );
    } catch (e) {
      debugPrint('❌ Error obteniendo config del membrete: $e');
      return const MembreteConfig();
    }
  }

  /// Guarda los ajustes de alineación y tamaño del membrete.
  static Future<void> guardarAjustes({
    required String alineacion,
    required String tamano,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;
      await _supabase.from('configuracion_usuario').upsert({
        'user_id': userId,
        'membrete_alineacion': alineacion,
        'membrete_tamano': tamano,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Error guardando ajustes del membrete: $e');
    }
  }

  /// Elimina el membrete del usuario (archivo y URL).
  static Future<void> eliminarMembrete() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      try {
        final files = await _supabase.storage.from('membretes').list(path: userId);
        for (final f in files) {
          await _supabase.storage.from('membretes').remove(['$userId/${f.name}']);
        }
      } catch (e) {
        debugPrint('⚠️ No se pudieron eliminar archivos del membrete: $e');
      }

      await _supabase.from('configuracion_usuario').upsert({
        'user_id': userId,
        'membrete_url': null,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Error eliminando membrete: $e');
    }
  }
}

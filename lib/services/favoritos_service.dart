import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para gestionar sentencias favoritas/importantes.
///
/// Estrategia **LOCAL-FIRST** (compatible con Android, iOS y Web):
///
/// 1. Siempre guarda en [SharedPreferences] (localStorage en Web,
///    NSUserDefaults en iOS) → funciona offline y sin sesión.
/// 2. Si hay sesión de Firebase, sincroniza con Supabase
///    (tabla `sentencias_favoritas`, usando el UID de Firebase como
///    `user_id`) → los favoritos viajan entre dispositivos.
/// 3. Si falla la red o no hay sesión, se degrada a solo-local
///    sin romper nada.
class FavoritosService {
  static const String _keyIds = 'sentencias_favoritas_ids';

  SupabaseClient get _supabase => Supabase.instance.client;

  /// UID de Firebase del usuario actual (null si no hay sesión).
  String? get _userId {
    try {
      return fb.FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// Obtiene los IDs de favoritas guardados localmente (rápido, sin red).
  Future<Set<String>> obtenerIdsFavoritas() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_keyIds) ?? []).toSet();
  }

  /// Indica si una sentencia está marcada como favorita por su ID.
  Future<bool> estaFavorita(String id) async {
    final ids = await obtenerIdsFavoritas();
    return ids.contains(id);
  }

  /// Agrega o elimina una sentencia de favoritas según su estado actual.
  ///
  /// Actualiza siempre el almacenamiento local y, si hay sesión,
  /// sincroniza el cambio en Supabase en segundo plano.
  Future<void> toggleFavorita(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_keyIds) ?? [];
    final yaEraFavorita = ids.contains(id);

    if (yaEraFavorita) {
      ids.remove(id);
    } else {
      ids.add(id);
    }

    await prefs.setStringList(_keyIds, ids);

    // Sincronizar en la nube sin bloquear la UI
    final userId = _userId;
    if (userId == null) return;
    unawaited(_sincronizarFavoritaEnNube(
      userId: userId,
      documentoId: id,
      agregar: !yaEraFavorita,
    ));
  }

  /// Sincronización bidireccional con Supabase:
  /// - Trae las favoritas de la nube y las fusiona con las locales (unión).
  /// - Sube a la nube las favoritas locales que no existían (agregadas
  ///   sin conexión o en otro dispositivo).
  Future<void> sincronizarDesdeNube() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final response = await _supabase
          .from('sentencias_favoritas')
          .select('documento_id')
          .eq('user_id', userId);
      final cloudIds = (response as List)
          .map((r) => r['documento_id'] as String)
          .toSet();

      final prefs = await SharedPreferences.getInstance();
      final local = (prefs.getStringList(_keyIds) ?? []).toSet();

      // Unión: favoritas locales + favoritas de la nube
      final fusion = local..addAll(cloudIds);

      // Subir a la nube las que solo existen localmente
      final soloLocales = local.difference(cloudIds).toList();
      if (soloLocales.isNotEmpty) {
        await _supabase.from('sentencias_favoritas').upsert(
              soloLocales
                  .map((id) => {
                        'user_id': userId,
                        'documento_id': id,
                        'created_at': DateTime.now().toIso8601String(),
                      })
                  .toList(),
              onConflict: 'user_id, documento_id',
            );
      }

      await prefs.setStringList(_keyIds, fusion.toList());
      debugPrint('⭐ Favoritas sincronizadas desde la nube: ${fusion.length}');
    } catch (e) {
      debugPrint('⚠️ No se pudieron sincronizar favoritas (modo local): $e');
    }
  }

  Future<void> _sincronizarFavoritaEnNube({
    required String userId,
    required String documentoId,
    required bool agregar,
  }) async {
    try {
      if (agregar) {
        await _supabase.from('sentencias_favoritas').upsert({
          'user_id': userId,
          'documento_id': documentoId,
          'created_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id, documento_id');
      } else {
        await _supabase
            .from('sentencias_favoritas')
            .delete()
            .eq('user_id', userId)
            .eq('documento_id', documentoId);
      }
      debugPrint(agregar
          ? '⭐ Favorita subida a Supabase: $documentoId'
          : '🗑️ Favorita eliminada de Supabase: $documentoId');
    } catch (e) {
      debugPrint('⚠️ Error sincronizando favorita en Supabase: $e');
    }
  }

  /// Elimina todas las favoritas locales (útil para pruebas o limpiar datos).
  Future<void> limpiarFavoritas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIds);
  }
}

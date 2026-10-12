// Puente de identidad Firebase -> Supabase.
//
// Cuando Firebase autentica a un usuario, este puente pide al worker
// penalex-auth-bridge un JWT de Supabase con la MISMA identidad y lo inicia
// en Supabase (`signInWithToken`). Así Supabase sabe quién es cada usuario y
// las políticas RLS por `auth.uid()` muestran el contenido privado correcto.
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseIdentityBridge {
  SupabaseIdentityBridge._();

  static String get _bridgeUrl => dotenv.env['BRIDGE_URL'] ?? '';

  /// Evita repetir el intercambio con el mismo usuario (cada cambio de token
  /// Firebase lo vuelve a sincronizar cuando _uid cambia).
  static String? _uidSincronizado;

  /// Traduce la sesión de Firebase a Supabase. Llámala en cada cambio de
  /// autenticación de Firebase. Nunca lanza: la app funciona igual sin
  /// identidad Supabase (solo el contenido privado queda bloqueado por RLS).
  static Future<void> sincronizar(firebase_auth.User? user) async {
    final supabase = Supabase.instance.client;

    if (user == null) {
      _uidSincronizado = null;
      try {
        if (supabase.auth.currentSession != null) {
          await supabase.auth.signOut();
        }
      } catch (e) {
        debugPrint('supabase signOut: $e');
      }
      return;
    }

    if (_uidSincronizado == user.uid) return;

    final url = _bridgeUrl;
    if (url.isEmpty) {
      debugPrint('BRIDGE_URL no configurada; contenido privado bloqueado');
      return;
    }

    try {
      final idToken = await user.getIdToken();
      final res = await http
          .post(
            Uri.parse('$url/auth/bridge'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': idToken}),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) {
        debugPrint('bridge HTTP ${res.statusCode}: ${res.body}');
        return;
      }
      final jwt = (jsonDecode(res.body) as Map<String, dynamic>)['token'];
      if (jwt is! String || jwt.isEmpty) return;
      // JWT firmado con el JWT secret del proyecto: GoTrue lo verifica
      // vía el proveedor 'custom' (grant_type=id_token) y devuelve sesión.
      await supabase.auth.signInWithIdToken(
        provider: const OAuthProvider('custom'),
        idToken: jwt,
      );
      _uidSincronizado = user.uid;
      debugPrint('✅ Identidad Supabase sincronizada (${user.uid})');
    } catch (e) {
      debugPrint('⚠️ SupabaseIdentityBridge: $e');
    }
  }
}
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Perfil del usuario en Supabase (user_profiles) y Storage (profile-pictures).
/// Firestore no se usa en ningún punto de este flujo.
class UserProfileService {
  static final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final ImagePicker _picker = ImagePicker();

  /// Se incrementa al cambiar algo del perfil (p. ej. la foto) para que
  /// los StreamBuilder activos reciban datos nuevos sin Firestore.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static const List<String> _adminEmails = <String>[
    'admin@penalex.ve',
    'ignaciojazpe47@example.com',
  ];

  /// Verifica si el usuario actual es administrador.
  static bool isAdmin() {
    final fb.User? user = _auth.currentUser;
    if (user == null || user.email == null) return false;
    return _adminEmails.contains(user.email!.toLowerCase());
  }

  /// URL pública del avatar. La ruta es estable ({uid}/avatar.jpg), así que
  /// no hace falta guardar la URL en la base de datos: basta el versionado
  /// por `updated_at` para refrescar la caché.
  static String avatarUrl(String uid, {String? version}) {
    final String base =
        _supabase.storage.from('profile-pictures').getPublicUrl('$uid/avatar.jpg');
    return version == null || version.isEmpty ? base : '$base?v=$version';
  }

  /// Perfil + nivel/XP desde Supabase. Sin Firestore.
  /// Emite al suscribirse y cada vez que cambia [revision].
  static Stream<Map<String, dynamic>> userDocStream({int refresh = 0}) async* {
    final fb.User? user = _auth.currentUser;
    if (user == null) return;
    yield await _cargarPerfil(user.uid);
    await for (final int _ in revision.stream) {
      yield await _cargarPerfil(user.uid);
    }
  }

  static Future<Map<String, dynamic>> _cargarPerfil(String uid) async {
    final Map<String, dynamic> datos = <String, dynamic>{
      'nivel_actual': 1,
      'xp_total': 0,
    };
    try {
      final Map<String, dynamic>? fila = await _supabase
          .from('user_profiles')
          .select('name,email,role,updated_at')
          .eq('id', uid)
          .maybeSingle();
      if (fila != null) {
        final String? version = fila['updated_at']?.toString();
        datos.addAll(<String, dynamic>{
          'displayName': fila['name'],
          'email': fila['email'],
          'rol': fila['role'],
          'photoUrl': avatarUrl(uid, version: version),
        });
      }
    } catch (e) {
      debugPrint('Perfil (user_profiles): $e');
    }

    try {
      final Map<String, dynamic>? rank = await _supabase
          .from('quiz_ranking')
          .select('nivel_actual,xp')
          .eq('user_id', uid)
          .maybeSingle();
      if (rank != null) {
        datos['nivel_actual'] = rank['nivel_actual'] ?? 1;
        datos['xp_total'] = rank['xp'] ?? 0;
      }
    } catch (e) {
      debugPrint('Perfil (quiz_ranking): $e');
    }

    return datos;
  }

  /// Sube la foto a Supabase Storage y marca el perfil como actualizado.
  static Future<String?> uploadProfileImage(ImageSource source) async {
    try {
      final fb.User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final XFile? selected = await _picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );
      if (selected == null) return null;

      final Uint8List bytes = await selected.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('No se pudo decodificar la imagen');
      }

      final img.Image resized = img.copyResize(
        image,
        width: image.width > 400 ? 400 : image.width,
        height: image.height > 400 ? 400 : image.height,
      );
      final List<int> compressed = img.encodeJpg(resized, quality: 85);
      if (compressed.length > 2 * 1024 * 1024) {
        throw Exception('Imagen muy grande. Intenta con otra imagen.');
      }

      final String path = '${user.uid}/avatar.jpg';
      await _supabase.storage.from('profile-pictures').uploadBinary(
            path,
            Uint8List.fromList(compressed),
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // Cache-buster: la URL se deriva del uid, no se guarda en la BD.
      final String version = DateTime.now().millisecondsSinceEpoch.toString();
      try {
        await _supabase
            .from('user_profiles')
            .update(<String, dynamic>{'updated_at': DateTime.now().toIso8601String()})
            .eq('id', user.uid);
      } catch (e) {
        debugPrint('No se pudo actualizar updated_at del perfil: $e');
      }

      revision.value++; // refresca el drawer sin recargar la app
      return avatarUrl(user.uid, version: version);
    } catch (e, stack) {
      debugPrint('Error al procesar imagen: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  static String rankLabel(int nivel) {
    if (nivel <= 100) return 'Asistente Judicial';
    if (nivel <= 500) return 'Abogado Litigante';
    return 'Magistrado';
  }
}

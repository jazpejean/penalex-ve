import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'device_id_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_identity_bridge.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthService() {
    // Puente Firebase -> Supabase: cada cambio de sesión de Firebase
    // sincroniza la identidad en Supabase para que el RLS aplique por usuario.
    _auth.authStateChanges().listen((user) {
      SupabaseIdentityBridge.sincronizar(user);
    });
  }

  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();
  firebase_auth.User? get currentUser => _auth.currentUser;

  Future<String?> _getDeviceId() async {
    try {
      // Compatible con Web, Android e iOS (ver device_id_helper.dart)
      return await obtenerDeviceId(_deviceInfo);
    } on Exception catch (e) {
      debugPrint('Error obteniendo ID de dispositivo: $e');
    }
    return null;
  }

  Future<void> registerCurrentDevice() async {
    final user = _auth.currentUser;
    final deviceId = await _getDeviceId();
    if (user != null && deviceId != null) {
      try {
        await _supabase.from('user_profiles').upsert(<String, dynamic>{
          'id': user.uid,
          'last_device_id': deviceId,
          'last_login': DateTime.now().toIso8601String(),
        }, onConflict: 'id');
      } catch (e) {
        debugPrint('No se pudo guardar el dispositivo: $e');
      }
    }
  }

  Future<bool> validateCurrentSession() async {
    final user = _auth.currentUser;
    final deviceId = await _getDeviceId();
    if (user == null || deviceId == null) return false;

    try {
      final fila = await _supabase
          .from('user_profiles')
          .select('last_device_id')
          .eq('id', user.uid)
          .maybeSingle();
      if (fila == null) return true;
      final savedId = fila['last_device_id'];
      return savedId == null || savedId == deviceId;
    } catch (e) {
      debugPrint('No se pudo validar el dispositivo: $e');
      return true;
    }
  }

  /// Sincronizar usuario de Firebase a Supabase (crear o actualizar)
  Future<void> _syncUserToSupabase(firebase_auth.User? user) async {
    if (user == null) return;
    
    try {
      // Verificar si el usuario ya existe en Supabase
      final existing = await _supabase
          .from('user_profiles')
          .select('id')
          .eq('id', user.uid)
          .maybeSingle();
      
      if (existing == null) {
        // No existe, crear nuevo perfil con el UID de Firebase
        await _supabase.from('user_profiles').insert({
          'id': user.uid, // ⭐ MISMO UID de Firebase
          'name': user.displayName ?? 'Usuario',
          'email': user.email ?? '',
          'role': 'user',
          'email_verified': user.emailVerified,
          'created_at': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ Usuario creado en Supabase con UID: ${user.uid}');
      } else {
        // Ya existe, actualizar datos
        await _supabase.from('user_profiles').update({
          'name': user.displayName ?? 'Usuario',
          'email_verified': user.emailVerified,
          'last_login': DateTime.now().toIso8601String(),
        }).eq('id', user.uid);
        debugPrint('✅ Usuario actualizado en Supabase: ${user.uid}');
      }
    } catch (e) {
      debugPrint('⚠️ Error sincronizando con Supabase: $e');
      // No lanzar error, el usuario ya está en Firebase
    }
  }

  Future<firebase_auth.UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    await registerCurrentDevice();
    await _syncUserToSupabase(cred.user); // Sincronizar en cada login
    return cred;
  }

  Future<firebase_auth.UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    await registerCurrentDevice();
    await _syncUserToSupabase(cred.user); // Sincronizar en cada login con Google
    return cred;
  }

  Future<firebase_auth.UserCredential> registerWithEmailAndPassword(
      String email, String password, String name) async {
    final firebase_auth.UserCredential res = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await res.user?.updateDisplayName(name);
    
    // Perfil en Supabase con el MISMO UID de Firebase
    if (res.user != null) {
      await _syncUserToSupabase(res.user);
    }
    
    await res.user?.reload();
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
    return res;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> confirmPasswordReset(String code, String newPassword) async {
    await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
  }

  Future<void> sendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<bool> refreshUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return _auth.currentUser!.emailVerified;
    }
    return false;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<void> logout() async {
    await signOut();
  }

  Future<firebase_auth.UserCredential> signInAnonymously() async {
    final firebase_auth.UserCredential cred = await _auth.signInAnonymously();
    await registerCurrentDevice();
    await _syncUserToSupabase(cred.user);
    return cred;
  }
}

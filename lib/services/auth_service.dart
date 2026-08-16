import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();
  firebase_auth.User? get currentUser => _auth.currentUser;

  Future<String?> _getDeviceId() async {
    try {
      // Soporte para web
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        // Usar una combinación de propiedades del navegador como ID
        return '${webInfo.vendor}_${webInfo.userAgent}_${webInfo.browserName}'.hashCode.toString();
      }
      
      if (Platform.isAndroid) {
        final build = await _deviceInfo.androidInfo;
        return build.id;
      } else if (Platform.isIOS) {
        final data = await _deviceInfo.iosInfo;
        return data.identifierForVendor;
      }
    } on Exception catch (e) {
      debugPrint('Error obteniendo ID de dispositivo: $e');
    }
    return null;
  }

  Future<void> registerCurrentDevice() async {
    final user = _auth.currentUser;
    final deviceId = await _getDeviceId();
    if (user != null && deviceId != null) {
      await _db.collection('users').doc(user.uid).set({
        'lastDeviceId': deviceId,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<bool> validateCurrentSession() async {
    final user = _auth.currentUser;
    final deviceId = await _getDeviceId();
    if (user == null || deviceId == null) return false;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return true;

    final savedId = doc.data()?['lastDeviceId'];
    return savedId == deviceId;
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
    
    // Guardar en Firebase Firestore
    if (res.user != null) {
      await _db.collection('users').doc(res.user!.uid).set({
        'name': name,
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
      });
      
      // TAMBIÉN guardar en Supabase con el MISMO UID de Firebase
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

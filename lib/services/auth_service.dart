import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<String?> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo build = await _deviceInfo.androidInfo;
        return build.id;
      } else if (Platform.isIOS) {
        final IosDeviceInfo data = await _deviceInfo.iosInfo;
        return data.identifierForVendor;
      }
    } on Exception catch (e) {
      debugPrint('Error obteniendo ID de dispositivo: $e');
    }
    return null;
  }

  Future<void> _ensureUserDocument(User user) async {
    await _db.collection('users').doc(user.uid).set(<String, dynamic>{
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
      'nivel_actual': 1,
      'xp_total': 0,
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> registerCurrentDevice() async {
    final User? user = _auth.currentUser;
    final String? deviceId = await _getDeviceId();
    if (user != null) {
      if (deviceId != null) {
        await _db.collection('users').doc(user.uid).set(<String, dynamic>{
          'lastDeviceId': deviceId,
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await _ensureUserDocument(user);
    }
  }

  Future<bool> validateCurrentSession() async {
    final User? user = _auth.currentUser;
    final String? deviceId = await _getDeviceId();
    if (user == null) return false;

    // Si no se puede obtener el ID, permitimos acceso (web o error)
    if (deviceId == null) return true;

    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return true;

    final savedId = doc.data()?['lastDeviceId'];
    return savedId == deviceId;
  }

  Future<UserCredential> signInAnonymously() async {
    final UserCredential cred = await _auth.signInAnonymously();
    await registerCurrentDevice();
    return cred;
  }

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    final UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    await registerCurrentDevice();
    return cred;
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final UserCredential cred = await _auth.signInWithCredential(credential);
      await registerCurrentDevice();
      return cred;
    } on FirebaseAuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Error during Google Sign-In: $e');
      rethrow;
    }
  }

  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, String name) async {
    final UserCredential res = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await res.user?.updateDisplayName(name);
    await res.user?.reload();
    final User? user = _auth.currentUser;
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
    final User? user = _auth.currentUser;
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
}
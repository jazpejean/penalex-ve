import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AppAuthProvider extends ChangeNotifier {
  AppAuthProvider();

  AuthService? _authService;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<User?>? _idTokenSub;
  User? _user;
  bool _isLoading = false;
  bool _isDeviceValid = true;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isDeviceValid => _isDeviceValid;
  String? get error => _error;

  String? get userName {
    if (_user?.displayName != null) return _user!.displayName!.split(' ').first;
    return _user?.email?.split('@').first;
  }

  bool get isEmailVerified => _user?.emailVerified ?? false;

  void setAuthService(AuthService authService) {
    if (_authService != null) return;
    _authService = authService;
    _setupAuthListeners();
  }

  void _setupAuthListeners() {
    if (_authService == null) return;
    _authSub = _authService!.authStateChanges.listen((User? user) async {
      _user = user;
      if (user != null) {
        await revalidateDeviceSession();
        _startIdTokenListener();
      } else {
        _stopIdTokenListener();
        _isDeviceValid = true;
        notifyListeners();
      }
    });
  }

  void _startIdTokenListener() {
    _stopIdTokenListener();
    _idTokenSub = FirebaseAuth.instance.idTokenChanges().listen((User? user) {
      if (user != null) {
        revalidateDeviceSession();
      }
    });
  }

  void _stopIdTokenListener() {
    _idTokenSub?.cancel();
    _idTokenSub = null;
  }

  Future<void> revalidateDeviceSession() async {
    if (_authService == null) return;
    final User? user = _user;
    if (user == null) {
      _isDeviceValid = true;
      notifyListeners();
      return;
    }
    try {
      final bool ok = await _authService!.validateCurrentSession();
      if (_isDeviceValid != ok) {
        _isDeviceValid = ok;
        notifyListeners();
      }
    } on Exception catch (_) {
      // For now, allow access even if device validation fails
      if (!_isDeviceValid) {
        _isDeviceValid = true;
        notifyListeners();
      }
    }
  }

  Future<bool> resendVerificationEmail() async {
    if (_authService == null) return false;
    _setLoading(true);
    _clearError();
    try {
      await _authService!.sendVerificationEmail();
      return true;
    } on Exception catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String oobCode, String newPassword) async {
    if (_authService == null) return false;
    _setLoading(true);
    _clearError();
    try {
      await _authService!.confirmPasswordReset(oobCode, newPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e);
      return false;
    } on Exception catch (e) {
      _error = 'No se pudo actualizar la contraseña. Intenta de nuevo.';
      debugPrint('resetPassword error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'expired-action-code':
        return 'El enlace expiró. Solicita uno nuevo.';
      case 'invalid-action-code':
        return 'El enlace o código es inválido. Solicita uno nuevo.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'user-not-found':
        return 'No existe una cuenta asociada a este enlace.';
      case 'weak-password':
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      case 'network-request-failed':
        return 'Error de conexión. Revisa tu internet.';
      default:
        return 'No se pudo actualizar la contraseña. Intenta de nuevo.';
    }
  }

  Future<bool> refreshUser() async {
    if (_authService == null) return false;
    _setLoading(true);
    _clearError();
    try {
      final bool verified = await _authService!.refreshUser();
      notifyListeners();
      return verified;
    } on Exception catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    if (_authService == null) return;
    await _authService!.signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _stopIdTokenListener();
    super.dispose();
  }
}

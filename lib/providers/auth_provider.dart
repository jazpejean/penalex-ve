import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AppAuthProvider extends ChangeNotifier {
  AppAuthProvider({required AuthService authService})
      : _authService = authService {
    _setupAuthListeners();
  }

  final AuthService _authService;
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

  void _setupAuthListeners() {
    _authSub = _authService.authStateChanges.listen((User? user) async {
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
        unawaited(revalidateDeviceSession());
      }
    });
  }

  void _stopIdTokenListener() {
    _idTokenSub?.cancel();
    _idTokenSub = null;
  }

  Future<void> revalidateDeviceSession() async {
    final User? user = _user;
    if (user == null) {
      _isDeviceValid = true;
      notifyListeners();
      return;
    }
    try {
      final bool ok = await _authService.validateCurrentSession();
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
    _setLoading(true);
    _clearError();
    try {
      await _authService.sendVerificationEmail();
      return true;
    } on Exception catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String oobCode, String newPassword) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.confirmPasswordReset(oobCode, newPassword);
      return true;
    } on Exception catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> refreshUser() async {
    _setLoading(true);
    _clearError();
    try {
      final bool verified = await _authService.refreshUser();
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
    await _authService.signOut();
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
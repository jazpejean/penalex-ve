import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_auth_service.dart';

class SupabaseAuthProvider extends ChangeNotifier {
  SupabaseAuthProvider();

  SupabaseAuthService? _authService;
  StreamSubscription<AuthState>? _authSub;
  User? _user;
  bool _isLoading = false;
  bool _isDeviceValid = true;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isDeviceValid => _isDeviceValid;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  String? get userName {
    if (_user?.userMetadata?['name'] != null) {
      return _user!.userMetadata!['name'].toString().split(' ').first;
    }
    return _user?.email?.split('@').first;
  }

  bool get isEmailVerified {
    // En Supabase, la confirmación de email se maneja diferente
    // El usuario está confirmado si tiene email_confirmed_at
    return _user?.emailConfirmedAt != null;
  }

  void setAuthService(SupabaseAuthService authService) {
    if (_authService != null) return;
    _authService = authService;
    _setupAuthListeners();
  }

  void _setupAuthListeners() {
    if (_authService == null) return;
    
    // Establecer usuario inicial
    _user = _authService!.currentUser;
    
    // Escuchar cambios de autenticación
    _authSub = _authService!.authStateChanges.listen((AuthState state) async {
      _user = state.session?.user;
      
      if (_user != null) {
        await revalidateDeviceSession();
      } else {
        _isDeviceValid = true;
      }
      
      notifyListeners();
    });
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
    } on Exception catch (e) {
      debugPrint('Error validando sesión: $e');
      // Permitir acceso incluso si falla la validación
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
      await _authService!.resendVerificationEmail();
      return true;
    } on AuthException catch (e) {
      _error = _mapSupabaseError(e);
      return false;
    } on Exception catch (e) {
      _error = 'No se pudo enviar el correo. Intenta de nuevo.';
      debugPrint('resendVerificationEmail error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String newPassword) async {
    if (_authService == null) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      await _authService!.updatePassword(newPassword);
      return true;
    } on AuthException catch (e) {
      _error = _mapSupabaseError(e);
      return false;
    } on Exception catch (e) {
      _error = 'No se pudo actualizar la contraseña. Intenta de nuevo.';
      debugPrint('resetPassword error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String _mapSupabaseError(AuthException e) {
    // Mapeo de errores comunes de Supabase
    final message = e.message.toLowerCase();
    
    if (message.contains('invalid login credentials') || 
        message.contains('invalid email or password')) {
      return 'Credenciales inválidas. Verifica tu email y contraseña.';
    }
    if (message.contains('email not confirmed')) {
      return 'Debes verificar tu correo antes de iniciar sesión.';
    }
    if (message.contains('user already registered')) {
      return 'Este correo ya está registrado. Intenta iniciar sesión.';
    }
    if (message.contains('password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (message.contains('unable to validate email')) {
      return 'El correo electrónico no es válido.';
    }
    if (message.contains('email rate limit exceeded')) {
      return 'Demasiados intentos. Espera un momento e intenta nuevamente.';
    }
    if (message.contains('invalid token') || message.contains('token expired')) {
      return 'El enlace expiró. Solicita uno nuevo.';
    }
    
    return e.message;
  }

  Future<bool> refreshUser() async {
    if (_authService == null) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService!.refreshUser();
      _user = user;
      notifyListeners();
      return user?.emailConfirmedAt != null;
    } on Exception catch (e) {
      _error = e.toString();
      debugPrint('refreshUser error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    if (_authService == null) return;
    await _authService!.signOut();
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_authService == null) return null;
    return await _authService!.getUserProfile();
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (_authService == null) return;
    
    try {
      await _authService!.updateUserProfile(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Error actualizando perfil: $e');
      rethrow;
    }
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
    super.dispose();
  }
}

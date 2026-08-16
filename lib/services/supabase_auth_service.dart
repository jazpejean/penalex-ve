import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Stream de cambios de autenticación
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  
  // Usuario actual
  User? get currentUser => _supabase.auth.currentUser;
  
  // Session actual
  Session? get currentSession => _supabase.auth.currentSession;

  /// Obtener ID único del dispositivo
  Future<String?> _getDeviceId() async {
    try {
      // Soporte para web
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return '${webInfo.vendor}_${webInfo.userAgent}_${webInfo.browserName}'
            .hashCode
            .toString();
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

  /// Registrar el dispositivo actual en la tabla de perfiles
  Future<void> registerCurrentDevice() async {
    final user = currentUser;
    final deviceId = await _getDeviceId();
    
    if (user != null && deviceId != null) {
      try {
        await _supabase.from('user_profiles').upsert({
          'id': user.id,
          'last_device_id': deviceId,
          'last_login': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Error registrando dispositivo: $e');
      }
    }
  }

  /// Validar sesión del dispositivo actual
  Future<bool> validateCurrentSession() async {
    final user = currentUser;
    final deviceId = await _getDeviceId();
    
    if (user == null || deviceId == null) return false;

    try {
      final response = await _supabase
          .from('user_profiles')
          .select('last_device_id')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return true;

      final savedId = response['last_device_id'];
      return savedId == deviceId;
    } catch (e) {
      debugPrint('Error validando sesión: $e');
      // En caso de error, permitir acceso
      return true;
    }
  }

  /// Iniciar sesión con email y contraseña
  Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    await registerCurrentDevice();
    return response;
  }

  /// Iniciar sesión con Google (OAuth)
  Future<bool> signInWithGoogle() async {
    try {
      debugPrint('🔐 Iniciando Google Sign-In...');
      
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.penalex://login-callback',
      );
      
      debugPrint('✅ Google OAuth response: $response');
      
      if (response) {
        await registerCurrentDevice();
      }
      
      return response;
    } on AuthException catch (e) {
      debugPrint('❌ AuthException en Google Sign-In: ${e.message}');
      debugPrint('   Código: ${e.statusCode}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Error en Google Sign-In: $e');
      rethrow;
    }
  }

  /// Registrar nuevo usuario con email y contraseña
  Future<AuthResponse> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      debugPrint('🔐 Iniciando registro para: $email');
      
      // Crear cuenta en Supabase Auth con emailRedirectTo configurado
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
        emailRedirectTo: kIsWeb 
            ? '${Uri.base.origin}/login' 
            : 'io.supabase.penalex://login-callback',
      );

      debugPrint('✅ Usuario creado en Auth: ${response.user?.id}');

      // Si el usuario fue creado, crear su perfil
      if (response.user != null) {
        try {
          await _supabase.from('user_profiles').insert({
            'id': response.user!.id,
            'name': name,
            'email': email,
            'role': 'user',
            'email_verified': false,
            'created_at': DateTime.now().toIso8601String(),
          });
          debugPrint('✅ Perfil creado en user_profiles');
        } catch (e) {
          debugPrint('⚠️ Error creando perfil (no crítico): $e');
          // No lanzar error, el usuario ya fue creado en Auth
        }
      }

      return response;
    } catch (e) {
      debugPrint('❌ Error en registro: $e');
      rethrow;
    }
  }

  /// Enviar email de recuperación de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb 
          ? '${Uri.base.origin}/reset-password' 
          : 'io.supabase.penalex://reset-password',
    );
  }

  /// Actualizar contraseña (cuando el usuario tiene un token de reset)
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Reenviar email de verificación
  Future<void> resendVerificationEmail() async {
    final user = currentUser;
    if (user != null && user.email != null) {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: user.email!,
      );
    }
  }

  /// Refrescar información del usuario
  Future<User?> refreshUser() async {
    final response = await _supabase.auth.refreshSession();
    return response.user;
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Iniciar sesión anónima (si lo necesitas)
  Future<AuthResponse> signInAnonymously() async {
    final response = await _supabase.auth.signInAnonymously();
    await registerCurrentDevice();
    return response;
  }

  /// Obtener perfil completo del usuario
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      
      return response;
    } catch (e) {
      debugPrint('Error obteniendo perfil: $e');
      return null;
    }
  }

  /// Actualizar perfil del usuario
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user == null) return;

    await _supabase.from('user_profiles').upsert({
      'id': user.id,
      ...data,
    });
  }
}

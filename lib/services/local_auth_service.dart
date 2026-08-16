import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de autenticación LOCAL que funciona 100% sin conexión.
/// Guarda en SharedPreferences si el usuario inició sesión previamente.
/// NO depende de Firebase ni de internet.
class LocalAuthService {
  static const String _keyIsLoggedIn = 'local_is_logged_in';
  static const String _keyUserEmail = 'local_user_email';
  static const String _keyUserName = 'local_user_name';
  static const String _keyEmailVerified = 'local_email_verified';

  /// Verifica si hay una sesión local guardada.
  /// Esto funciona instantáneamente y sin conexión.
  static Future<bool> isLoggedIn() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsLoggedIn) ?? false;
    } on Exception catch (_) {
      return false;
    }
  }

  /// Guarda la sesión localmente.
  static Future<void> saveSession({
    required String email,
    required String name,
    required bool emailVerified,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserEmail, email);
      await prefs.setString(_keyUserName, name);
      await prefs.setBool(_keyEmailVerified, emailVerified);
    } on Exception catch (_) {
      // Ignorar errores de almacenamiento local
    }
  }

  /// Actualiza solo el estado de verificación de email.
  static Future<void> updateEmailVerified({required bool verified}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEmailVerified, verified);
    } on Exception catch (_) {
      // Ignorar
    }
  }

  /// Obtiene el email guardado localmente.
  static Future<String?> getSavedEmail() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserEmail);
    } on Exception catch (_) {
      return null;
    }
  }

  /// Obtiene el nombre guardado localmente.
  static Future<String?> getSavedName() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserName);
    } on Exception catch (_) {
      return null;
    }
  }

  /// Obtiene si el email estaba verificado según el último guardado local.
  static Future<bool> isEmailVerifiedLocally() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyEmailVerified) ?? false;
    } on Exception catch (_) {
      return false;
    }
  }

  /// Limpia la sesión local (logout).
  static Future<void> clearSession() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, false);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserName);
      await prefs.remove(_keyEmailVerified);
    } on Exception catch (_) {
      // Ignorar
    }
  }
}

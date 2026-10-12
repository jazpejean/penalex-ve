import 'package:firebase_auth/firebase_auth.dart';
import '../services/haptics_service.dart';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

String _getFirebaseErrorMessage(String errorCode) {
  if (errorCode.contains('email-already-in-use')) {
    return 'Este correo ya está registrado. Intenta iniciar sesión o usa otra cuenta.';
  }
  if (errorCode.contains('invalid-email')) {
    return 'El correo electrónico no es válido.';
  }
  if (errorCode.contains('weak-password')) {
    return 'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
  }
  if (errorCode.contains('network-request-failed')) {
    return 'Error de conexión. Revisa tu internet.';
  }
  if (errorCode.contains('user-not-found')) {
    return 'No existe una cuenta con este correo.';
  }
  if (errorCode.contains('wrong-password')) {
    return 'Contraseña incorrecta. Intenta de nuevo.';
  }
  if (errorCode.contains('too-many-requests')) {
    return 'Demasiados intentos. Espera un momento e intenta nuevamente.';
  }
  return 'Ocurrió un error inesperado. Intenta de nuevo.';
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _errorMessage = '';
  bool _isLoading = false;

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static Color get fondoGris => TemaGlobal.superficie;
  static const Color grisTexto = Color(0xFF4A5568);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _showVerifyEmailDialog({required bool resent}) {
    final subtitle = resent
        ? 'Te reenviamos el correo de verificación. Revisa tu bandeja de entrada y también la carpeta de spam.'
        : 'Por favor, revisa tu bandeja de entrada (y spam) para verificar tu correo antes de iniciar sesión.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Correo no verificado',
          style: TextStyle(color: TemaGlobal.texto, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle,
                style: TextStyle(color: azulMarino.withValues(alpha: 0.85))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.10)),
              ),
              child: Row(
                children: [
                  Icon(Icons.mark_email_unread_outlined,
                      color: azulMarino.withValues(alpha: 0.85)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Abre el enlace del correo y luego intenta iniciar sesión nuevamente.',
                      style: TextStyle(
                          color: azulMarino.withValues(alpha: 0.80),
                          height: 1.2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido', style: TextStyle(color: azulMarino)),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    Haptics.light();
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      Haptics.error();
      setState(() {
        _errorMessage = 'Ingresa un correo electrónico válido';
        _isLoading = false;
      });
      _showSnackBar('Ingresa un correo electrónico válido.', isError: true);
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Ingresa tu contraseña';
        _isLoading = false;
      });
      _showSnackBar('La contraseña no puede estar vacía.', isError: true);
      return;
    }

    final AuthService auth = context.read<AuthService>();
    try {
      await auth.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      final User? user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      final User? refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && !refreshedUser.emailVerified) {
        bool resent = false;
        try {
          await refreshedUser.sendEmailVerification();
          resent = true;
        } on Exception catch (_) {}
        await auth.signOut();
        _showVerifyEmailDialog(resent: resent);
        setState(() => _isLoading = false);
        return;
      }
    } on FirebaseAuthException catch (e) {
      final String errorMsg = _getFirebaseErrorMessage(e.toString());
      setState(() => _errorMessage = errorMsg);
      _showSnackBar(errorMsg, isError: true);
    } on Exception catch (e) {
      final String errorMsg = _getFirebaseErrorMessage(e.toString());
      setState(() => _errorMessage = errorMsg);
      _showSnackBar(errorMsg, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    Haptics.light();
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });
    final AuthService auth = context.read<AuthService>();
    try {
      final UserCredential? cred = await auth.signInWithGoogle();
      if (cred == null) {
        setState(() => _isLoading = false);
        return;
      }
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await auth.signOut();
        _showSnackBar(
            'Tu cuenta de Google no tiene el correo verificado. Por favor, verifícalo antes de continuar.',
            isError: true);
        setState(() => _isLoading = false);
        return;
      }
    } on FirebaseAuthException catch (e) {
      final String errorMsg = _getFirebaseErrorMessage(e.toString());
      setState(() => _errorMessage = errorMsg);
      _showSnackBar(errorMsg, isError: true);
    } on Exception catch (e) {
      final String errorMsg = _getFirebaseErrorMessage(e.toString());
      setState(() => _errorMessage = errorMsg);
      _showSnackBar(errorMsg, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondoGris,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(24, 40, 24,
                  MediaQuery.of(context).viewInsets.bottom + 30),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight:
                        constraints.maxHeight -
                        MediaQuery.of(context).viewInsets.bottom),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                const Icon(Icons.gavel_rounded, size: 80, color: azulMarino),
                const SizedBox(height: 24),
                const Text(
                  'Penalex VE',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: azulMarino),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Inicia sesión para continuar',
                  style: TextStyle(fontSize: 16, color: grisTexto),
                ),
                const SizedBox(height: 40),
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(_errorMessage,
                                style: const TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined,
                        color: azulMarino.withValues(alpha: 0.90)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline,
                        color: azulMarino.withValues(alpha: 0.90)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: azulMarino.withValues(alpha: 0.90),
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage()),
                    ),
                    child: const Text('¿Olvidaste tu contraseña?',
                        style: TextStyle(color: azulMarino)),
                  ),
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azulMarino,
                      foregroundColor: dorado,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('INICIAR SESIÓN',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _loginWithGoogle,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: dorado.withValues(alpha: 0.85), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        'assets/images/google_logo.png',
                        height: 24,
                        width: 24,
                        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
                            Icon(Icons.g_mobiledata,
                                size: 24, color: Color(0xFFDB4437)),
                      ),
                      SizedBox(width: 12),
                      Text('Iniciar con Google',
                          style: TextStyle(color: TemaGlobal.texto, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text('¿No tienes cuenta? ',
                        style: TextStyle(color: grisTexto)),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => RegisterPage()),
                      ),
                      child: Text('Regístrate',
                          style: TextStyle(
                              color: TemaGlobal.texto, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
              ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_auth_service.dart';
import 'supabase_register_page.dart';
import 'forgot_password_page.dart';

String _getSupabaseErrorMessage(String errorMessage) {
  final message = errorMessage.toLowerCase();
  
  if (message.contains('invalid login credentials') || 
      message.contains('invalid email or password')) {
    return 'Credenciales inválidas. Verifica tu email y contraseña.';
  }
  if (message.contains('email not confirmed')) {
    return 'Debes verificar tu correo antes de iniciar sesión. Revisa tu bandeja de entrada.';
  }
  if (message.contains('invalid email')) {
    return 'El correo electrónico no es válido.';
  }
  if (message.contains('user not found')) {
    return 'No existe una cuenta con este correo.';
  }
  if (message.contains('too many requests') || 
      message.contains('rate limit')) {
    return 'Demasiados intentos. Espera un momento e intenta nuevamente.';
  }
  if (message.contains('network')) {
    return 'Error de conexión. Revisa tu internet.';
  }
  
  return 'Ocurrió un error inesperado. Intenta de nuevo.';
}

class SupabaseLoginPage extends StatefulWidget {
  const SupabaseLoginPage({super.key});

  @override
  State<SupabaseLoginPage> createState() => _SupabaseLoginPageState();
}

class _SupabaseLoginPageState extends State<SupabaseLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _errorMessage = '';
  bool _isLoading = false;

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color fondoGris = Color(0xFFF1F5F9);
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
        title: const Text(
          'Correo no verificado',
          style: TextStyle(color: azulMarino, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle,
                style: TextStyle(color: azulMarino.withOpacity(0.85))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: azulMarino.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: azulMarino.withOpacity(0.10)),
              ),
              child: Row(
                children: [
                  Icon(Icons.mark_email_unread_outlined,
                      color: azulMarino.withOpacity(0.85)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Abre el enlace del correo y luego intenta iniciar sesión nuevamente.',
                      style: TextStyle(
                          color: azulMarino.withOpacity(0.80), height: 1.2),
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
            child: const Text('Entendido', style: TextStyle(color: dorado)),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
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

    final SupabaseAuthService auth = context.read<SupabaseAuthService>();
    try {
      final response = await auth.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Verificar si el email está confirmado
      if (response.user != null && response.user!.emailConfirmedAt == null) {
        await auth.signOut();
        _showVerifyEmailDialog(resent: false);
        setState(() => _isLoading = false);
        return;
      }

      // Login exitoso, la navegación se manejará por el stream de auth
    } on AuthException catch (e) {
      final String errorMsg = _getSupabaseErrorMessage(e.message);
      setState(() => _errorMessage = errorMsg);
      _showSnackBar(errorMsg, isError: true);
    } on Exception catch (e) {
      final String errorMsg = _getSupabaseErrorMessage(e.toString());
      setState(() => _errorMessage = errorMsg);
      _showSnackBar(errorMsg, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    final SupabaseAuthService auth = context.read<SupabaseAuthService>();
    try {
      final success = await auth.signInWithGoogle();
      
      if (!success) {
        _showSnackBar('No se pudo iniciar sesión con Google.', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // El flujo OAuth manejará la redirección automáticamente
      _showSnackBar('Redirigiendo a Google...');
    } on AuthException catch (e) {
      final String errorMsg = _getSupabaseErrorMessage(e.message);
      setState(() => _errorMessage = errorMsg);
      _showSnackBar(errorMsg, isError: true);
    } on Exception catch (e) {
      final String errorMsg = _getSupabaseErrorMessage(e.toString());
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
          builder: (BuildContext context, BoxConstraints constraints) =>
              SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
                24, 40, 24, MediaQuery.of(context).viewInsets.bottom + 30),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: constraints.maxHeight -
                      MediaQuery.of(context).viewInsets.bottom),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.gavel_rounded,
                        size: 80, color: azulMarino),
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
                            color: azulMarino.withOpacity(0.90)),
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
                            color: azulMarino.withOpacity(0.90)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: azulMarino.withOpacity(0.90),
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
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
                    // GOOGLE SIGN-IN TEMPORALMENTE DESHABILITADO
                    // Para habilitarlo, configura Google OAuth en Supabase
                    /* const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _loginWithGoogle,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: dorado.withOpacity(0.85), width: 1.5),
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
                            errorBuilder: (BuildContext context, Object error,
                                    StackTrace? stackTrace) =>
                                const Icon(Icons.g_mobiledata,
                                    size: 24, color: Color(0xFFDB4437)),
                          ),
                          const SizedBox(width: 12),
                          const Text('Iniciar con Google',
                              style:
                                  TextStyle(color: azulMarino, fontSize: 16)),
                        ],
                      ),
                    ), */
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
                                builder: (_) => const SupabaseRegisterPage()),
                          ),
                          child: const Text('Regístrate',
                              style: TextStyle(
                                  color: dorado, fontWeight: FontWeight.bold)),
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

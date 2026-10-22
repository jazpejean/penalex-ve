import 'dart:async';
import '../services/haptics_service.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

// Función para traducir errores de Firebase
String _getFirebaseErrorMessage(String errorCode) {
  if (errorCode.contains('email-already-in-use')) return 'Este correo ya está registrado. Intenta iniciar sesión o usa otra cuenta.';
  if (errorCode.contains('invalid-email')) return 'El correo electrónico no es válido.';
  if (errorCode.contains('weak-password')) return 'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
  if (errorCode.contains('network-request-failed')) return 'Error de conexión. Revisa tu internet.';
  return 'Ocurrió un error inesperado. Intenta de nuevo.';
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static Color get fondoGris => TemaGlobal.superficie;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showDialog(String titulo, String mensaje, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(titulo, style: TextStyle(color: TemaGlobal.texto, fontWeight: FontWeight.bold)),
        content: Text(mensaje, style: TextStyle(color: isError ? Colors.red : TemaGlobal.textoSecundario)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Entendido', style: TextStyle(color: TemaGlobal.dorado)),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    Haptics.light();
    FocusScope.of(context).unfocus();

    if (_nameController.text.trim().isEmpty) {
      _showDialog('Nombre requerido', 'Por favor, ingresa tu nombre completo.', isError: true);
      Haptics.error();
      return;
    }
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
      _showDialog('Correo inválido', 'Ingresa un correo electrónico válido.', isError: true);
      Haptics.error();
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showDialog('Contraseña requerida', 'La contraseña no puede estar vacía.', isError: true);
      Haptics.error();
      return;
    }
    if (_passwordController.text.length < 6) {
      _showDialog('Contraseña débil', 'La contraseña debe tener al menos 6 caracteres.', isError: true);
      Haptics.error();
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      _showDialog('Contraseñas no coinciden', 'Las contraseñas ingresadas no son iguales.', isError: true);
      Haptics.error();
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthService>();
    try {
      await auth.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      if (mounted) {
        _showDialog('¡Registro exitoso!', 'Revisa tu correo para verificar tu cuenta.');
        // Redirige a la pantalla de verificación de correo
        unawaited(Navigator.pushReplacementNamed(context, '/verify-email'));
      }
    } on FirebaseAuthException catch (e) {
      final errorMsg = _getFirebaseErrorMessage(e.code);
      _showDialog('Error al registrarse', errorMsg, isError: true);
    } catch (e) {
      final errorMsg = _getFirebaseErrorMessage(e.toString());
      _showDialog('Error al registrarse', errorMsg, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondoGris,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add_alt_1, size: 80, color: TemaGlobal.texto),
              const SizedBox(height: 24),
              Text(
                'Crear cuenta',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: TemaGlobal.texto),
              ),
              const SizedBox(height: 8),
              Text(
                'Regístrate para comenzar',
                style: TextStyle(fontSize: 16, color: TemaGlobal.textoSecundario),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline, color: TemaGlobal.textoSecundario),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined, color: TemaGlobal.textoSecundario),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_outline, color: TemaGlobal.textoSecundario),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: TemaGlobal.textoSecundario),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: Icon(Icons.lock_outline, color: TemaGlobal.textoSecundario),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: TemaGlobal.textoSecundario),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _register(),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TemaGlobal.azulMarino,
                    foregroundColor: TemaGlobal.dorado,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('CREAR CUENTA', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('¿Ya tienes cuenta? ', style: TextStyle(color: TemaGlobal.textoSecundario)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Inicia sesión', style: TextStyle(color: TemaGlobal.texto, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
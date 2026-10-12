import 'dart:async';

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

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static Color get fondoGris => TemaGlobal.superficie;
  static const Color grisTexto = Color(0xFF4A5568);

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
        content: Text(mensaje, style: TextStyle(color: isError ? Colors.red : azulMarino)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido', style: TextStyle(color: azulMarino)),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (_nameController.text.trim().isEmpty) {
      _showDialog('Nombre requerido', 'Por favor, ingresa tu nombre completo.', isError: true);
      return;
    }
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
      _showDialog('Correo inválido', 'Ingresa un correo electrónico válido.', isError: true);
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showDialog('Contraseña requerida', 'La contraseña no puede estar vacía.', isError: true);
      return;
    }
    if (_passwordController.text.length < 6) {
      _showDialog('Contraseña débil', 'La contraseña debe tener al menos 6 caracteres.', isError: true);
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      _showDialog('Contraseñas no coinciden', 'Las contraseñas ingresadas no son iguales.', isError: true);
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
              const Icon(Icons.person_add_alt_1, size: 80, color: azulMarino),
              const SizedBox(height: 24),
              const Text(
                'Crear cuenta',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: azulMarino),
              ),
              const SizedBox(height: 8),
              const Text(
                'Regístrate para comenzar',
                style: TextStyle(fontSize: 16, color: grisTexto),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: const Icon(Icons.person_outline, color: azulMarino),
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
                  prefixIcon: const Icon(Icons.email_outlined, color: azulMarino),
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
                  prefixIcon: const Icon(Icons.lock_outline, color: azulMarino),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: azulMarino),
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
                  prefixIcon: const Icon(Icons.lock_outline, color: azulMarino),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: azulMarino),
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
                    backgroundColor: azulMarino,
                    foregroundColor: dorado,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('CREAR CUENTA', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('¿Ya tienes cuenta? ', style: TextStyle(color: grisTexto)),
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
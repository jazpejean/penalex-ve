import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isCooldown = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  bool _emailSent = false;

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color fondoGris = Color(0xFFF1F5F9);
  static const Color grisTexto = Color(0xFF4A5568);

  @override
  void dispose() {
    _emailController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _isCooldown = true;
      _cooldownSeconds = 60;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        if (_cooldownSeconds > 0) {
          _cooldownSeconds--;
        } else {
          _isCooldown = false;
          timer.cancel();
        }
      });
    });
  }

  void _showDialog(String title, String message, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: azulMarino, fontWeight: FontWeight.bold)),
        content: Text(message, style: TextStyle(color: isError ? Colors.red : azulMarino)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido', style: TextStyle(color: dorado)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendResetEmail() async {
    if (_isCooldown) return;

    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showDialog('Correo inválido', 'Ingresa un correo electrónico válido.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _emailSent = false;
    });
    final AuthService auth = context.read<AuthService>();
    try {
      await auth.sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) {
        _startCooldown();
        setState(() => _emailSent = true);
        _showDialog(
          'Enlace enviado',
          'Revisa tu correo. Enviamos un enlace para restablecer tu contraseña.\n'
          'Si no lo ves en unos minutos, revisa tu carpeta de SPAM.\n\n'
          'Después de cambiar tu contraseña, presiona el botón "YA CAMBIÉ MI CONTRASEÑA".',
        );
      }
    } on Exception catch (e) {
      _showDialog('Error', e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: fondoGris,
      appBar: AppBar(
        backgroundColor: azulMarino,
        elevation: 0,
        title: const Text("Recuperar cuenta", style: TextStyle(color: dorado)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.lock_reset_outlined, size: 80, color: azulMarino),
              const SizedBox(height: 20),
              const Text("¿Olvidaste tu contraseña?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: azulMarino)),
              const SizedBox(height: 8),
              const Text("Te enviaremos un enlace para restablecer tu contraseña", style: TextStyle(fontSize: 16, color: grisTexto)),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Correo electrónico",
                  prefixIcon: const Icon(Icons.email_outlined, color: azulMarino),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: _isCooldown ? null : _sendResetEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azulMarino,
                        foregroundColor: dorado,
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      child: Text(_isCooldown ? "Reenviar en $_cooldownSeconds s" : "ENVIAR ENLACE"),
                    ),
                    if (_emailSent) ...<Widget>[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/reset-password');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: azulMarino,
                          side: const BorderSide(color: dorado),
                          minimumSize: const Size(double.infinity, 52),
                        ),
                        child: const Text("TENGO EL ENLACE / CÓDIGO"),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: azulMarino,
                          foregroundColor: dorado,
                          minimumSize: const Size(double.infinity, 52),
                        ),
                        child: const Text("YA CAMBIÉ MI CONTRASEÑA"),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/reset-password'),
                child: const Text("Ya tengo el código de restablecimiento",
                    style: TextStyle(color: dorado)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Volver al login", style: TextStyle(color: azulMarino)),
              ),
            ],
          ),
        ),
      ),
    );
}
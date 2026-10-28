import 'dart:async';
import '../services/haptics_service.dart';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_theme.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/app_bar_institucional.dart';

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

  static Color get fondoGris => TemaGlobal.superficie;

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
        title: Text(title, style: TextStyle(color: TemaGlobal.texto, fontWeight: FontWeight.bold)),
        content: Text(message, style: TextStyle(color: isError ? AppColors.error : TemaGlobal.textoSecundario)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Entendido', style: TextStyle(color: TemaGlobal.dorado)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendResetEmail() async {
    Haptics.light();
    if (_isCooldown) return;

    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      Haptics.error();
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
            appBar: AppBarInstitucional(
        title: 'Recuperar cuenta',
        mostrarBack: true,
        mostrarHome: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.lock_reset_outlined, size: 80, color: TemaGlobal.texto),
              const SizedBox(height: 20),
              Text("¿Olvidaste tu contraseña?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: TemaGlobal.texto)),
              const SizedBox(height: 8),
              Text("Te enviaremos un enlace para restablecer tu contraseña", style: TextStyle(fontSize: 16, color: TemaGlobal.textoSecundario)),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Correo electrónico",
                  prefixIcon: Icon(Icons.email_outlined, color: TemaGlobal.textoSecundario),
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
                        backgroundColor: TemaGlobal.azulMarino,
                        foregroundColor: TemaGlobal.dorado,
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
                          backgroundColor: TemaGlobal.tarjeta,
                          foregroundColor: TemaGlobal.texto,
                          side: BorderSide(color: TemaGlobal.dorado),
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
                          backgroundColor: TemaGlobal.azulMarino,
                          foregroundColor: TemaGlobal.dorado,
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
                child: Text("Ya tengo el código de restablecimiento",
                    style: TextStyle(color: TemaGlobal.dorado)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Volver al login", style: TextStyle(color: TemaGlobal.dorado)),
              ),
            ],
          ),
        ),
      ),
    );
}
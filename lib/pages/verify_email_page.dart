import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/local_auth_service.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isLoading = false;
  bool _canResend = true;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color fondoGris = Color(0xFFF1F5F9);
  static const Color grisTexto = Color(0xFF4A5568);

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldownTimer() {
    _resendCooldown = 60; // 60 seconds cooldown
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
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

  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _canResend = false;
    });

    final AuthService auth = context.read<AuthService>();
    
    try {
      await auth.sendVerificationEmail();
      _showSnackBar('Correo de verificación reenviado. Revisa tu bandeja de entrada.');
      _startCooldownTimer();
    } catch (e) {
      _showSnackBar('Error al reenviar el correo. Intenta de nuevo.', isError: true);
      setState(() => _canResend = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _isLoading = true);

    final AuthService auth = context.read<AuthService>();
    final bool verified = await auth.refreshUser();

    if (verified) {
      await LocalAuthService.updateEmailVerified(verified: true);
      if (mounted) {
        unawaited(Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
          (Route<dynamic> route) => false,
        ));
      }
    } else {
      _showSnackBar('Tu correo aún no está verificado. Revisa tu bandeja de entrada.', isError: true);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    final AuthService auth = context.read<AuthService>();
    await auth.logout();
    if (mounted) {
      unawaited(Navigator.pushReplacementNamed(context, '/login'));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: fondoGris,
        appBar: AppBar(
          backgroundColor: azulMarino,
          foregroundColor: dorado,
          elevation: 0,
          title: const Text('Verificar Correo'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.mark_email_unread_outlined, size: 80, color: azulMarino),
                const SizedBox(height: 24),
                const Text(
                  'Verifica tu correo electrónico',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: azulMarino),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Te hemos enviado un correo de verificación. Haz clic en el enlace del correo para activar tu cuenta.',
                  style: TextStyle(fontSize: 16, color: grisTexto),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: azulMarino.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(Icons.email_outlined, color: azulMarino),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Revisa tu bandeja de entrada y carpeta de spam/junk',
                              style: TextStyle(color: azulMarino.withValues(alpha: 0.8)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          const Icon(Icons.link_outlined, color: azulMarino),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Haz clic en el enlace de verificación',
                              style: TextStyle(color: azulMarino.withValues(alpha: 0.8)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          const Icon(Icons.refresh_outlined, color: azulMarino),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Vuelve aquí y presiona "Ya verifiqué mi correo"',
                              style: TextStyle(color: azulMarino.withValues(alpha: 0.8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Column(
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: _checkVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: azulMarino,
                          foregroundColor: dorado,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('YA VERIFIQUÉ MI CORREO',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      if (_canResend)
                        TextButton(
                          onPressed: _resendVerificationEmail,
                          child: const Text(
                            '¿No recibiste el correo? Reenviar verificación',
                            style: TextStyle(color: dorado, fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        Text(
                          'Puedes reenviar en $_resendCooldown segundos',
                          style: const TextStyle(color: grisTexto, fontSize: 14),
                        ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _logout,
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Usar otra cuenta'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
}
import 'dart:async';

import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_theme.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/local_auth_service.dart';
import '../utils/main_tab_controller.dart';
import '../widgets/app_bar_institucional.dart';

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

  
  
  static Color get fondoGris => TemaGlobal.superficie;
  static Color get grisTexto => TemaGlobal.textoSecundario;

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
        backgroundColor: isError ? AppColors.error : AppColors.success,
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
        // Navegación compartida: MainScreen como raíz + pestaña Inicio,
        // nunca un DashboardScreen huérfano sin barra inferior.
        navegarDesdeMain(context, '/dashboard');
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
              appBar: AppBarInstitucional(
        title: 'Verificar Correo',
        mostrarBack: true,

      ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.mark_email_unread_outlined, size: 80, color: TemaGlobal.texto),
                const SizedBox(height: 24),
                Text(
                  'Verifica tu correo electrónico',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: TemaGlobal.texto),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Te hemos enviado un correo de verificación. Haz clic en el enlace del correo para activar tu cuenta.',
                  style: TextStyle(fontSize: 16, color: grisTexto),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TemaGlobal.tarjeta,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: TemaGlobal.capa),
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(Icons.email_outlined, color: TemaGlobal.textoSecundario),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Revisa tu bandeja de entrada y carpeta de spam/junk',
                              style: TextStyle(color: TemaGlobal.textoSecundario),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Icon(Icons.link_outlined, color: TemaGlobal.textoSecundario),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Haz clic en el enlace de verificación',
                              style: TextStyle(color: TemaGlobal.textoSecundario),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Icon(Icons.refresh_outlined, color: TemaGlobal.textoSecundario),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Vuelve aquí y presiona "Ya verifiqué mi correo"',
                              style: TextStyle(color: TemaGlobal.textoSecundario),
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
                          backgroundColor: AppColors.azulMarino,
                          foregroundColor: AppColors.dorado,
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
                          child: Text(
                            '¿No recibiste el correo? Reenviar verificación',
                            style: TextStyle(color: TemaGlobal.texto, fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        Text(
                          'Puedes reenviar en $_resendCooldown segundos',
                          style: TextStyle(color: grisTexto, fontSize: 14),
                        ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _logout,
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
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
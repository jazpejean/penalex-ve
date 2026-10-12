import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, this.oobCode = ''});
  final String oobCode;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('oobCode', oobCode));
  }
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static Color get fondoGris => TemaGlobal.superficie;
  static const Color grisTexto = Color(0xFF4A5568);

  @override
  void initState() {
    super.initState();
    if (widget.oobCode.isNotEmpty) {
      _codeController.text = widget.oobCode;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _extractOobCode(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    final Uri? uri = Uri.tryParse(trimmed);
    if (uri != null) {
      final String? fromQuery = uri.queryParameters['oobCode'];
      if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
    }
    return trimmed;
  }

  Future<void> _handleReset() async {
    setState(() => _errorMessage = '');

    final String oobCode = _extractOobCode(_codeController.text);
    if (oobCode.isEmpty) {
      setState(() => _errorMessage =
          'Pega el enlace del correo o el código oobCode para continuar.');
      return;
    }
    if (_passController.text.isEmpty) {
      setState(() => _errorMessage = 'Ingresa una nueva contraseña');
      return;
    }
    if (_passController.text.length < 6) {
      setState(() =>
          _errorMessage = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (_passController.text != _confirmController.text) {
      setState(() => _errorMessage = 'Las contraseñas no coinciden');
      return;
    }

    setState(() => _isLoading = true);
    final AuthService authProvider = context.read<AuthService>();
    
    try {
      await authProvider.confirmPasswordReset(oobCode, _passController.text);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada. Ahora puedes iniciar sesión.'),
          backgroundColor: Colors.green,
        ),
      );
      unawaited(Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (Route<dynamic> route) => false,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'El enlace expiró o es inválido');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: fondoGris,
        appBar: AppBar(
          backgroundColor: azulMarino,
          foregroundColor: dorado,
          elevation: 0,
          title: const Text('Nueva contraseña'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.lock_reset, size: 80, color: azulMarino),
                SizedBox(height: 20),
                Text(
                  'Restablecer contraseña',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: TemaGlobal.texto,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pega el enlace del correo de recuperación o el código oobCode, luego define tu nueva contraseña.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: grisTexto),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _codeController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Enlace o código del correo',
                    prefixIcon:
                        const Icon(Icons.link, color: azulMarino),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    prefixIcon:
                        Icon(Icons.lock_outline, color: azulMarino),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: TemaGlobal.texto,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon:
                        Icon(Icons.lock_outline, color: azulMarino),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: TemaGlobal.texto,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!_isLoading) unawaited(_handleReset());
                  },
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _handleReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azulMarino,
                      foregroundColor: dorado,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'ACTUALIZAR',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({required this.oobCode, super.key});
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
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);

  Future<void> _handleReset() async {
    if (_passController.text != _confirmController.text) {
      setState(() => _errorMessage = 'Las contraseñas no coinciden');
      return;
    }
    if (_passController.text.length < 6) {
      setState(() => _errorMessage = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() => _isLoading = true);
    final AppAuthProvider authProvider = context.read<AppAuthProvider>();
    final bool success = await authProvider.resetPassword(widget.oobCode, _passController.text.trim());

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña actualizada. Ahora puedes iniciar sesión.'), backgroundColor: Colors.green),
        );
        unawaited(Navigator.pushReplacementNamed(context, '/'));
      }
    } else {
      setState(() => _errorMessage = authProvider.error ?? 'El enlace expiró o es inválido');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.lock_reset, size: 80, color: azulMarino),
            const SizedBox(height: 20),
            const Text("Nueva Contraseña", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: azulMarino)),
            const SizedBox(height: 30),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Nueva Contraseña", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirmar Contraseña", border: OutlineInputBorder()),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text(_errorMessage, style: const TextStyle(color: Colors.red))),
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
                ),
                child: const Text("ACTUALIZAR"),
              ),
          ],
        ),
      ),
    );
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class DeviceLockScreen extends StatelessWidget {
  const DeviceLockScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.lock_person, size: 80, color: Colors.red),
            const Text("DISPOSITIVO NO AUTORIZADO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () async {
                final authService = context.read<AuthService>();
                await authService.signOut();
              },
              child: const Text("SALIR", style: TextStyle(color: Color(0xFFC5A059))),
            ),
          ],
        ),
      ),
    );
}
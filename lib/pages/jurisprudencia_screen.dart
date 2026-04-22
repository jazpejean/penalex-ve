import 'package:flutter/material.dart';

class JurisprudenciaScreen extends StatelessWidget {
  const JurisprudenciaScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text("Jurisprudencia"),
        backgroundColor: const Color(0xFF0F172A),
      ),
      backgroundColor: const Color(0xFF0F172A),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "Próximamente: módulo de jurisprudencia para agregar sentencias y doctrina relevante.",
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
}

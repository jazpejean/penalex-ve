import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      drawer: const AppDrawer(currentRoute: "/privacidad"),
      appBar: AppBar(
        title: const Text("Política de Privacidad"),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "Política de Privacidad de Penalex VE",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              "Última actualización: 9 de abril de 2026",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 16),
            Text(
              "1. Información que recopilamos\n\n"
              "Recopilamos información personal que usted nos proporciona directamente, como nombre, correo electrónico y datos de perfil. También recopilamos datos de uso de la aplicación.\n\n"
              "2. Cómo usamos su información\n\n"
              "Utilizamos su información para proporcionar y mejorar nuestros servicios, procesar transacciones y comunicarnos con usted.\n\n"
              "3. Compartir información\n\n"
              "No vendemos ni alquilamos su información personal a terceros. Podemos compartir información en cumplimiento de la ley.\n\n"
              "4. Seguridad\n\n"
              "Implementamos medidas de seguridad para proteger su información.\n\n"
              "5. Sus derechos\n\n"
              "Tiene derecho a acceder, corregir o eliminar su información personal.\n\n"
              "6. Cambios a esta política\n\n"
              "Podemos actualizar esta política y le notificaremos de cambios significativos.\n\n"
              "Para más información, contacte: privacidad@penalexve.com",
            ),
          ],
        ),
      ),
    );
}
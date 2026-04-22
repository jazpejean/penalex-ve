import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      drawer: const AppDrawer(currentRoute: "/terminos"),
      appBar: AppBar(
        title: const Text("Términos de Servicio"),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "Términos de Servicio de Penalex VE",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              "Última actualización: 9 de abril de 2026",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 16),
            Text(
              "1. Aceptación de términos\n\n"
              "Al usar Penalex VE, acepta estos términos.\n\n"
              "2. Descripción del servicio\n\n"
              "Penalex VE es una herramienta para cálculos penales.\n\n"
              "3. Uso aceptable\n\n"
              "Debe usar la app de manera legal y ética.\n\n"
              "4. Propiedad intelectual\n\n"
              "Todo el contenido es propiedad de Penalex VE.\n\n"
              "5. Limitación de responsabilidad\n\n"
              "No somos responsables por daños indirectos.\n\n"
              "6. Terminación\n\n"
              "Podemos terminar su acceso en cualquier momento.\n\n"
              "7. Ley aplicable\n\n"
              "Estos términos se rigen por las leyes de Venezuela.\n\n"
              "Para más información, contacte: soporte@penalexve.com",
            ),
          ],
        ),
      ),
    );
}
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppAuthProvider authProvider = context.watch<AppAuthProvider>();
    final String nombreUsuario = authProvider.userName ?? 'Usuario';

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: <Widget>[
            Icon(Icons.gavel, color: Color(0xFFC5A059), size: 28),
            SizedBox(width: 8),
            Text(
              'PENALEX VE',
              style: TextStyle(
                color: Color(0xFFC5A059),
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1.5,
                shadows: <Shadow>[Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black26)],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Color(0xFFC5A059)),
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              unawaited(context.read<AppAuthProvider>().logout());
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
              }
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/dashboard'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('¡Hola, $nombreUsuario!',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFC5A059))),
                  const SizedBox(height: 8),
                  const Text('¿Qué herramienta legal usaremos hoy?',
                      style: TextStyle(fontSize: 16, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildCard(
              context,
              title: '⚖️ Dosimetría Penal',
              subtitle: 'Cálculo técnico de penas',
              description: 'Determina la pena individualizada, concurso de delitos y más.',
              icon: Icons.calculate,
              route: '/calculadora',
              actionText: 'Iniciar cálculo',
            ),
            _buildCard(
              context,
              title: '⏱️ Cómputo de Lapsos',
              subtitle: 'Plazos procesales al instante',
              description: 'Calcula fechas, términos y vencimientos judiciales.',
              icon: Icons.timer,
              route: '/lapsos',
              actionText: 'Calcular plazos',
            ),
            _buildCard(
              context,
              title: '📅 Agenda Judicial',
              subtitle: 'Organiza tus audiencias',
              description: 'Registro de actos procesales y recordatorios.',
              icon: Icons.calendar_month,
              route: '/agenda',
              actionText: 'Ir a mi agenda',
            ),
            _buildCard(
              context,
              title: '📚 Legislación Penal',
              subtitle: 'Marco legal venezolano',
              description: 'Constitución, Código Penal, COPP y más.',
              icon: Icons.gavel,
              route: '/leyes',
              actionText: 'Explorar leyes',
            ),
            _buildCard(
              context,
              title: '⚖️ Jurisprudencia',
              subtitle: 'Sentencias y doctrina',
              description: 'Consulta fallos relevantes de los tribunales venezolanos.',
              icon: Icons.account_balance,
              route: '/jurisprudencia',
              actionText: 'Ver jurisprudencia',
            ),
            _buildCard(
              context,
              title: '📖 Glosario Jurídico',
              subtitle: 'Definiciones claras',
              description: 'Aclara términos y conceptos del derecho penal.',
              icon: Icons.menu_book,
              route: '/glosario',
              actionText: 'Ver glosario',
            ),
            _buildCard(
              context,
              title: '🎯 Desafío Penal',
              subtitle: 'Pon a prueba tus conocimientos',
              description: 'Responde preguntas sobre derecho penal venezolano.',
              icon: Icons.quiz,
              route: '/quiz_lobby',
              actionText: 'Comenzar desafío',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required String route,
    required String actionText,
  }) =>
      GestureDetector(
        onTap: () => Navigator.pushNamed(context, route),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(icon, size: 32, color: const Color(0xFFC5A059)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(subtitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(actionText,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFC5A059))),
                ),
              ],
            ),
          ),
        ),
      );
}
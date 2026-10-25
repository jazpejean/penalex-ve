import 'package:flutter/material.dart';
import '../services/haptics_service.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../config/app_theme.dart';
import '../utils/main_tab_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  /// Navega desde el dashboard manteniendo la bottom bar siempre visible:
  /// - rutas-pestaña (agenda, asistente, consulta) cambian el tab del MainScreen;
  /// - las 3 rutas de consulta abren la pestaña "Buscar" con su corpus;
  /// - herramientas externas (calculadora, mapa, quiz) se apilan con la barra.
  void _navegar(BuildContext context, String route) {
    Haptics.tap();
    switch (route) {
      case '/repositorio_jurisprudencia':
        navegarAConsulta(context, 'sentencias');
      case '/repositorio_leyes':
        navegarAConsulta(context, 'leyes');
      case '/glosario':
        navegarAConsulta(context, 'glosario');
      default:
        navegarDesdeMain(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    final String nombreUsuario = user?.displayName ?? 'Usuario';

    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            // Header institucional (tarjeta de bienvenida con el logo de la app)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: TemaGlobal.azulMarino.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Logo de Penalex (movido del AppBar a la tarjeta de bienvenida)
                  Row(
                    children: <Widget>[
                      Icon(Icons.gavel, color: TemaGlobal.dorado, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'PENALEX VE',
                        style: TextStyle(
                          color: TemaGlobal.dorado,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: TemaGlobal.dorado.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: TemaGlobal.dorado.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.account_balance,
                          color: TemaGlobal.dorado,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '¡Bienvenido, $nombreUsuario!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: TemaGlobal.dorado,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Herramientas Jurídicas Profesionales',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            
            // ULPIANO - Feature destacada
            _buildStarCard(
              context,
              title: 'Ulpiano — Asistente Legal',
              subtitle: 'Tu equipo de estrategas legales',
              description: 'Consulta, redacta, analiza y calcula con IA. Todo con fuentes verificables.',
              icon: Icons.auto_awesome,
              route: '/asistente_legal',
              actionText: 'Hablar con Ulpiano',
              badge: 'NUEVO',
            ),
            
            // HERRAMIENTAS PRINCIPALES
            _buildCard(
              context,
              title: 'Dosimetría Penal',
              subtitle: 'Cálculo técnico de penas',
              description: 'Determina la pena individualizada, concurso de delitos y más.',
              icon: Icons.calculate,
              route: '/calculadora',
              actionText: 'Iniciar cálculo',
            ),
            _buildCard(
              context,
              title: 'Agenda Judicial',
              subtitle: 'Organiza tus audiencias',
              description: 'Audiencias, recordatorios y lapsos procesales de cada expediente.',
              icon: Icons.calendar_month,
              route: '/agenda',
              actionText: 'Ir a mi agenda',
            ),
            _buildCard(
              context,
              title: 'Legislación Penal',
              subtitle: 'Marco legal venezolano',
              description: 'Constitución, Código Penal, COPP y más.',
              icon: Icons.gavel,
              route: '/repositorio_leyes',
              actionText: 'Explorar leyes',
            ),
            _buildCard(
              context,
              title: 'Jurisprudencia',
              subtitle: 'Sentencias y doctrina',
              description: 'Consulta fallos relevantes de los tribunales venezolanos.',
              icon: Icons.account_balance,
              route: '/repositorio_jurisprudencia',
              actionText: 'Ver jurisprudencia',
            ),
            _buildCard(
              context,
              title: 'Mapa de Tribunales',
              subtitle: 'Catálogo oficial del TSJ',
              description: 'Ubica los tribunales penales del país por estado y función.',
              icon: Icons.map,
              route: '/mapa_tribunales',
              actionText: 'Ver mapa',
            ),
            _buildCard(
              context,
              title: 'Glosario Jurídico',
              subtitle: 'Definiciones claras',
              description: 'Aclara términos y conceptos del derecho penal.',
              icon: Icons.menu_book,
              route: '/glosario',
              actionText: 'Ver glosario',
            ),
            _buildCard(
              context,
              title: 'Desafío Penal',
              subtitle: 'Pon a prueba tus conocimientos',
              description: 'Responde preguntas sobre derecho penal venezolano.',
              icon: Icons.quiz,
              route: '/quiz_lobby',
              actionText: 'Comenzar desafío',
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildStarCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required String route,
    required String actionText,
    required String badge,
  }) =>
      GestureDetector(
        onTap: () => _navegar(context, route),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: TemaGlobal.dorado,
              width: 2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: TemaGlobal.dorado.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navegar(context, route),
              borderRadius: BorderRadius.circular(20),
              splashColor: TemaGlobal.dorado.withValues(alpha: 0.2),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: TemaGlobal.dorado.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: TemaGlobal.dorado.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(icon, size: 32, color: TemaGlobal.dorado),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: TemaGlobal.dorado,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: TemaGlobal.texto,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      badge,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: TemaGlobal.texto,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: TemaGlobal.dorado.withValues(alpha: 0.9),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: TemaGlobal.dorado,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: TemaGlobal.dorado,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: TemaGlobal.dorado.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.auto_awesome,
                            color: TemaGlobal.texto,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            actionText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: TemaGlobal.texto,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

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
        onTap: () => _navegar(context, route),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: TemaGlobal.dorado.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navegar(context, route),
              borderRadius: BorderRadius.circular(16),
              splashColor: TemaGlobal.dorado.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: TemaGlobal.dorado.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: TemaGlobal.dorado.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(icon, size: 28, color: TemaGlobal.dorado),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: TemaGlobal.dorado.withValues(alpha: 0.8),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: TemaGlobal.dorado.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 60),
                      child: Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 60),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: TemaGlobal.dorado.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: TemaGlobal.dorado.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          actionText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: TemaGlobal.dorado,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

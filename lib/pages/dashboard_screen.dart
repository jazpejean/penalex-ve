import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    final String nombreUsuario = user?.displayName ?? 'Usuario';

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: <Widget>[
            Icon(Icons.gavel, color: AppColors.secondary, size: 28),
            SizedBox(width: 8),
            Text(
              'PENALEX VE',
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1.5,
                shadows: <Shadow>[Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black26)],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.secondary),
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = context.read<AuthService>();
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
              }
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/dashboard'),
      backgroundColor: const Color(0xFFF1F5F9), // Fondo gris muy claro
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            // Header institucional
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
                    color: const Color(0xFF0F172A).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC5A059).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFC5A059).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.account_balance,
                          color: Color(0xFFC5A059),
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
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC5A059),
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
            
            // BARRA DE ACCESOS DIRECTOS
            _buildQuickActionsBar(context),
            const SizedBox(height: 28),
            
            // ASISTENTE LEGAL - Feature destacada
            _buildStarCard(
              context,
              title: '🤖 Asistente Legal con IA',
              subtitle: 'Tu equipo de estrategas legales',
              description: 'Chat, Redactor, Escáner y Comparador de Estrategias. Todo en un solo lugar.',
              icon: Icons.auto_awesome,
              route: '/asistente_legal',
              actionText: 'Acceder al asistente',
              badge: '⭐ NUEVO',
            ),
            
            // HERRAMIENTAS PRINCIPALES
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

  Widget _buildQuickActionsBar(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC5A059).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          // Agenda
          _buildQuickActionItem(
            context,
            icon: Icons.calendar_month,
            label: 'Agenda',
            route: '/agenda',
            isCenter: false,
          ),
          // Dosimetría
          _buildQuickActionItem(
            context,
            icon: Icons.calculate,
            label: 'Dosimetría',
            route: '/calculadora',
            isCenter: false,
          ),
          // CENTRO: Asistente IA (destacado)
          _buildQuickActionItem(
            context,
            icon: Icons.auto_awesome,
            label: 'Asistente IA',
            route: '/asistente_legal',
            isCenter: true,
          ),
          // Leyes
          _buildQuickActionItem(
            context,
            icon: Icons.gavel,
            label: 'Leyes',
            route: '/leyes',
            isCenter: false,
          ),
          // Jurisprudencia
          _buildQuickActionItem(
            context,
            icon: Icons.account_balance,
            label: 'Sentencias',
            route: '/jurisprudencia',
            isCenter: false,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isCenter,
  }) {
    final bool isHighlighted = isCenter;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: isCenter ? 4 : 2,
            vertical: isCenter ? 8 : 16,
          ),
          decoration: BoxDecoration(
            gradient: isCenter
                ? const LinearGradient(
                    colors: [Color(0xFFC5A059), Color(0xFFD4AF6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isCenter ? null : const Color(0xFF1E293B).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(isCenter ? 16 : 12),
            border: Border.all(
              color: isCenter
                  ? const Color(0xFFFBBF24)
                  : const Color(0xFFC5A059).withValues(alpha: 0.2),
              width: isCenter ? 2 : 1,
            ),
            boxShadow: isCenter
                ? <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFFC5A059).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: isCenter ? 32 : 26,
                color: isCenter ? const Color(0xFF0F172A) : const Color(0xFFC5A059),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCenter ? 12 : 11,
                  fontWeight: isCenter ? FontWeight.bold : FontWeight.w600,
                  color: isCenter ? const Color(0xFF0F172A) : Colors.white,
                  letterSpacing: 0.3,
                ),
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
        onTap: () => Navigator.pushNamed(context, route),
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
              color: const Color(0xFFC5A059),
              width: 2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFFC5A059).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, route),
              borderRadius: BorderRadius.circular(20),
              splashColor: const Color(0xFFC5A059).withValues(alpha: 0.2),
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
                            color: const Color(0xFFC5A059).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFC5A059).withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(icon, size: 32, color: const Color(0xFFC5A059)),
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
                                  color: const Color(0xFFFBBF24),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  badge,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: 0.5,
                                  ),
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
                                  color: const Color(0xFFC5A059).withValues(alpha: 0.9),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: const Color(0xFFC5A059),
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
                        color: const Color(0xFFC5A059),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: const Color(0xFFC5A059).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF0F172A),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            actionText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
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
        onTap: () => Navigator.pushNamed(context, route),
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
              color: const Color(0xFFC5A059).withValues(alpha: 0.2),
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
              onTap: () => Navigator.pushNamed(context, route),
              borderRadius: BorderRadius.circular(16),
              splashColor: const Color(0xFFC5A059).withValues(alpha: 0.1),
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
                            color: const Color(0xFFC5A059).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFC5A059).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(icon, size: 28, color: const Color(0xFFC5A059)),
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
                                  color: const Color(0xFFC5A059).withValues(alpha: 0.8),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: const Color(0xFFC5A059).withValues(alpha: 0.6),
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
                          color: const Color(0xFFC5A059).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFC5A059).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          actionText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFC5A059),
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

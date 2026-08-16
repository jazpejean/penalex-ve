import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'repositorio_jurisprudencia_screen.dart';
import 'chat_legal_screen.dart';
import 'agenda_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    RepositorioJurisprudenciaScreen(),
    ChatLegalScreen(),
    AgendaScreen(),
    _ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // ✅ Evita que la barra suba con el teclado
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // ✅ Ocultar barra dentro de herramientas (solo mostrar en Dashboard/Home/Perfil)
      bottomNavigationBar: _shouldShowBottomBar()
          ? Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: BottomAppBar(
                color: const Color(0xFF1E293B),
                shape: const CircularNotchedRectangle(),
                notchMargin: 8,
                child: SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(Icons.home_outlined, Icons.home, 'Inicio', 0),
                      _buildNavItem(Icons.search_outlined, Icons.search, 'Buscar', 1),
                      const SizedBox(width: 60), // Espacio para el FAB
                      _buildNavItem(Icons.calendar_today_outlined, Icons.calendar_today, 'Agenda', 3),
                      _buildNavItem(Icons.person_outline, Icons.person, 'Perfil', 4),
                    ],
                  ),
                ),
              ),
            )
          : null,
      // ✅ Ocultar FAB y barra cuando NO estamos en Dashboard/Home/Perfil
      floatingActionButton: _shouldShowBottomBar()
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _currentIndex = 2;
                });
              },
              backgroundColor: const Color(0xFFC5A059),
              elevation: 8,
              child: const Icon(
                Icons.gavel, // ⚖️ Icono de martillo legal (representa asistente legal)
                color: Color(0xFF0F172A),
                size: 28,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// ✅ Determina si se debe mostrar la barra inferior
  /// Solo en: Dashboard (0), Perfil (4)
  /// NO en: Jurisprudencias (1), Chat Legal (2), Agenda (3)
  bool _shouldShowBottomBar() {
    return _currentIndex == 0 || _currentIndex == 4;
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? const Color(0xFFC5A059)
                  : Colors.white.withValues(alpha: 0.5),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFFC5A059)
                    : Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    final userName = user?.displayName ?? 'Usuario';
    final userEmail = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            color: Color(0xFFC5A059),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF0F172A),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header de perfil
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC5A059).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFC5A059),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 48,
                      color: Color(0xFFC5A059),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Opciones de perfil
            _buildOptionCard(
              context,
              icon: Icons.person_outline,
              title: 'Información Personal',
              subtitle: 'Editar nombre y datos',
              onTap: () {
                // TODO: Navegar a editar perfil
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximamente')),
                );
              },
            ),
            _buildOptionCard(
              context,
              icon: Icons.security_outlined,
              title: 'Seguridad',
              subtitle: 'Cambiar contraseña',
              onTap: () {
                // TODO: Navegar a cambiar contraseña
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximamente')),
                );
              },
            ),
            _buildOptionCard(
              context,
              icon: Icons.notifications_outlined,
              title: 'Notificaciones',
              subtitle: 'Configurar alertas',
              onTap: () {
                // TODO: Navegar a configuración de notificaciones
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximamente')),
                );
              },
            ),
            _buildOptionCard(
              context,
              icon: Icons.help_outline,
              title: 'Ayuda y Soporte',
              subtitle: 'Preguntas frecuentes',
              onTap: () {
                // TODO: Navegar a ayuda
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximamente')),
                );
              },
            ),
            _buildOptionCard(
              context,
              icon: Icons.logout_outlined,
              title: 'Cerrar Sesión',
              subtitle: 'Salir de la aplicación',
              onTap: () async {
                final authService = context.read<AuthService>();
                await authService.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                }
              },
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDestructive
              ? [const Color(0xFF991B1B), const Color(0xFF7F1D1D)]
              : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isDestructive
                            ? Colors.white
                            : const Color(0xFFC5A059))
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isDestructive ? Colors.white : const Color(0xFFC5A059),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

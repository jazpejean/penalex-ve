import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({required this.currentRoute, super.key});
  final String currentRoute;

  // Rutas que existen en main.dart (y que no causarán error)
  static const Set<String> validRoutes = <String>{
    '/dashboard',
    '/calculadora',
    '/agenda',
    '/quiz',
    '/login',
    '/',
  };

  void _navigate(BuildContext context, String route, {Object? arguments}) {
    // Cerrar el drawer
    Navigator.pop(context);

    // Si es la ruta del dashboard, usar pushNamedAndRemoveUntil para limpiar pila
    if (route == '/dashboard') {
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (Route<dynamic> route) => false);
      return;
    }

    // Evitar navegar a la misma ruta
    if (currentRoute == route && arguments == null) return;

    // Verificar si la ruta es válida antes de navegar
    if (validRoutes.contains(route)) {
      Navigator.pushNamed(context, route, arguments: arguments);
    } else {
      // Mostrar mensaje amigable en lugar de crashear
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Próximamente disponible'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showProfilePicker(BuildContext context) async {
    unawaited(showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.secondary),
              title: const Text("Seleccionar de la galería", style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await _uploadProfileImage(context, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.secondary),
              title: const Text("Tomar foto con cámara", style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await _uploadProfileImage(context, ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    ));
  }

  Future<void> _uploadProfileImage(BuildContext context, ImageSource source) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Subiendo foto de perfil...'), duration: Duration(seconds: 2)),
    );
    try {
      final String? url = await UserProfileService.uploadProfileImage(source);
      if (url != null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil actualizada correctamente'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No se seleccionó ninguna imagen.'),
            backgroundColor: Color(0xFFB45309),
          ),
        );
      }
    } on Exception catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error al subir la imagen: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppAuthProvider authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    final User? user = authProvider.user;
    final String nombreUsuario = authProvider.userName ?? 'Usuario';
    final String email = user?.email ?? 'Sin correo';
    final String inicial = nombreUsuario.isNotEmpty ? nombreUsuario[0].toUpperCase() : 'U';

    return Drawer(
      child: Container(
        color: const Color(0xFF0F172A),
        child: Column(
          children: <Widget>[
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: UserProfileService.userDocStream(),
              builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
                final Map<String, dynamic> data = snapshot.data?.data() ?? <String, dynamic>{};
                final String? photoUrl = data['photoUrl'] as String? ?? user?.photoURL;
                final int nivel = (data['nivel_actual'] as int?) ?? 1;
                final String rango = UserProfileService.rankLabel(nivel);

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF111827),
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                  ),
                  child: Row(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () => unawaited(_showProfilePicker(context)),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: <Widget>[
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: const Color(0xFFC5A059),
                              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                              child: photoUrl == null
                                  ? Text(inicial,
                                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 28, fontWeight: FontWeight.bold))
                                  : null,
                            ),
                            Container(
                              height: 28,
                              width: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFFC5A059),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF0F172A), width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(nombreUsuario,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(email, style: TextStyle(color: const Color(0xFFFFFFFF).withValues(alpha: 0.72), fontSize: 13)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC5A059).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(rango,
                                  style: const TextStyle(color: Color(0xFFC5A059), fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  _buildExpansionTile(
                    context,
                    icon: Icons.calculate_outlined,
                    title: 'Calculadora de Penas',
                    children: <Widget>[
                      _buildSubMenuItem(context, icon: Icons.calculate, title: 'Ir a Calculadora', route: '/calculadora'),
                      _buildSubMenuItem(context, icon: Icons.folder_open, title: 'Cálculos Guardados', route: '/calculos', showSnackbar: true),
                      _buildSubMenuItem(context, icon: Icons.picture_as_pdf, title: 'Reportes Guardados', route: '/reportes', showSnackbar: true),
                    ],
                  ),
                  _buildMenuItem(context, icon: Icons.timer, title: 'Lapsos Procesales', route: '/lapsos', showSnackbar: true),
                  _buildMenuItem(context, icon: Icons.calendar_month_outlined, title: 'Agenda Judicial', route: '/agenda'),
                  _buildExpansionTile(
                    context,
                    icon: Icons.menu_book,
                    title: 'Biblioteca Legal',
                    children: <Widget>[
                      _buildSubMenuItem(context, icon: Icons.description, title: 'Constitución de la República Bolivariana de Venezuela', route: '/leyes', showSnackbar: true),
                      _buildSubMenuItem(context, icon: Icons.gavel, title: 'Código Penal Venezolano', route: '/leyes', showSnackbar: true),
                      _buildSubMenuItem(context, icon: Icons.account_balance, title: 'Código Orgánico Procesal Penal', route: '/leyes', showSnackbar: true),
                      _buildSubMenuItem(context, icon: Icons.woman, title: 'Ley Orgánica sobre el Derecho de las Mujeres a una Vida Libre de Violencia', route: '/leyes', showSnackbar: true),
                      _buildSubMenuItem(context, icon: Icons.medical_services, title: 'Ley Orgánica de Drogas', route: '/leyes', showSnackbar: true),
                      _buildSubMenuItem(context, icon: Icons.security, title: 'Ley Orgánica contra la Delincuencia Organizada y Financiamiento al Terrorismo', route: '/leyes', showSnackbar: true),
                      _buildSubMenuItem(context, icon: Icons.money_off, title: 'Ley contra el Secuestro y la Extorsión', route: '/leyes', showSnackbar: true),
                      _buildSubMenuItem(context, icon: Icons.directions_car, title: 'Ley sobre el Hurto y Robo de Vehículos Automotores', route: '/leyes', showSnackbar: true),
                      _buildSubMenuItem(context, icon: Icons.shield, title: 'Ley para el Desarme y Control de Armas y Municiones', route: '/leyes', showSnackbar: true),
                    ],
                  ),
                  _buildMenuItem(context, icon: Icons.balance, title: 'Jurisprudencia', route: '/jurisprudencia', showSnackbar: true),
                  _buildMenuItem(context, icon: Icons.book, title: 'Glosario Jurídico', route: '/glosario', showSnackbar: true),
                  _buildExpansionTile(
                    context,
                    icon: Icons.quiz_outlined,
                    title: 'Desafío Penal',
                    children: <Widget>[
                      _buildSubMenuItem(context, icon: Icons.play_arrow, title: 'Iniciar Quiz / Niveles', route: '/quiz'),
                      _buildSubMenuItem(context, icon: Icons.emoji_events, title: 'Mis Logros', route: '/achievements', showSnackbar: true),
                      _buildSubMenuItem(context, icon: Icons.leaderboard, title: 'Ranking Global', route: '/ranking', showSnackbar: true),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  _buildMenuItem(context, icon: Icons.privacy_tip, title: 'Política de Privacidad', route: '/privacidad', showSnackbar: true),
                  _buildMenuItem(context, icon: Icons.description, title: 'Términos de Servicio', route: '/terminos', showSnackbar: true),
                  const Divider(color: Colors.white12, height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                    title: const Text('Cerrar sesión', style: TextStyle(color: Color(0xFFEF4444))),
                    onTap: () async {
                      await AuthService().logout();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
                      }
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Divider(color: Colors.white12),
                  const Text('Penalex VE v1.0', style: TextStyle(fontSize: 12, color: Colors.white54)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onLongPress: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Función deshabilitada'), duration: Duration(seconds: 1)),
                      );
                    },
                    child: const Text('Desarrollado por Jean Jazpe Lizcano',
                        style: TextStyle(fontSize: 12, color: Colors.white54)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool showSnackbar = false,
    Object? arguments,
  }) {
    final bool isSelected = currentRoute == route;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFFC5A059) : const Color(0xFF94A3B8), size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFFC5A059).withValues(alpha: 0.18),
      onTap: () {
        if (showSnackbar) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Próximamente disponible'), duration: Duration(seconds: 2)),
          );
        } else {
          _navigate(context, route, arguments: arguments);
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  Widget _buildSubMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool showSnackbar = false,
    Object? arguments,
  }) {
    final bool isSelected = currentRoute == route;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFFC5A059) : const Color(0xFF94A3B8), size: 20),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
        ),
      ),
      onTap: () {
        if (showSnackbar) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Próximamente disponible'), duration: Duration(seconds: 2)),
          );
        } else {
          _navigate(context, route, arguments: arguments);
        }
      },
      contentPadding: const EdgeInsets.only(left: 56, right: 20),
    );
  }

  Widget _buildExpansionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) =>
      Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: const Color(0xFF94A3B8), size: 24),
          title: Text(title, style: const TextStyle(fontSize: 15, color: Colors.white70)),
          collapsedIconColor: const Color(0xFFC5A059),
          childrenPadding: EdgeInsets.zero,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20),
          children: children,
        ),
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('currentRoute', currentRoute));
  }
}
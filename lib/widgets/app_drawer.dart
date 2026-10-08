import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({required this.currentRoute, super.key});
  final String currentRoute;

  // Colores consistentes
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color grisClaro = Color(0xFFF1F5F9);

  // Rutas que existen en main.dart
  static const Set<String> validRoutes = <String>{
    '/dashboard',
    '/calculadora',
    '/agenda',
    '/quiz',
    '/login',
    '/',
    '/asistente_legal',
    '/glosario',
    '/repositorio_jurisprudencia',
    '/chat_legal',
    '/busqueda_semantica',
    '/admin_ia_config',
    '/admin_glosario',
    '/calculos',
  };

  void _navigate(BuildContext context, String route, {Object? arguments}) {
    Navigator.pop(context);

    if (route == '/dashboard') {
      // Se apila sobre la navegación principal: el botón "atrás" del sistema
      // devuelve a las pestañas. (Antes usaba pushNamedAndRemoveUntil, que
      // reemplazaba toda la pila y dejaba la app sin la barra inferior.)
      Navigator.pushNamed(context, '/dashboard');
      return;
    }

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
              leading:
                  const Icon(Icons.photo_library, color: AppColors.secondary),
              title: const Text("Seleccionar de la galería",
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await _uploadProfileImage(context, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.secondary),
              title: const Text("Tomar foto con cámara",
                  style: TextStyle(color: Colors.white)),
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

  Future<void> _uploadProfileImage(
      BuildContext context, ImageSource source) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
          content: Text('Subiendo foto de perfil...'),
          duration: Duration(seconds: 2)),
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
        SnackBar(
            content: Text('Error al subir la imagen: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    final String nombreUsuario = user?.displayName ?? 'Usuario';
    final String email = user?.email ?? 'Sin correo';
    final String inicial =
        nombreUsuario.isNotEmpty ? nombreUsuario[0].toUpperCase() : 'U';

    return Drawer(
      child: Container(
        color: const Color(0xFF0F172A),
        child: Column(
          children: <Widget>[
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: UserProfileService.userDocStream(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
                      snapshot) {
                final Map<String, dynamic> data =
                    snapshot.data?.data() ?? <String, dynamic>{};
                
                // Leer photoBase64 (nuevo) o photoUrl (legacy)
                final String? photoBase64 = data['photoBase64'] as String?;
                final String? photoUrl = data['photoUrl'] as String? ?? user?.photoURL;
                
                final int nivel = (data['nivel_actual'] as int?) ?? 1;
                final String rango = UserProfileService.rankLabel(nivel);

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF111827),
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24)),
                  ),
                  child: Row(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () async {
                          await _showProfilePicker(context);
                        },
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: <Widget>[
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: const Color(0xFFC5A059),
                              backgroundImage: photoBase64 != null
                                  ? MemoryImage(base64Decode(photoBase64))
                                  : (photoUrl != null ? NetworkImage(photoUrl) : null) as ImageProvider?,
                              onBackgroundImageError: (exception, stackTrace) {
                                // Silenciosamente ignorar errores de carga de imagen
                                if (kDebugMode) {
                                  debugPrint('⚠️ Error cargando imagen de perfil: $exception');
                                }
                              },
                              child: (photoBase64 == null && photoUrl == null)
                                  ? Text(inicial,
                                      style: const TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold))
                                  : null,
                            ),
                            Container(
                              height: 28,
                              width: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFFC5A059),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF0F172A), width: 2),
                              ),
                              child: const Icon(Icons.camera_alt,
                                  size: 16, color: Color(0xFF0F172A)),
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
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(email,
                                style: TextStyle(
                                    color: const Color(0xFFFFFFFF)
                                        .withValues(alpha: 0.72),
                                    fontSize: 13)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC5A059)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(rango,
                                  style: const TextStyle(
                                      color: Color(0xFFC5A059),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
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
                  // 🏠 INICIO
                  _buildSectionHeader('INICIO'),
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    route: '/dashboard',
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 🤖 ASISTENTE IA
                  _buildSectionHeader('ASISTENTE IA'),
                  _buildMenuItem(
                    context,
                    icon: Icons.chat_bubble_outline,
                    title: 'Chat Legal',
                    route: '/chat_legal',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.auto_awesome,
                    title: 'Hub de Herramientas IA',
                    route: '/asistente_legal',
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 🧮 CALCULADORA PENAL
                  _buildSectionHeader('CALCULADORA PENAL'),
                  _buildExpansionTile(
                    context,
                    icon: Icons.calculate_outlined,
                    title: 'Dosimetría de Penas',
                    children: <Widget>[
                      _buildSubMenuItem(context,
                          icon: Icons.add_circle_outline,
                          title: 'Nueva Dosimetría',
                          route: '/calculadora'),
                      _buildSubMenuItem(context,
                          icon: Icons.folder_open,
                          title: 'Cálculos Guardados',
                          route: '/calculos'),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 📚 RECURSOS LEGALES
                  _buildSectionHeader('RECURSOS LEGALES'),
                  _buildMenuItem(context,
                      icon: Icons.balance,
                      title: 'Jurisprudencias TSJ',
                      route: '/repositorio_jurisprudencia'),
                  _buildMenuItem(context,
                      icon: Icons.search,
                      title: 'Búsqueda Semántica IA',
                      route: '/busqueda_semantica'),
                  _buildMenuItem(context,
                      icon: Icons.book,
                      title: 'Glosario Jurídico',
                      route: '/glosario'),
                  _buildMenuItem(context,
                      icon: Icons.menu_book,
                      title: 'Biblioteca Jurídica',
                      subtitle: 'CRBV, COPP, Código Penal y más',
                      route: '/repositorio_leyes'),
                  
                  const SizedBox(height: 8),
                  
                  // 📆 AGENDA & GESTIÓN
                  _buildSectionHeader('AGENDA & GESTIÓN'),
                  _buildMenuItem(context,
                      icon: Icons.calendar_month_outlined,
                      title: 'Agenda Judicial',
                      subtitle: 'Con calculadora de lapsos',
                      route: '/agenda'),
                  _buildMenuItem(context,
                      icon: Icons.folder_outlined,
                      title: 'Mis Documentos',
                      route: '/mis_documentos',
                      showSnackbar: true),
                  
                  const SizedBox(height: 8),
                  
                  // 🎮 FORMACIÓN
                  _buildSectionHeader('FORMACIÓN'),
                  _buildExpansionTile(
                    context,
                    icon: Icons.quiz_outlined,
                    title: 'Quiz Legal',
                    children: <Widget>[
                      _buildSubMenuItem(context,
                          icon: Icons.play_arrow,
                          title: 'Iniciar / Continuar',
                          route: '/quiz'),
                      _buildSubMenuItem(context,
                          icon: Icons.emoji_events,
                          title: 'Mis Logros',
                          route: '/achievements',
                          showSnackbar: true),
                      _buildSubMenuItem(context,
                          icon: Icons.leaderboard,
                          title: 'Ranking Global',
                          route: '/ranking',
                          showSnackbar: true),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 8),
                  
                  // ⚙️ CONFIGURACIÓN
                  // Configuración de IA (solo para administradores)
                  if (UserProfileService.isAdmin()) ...[
                    _buildSectionHeader('ADMINISTRACIÓN'),
                    _buildMenuItem(context,
                        icon: Icons.settings,
                        title: 'Configuración de IA',
                        route: '/admin_ia_config'),
                    _buildMenuItem(context,
                        icon: Icons.book_outlined,
                        title: 'Gestionar Glosario',
                        route: '/admin_glosario'),
                    const Divider(color: Colors.white12, height: 1),
                  ],
                  _buildMenuItem(context,
                      icon: Icons.privacy_tip,
                      title: 'Política de Privacidad',
                      route: '/privacidad',
                      showSnackbar: true),
                  _buildMenuItem(context,
                      icon: Icons.description,
                      title: 'Términos de Servicio',
                      route: '/terminos',
                      showSnackbar: true),
                  const Divider(color: Colors.white12, height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                    title: const Text('Cerrar sesión',
                        style: TextStyle(color: Color(0xFFEF4444))),
                    onTap: () async {
                      final authService = context.read<AuthService>();
                      await authService.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                      }
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
                  const Text('Penalex VE v1.0',
                      style: TextStyle(fontSize: 12, color: Colors.white54)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onLongPress: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Función deshabilitada'),
                            duration: Duration(seconds: 1)),
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

  /// Header de sección con estilo moderno
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFC5A059),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    String? subtitle, // ✅ Nuevo parámetro
    bool showSnackbar = false,
    Object? arguments,
  }) {
    final bool isSelected = currentRoute == route;
    return ListTile(
      leading: Icon(icon,
          color: isSelected ? const Color(0xFFC5A059) : const Color(0xFF94A3B8),
          size: 24),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFFC5A059) : Colors.white,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      // ✅ Mostrar subtítulo si existe
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            )
          : null,
      selected: isSelected,
      selectedTileColor: const Color(0xFFC5A059).withValues(alpha: 0.18),
      onTap: () {
        if (showSnackbar) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Próximamente disponible'),
                duration: Duration(seconds: 2)),
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
      leading: Icon(icon,
          color: isSelected ? const Color(0xFFC5A059) : const Color(0xFF94A3B8),
          size: 20),
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
            const SnackBar(
                content: Text('Próximamente disponible'),
                duration: Duration(seconds: 2)),
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
          title: Text(title,
              style: const TextStyle(fontSize: 15, color: Colors.white70)),
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

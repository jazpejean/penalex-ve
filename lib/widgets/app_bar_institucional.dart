import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../pages/main_screen.dart';
import '../utils/main_tab_controller.dart';

/// AppBar institucional unificado de Penalex VE.
///
/// Reglas fijas: fondo [AppColors.azulMarino], iconos [AppColors.onAzulMarino]
/// (blanco) y título [AppColors.dorado]. Nunca definir backgroundColor ni
/// foregroundColor a mano en las pantallas: usar este widget.
class AppBarInstitucional extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool mostrarHome; // true en pantallas pushed
  final bool mostrarBack; // true en pantallas pushed
  final bool mostrarDrawer; // true SOLO si la pantalla tiene AppDrawer
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppBarInstitucional({
    super.key,
    required this.title,
    this.actions,
    this.mostrarHome = false,
    this.mostrarBack = false,
    this.mostrarDrawer = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.azulMarino;
    final fg = foregroundColor ?? AppColors.onAzulMarino;

    return AppBar(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      centerTitle: true,
      leading: mostrarBack
          ? const BackButton(color: AppColors.onAzulMarino)
          : (mostrarDrawer
              ? Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu),
                    color: AppColors.onAzulMarino,
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                )
              : null),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.dorado,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: <Widget>[
        ...?actions,
        if (mostrarHome)
          IconButton(
            icon: const Icon(Icons.home_outlined),
            color: AppColors.onAzulMarino,
            tooltip: 'Ir al inicio',
            onPressed: () {
              mainTabIndex.value = 0;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainScreen()),
                (r) => false,
              );
            },
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
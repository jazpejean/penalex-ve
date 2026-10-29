import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// AppBar institucional unificado de Penalex VE (patrón moderno).
///
/// Política única (GUIA_ARQUITECTURA 2.1): barra INTEGRADA al contenido —
/// fondo [TemaGlobal.superficie] (igual que el body), título en
/// [TemaGlobal.texto] bold alineado a la izquierda, flecha atrás en
/// [TemaGlobal.texto]. SIN botón home (🏠): el back es el único camino de
/// regreso; el inicio vive solo en la barra de pestañas. SIN navy ni dorado
/// forzados: la marca queda en logos/heroes, no en la barra.
class AppBarInstitucional extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool mostrarBack; // true en pantallas pushed
  final bool mostrarDrawer; // true SOLO si la pantalla tiene AppDrawer
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppBarInstitucional({
    super.key,
    required this.title,
    this.actions,
    this.mostrarBack = false,
    this.mostrarDrawer = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? TemaGlobal.superficie;
    final fg = foregroundColor ?? TemaGlobal.texto;

    return AppBar(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: mostrarBack
          ? BackButton(color: fg)
          : (mostrarDrawer
              ? Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu),
                    color: fg,
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                )
              : null),
      title: Text(
        title,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 20,
          letterSpacing: -0.3,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
import 'package:flutter/material.dart';

import '../utils/main_tab_controller.dart';

/// Barra de navegación inferior compartida de Penalex VE.
///
/// Misma identidad visual que la del MainScreen (navy + dorado) pero
/// manejada por [mainTabIndex] (ValueNotifier global): cualquier pantalla —
/// incluso las herramientas externas apiladas sobre el MainScreen — puede
/// incrustarla en su propio Scaffold y conservar la navegación principal.
///
/// Al tocar una pestaña: actualiza [mainTabIndex] y, si la pantalla actual
/// es una ruta externa, vuelve a la raíz (MainScreen) con `popUntil`.
class MainBottomBar extends StatelessWidget {
  const MainBottomBar({super.key, this.onOpenDrawer});

  /// Opcional: abre el drawer del MainScreen (solo tiene sentido ahí).
  final VoidCallback? onOpenDrawer;

  static const _fondoProfundo = Color(0xFF0F172A);
  static const _oro = Color(0xFFC5A059);
  static const _oroBrillante = Color(0xFFE9C86A);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: mainTabIndex,
      builder: (context, currentIndex, _) {
        return Container(
          decoration: BoxDecoration(
            color: _fondoProfundo,
            border: Border(
              top: BorderSide(color: _oro.withValues(alpha: 0.35), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  _buildNavItem(
                    Icons.home_outlined,
                    'Inicio',
                    0,
                    currentIndex,
                  ),
                  _buildNavItem(
                    Icons.calendar_month_outlined,
                    'Agenda',
                    1,
                    currentIndex,
                  ),
                  _buildNavItem(
                    Icons.auto_awesome,
                    'Asistente',
                    2,
                    currentIndex,
                    isCenter: true,
                  ),
                  _buildNavItem(
                    Icons.search,
                    'Buscar',
                    3,
                    currentIndex,
                  ),
                  _buildDrawerItem(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    int currentIndex, {
    bool isCenter = false,
  }) {
    final bool isSelected = currentIndex == index;
    final double iconSize = isCenter ? 26 : 22;

    return Expanded(
      child: InkWell(
        onTap: () {
          mainTabIndex.value = index;
          // Si la pantalla actual es una ruta externa, volver a la raíz
          // (MainScreen) para que el cambio de pestaña sea visible.
          Navigator.popUntil(context, (r) => r.isFirst);
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (isCenter)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? _oro
                      : _oro.withValues(alpha: 0.15),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _oro.withValues(alpha: 0.5),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: isSelected ? _fondoProfundo : _oro,
                ),
              )
            else
              Icon(
                icon,
                size: iconSize,
                color: isSelected
                    ? _oroBrillante
                    : _oro.withValues(alpha: 0.6),
              ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    letterSpacing: 0.2,
                    color: isSelected
                        ? _oroBrillante
                        : _oro.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Item "Más" del bottom nav: abre el drawer si se provee callback;
  /// en pantallas externas vuelve al inicio (pestaña 0).
  Widget _buildDrawerItem() {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (onOpenDrawer != null) {
            onOpenDrawer!();
          } else {
            mainTabIndex.value = 0;
            Navigator.popUntil(context, (r) => r.isFirst);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.menu,
              size: 22,
              color: _oro.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Más',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    color: _oro.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
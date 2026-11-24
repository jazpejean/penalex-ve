import 'package:flutter/material.dart';

import '../utils/main_tab_controller.dart';
import '../config/app_colors.dart';
import '../config/app_theme.dart';

/// Barra de navegación inferior compartida de Penalex VE.
///
/// Estilo sobrio: fondo claro, borde superior fino, iconos lineales y un
/// indicador tenue detrás del ítem activo. Sin círculo central ni sombras.
class MainBottomBar extends StatelessWidget {
  const MainBottomBar({super.key, this.onOpenDrawer});

  /// Opcional: abre el drawer del MainScreen (solo tiene sentido ahí).
  final VoidCallback? onOpenDrawer;

  static const List<(IconData, String, int)> _items = <(IconData, String, int)>[
    (Icons.home_outlined, 'Inicio', 0),
    (Icons.calendar_month_outlined, 'Agenda', 1),
    (Icons.auto_awesome, 'Asistente', 2),
    (Icons.search, 'Buscar', 3),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: mainTabIndex,
      builder: (context, currentIndex, _) {
        return Container(
          decoration: BoxDecoration(
            color: TemaGlobal.tarjeta,
            border: Border(top: BorderSide(color: TemaGlobal.capa)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: Row(
                children: <Widget>[
                  for (final (IconData icono, String etiqueta, int indice)
                      in _items)
                    _buildItem(context, icono, etiqueta, indice, currentIndex),
                  _buildMas(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    int currentIndex,
  ) {
    final bool isSelected = currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          mainTabIndex.value = index;
          Navigator.popUntil(context, (Route<dynamic> r) => r.isFirst);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.azulMarino.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected
                    ? AppColors.azulMarino
                    : TemaGlobal.textoSecundario,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    isSelected ? AppColors.azulMarino : TemaGlobal.textoTenue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Item "Más": abre el drawer si se provee callback; en pantallas externas
  /// vuelve al inicio (pestaña 0).
  Widget _buildMas(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (onOpenDrawer != null) {
            onOpenDrawer!();
          } else {
            mainTabIndex.value = 0;
            Navigator.popUntil(context, (Route<dynamic> r) => r.isFirst);
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.menu,
              size: 22,
              color: TemaGlobal.textoSecundario,
            ),
            const SizedBox(height: 2),
            Text(
              'Más',
              maxLines: 1,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: TemaGlobal.textoTenue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

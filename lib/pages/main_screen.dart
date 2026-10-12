import 'package:flutter/material.dart';

import '../utils/main_tab_controller.dart';
import '../widgets/app_drawer.dart';
import 'dashboard_screen.dart';
import 'agenda_screen.dart';
import 'asistente_legal_hub_screen.dart';
import 'buscador_juridico_screen.dart';

/// Navegación principal de Penalex VE — patrón Facebook/WhatsApp.
///
/// Barra inferior con 4 pestañas (Inicio · Agenda · Asistente IA · Buscar)
/// y el item "Más" que NO cambia de pestaña: abre el AppDrawer (también se
/// abre con swipe desde el borde izquierdo). Las pantallas de las pestañas
/// viven en un [IndexedStack]: conservan su estado al alternar.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Arranca en la pestaña global: si otra pantalla pidió un tab (p. ej.
  // el drawer navegó a 'Agenda' y reemplazó la pila), la nueva instancia
  // del MainScreen abre directamente esa pestaña.
  int _currentIndex = mainTabIndex.value;

  static const _fondoProfundo = Color(0xFF0F172A);
  static const _oro = Color(0xFFC5A059);
  static const _oroBrillante = Color(0xFFE9C86A);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Ruta activa del drawer: resalta el item de la pestaña actual.
  String get _currentRoute => switch (_currentIndex) {
        0 => '/dashboard',
        1 => '/agenda',
        2 => '/asistente_legal',
        _ => '/jurisprudencia',
      };

  @override
  void initState() {
    super.initState();
    mainTabIndex.addListener(_onExternalTabChange);
  }

  @override
  void dispose() {
    mainTabIndex.removeListener(_onExternalTabChange);
    super.dispose();
  }

  /// Cambio externo de pestaña (drawer, botón "Ir al inicio" de otras
  /// pantallas): sincroniza el tab interno sin perder el estado del stack.
  void _onExternalTabChange() {
    final int nuevo = mainTabIndex.value;
    if (_currentIndex == nuevo) return;
    setState(() => _currentIndex = nuevo);
  }

  final List<Widget> _screens = const <Widget>[
    DashboardScreen(), // 0 - Inicio
    AgendaScreen(), // 1 - Agenda
    AsistenteLegalHubScreen(), // 2 - Asistente IA (centro destacado)
    BuscadorJuridicoScreen(), // 3 - Buscar
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // En la pestaña Inicio, atrás sale de la app; en cualquier otra,
      // atrás vuelve a Inicio ("home en 1 tap").
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        mainTabIndex.value = 0;
        setState(() => _currentIndex = 0);
      },
      child: Scaffold(
        key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      drawer: AppDrawer(currentRoute: _currentRoute),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildBottomBar() {
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
              // TODO: reemplazar por QuizIcon('home_ornate')
              _buildNavItem(Icons.home_outlined, 'Inicio', 0),
              // TODO: reemplazar por QuizIcon('calendar_court')
              _buildNavItem(Icons.calendar_month_outlined, 'Agenda', 1),
              // TODO: reemplazar por QuizIcon('auto_awesome_ornate')
              _buildNavItem(Icons.auto_awesome, 'Asistente', 2, isCenter: true),
              // TODO: reemplazar por QuizIcon('search_ornate')
              _buildNavItem(Icons.search, 'Buscar', 3),
              _buildDrawerItem(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index, {
    bool isCenter = false,
  }) {
    final bool isSelected = _currentIndex == index;
    final double iconSize = isCenter ? 26 : 22;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
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

  /// Item "Más" del bottom nav: NO cambia _currentIndex, abre el drawer.
  Widget _buildDrawerItem() {
    return Expanded(
      child: InkWell(
        onTap: () => _scaffoldKey.currentState?.openDrawer(),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // TODO: reemplazar por QuizIcon('menu_ornate')
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
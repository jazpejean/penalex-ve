import 'package:flutter/material.dart';

import '../utils/main_tab_controller.dart';
import 'hub_consulta_juridica_screen.dart';
import '../widgets/app_drawer.dart';
import '../widgets/main_bottom_bar.dart';
import 'dashboard_screen.dart';
import 'agenda_screen.dart';
import 'asistente_legal_hub_screen.dart';

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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Ruta activa del drawer: resalta el item de la pestaña actual.
  String get _currentRoute => switch (_currentIndex) {
        0 => '/dashboard',
        1 => '/agenda',
        2 => '/asistente_legal',
        _ => '/consulta_juridica',
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
    HubConsultaJuridicaScreen(), // 3 - Buscar (hub con las 3 herramientas)
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
      bottomNavigationBar: MainBottomBar(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      ),
    );
  }
}
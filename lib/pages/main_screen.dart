import 'package:flutter/material.dart';

import 'agenda_screen.dart';
import 'asistente_legal_hub_screen.dart';
import 'dosimetria_page.dart';
import 'repositorio_jurisprudencia_screen.dart';
import 'repositorio_leyes_screen.dart';

/// Navegación principal de Penalex VE.
///
/// 5 pestañas: Agenda · Dosimetría · Asistente Legal · Leyes · Sentencias.
/// La barra inferior es la ÚNICA barra de navegación de la app (siempre
/// visible) y usa el estilo de accesos rápidos del dashboard: círculos
/// dorados con el ítem central (Asistente Legal) destacado.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);

  final List<Widget> _screens = const <Widget>[
    AgendaScreen(), // 0 - Agenda
    DosimetriaPage(), // 1 - Dosimetría
    AsistenteLegalHubScreen(), // 2 - Asistente Legal (centro)
    RepositorioLeyesScreen(), // 3 - Leyes
    RepositorioJurisprudenciaScreen(), // 4 - Sentencias
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Evita que la barra suba con el teclado
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // ✅ Barra de navegación única, siempre visible en las 5 pestañas
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: azulMarino,
        border: const Border(top: BorderSide(color: dorado, width: 1)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.33),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavItem(Icons.calendar_month, 'Agenda', 0),
              _buildNavItem(Icons.calculate, 'Dosimetría', 1),
              _buildNavItem(Icons.auto_awesome, 'Asistente Legal', 2,
                  isCenter: true),
              _buildNavItem(Icons.gavel, 'Leyes', 3),
              _buildNavItem(Icons.account_balance, 'Sentencias', 4),
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
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Círculo dorado: sólido cuando está seleccionado
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? dorado : dorado.withValues(alpha: 0.12),
              ),
              child: Icon(
                icon,
                size: 21,
                color: isSelected ? azulMarino : dorado,
              ),
            ),
            const SizedBox(height: 5),
            // FittedBox evita que la etiqueta larga ("Asistente Legal")
            // se corte con "…" en pantallas pequeñas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? dorado
                        : Colors.white.withValues(alpha: 0.85),
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
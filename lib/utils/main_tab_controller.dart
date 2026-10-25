import 'package:flutter/widgets.dart';

/// Índice global de la pestaña activa del MainScreen.
///
/// Cualquier pantalla puede pedir "volver al inicio" escribiendo 0 aquí;
/// el MainScreen escucha este notifier y sincroniza su pestaña interna.
final ValueNotifier<int> mainTabIndex = ValueNotifier<int>(0);

/// Alcance pedido para la pestaña "Buscar" (3) desde fuera (dashboard).
///
/// El dashboard navega a la pestaña Buscar con un corpus concreto
/// ('sentencias' | 'leyes' | 'glosario'); BuscadorJuridicoScreen escucha
/// este notifier y aplica el alcance sin recrear la pantalla.
final ValueNotifier<String?> consultaAlcance = ValueNotifier<String?>(null);

/// Pide a la pestaña "Agenda" (1) abrir su sección de LAPSOS procesales.
///
/// La Agenda vive en un IndexedStack y conserva su estado; este notifier
/// le dice que muestre la vista de lapsos (Calendario Judicial integrado)
/// en lugar de las audiencias. Se resetea a false al entrar por el tab.
final ValueNotifier<bool> agendaEnLapsos = ValueNotifier<bool>(false);

/// Mapa de rutas principales a su índice de tab en el bottom nav.
///
/// Si una ruta aparece aquí, el drawer la trata como pestaña: cambia el tab
/// y reemplaza la pila en lugar de apilar una pantalla nueva.
const Map<String, int> kRutaATab = <String, int>{
  '/dashboard': 0,
  '/': 0,
  '/agenda': 1,
  '/lapsos': 1,
  '/asistente_legal': 2,
  '/repositorio_jurisprudencia': 3,
  '/repositorio_leyes': 3,
  '/glosario': 3,
  '/busqueda_semantica': 3,
};

/// Navegación desde una pantalla que vive DENTRO del MainScreen (p. ej. el
/// dashboard). Si la ruta es una pestaña del bottom nav, cambia la pestaña
/// global y vuelve a la raíz conservando el estado del IndexedStack (la
/// bottom bar permanece visible); si es una herramienta externa, la apila
/// como antes.
void navegarDesdeMain(BuildContext context, String route) {
  final int? tab = kRutaATab[route];
  if (tab != null) {
    mainTabIndex.value = tab;
    Navigator.popUntil(context, (r) => r.isFirst);
  } else {
    Navigator.pushNamed(context, route);
  }
}

/// Abre la pestaña "Buscar" (3) con un corpus concreto.
void navegarAConsulta(BuildContext context, String alcance) {
  mainTabIndex.value = 3;
  consultaAlcance.value = alcance;
  Navigator.popUntil(context, (r) => r.isFirst);
}

/// Abre la pestaña "Agenda" (1) en su sección de LAPSOS procesales
/// (Calendario Judicial integrado en la Agenda, decisión del usuario).
void navegarALapsos(BuildContext context) {
  agendaEnLapsos.value = true;
  mainTabIndex.value = 1;
  Navigator.popUntil(context, (r) => r.isFirst);
}
import 'package:flutter/foundation.dart';

/// Índice global de la pestaña activa del MainScreen.
///
/// Cualquier pantalla puede pedir "volver al inicio" escribiendo 0 aquí;
/// el MainScreen escucha este notifier y sincroniza su pestaña interna.
final ValueNotifier<int> mainTabIndex = ValueNotifier<int>(0);

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
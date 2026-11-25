import 'package:shared_preferences/shared_preferences.dart';

/// Marcadores de artículos de leyes, guardados en el dispositivo.
class FavoritosLeyesService {
  FavoritosLeyesService._();

  static const String _clave = 'leyes_favoritos_v1';

  static Future<Set<String>> leer() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_clave) ?? <String>[]).toSet();
  }

  /// Devuelve true si el artículo quedó guardado.
  static Future<bool> alternar(String id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Set<String> lista =
        (prefs.getStringList(_clave) ?? <String>[]).toSet();
    final bool agregado = !lista.contains(id);
    if (agregado) {
      lista.add(id);
    } else {
      lista.remove(id);
    }
    await prefs.setStringList(_clave, lista.toList());
    return agregado;
  }
}

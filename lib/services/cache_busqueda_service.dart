import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Caché local de resultados de búsqueda.
///
/// Guarda la última respuesta de cada consulta (texto y filtros) para que el
/// usuario siempre tenga algo que ver, aunque la red falle.
class CacheBusquedaService {
  CacheBusquedaService._();

  // v2: invalida las cachés guardadas con la fecha equivocada.
  static String _clave(String consulta) =>
      'v2_${consulta.hashCode.toRadixString(16)}';

  static Future<File> _archivo(String consulta) async {
    final Directory dir = await getApplicationSupportDirectory();
    final Directory carpeta = Directory('${dir.path}/cache_busqueda');
    if (!await carpeta.exists()) {
      await carpeta.create(recursive: true);
    }
    return File('${carpeta.path}/${_clave(consulta)}.json');
  }

  static Future<void> guardar(
      String consulta, List<Map<String, dynamic>> datos) async {
    try {
      if (datos.isEmpty) return;
      final File archivo = await _archivo(consulta);
      await archivo.writeAsString(jsonEncode(datos), flush: true);
    } catch (e) {
      debugPrint('No se pudo guardar la caché de búsqueda: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> leer(String consulta) async {
    try {
      final File archivo = await _archivo(consulta);
      if (!await archivo.exists()) return <Map<String, dynamic>>[];
      final dynamic crudo = jsonDecode(await archivo.readAsString());
      if (crudo is List) {
        return crudo.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('No se pudo leer la caché de búsqueda: $e');
    }
    return <Map<String, dynamic>>[];
  }
}

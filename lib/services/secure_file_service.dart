import 'dart:io';

import 'package:flutter/foundation.dart';

/// Borrado seguro de archivos temporales del escáner.
///
/// Sobrescribe el contenido con ceros antes de eliminarlo, para que el
/// documento no quede recuperable en el almacenamiento. Solo actúa sobre
/// archivos generados por la app (prefijos conocidos); nunca borra la foto
/// original del usuario.
class SecureFileService {
  SecureFileService._();

  static const List<String> _prefijosTemporales = <String>[
    '/doc_',
    '/filtered_',
    '/optimized_',
    '/edge_detected_',
    '/crop_',
    '/page_',
  ];

  static bool esTemporal(String ruta) =>
      _prefijosTemporales.any((String p) => ruta.contains(p));

  /// Sobrescribe con ceros y elimina. Devuelve true si borró.
  static Future<bool> borrarSeguro(String ruta) async {
    try {
      if (!esTemporal(ruta)) return false;
      final File archivo = File(ruta);
      if (!await archivo.exists()) return false;
      final int tamano = await archivo.length();
      if (tamano > 0) {
        final RandomAccessFile raf =
            await archivo.open(mode: FileMode.write);
        await raf.writeFrom(Uint8List(tamano));
        await raf.close();
      }
      await archivo.delete();
      return true;
    } catch (e) {
      debugPrint('❌ No se pudo borrar de forma segura: $e');
      return false;
    }
  }
}

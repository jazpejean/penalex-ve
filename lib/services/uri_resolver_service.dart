import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Resuelve URIs `content://` (Android) a rutas de archivo locales.
///
/// El plugin `flutter_doc_scanner` devuelve content URIs en Android, que no
/// pueden leerse directamente con `dart:io`. Este servicio copia cada URI al
/// caché de la app mediante un canal nativo y devuelve rutas reales.
class UriResolverService {
  UriResolverService._();
  static final UriResolverService _instance = UriResolverService._();
  factory UriResolverService() => _instance;

  static const MethodChannel _channel = MethodChannel('penalex/uri_resolver');

  Future<List<String>> resolverImagenes(List<String> uris) async {
    final resultado = <String>[];
    for (final uri in uris) {
      if (uri.isEmpty) continue;
      if (Platform.isAndroid && uri.startsWith('content://')) {
        try {
          final path = await _channel.invokeMethod<String>(
            'copyToCache',
            {'uri': uri},
          );
          if (path != null && path.isNotEmpty) {
            resultado.add(path);
          } else {
            debugPrint('⚠️ copyToCache devolvió vacío para $uri');
          }
        } catch (e) {
          debugPrint('❌ Error resolviendo content URI: $e');
        }
      } else if (uri.startsWith('file://')) {
        // URI file:// → convertir a ruta local directa.
        resultado.add(Uri.parse(uri).toFilePath());
      } else {
        resultado.add(uri);
      }
    }
    return resultado;
  }
}

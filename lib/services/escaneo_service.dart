import 'package:flutter/foundation.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';

import 'uri_resolver_service.dart';

/// Orquesta la captura de documentos con el escáner nativo (ML Kit en Android,
/// VisionKit en iOS) y devuelve rutas de archivo locales listas para usar.
class EscaneoService {
  EscaneoService._();
  static final EscaneoService _instance = EscaneoService._();
  factory EscaneoService() => _instance;

  final FlutterDocScanner _scanner = FlutterDocScanner();
  final UriResolverService _resolver = UriResolverService();

  /// Escanea hasta [paginas] páginas y devuelve sus rutas locales.
  /// Devuelve lista vacía si el usuario cancela o algo falla.
  Future<List<String>> escanear({int paginas = 30}) async {
    try {
      final result = await _scanner.getScannedDocumentAsImages(
        page: paginas,
        imageFormat: ImageFormat.jpeg,
        quality: 0.9,
      );

      if (result == null || result.images.isEmpty) {
        debugPrint('⚠️ Escaneo cancelado o sin imágenes');
        return [];
      }

      return await _resolver.resolverImagenes(result.images);
    } on DocScanException catch (e) {
      if (e.code == DocScanException.codeCancelled) {
        debugPrint('ℹ️ Escaneo cancelado por el usuario');
      } else {
        debugPrint('❌ DocScanException: ${e.code} ${e.message}');
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error escaneando: $e');
      return [];
    }
  }
}

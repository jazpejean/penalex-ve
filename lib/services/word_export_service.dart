import 'dart:io';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'docx_builder.dart';

/// Exporta un documento (Delta de Quill) a un archivo Word REAL (.docx,
/// formato Open XML), con estilos de párrafo genuinos, membrete incrustado
/// y listas numeradas/viñetas.
///
/// La construcción del paquete OOXML vive en [DocxBuilder] (lógica pura,
/// verificada por tests). Este servicio solo maneja la descarga del membrete
/// y la escritura del archivo en el dispositivo.
class WordExportService {
  /// Convierte el [delta] (contenido del editor Quill) en un archivo .docx.
  ///
  /// Devuelve la ruta del archivo generado, o `null` si falla.
  static Future<String?> exportarDeltaADocx(
    Delta delta, {
    String titulo = 'Documento Legal',
    String? membreteUrl,
    String alineacion = 'centro',
    String tamano = 'medio',
  }) async {
    try {
      // Membrete: descargar y empaquetar como imagen en el ZIP
      List<int>? membreteBytes;
      String membreteExt = 'png';
      if (membreteUrl != null && membreteUrl.isNotEmpty) {
        final img = await _descargarImagen(membreteUrl);
        if (img != null) {
          membreteBytes = img.bytes;
          membreteExt = img.extension;
        }
      }

      final zip = DocxBuilder.build(
        delta,
        membreteBytes: membreteBytes,
        membreteExt: membreteExt,
      );

      final dir = await getApplicationDocumentsDirectory();
      final nombreSeguro = titulo
          .replaceAll(RegExp(r'[^a-zA-Z0-9áéíóúñÁÉÍÓÚÑ ]'), '')
          .trim();
      final filePath = path.join(
        dir.path,
        '${nombreSeguro.isEmpty ? 'documento' : nombreSeguro}_'
        '${DateTime.now().millisecondsSinceEpoch}.docx',
      );
      await File(filePath).writeAsBytes(zip);
      return filePath;
    } catch (e) {
      debugPrint('❌ Error generando Word (docx): $e');
      return null;
    }
  }

  static Future<({List<int> bytes, String extension})?> _descargarImagen(
      String url) async {
    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        final lower = url.toLowerCase();
        final ext = lower.contains('.png')
            ? 'png'
            : (lower.contains('.webp')
                ? 'webp'
                : (lower.contains('.jpg') || lower.contains('.jpeg')
                    ? 'jpeg'
                    : 'png'));
        return (bytes: resp.bodyBytes, extension: ext);
      }
    } catch (e) {
      debugPrint('⚠️ No se pudo descargar el membrete: $e');
    }
    return null;
  }
}
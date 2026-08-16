import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Servicio para extraer texto de documentos e imágenes
class DocumentTextExtractionService {
  /// Extrae texto de una imagen usando OCR
  static Future<String?> extraerTextoDeImagen(String imagePath) async {
    try {
      debugPrint('📷 Extrayendo texto de imagen: $imagePath');

      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer();
      
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final texto = recognizedText.text;
      
      if (texto.isEmpty) {
        debugPrint('⚠️ No se detectó texto en la imagen');
        return null;
      }

      debugPrint('✅ Texto extraído: ${texto.length} caracteres');
      return texto;
    } catch (e) {
      debugPrint('❌ Error extrayendo texto de imagen: $e');
      return null;
    }
  }

  /// Extrae texto de un PDF (solo imágenes escaneadas con OCR)
  /// Nota: Para PDFs con texto nativo, se recomienda usar un lector externo
  static Future<String?> extraerTextoDePDF(String pdfPath) async {
    try {
      debugPrint('📄 PDF detectado: $pdfPath');
      debugPrint('⚠️ Extracción de texto de PDF no disponible (requiere dependencias adicionales)');
      return 'Archivo PDF adjunto: ${pdfPath.split('/').last}\n(Para análisis completo, convierte el PDF a imágenes)';
    } catch (e) {
      debugPrint('❌ Error con PDF: $e');
      return null;
    }
  }

  /// Detecta el tipo de archivo y extrae texto apropiadamente
  static Future<String?> extraerTexto(String filePath) async {
    final extension = filePath.toLowerCase().split('.').last;

    debugPrint('🔍 Detectando tipo de archivo: .$extension');

    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return await extraerTextoDeImagen(filePath);

      case 'pdf':
        return await extraerTextoDePDF(filePath);

      default:
        debugPrint('⚠️ Tipo de archivo no soportado para extracción: .$extension');
        return 'Archivo adjunto: ${filePath.split('/').last}';
    }
  }

  /// Extrae texto de múltiples archivos
  static Future<Map<String, String>> extraerTextoDeMultiplesArchivos(
    List<String> filePaths,
  ) async {
    final Map<String, String> resultados = {};

    for (final filePath in filePaths) {
      final fileName = filePath.split('/').last;
      debugPrint('📂 Procesando: $fileName');

      final texto = await extraerTexto(filePath);
      if (texto != null && texto.isNotEmpty) {
        resultados[fileName] = texto;
      }
    }

    debugPrint('✅ Procesados ${resultados.length}/${filePaths.length} archivos');
    return resultados;
  }

  /// Resume el texto extraído si es muy largo
  static String resumirTextoExtraido(String texto, {int maxCaracteres = 2000}) {
    if (texto.length <= maxCaracteres) {
      return texto;
    }

    final primeraParte = texto.substring(0, maxCaracteres ~/ 2);
    final ultimaParte = texto.substring(texto.length - maxCaracteres ~/ 2);

    return '$primeraParte\n\n[... ${texto.length - maxCaracteres} caracteres omitidos ...]\n\n$ultimaParte';
  }

  /// Genera un resumen de los archivos procesados
  static String generarResumenExtraccion(Map<String, String> textosExtraidos) {
    if (textosExtraidos.isEmpty) {
      return 'No se pudo extraer texto de los archivos adjuntos.';
    }

    final StringBuffer resumen = StringBuffer();
    resumen.writeln('📎 DOCUMENTOS ADJUNTOS:\n');

    textosExtraidos.forEach((fileName, texto) {
      resumen.writeln('📄 $fileName');
      resumen.writeln('Texto extraído (${texto.length} caracteres):');
      resumen.writeln('---');
      resumen.writeln(resumirTextoExtraido(texto, maxCaracteres: 1000));
      resumen.writeln('\n---\n');
    });

    return resumen.toString();
  }
}

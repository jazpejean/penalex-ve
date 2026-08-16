import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

/// Enum de filtros disponibles para documentos
enum DocumentFilter {
  auto,
  blancoYNegro,
  optimizado,
  brillante,
  contraste,
  nitidez,
  original;

  String get displayName {
    switch (this) {
      case DocumentFilter.auto:
        return 'Automático';
      case DocumentFilter.blancoYNegro:
        return 'B&N';
      case DocumentFilter.optimizado:
        return 'Optimizado';
      case DocumentFilter.brillante:
        return 'Brillante';
      case DocumentFilter.contraste:
        return 'Contraste';
      case DocumentFilter.nitidez:
        return 'Nitidez';
      case DocumentFilter.original:
        return 'Original';
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentFilter.auto:
        return Icons.auto_awesome;
      case DocumentFilter.blancoYNegro:
        return Icons.filter_b_and_w;
      case DocumentFilter.optimizado:
        return Icons.tune;
      case DocumentFilter.brillante:
        return Icons.brightness_5;
      case DocumentFilter.contraste:
        return Icons.contrast;
      case DocumentFilter.nitidez:
        return Icons.gradient;
      case DocumentFilter.original:
        return Icons.image;
    }
  }
}

class ImageFilterService {
  /// Ajusta el brillo de una imagen
  /// brightness: -100 a 100 (0 = sin cambios)
  static Future<String?> ajustarBrillo(String imagePath, int brightness) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return null;

      // Ajustar brillo
      final adjusted = img.adjustColor(
        image,
        brightness: brightness.toDouble(),
      );

      // Guardar imagen procesada
      final directory = await getApplicationSupportDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = path.join(directory.path, 'filtered_brightness_$timestamp.jpg');
      
      final newFile = File(newPath);
      await newFile.writeAsBytes(img.encodeJpg(adjusted, quality: 95));
      
      debugPrint('✅ Brillo ajustado: $newPath');
      return newPath;
    } catch (e) {
      debugPrint('❌ Error ajustando brillo: $e');
      return null;
    }
  }

  /// Ajusta el contraste de una imagen
  /// contrast: 0 a 200 (100 = sin cambios)
  static Future<String?> ajustarContraste(String imagePath, int contrast) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return null;

      // Ajustar contraste
      final adjusted = img.adjustColor(
        image,
        contrast: contrast.toDouble(),
      );

      // Guardar imagen procesada
      final directory = await getApplicationSupportDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = path.join(directory.path, 'filtered_contrast_$timestamp.jpg');
      
      final newFile = File(newPath);
      await newFile.writeAsBytes(img.encodeJpg(adjusted, quality: 95));
      
      debugPrint('✅ Contraste ajustado: $newPath');
      return newPath;
    } catch (e) {
      debugPrint('❌ Error ajustando contraste: $e');
      return null;
    }
  }

  /// Convierte imagen a blanco y negro
  static Future<String?> aplicarBlancoYNegro(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return null;

      // Convertir a escala de grises
      final grayscale = img.grayscale(image);

      // Guardar imagen procesada
      final directory = await getApplicationSupportDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = path.join(directory.path, 'filtered_bw_$timestamp.jpg');
      
      final newFile = File(newPath);
      await newFile.writeAsBytes(img.encodeJpg(grayscale, quality: 95));
      
      debugPrint('✅ Blanco y negro aplicado: $newPath');
      return newPath;
    } catch (e) {
      debugPrint('❌ Error aplicando B&N: $e');
      return null;
    }
  }

  /// Aplica múltiples ajustes a la vez
  static Future<String?> aplicarFiltrosMultiples({
    required String imagePath,
    int brightness = 0,
    int contrast = 100,
    bool blancoYNegro = false,
  }) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      var image = img.decodeImage(bytes);
      
      if (image == null) return null;

      // Aplicar brillo y contraste
      if (brightness != 0 || contrast != 100) {
        image = img.adjustColor(
          image,
          brightness: brightness.toDouble(),
          contrast: contrast.toDouble(),
        );
      }

      // Aplicar blanco y negro
      if (blancoYNegro) {
        image = img.grayscale(image);
      }

      // Guardar imagen procesada
      final directory = await getApplicationSupportDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = path.join(directory.path, 'filtered_multiple_$timestamp.jpg');
      
      final newFile = File(newPath);
      await newFile.writeAsBytes(img.encodeJpg(image, quality: 95));
      
      debugPrint('✅ Filtros múltiples aplicados: $newPath');
      return newPath;
    } catch (e) {
      debugPrint('❌ Error aplicando filtros: $e');
      return null;
    }
  }

  /// Aumenta la nitidez del documento
  static Future<String?> aumentarNitidez(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return null;

      // Aplicar filtro de nitidez
      final sharpened = img.adjustColor(
        image,
        contrast: 120,
        saturation: 0.8,
      );

      // Guardar imagen procesada
      final directory = await getApplicationSupportDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = path.join(directory.path, 'filtered_sharp_$timestamp.jpg');
      
      final newFile = File(newPath);
      await newFile.writeAsBytes(img.encodeJpg(sharpened, quality: 95));
      
      debugPrint('✅ Nitidez aumentada: $newPath');
      return newPath;
    } catch (e) {
      debugPrint('❌ Error aumentando nitidez: $e');
      return null;
    }
  }

  /// Optimiza la imagen para documentos (aumenta legibilidad)
  static Future<String?> optimizarParaDocumento(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      var image = img.decodeImage(bytes);
      
      if (image == null) return null;

      // Ajustes óptimos para documentos escaneados
      image = img.adjustColor(
        image,
        brightness: 10,      // Ligeramente más brillante
        contrast: 120,       // Más contraste
        saturation: 0.7,     // Menos saturación
      );

      // Convertir a escala de grises para mejor legibilidad
      image = img.grayscale(image);

      // Guardar imagen optimizada
      final directory = await getApplicationSupportDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = path.join(directory.path, 'optimized_$timestamp.jpg');
      
      final newFile = File(newPath);
      await newFile.writeAsBytes(img.encodeJpg(image, quality: 95));
      
      debugPrint('✅ Documento optimizado: $newPath');
      return newPath;
    } catch (e) {
      debugPrint('❌ Error optimizando documento: $e');
      return null;
    }
  }

  /// Comprime una imagen manteniendo calidad
  static Future<String?> comprimirImagen(
    String imagePath, {
    int quality = 85,
  }) async {
    try {
      final directory = await getApplicationSupportDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = path.join(directory.path, 'compressed_$timestamp.jpg');

      final result = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (result == null) return null;

      debugPrint('✅ Imagen comprimida: ${result.path}');
      return result.path;
    } catch (e) {
      debugPrint('❌ Error comprimiendo imagen: $e');
      return null;
    }
  }

  /// Rota una imagen
  static Future<String?> rotarImagen(String imagePath, int grados) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return null;

      // Rotar imagen (grados debe ser múltiplo de 90)
      final rotated = img.copyRotate(image, angle: grados);

      // Guardar imagen rotada
      final directory = await getApplicationSupportDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = path.join(directory.path, 'rotated_$timestamp.jpg');
      
      final newFile = File(newPath);
      await newFile.writeAsBytes(img.encodeJpg(rotated, quality: 95));
      
      debugPrint('✅ Imagen rotada: $newPath');
      return newPath;
    } catch (e) {
      debugPrint('❌ Error rotando imagen: $e');
      return null;
    }
  }

  /// Genera previews de todos los filtros disponibles
  static Future<Map<DocumentFilter, String>> generatePreviews(String imagePath) async {
    final Map<DocumentFilter, String> previews = {};
    
    try {
      debugPrint('🎨 Generando previews de filtros para: $imagePath');
      
      // Original
      previews[DocumentFilter.original] = imagePath;
      
      // Automático (optimizado)
      final auto = await optimizarParaDocumento(imagePath);
      if (auto != null) previews[DocumentFilter.auto] = auto;
      
      // Blanco y negro
      final bw = await aplicarBlancoYNegro(imagePath);
      if (bw != null) previews[DocumentFilter.blancoYNegro] = bw;
      
      // Optimizado
      final opt = await aplicarFiltrosMultiples(
        imagePath: imagePath,
        brightness: 10,
        contrast: 115,
      );
      if (opt != null) previews[DocumentFilter.optimizado] = opt;
      
      // Brillante
      final bright = await ajustarBrillo(imagePath, 30);
      if (bright != null) previews[DocumentFilter.brillante] = bright;
      
      // Contraste
      final contrast = await ajustarContraste(imagePath, 130);
      if (contrast != null) previews[DocumentFilter.contraste] = contrast;
      
      // Nitidez
      final sharp = await aumentarNitidez(imagePath);
      if (sharp != null) previews[DocumentFilter.nitidez] = sharp;
      
      debugPrint('✅ ${previews.length} previews generados');
      
    } catch (e) {
      debugPrint('❌ Error generando previews: $e');
    }
    
    return previews;
  }
}

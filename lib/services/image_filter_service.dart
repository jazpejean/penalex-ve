import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
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


  /// Binarización adaptativa Sauvola: texto negro sobre blanco, resistente a
  /// sombras y a iluminación desigual. Es la mejora que distingue un documento
  /// escaneado de una foto.
  static Future<String?> binarizarDocumento(String imagePath) async {
    try {
      final Uint8List bytes = await File(imagePath).readAsBytes();
      final Uint8List procesada = await Isolate.run(() => _sauvola(bytes));
      final Directory dir = await getApplicationSupportDirectory();
      final String destino = path.join(
          dir.path, 'doc_${DateTime.now().millisecondsSinceEpoch}.png');
      await File(destino).writeAsBytes(procesada);
      debugPrint('✅ Documento binarizado: $destino');
      return destino;
    } catch (e) {
      debugPrint('❌ Error binarizando: $e');
      return null;
    }
  }

  /// Versión síncrona sobre bytes, para pruebas.
  static Uint8List binarizarBytes(Uint8List bytes) => _sauvola(bytes);

  /// Corre en un isolate aparte para no congelar la interfaz.
  static Uint8List _sauvola(Uint8List bytes) {
    img.Image? src = img.decodeImage(bytes);
    if (src == null) return bytes;

    const int maxLado = 2400;
    if (src.width > maxLado || src.height > maxLado) {
      final double escala =
          maxLado / (src.width > src.height ? src.width : src.height);
      src = img.copyResize(src,
          width: (src.width * escala).round(),
          height: (src.height * escala).round());
    }

    final int w = src.width;
    final int h = src.height;
    final Uint8List gris = Uint8List(w * h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final img.Pixel p = src.getPixel(x, y);
        gris[y * w + x] =
            (p.r * 0.299 + p.g * 0.587 + p.b * 0.114).round().clamp(0, 255);
      }
    }

    final Float64List integral = Float64List((w + 1) * (h + 1));
    final Float64List integralSq = Float64List((w + 1) * (h + 1));
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final double g = gris[y * w + x].toDouble();
        final int i = (y + 1) * (w + 1) + (x + 1);
        integral[i] = g +
            integral[y * (w + 1) + (x + 1)] +
            integral[(y + 1) * (w + 1) + x] -
            integral[y * (w + 1) + x];
        integralSq[i] = g * g +
            integralSq[y * (w + 1) + (x + 1)] +
            integralSq[(y + 1) * (w + 1) + x] -
            integralSq[y * (w + 1) + x];
      }
    }

    final img.Image salida = img.Image(width: w, height: h);
    const int r = 12;
    const double k = 0.2;
    for (int y = 0; y < h; y++) {
      final int y0 = (y - r).clamp(0, h - 1);
      final int y1 = (y + r).clamp(0, h - 1);
      for (int x = 0; x < w; x++) {
        final int x0 = (x - r).clamp(0, w - 1);
        final int x1 = (x + r).clamp(0, w - 1);
        final int n = (x1 - x0 + 1) * (y1 - y0 + 1);
        final double suma = integral[(y1 + 1) * (w + 1) + (x1 + 1)] -
            integral[y0 * (w + 1) + (x1 + 1)] -
            integral[(y1 + 1) * (w + 1) + x0] +
            integral[y0 * (w + 1) + x0];
        final double sumaCuad = integralSq[(y1 + 1) * (w + 1) + (x1 + 1)] -
            integralSq[y0 * (w + 1) + (x1 + 1)] -
            integralSq[(y1 + 1) * (w + 1) + x0] +
            integralSq[y0 * (w + 1) + x0];
        final double media = suma / n;
        final double varianza =
            (sumaCuad / n - media * media).clamp(0.0, double.infinity);
        final double desv = varianza <= 0 ? 0 : math.sqrt(varianza);
        final double umbral = media * (1 + k * ((desv / 128) - 1));
        final int v = gris[y * w + x] < umbral ? 0 : 255;
        salida.setPixelRgb(x, y, v, v, v);
      }
    }
    return img.encodePng(salida);
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

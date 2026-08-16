import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:edge_detection/edge_detection.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Servicio profesional para escaneo de documentos
/// Incluye detección de bordes, corrección de perspectiva y filtros
class DocumentScannerServicePro {
  
  /// Detecta bordes del documento automáticamente usando edge_detection
  static Future<String?> detectEdges(String imagePath) async {
    try {
      debugPrint('🔍 Detectando bordes con edge_detection en: $imagePath');
      
      // Crear ruta para imagen con bordes detectados
      final Directory tempDir = await getTemporaryDirectory();
      final String outputPath = '${tempDir.path}/edge_detected_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Usar edge_detection (nueva API - retorna bool y guarda automáticamente)
      final bool success = await EdgeDetection.detectEdgeFromGallery(
        outputPath,
        androidCropTitle: "Ajustar Bordes",
        androidCropBlackWhiteTitle: "Blanco y Negro",
        androidCropReset: "Restablecer",
      );
      
      if (success && await File(outputPath).exists()) {
        debugPrint('✅ Bordes detectados y guardados en: $outputPath');
        return outputPath;
      }
      
      debugPrint('⚠️ No se pudieron detectar bordes automáticamente');
      return null;
      
    } catch (e) {
      debugPrint('❌ Error detectando bordes: $e');
      return null;
    }
  }
  
  /// Detecta bordes manualmente usando algoritmo de Canny/Contornos
  static Future<List<Offset>?> detectEdgesManual(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return null;
      
      debugPrint('🔍 Detectando bordes manualmente...');
      
      // Convertir a escala de grises
      final grayscale = img.grayscale(image);
      
      // Aplicar filtro Gaussiano para reducir ruido
      final blurred = img.gaussianBlur(grayscale, radius: 5);
      
      // Detectar bordes con Sobel
      final edges = img.sobel(blurred);
      
      // Encontrar contornos (simplificado - buscar el rectángulo más grande)
      final corners = _findLargestRectangle(edges);
      
      if (corners != null && corners.length == 4) {
        debugPrint('✅ Esquinas detectadas: $corners');
        return corners;
      }
      
      // Si no se encuentran esquinas, usar esquinas de la imagen
      debugPrint('⚠️ Usando esquinas por defecto');
      return [
        Offset(0, 0),
        Offset(image.width.toDouble(), 0),
        Offset(image.width.toDouble(), image.height.toDouble()),
        Offset(0, image.height.toDouble()),
      ];
      
    } catch (e) {
      debugPrint('❌ Error en detección manual: $e');
      return null;
    }
  }
  
  /// Encuentra el rectángulo más grande en la imagen de bordes
  static List<Offset>? _findLargestRectangle(img.Image edges) {
    // Algoritmo simplificado - en producción usarías OpenCV
    // Por ahora, busca las 4 esquinas más probables
    
    final width = edges.width;
    final height = edges.height;
    
    // Dividir imagen en cuadrantes y buscar puntos brillantes
    final topLeft = _findCornerInQuadrant(edges, 0, 0, width ~/ 2, height ~/ 2);
    final topRight = _findCornerInQuadrant(edges, width ~/ 2, 0, width, height ~/ 2);
    final bottomRight = _findCornerInQuadrant(edges, width ~/ 2, height ~/ 2, width, height);
    final bottomLeft = _findCornerInQuadrant(edges, 0, height ~/ 2, width ~/ 2, height);
    
    if (topLeft != null && topRight != null && bottomRight != null && bottomLeft != null) {
      return [topLeft, topRight, bottomRight, bottomLeft];
    }
    
    return null;
  }
  
  /// Encuentra una esquina en un cuadrante específico
  static Offset? _findCornerInQuadrant(img.Image image, int x1, int y1, int x2, int y2) {
    int maxIntensity = 0;
    int? maxX, maxY;
    
    for (int y = y1; y < y2; y++) {
      for (int x = x1; x < x2; x++) {
        final pixel = image.getPixel(x, y);
        final intensity = pixel.r.toInt(); // Imagen en escala de grises
        
        if (intensity > maxIntensity) {
          maxIntensity = intensity;
          maxX = x;
          maxY = y;
        }
      }
    }
    
    if (maxX != null && maxY != null) {
      return Offset(maxX.toDouble(), maxY.toDouble());
    }
    
    return null;
  }
  
  /// Aplica corrección de perspectiva y recorta el documento
  static Future<String?> cropAndCorrectPerspective({
    required String imagePath,
    required List<Offset> corners,
  }) async {
    try {
      debugPrint('✂️ Recortando y corrigiendo perspectiva...');
      
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return null;
      
      // Ordenar esquinas: topLeft, topRight, bottomRight, bottomLeft
      final orderedCorners = _orderCorners(corners);
      
      // Calcular dimensiones del documento final
      final width = _distance(orderedCorners[0], orderedCorners[1]).round();
      final height = _distance(orderedCorners[0], orderedCorners[3]).round();
      
      debugPrint('📏 Dimensiones documento: ${width}x$height');
      
      // Crear imagen destino
      final output = img.Image(width: width, height: height);
      
      // Aplicar transformación de perspectiva
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          // Mapear coordenadas destino a coordenadas origen
          final srcPoint = _getPerspectivePoint(
            x.toDouble() / width,
            y.toDouble() / height,
            orderedCorners,
          );
          
          if (srcPoint.dx >= 0 && srcPoint.dx < image.width &&
              srcPoint.dy >= 0 && srcPoint.dy < image.height) {
            final pixel = image.getPixel(srcPoint.dx.toInt(), srcPoint.dy.toInt());
            output.setPixel(x, y, pixel);
          }
        }
      }
      
      // Guardar imagen procesada
      final outputPath = imagePath.replaceAll('.jpg', '_cropped.jpg');
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(img.encodeJpg(output, quality: 95));
      
      debugPrint('✅ Imagen recortada guardada: $outputPath');
      return outputPath;
      
    } catch (e) {
      debugPrint('❌ Error en corrección de perspectiva: $e');
      return null;
    }
  }
  
  /// Ordena las 4 esquinas: topLeft, topRight, bottomRight, bottomLeft
  static List<Offset> _orderCorners(List<Offset> corners) {
    // Ordenar por suma (x + y): menor = topLeft, mayor = bottomRight
    final sorted = List<Offset>.from(corners)..sort((a, b) {
      return (a.dx + a.dy).compareTo(b.dx + b.dy);
    });
    
    final topLeft = sorted[0];
    final bottomRight = sorted[3];
    
    // De los dos puntos medios, el de menor diferencia (x - y) es topRight
    final middle = [sorted[1], sorted[2]];
    middle.sort((a, b) => (a.dx - a.dy).compareTo(b.dx - b.dy));
    
    final topRight = middle[1];
    final bottomLeft = middle[0];
    
    return [topLeft, topRight, bottomRight, bottomLeft];
  }
  
  /// Calcula distancia euclidiana entre dos puntos
  static double _distance(Offset a, Offset b) {
    return math.sqrt(math.pow(a.dx - b.dx, 2) + math.pow(a.dy - b.dy, 2));
  }
  
  /// Mapea punto normalizado (0-1) a coordenadas de imagen usando perspectiva
  static Offset _getPerspectivePoint(double u, double v, List<Offset> corners) {
    // Interpolación bilineal para transformación de perspectiva
    final topLeft = corners[0];
    final topRight = corners[1];
    final bottomRight = corners[2];
    final bottomLeft = corners[3];
    
    // Interpolar horizontalmente en el borde superior
    final top = Offset(
      topLeft.dx + u * (topRight.dx - topLeft.dx),
      topLeft.dy + u * (topRight.dy - topLeft.dy),
    );
    
    // Interpolar horizontalmente en el borde inferior
    final bottom = Offset(
      bottomLeft.dx + u * (bottomRight.dx - bottomLeft.dx),
      bottomLeft.dy + u * (bottomRight.dy - bottomLeft.dy),
    );
    
    // Interpolar verticalmente entre top y bottom
    return Offset(
      top.dx + v * (bottom.dx - top.dx),
      top.dy + v * (bottom.dy - top.dy),
    );
  }
  
  /// Comprime imagen para optimizar almacenamiento
  static Future<String?> compressImage(String imagePath, {int quality = 85}) async {
    try {
      debugPrint('🗜️ Comprimiendo imagen...');
      
      final outputPath = imagePath.replaceAll('.jpg', '_compressed.jpg');
      
      final result = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        outputPath,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      
      if (result != null) {
        final originalSize = await File(imagePath).length();
        final compressedSize = await result.length();
        final reduction = ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);
        
        debugPrint('✅ Imagen comprimida: $originalSize → $compressedSize bytes ($reduction% reducción)');
        return result.path;
      }
      
      return null;
      
    } catch (e) {
      debugPrint('❌ Error comprimiendo imagen: $e');
      return null;
    }
  }
  
  /// Rota imagen 90 grados
  static Future<String?> rotateImage(String imagePath, {int degrees = 90}) async {
    try {
      debugPrint('🔄 Rotando imagen $degrees°...');
      
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return null;
      
      img.Image rotated;
      switch (degrees) {
        case 90:
          rotated = img.copyRotate(image, angle: 90);
          break;
        case 180:
          rotated = img.copyRotate(image, angle: 180);
          break;
        case 270:
          rotated = img.copyRotate(image, angle: 270);
          break;
        default:
          rotated = image;
      }
      
      final outputPath = imagePath.replaceAll('.jpg', '_rotated.jpg');
      await File(outputPath).writeAsBytes(img.encodeJpg(rotated, quality: 95));
      
      debugPrint('✅ Imagen rotada guardada: $outputPath');
      return outputPath;
      
    } catch (e) {
      debugPrint('❌ Error rotando imagen: $e');
      return null;
    }
  }
  
  /// Convierte resultado de detección a lista de Offsets
  /// NOTA: edge_detection ahora retorna directamente la imagen procesada
  /// Este método se mantiene por compatibilidad pero ya no se usa
  static List<Offset> edgeResultToOffsets(dynamic result) {
    // Ya no se usa - edge_detection procesa directamente
    // Retornar corners por defecto (para evitar errores en código legacy)
    debugPrint('⚠️ edgeResultToOffsets está deprecado - edge_detection procesa automáticamente');
    return [
      const Offset(0, 0),
      const Offset(1, 0),
      const Offset(1, 1),
      const Offset(0, 1),
    ];
  }
}

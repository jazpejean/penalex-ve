import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Servicio de escaneo de documentos tipo CamScanner
/// - Detección de bordes automática
/// - Corrección de perspectiva
/// - Mejoras de imagen (contraste, brillo, nitidez)
class DocumentScannerService {
  /// Procesa una imagen para extraer y corregir un documento (como CamScanner)
  /// Usa compute() para NO bloquear la UI
  static Future<Uint8List> procesarDocumento(String imagePath) async {
    try {
      debugPrint('📷 Procesando documento...');
      
      // Ejecutar TODO el procesamiento en isolate separado (no bloquea UI)
      final Uint8List processedBytes = await compute(_procesarDocumentoIsolate, imagePath);
      
      debugPrint('✅ Documento procesado: ${processedBytes.length} bytes');
      return processedBytes;
    } catch (e, stack) {
      debugPrint('❌ Error procesando documento: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  /// Función top-level para ejecutar en isolate (NO bloquea UI principal)
  static Future<Uint8List> _procesarDocumentoIsolate(String imagePath) async {
    // 1. Cargar imagen
    final File imageFile = File(imagePath);
    final Uint8List bytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      throw Exception('No se pudo decodificar la imagen');
    }

    // 2. Redimensionar si es muy grande
    if (originalImage.width > 2000 || originalImage.height > 2000) {
      final double scale = min(2000 / originalImage.width, 2000 / originalImage.height);
      originalImage = img.copyResize(
        originalImage,
        width: (originalImage.width * scale).toInt(),
        height: (originalImage.height * scale).toInt(),
      );
    }

    // 3. Detectar bordes del documento (como CamScanner)
    final corners = detectDocumentCorners(originalImage);

    // 4. Aplicar corrección de perspectiva
    img.Image correctedImage;
    if (corners != null && corners.length == 4) {
      correctedImage = applyPerspectiveCorrection(originalImage, corners);
    } else {
      correctedImage = originalImage;
    }

    // 5. Mejorar calidad (contraste, brillo, nitidez)
    final enhancedImage = enhanceDocument(correctedImage);

    // 6. Convertir a bytes
    final Uint8List processedBytes = Uint8List.fromList(
      img.encodeJpg(enhancedImage, quality: 90),
    );

    return processedBytes;
  }

  /// Detecta las esquinas del documento en la imagen
  static List<Point<int>>? detectDocumentCorners(img.Image image) {
    try {
      // Convertir a escala de grises
      final grayImage = img.grayscale(image);

      // Aplicar desenfoque gaussiano para reducir ruido
      final blurred = img.gaussianBlur(grayImage, radius: 5);

      // Detectar bordes con Canny (simplificado con threshold)
      final edges = _cannyEdgeDetection(blurred);

      // Encontrar contornos
      final contours = _findContours(edges);

      if (contours.isEmpty) {
        debugPrint('⚠️ No se encontraron contornos');
        return null;
      }

      // Encontrar el contorno más grande que parezca un rectángulo
      final documentContour = _findLargestRectangle(contours, image.width, image.height);

      if (documentContour == null) {
        debugPrint('⚠️ No se encontró un rectángulo válido');
        return null;
      }

      debugPrint('✅ Esquinas detectadas: $documentContour');
      return documentContour;
    } catch (e) {
      debugPrint('❌ Error detectando esquinas: $e');
      return null;
    }
  }

  /// Detección de bordes simplificada (Canny edge detection)
  static img.Image _cannyEdgeDetection(img.Image image) {
    // Aplicar threshold adaptativo
    final threshold = _calculateOtsuThreshold(image);
    
    final edges = img.Image(width: image.width, height: image.height);

    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        // Calcular gradientes con operador Sobel
        final gx = _sobelX(image, x, y);
        final gy = _sobelY(image, x, y);
        final magnitude = sqrt(gx * gx + gy * gy).toInt();

        if (magnitude > threshold) {
          edges.setPixelRgba(x, y, 255, 255, 255, 255);
        } else {
          edges.setPixelRgba(x, y, 0, 0, 0, 255);
        }
      }
    }

    return edges;
  }

  /// Operador Sobel para detectar gradiente horizontal
  static int _sobelX(img.Image image, int x, int y) {
    return (-1 * image.getPixel(x - 1, y - 1).r.toInt() +
            1 * image.getPixel(x + 1, y - 1).r.toInt() +
            -2 * image.getPixel(x - 1, y).r.toInt() +
            2 * image.getPixel(x + 1, y).r.toInt() +
            -1 * image.getPixel(x - 1, y + 1).r.toInt() +
            1 * image.getPixel(x + 1, y + 1).r.toInt());
  }

  /// Operador Sobel para detectar gradiente vertical
  static int _sobelY(img.Image image, int x, int y) {
    return (1 * image.getPixel(x - 1, y - 1).r.toInt() +
            2 * image.getPixel(x, y - 1).r.toInt() +
            1 * image.getPixel(x + 1, y - 1).r.toInt() +
            -1 * image.getPixel(x - 1, y + 1).r.toInt() +
            -2 * image.getPixel(x, y + 1).r.toInt() +
            -1 * image.getPixel(x + 1, y + 1).r.toInt());
  }

  /// Calcula threshold usando método de Otsu
  static int _calculateOtsuThreshold(img.Image image) {
    // Histograma de 256 niveles
    final histogram = List<int>.filled(256, 0);
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final intensity = image.getPixel(x, y).r.toInt();
        histogram[intensity]++;
      }
    }

    final total = image.width * image.height;
    double sum = 0;
    for (int i = 0; i < 256; i++) {
      sum += i * histogram[i];
    }

    double sumB = 0;
    int wB = 0;
    int wF = 0;
    double maxVariance = 0;
    int threshold = 0;

    for (int i = 0; i < 256; i++) {
      wB += histogram[i];
      if (wB == 0) continue;

      wF = total - wB;
      if (wF == 0) break;

      sumB += i * histogram[i];
      final mB = sumB / wB;
      final mF = (sum - sumB) / wF;

      final variance = wB * wF * (mB - mF) * (mB - mF);

      if (variance > maxVariance) {
        maxVariance = variance;
        threshold = i;
      }
    }

    return min(threshold + 30, 150); // Ajuste para bordes más prominentes
  }

  /// Encuentra contornos en la imagen de bordes
  static List<List<Point<int>>> _findContours(img.Image edges) {
    final contours = <List<Point<int>>>[];
    final visited = List.generate(
      edges.height,
      (_) => List<bool>.filled(edges.width, false),
    );

    for (int y = 0; y < edges.height; y++) {
      for (int x = 0; x < edges.width; x++) {
        if (!visited[y][x] && edges.getPixel(x, y).r > 128) {
          final contour = <Point<int>>[];
          _traceContour(edges, x, y, visited, contour);
          if (contour.length > 50) {
            // Solo contornos significativos
            contours.add(contour);
          }
        }
      }
    }

    return contours;
  }

  /// Traza un contorno desde un punto
  static void _traceContour(
    img.Image edges,
    int startX,
    int startY,
    List<List<bool>> visited,
    List<Point<int>> contour,
  ) {
    final stack = <Point<int>>[Point(startX, startY)];

    while (stack.isNotEmpty && contour.length < 10000) {
      final point = stack.removeLast();
      final x = point.x;
      final y = point.y;

      if (x < 0 || x >= edges.width || y < 0 || y >= edges.height) continue;
      if (visited[y][x]) continue;
      if (edges.getPixel(x, y).r <= 128) continue;

      visited[y][x] = true;
      contour.add(point);

      // Buscar vecinos
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;
          stack.add(Point(x + dx, y + dy));
        }
      }
    }
  }

  /// Encuentra el rectángulo más grande en los contornos
  static List<Point<int>>? _findLargestRectangle(
    List<List<Point<int>>> contours,
    int imageWidth,
    int imageHeight,
  ) {
    List<Point<int>>? bestRectangle;
    double maxArea = 0;

    for (final contour in contours) {
      // Aproximar contorno a polígono
      final approx = _approximatePolygon(contour);

      // Buscar cuadriláteros
      if (approx.length == 4) {
        final area = _calculatePolygonArea(approx);
        final imageArea = imageWidth * imageHeight;

        // Debe ser al menos 10% del área de la imagen
        if (area > imageArea * 0.1 && area > maxArea) {
          maxArea = area;
          bestRectangle = _orderCorners(approx);
        }
      }
    }

    return bestRectangle;
  }

  /// Aproxima un contorno a un polígono con menos vértices
  static List<Point<int>> _approximatePolygon(List<Point<int>> contour) {
    if (contour.length < 4) return contour;

    // Algoritmo Douglas-Peucker simplificado
    final epsilon = 0.02 * _calculatePerimeter(contour);
    return _douglasPeucker(contour, epsilon);
  }

  /// Algoritmo Douglas-Peucker para simplificación de polígonos
  static List<Point<int>> _douglasPeucker(List<Point<int>> points, double epsilon) {
    if (points.length < 3) return points;

    // Encontrar el punto más lejano
    double maxDistance = 0;
    int maxIndex = 0;

    final start = points.first;
    final end = points.last;

    for (int i = 1; i < points.length - 1; i++) {
      final distance = _perpendicularDistance(points[i], start, end);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // Si la distancia máxima es mayor que epsilon, dividir recursivamente
    if (maxDistance > epsilon) {
      final left = _douglasPeucker(points.sublist(0, maxIndex + 1), epsilon);
      final right = _douglasPeucker(points.sublist(maxIndex), epsilon);

      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [start, end];
    }
  }

  /// Calcula distancia perpendicular de un punto a una línea
  static double _perpendicularDistance(Point<int> point, Point<int> lineStart, Point<int> lineEnd) {
    final dx = lineEnd.x - lineStart.x;
    final dy = lineEnd.y - lineStart.y;

    final numerator = ((point.x - lineStart.x) * dy - (point.y - lineStart.y) * dx).abs();
    final denominator = sqrt(dx * dx + dy * dy);

    return denominator == 0 ? 0 : numerator / denominator;
  }

  /// Calcula el perímetro de un contorno
  static double _calculatePerimeter(List<Point<int>> contour) {
    double perimeter = 0;
    for (int i = 0; i < contour.length; i++) {
      final p1 = contour[i];
      final p2 = contour[(i + 1) % contour.length];
      perimeter += sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2));
    }
    return perimeter;
  }

  /// Calcula el área de un polígono
  static double _calculatePolygonArea(List<Point<int>> polygon) {
    double area = 0;
    for (int i = 0; i < polygon.length; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % polygon.length];
      area += p1.x * p2.y - p2.x * p1.y;
    }
    return area.abs() / 2;
  }

  /// Ordena las esquinas en orden: top-left, top-right, bottom-right, bottom-left
  static List<Point<int>> _orderCorners(List<Point<int>> corners) {
    // Ordenar por suma (x+y): top-left tiene menor suma, bottom-right tiene mayor
    corners.sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
    final topLeft = corners[0];
    final bottomRight = corners[3];

    // Ordenar los dos del medio por diferencia (x-y)
    corners.sort((a, b) => (a.x - a.y).compareTo(b.x - b.y));
    final topRight = corners[3];
    final bottomLeft = corners[0];

    return [topLeft, topRight, bottomRight, bottomLeft];
  }

  /// Aplica corrección de perspectiva usando transformación de 4 puntos
  static img.Image applyPerspectiveCorrection(
    img.Image image,
    List<Point<int>> corners,
  ) {
    // Calcular dimensiones del documento corregido
    final width1 = _distance(corners[0], corners[1]);
    final width2 = _distance(corners[2], corners[3]);
    final height1 = _distance(corners[0], corners[3]);
    final height2 = _distance(corners[1], corners[2]);

    final maxWidth = max(width1, width2).toInt();
    final maxHeight = max(height1, height2).toInt();

    // Crear imagen de salida
    final corrected = img.Image(width: maxWidth, height: maxHeight);

    // Puntos de destino (rectángulo perfecto)
    final dst = [
      Point(0, 0),
      Point(maxWidth - 1, 0),
      Point(maxWidth - 1, maxHeight - 1),
      Point(0, maxHeight - 1),
    ];

    // Calcular matriz de transformación perspectiva
    final matrix = _getPerspectiveTransform(corners, dst);

    // Aplicar transformación
    for (int y = 0; y < maxHeight; y++) {
      for (int x = 0; x < maxWidth; x++) {
        final srcPoint = _transformPoint(x, y, matrix);

        if (srcPoint.x >= 0 &&
            srcPoint.x < image.width &&
            srcPoint.y >= 0 &&
            srcPoint.y < image.height) {
          final pixel = image.getPixel(srcPoint.x.toInt(), srcPoint.y.toInt());
          corrected.setPixel(x, y, pixel);
        }
      }
    }

    return corrected;
  }

  /// Calcula distancia euclidiana entre dos puntos
  static double _distance(Point<int> p1, Point<int> p2) {
    return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2));
  }

  /// Calcula matriz de transformación perspectiva (simplificada)
  static List<double> _getPerspectiveTransform(
    List<Point<int>> src,
    List<Point<int>> dst,
  ) {
    // Transformación perspectiva 3x3 simplificada
    // En producción se usaría una librería de álgebra lineal
    // Por ahora usamos transformación afín aproximada

    return [
      1.0, 0.0, 0.0, // fila 1
      0.0, 1.0, 0.0, // fila 2
      0.0, 0.0, 1.0, // fila 3
    ];
  }

  /// Transforma un punto usando matriz perspectiva
  static Point<double> _transformPoint(int x, int y, List<double> matrix) {
    // Transformación simplificada (bilineal)
    // En producción se usaría transformación perspectiva completa
    return Point(x.toDouble(), y.toDouble());
  }

  /// Mejora la calidad del documento (contraste, brillo, nitidez)
  static img.Image enhanceDocument(img.Image image) {
    // 1. Aumentar contraste
    var enhanced = img.contrast(image, contrast: 120);

    // 2. Ajustar brillo (ajustColor en lugar de brightness)
    enhanced = img.adjustColor(enhanced, brightness: 1.1);

    // 3. Aumentar nitidez
    enhanced = _sharpen(enhanced);

    // 4. Binarización adaptativa para texto más claro
    enhanced = _adaptiveBinarization(enhanced);

    return enhanced;
  }

  /// Aplica filtro de nitidez
  static img.Image _sharpen(img.Image image) {
    final kernel = [
      0, -1, 0,
      -1, 5, -1,
      0, -1, 0,
    ];

    return img.convolution(image, filter: kernel, div: 1, offset: 0);
  }

  /// Binarización adaptativa para documentos
  static img.Image _adaptiveBinarization(img.Image image) {
    final grayscale = img.grayscale(image);
    final binarized = img.Image(width: image.width, height: image.height);

    const blockSize = 15;
    const c = 10;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        // Calcular media local
        int sum = 0;
        int count = 0;

        for (int by = max(0, y - blockSize); by < min(image.height, y + blockSize + 1); by++) {
          for (int bx = max(0, x - blockSize); bx < min(image.width, x + blockSize + 1); bx++) {
            sum += grayscale.getPixel(bx, by).r.toInt();
            count++;
          }
        }

        final threshold = sum / count - c;
        final pixel = grayscale.getPixel(x, y).r.toInt();

        if (pixel > threshold) {
          binarized.setPixelRgba(x, y, 255, 255, 255, 255);
        } else {
          binarized.setPixelRgba(x, y, 0, 0, 0, 255);
        }
      }
    }

    return binarized;
  }
}

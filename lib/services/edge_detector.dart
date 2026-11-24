import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;

/// Detector de bordes de documentos en Dart puro.
///
/// No depende de OpenCV ni de Google Play Services. Trabaja sobre una copia
/// reducida de la imagen, calcula el gradiente de Sobel y busca los cuatro
/// lados del documento por proyección de bordes. Devuelve las esquinas en
/// coordenadas de la imagen original, en orden: arriba-izquierda,
/// arriba-derecha, abajo-derecha, abajo-izquierda.
class EdgeDetector {
  EdgeDetector._();

  static const int _ladoMaximo = 600;

  static List<Offset>? detectar(Uint8List bytes) {
    img.Image? src = img.decodeImage(bytes);
    if (src == null) return null;

    final int ladoMayor = math.max(src.width, src.height);
    final double escala =
        ladoMayor > _ladoMaximo ? _ladoMaximo / ladoMayor : 1.0;
    final int w = math.max(1, (src.width * escala).round());
    final int h = math.max(1, (src.height * escala).round());
    final img.Image im = escala == 1.0
        ? src
        : img.copyResize(src, width: w, height: h);

    final int ancho = im.width;
    final int alto = im.height;
    if (ancho < 20 || alto < 20) return null;

    // Escala de grises.
    final Float32List gris = Float32List(ancho * alto);
    for (int y = 0; y < alto; y++) {
      for (int x = 0; x < ancho; x++) {
        final img.Pixel p = im.getPixel(x, y);
        gris[y * ancho + x] =
            p.r * 0.299 + p.g * 0.587 + p.b * 0.114;
      }
    }

    // Magnitud del gradiente (Sobel).
    final Float32List mag = Float32List(ancho * alto);
    for (int y = 1; y < alto - 1; y++) {
      for (int x = 1; x < ancho - 1; x++) {
        final double gx = -gris[(y - 1) * ancho + x - 1] -
            2 * gris[y * ancho + x - 1] -
            gris[(y + 1) * ancho + x - 1] +
            gris[(y - 1) * ancho + x + 1] +
            2 * gris[y * ancho + x + 1] +
            gris[(y + 1) * ancho + x + 1];
        final double gy = -gris[(y - 1) * ancho + x - 1] -
            2 * gris[(y - 1) * ancho + x] -
            gris[(y - 1) * ancho + x + 1] +
            gris[(y + 1) * ancho + x - 1] +
            2 * gris[(y + 1) * ancho + x] +
            gris[(y + 1) * ancho + x + 1];
        mag[y * ancho + x] = math.sqrt(gx * gx + gy * gy);
      }
    }

    // Proyección horizontal: dos picos, arriba y abajo.
    final Float32List filas = Float32List(alto);
    for (int y = 0; y < alto; y++) {
      double s = 0;
      for (int x = 0; x < ancho; x++) {
        s += mag[y * ancho + x];
      }
      filas[y] = s;
    }
    // Proyección vertical: dos picos, izquierda y derecha.
    final Float32List cols = Float32List(ancho);
    for (int x = 0; x < ancho; x++) {
      double s = 0;
      for (int y = 0; y < alto; y++) {
        s += mag[y * ancho + x];
      }
      cols[x] = s;
    }

    final int? arriba = _pico(filas, 0.03, 0.48);
    final int? abajo = _pico(filas, 0.52, 0.97);
    final int? izquierda = _pico(cols, 0.03, 0.48);
    final int? derecha = _pico(cols, 0.52, 0.97);
    if (arriba == null || abajo == null || izquierda == null || derecha == null) {
      return null;
    }
    if ((abajo - arriba) < alto * 0.25 || (derecha - izquierda) < ancho * 0.25) {
      return null;
    }

    final double inv = 1 / escala;
    final double x1 = izquierda * inv;
    final double x2 = derecha * inv;
    final double y1 = arriba * inv;
    final double y2 = abajo * inv;
    final double anchoOriginal = src.width.toDouble();
    final double altoOriginal = src.height.toDouble();

    return <Offset>[
      Offset(x1.clamp(0, anchoOriginal), y1.clamp(0, altoOriginal)),
      Offset(x2.clamp(0, anchoOriginal), y1.clamp(0, altoOriginal)),
      Offset(x2.clamp(0, anchoOriginal), y2.clamp(0, altoOriginal)),
      Offset(x1.clamp(0, anchoOriginal), y2.clamp(0, altoOriginal)),
    ];
  }

  /// Índice del máximo en la banda [desde, hasta] del arreglo.
  static int? _pico(Float32List valores, double desde, double hasta) {
    if (valores.isEmpty) return null;
    final int i0 = (valores.length * desde).floor().clamp(0, valores.length - 1);
    final int i1 = (valores.length * hasta).ceil().clamp(0, valores.length - 1);
    int? mejor;
    double mejorValor = double.negativeInfinity;
    for (int i = i0; i <= i1; i++) {
      if (valores[i] > mejorValor) {
        mejorValor = valores[i];
        mejor = i;
      }
    }
    return mejorValor <= 0 ? null : mejor;
  }
}

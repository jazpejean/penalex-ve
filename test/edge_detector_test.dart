import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:penalex_ve/services/edge_detector.dart';

void main() {
  test('detecta los cuatro lados de un documento sobre fondo oscuro', () {
    final img.Image base = img.Image(width: 400, height: 400);
    img.fill(base, color: img.ColorRgb8(0, 0, 0));
    for (int y = 50; y < 350; y++) {
      for (int x = 60; x < 340; x++) {
        base.setPixelRgb(x, y, 245, 245, 245);
      }
    }

    final Uint8List bytes = img.encodePng(base);
    final List<Offset>? esquinas = EdgeDetector.detectar(bytes);

    expect(esquinas, isNotNull, reason: 'debe encontrar el documento');
    expect(esquinas!.length, 4);

    final double x1 = esquinas[0].dx;
    final double y1 = esquinas[0].dy;
    final double x2 = esquinas[2].dx;
    final double y2 = esquinas[2].dy;

    expect((x1 - 60).abs(), lessThan(25), reason: 'borde izquierdo');
    expect((y1 - 50).abs(), lessThan(25), reason: 'borde superior');
    expect((x2 - 340).abs(), lessThan(25), reason: 'borde derecho');
    expect((y2 - 350).abs(), lessThan(25), reason: 'borde inferior');
  });

  test('devuelve null si no hay documento', () {
    final img.Image plano = img.Image(width: 200, height: 200);
    img.fill(plano, color: img.ColorRgb8(120, 120, 120));
    final List<Offset>? esquinas =
        EdgeDetector.detectar(img.encodePng(plano));
    expect(esquinas, isNull);
  });
}

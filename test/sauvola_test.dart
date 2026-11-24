import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:penalex_ve/services/image_filter_service.dart';

void main() {
  test('la binarización deja solo negro y blanco', () {
    // Fondo con degradado (simula iluminación desigual) y un bloque oscuro.
    final img.Image base = img.Image(width: 80, height: 80);
    for (int y = 0; y < 80; y++) {
      for (int x = 0; x < 80; x++) {
        final int fondo = 190 + (x * 50 ~/ 80);
        final bool texto = x > 20 && x < 60 && y > 25 && y < 55;
        final int v = texto ? 40 : fondo.clamp(0, 255);
        base.setPixelRgb(x, y, v, v, v);
      }
    }

    final Uint8List salida =
        ImageFilterService.binarizarBytes(img.encodePng(base));
    final img.Image resultado = img.decodeImage(salida)!;

    final Set<int> valores = <int>{};
    for (int y = 0; y < resultado.height; y++) {
      for (int x = 0; x < resultado.width; x++) {
        valores.add(resultado.getPixel(x, y).r.toInt());
      }
    }
    expect(valores.difference(<int>{0, 255}), isEmpty,
        reason: 'la salida debe ser binaria');
    expect(valores.contains(0), isTrue, reason: 'debe haber negro');
    expect(valores.contains(255), isTrue, reason: 'debe haber blanco');
  });
}

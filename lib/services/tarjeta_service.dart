import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Convierte una tarjeta renderizada en PNG y la comparte.
class TarjetaService {
  TarjetaService._();

  static Future<void> compartirImagen(
    GlobalKey clave, {
    String texto = 'Penalex VE',
  }) async {
    final RenderObject? objeto = clave.currentContext?.findRenderObject();
    if (objeto is! RenderRepaintBoundary) return;
    final ui.Image imagen = await objeto.toImage(pixelRatio: 2);
    final ByteData? datos =
        await imagen.toByteData(format: ui.ImageByteFormat.png);
    if (datos == null) return;
    final Directory dir = await getTemporaryDirectory();
    final File archivo = File(
        '${dir.path}/penalex_${DateTime.now().millisecondsSinceEpoch}.png');
    await archivo.writeAsBytes(datos.buffer.asUint8List(), flush: true);
    await Share.shareXFiles(<XFile>[XFile(archivo.path)], text: texto);
  }
}

import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Genera el certificado oficial de Penalex al alcanzar un rango significativo
/// en el quiz. Diseño "diploma": fondo azul marino, marco dorado, sello y
/// firmas, pensado para compartirse en redes.
class QuizCertificateService {
  static const _navy = PdfColor.fromInt(0xFF0F172A);
  static const _navy2 = PdfColor.fromInt(0xFF1E293B);
  static const _gold = PdfColor.fromInt(0xFFC5A059);
  static const _goldBright = PdfColor.fromInt(0xFFE9C86A);
  static const _white = PdfColor.fromInt(0xFFFFFFFF);
  static const _white70 = PdfColor.fromInt(0xFFB7C0CF);

  static Future<String?> generarCertificado({
    required String nombre,
    required String rango,
    required int xp,
    required String codigo,
  }) async {
    try {
      final pdf = pw.Document();

      pw.ImageProvider? logo;
      try {
        final bytes = await rootBundle.load('assets/images/logo.png');
        logo = pw.MemoryImage(bytes.buffer.asUint8List());
      } catch (_) {
        logo = null;
      }

      final fecha =
          '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Stack(
            children: [
              // Fondo azul marino
              pw.Positioned.fill(child: pw.Container(color: _navy)),

              // Bandas superior e inferior doradas
              pw.Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: pw.Container(height: 8, color: _gold),
              ),
              pw.Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: pw.Container(height: 8, color: _gold),
              ),

              // Marco doble dorado
              pw.Positioned.fill(
                child: pw.Container(
                  margin: const pw.EdgeInsets.all(24),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _gold, width: 2.5),
                  ),
                ),
              ),
              pw.Positioned.fill(
                child: pw.Container(
                  margin: const pw.EdgeInsets.all(32),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _goldBright, width: 0.8),
                  ),
                ),
              ),

              // Contenido
              pw.Positioned.fill(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 70, vertical: 40),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      if (logo != null) pw.Image(logo, height: 64),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'PENALEX VE',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: _goldBright,
                          letterSpacing: 5,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'CERTIFICADO DE ASCENSO EN LA CARRERA JUDICIAL',
                        style: pw.TextStyle(
                          fontSize: 13,
                          color: _gold,
                          letterSpacing: 2.5,
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      // Divisor decorativo
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Container(width: 90, height: 1, color: _gold),
                          pw.SizedBox(width: 10),
                          pw.Container(
                            width: 9,
                            height: 9,
                            decoration: pw.BoxDecoration(
                              color: _gold,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Container(width: 90, height: 1, color: _gold),
                        ],
                      ),
                      pw.SizedBox(height: 22),
                      pw.Text(
                        'Se otorga el presente certificado a',
                        style: const pw.TextStyle(fontSize: 12, color: _white70),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        nombre,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 36,
                          fontWeight: pw.FontWeight.bold,
                          color: _white,
                          font: pw.Font.timesBold(),
                        ),
                      ),
                      pw.SizedBox(height: 18),
                      pw.Text(
                        'por haber alcanzado el rango de',
                        style: const pw.TextStyle(fontSize: 12, color: _white70),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        rango,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: _goldBright,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        '$xp XP acumulados',
                        style: const pw.TextStyle(fontSize: 13, color: _white70),
                      ),
                      pw.SizedBox(height: 30),
                      // Fila inferior: fecha, sello, código
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Container(
                                  width: 100,
                                  height: 1,
                                  color: _gold,
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  fecha,
                                  style: const pw.TextStyle(
                                      fontSize: 11, color: _white),
                                ),
                                pw.Text(
                                  'Fecha de emisión',
                                  style: const pw.TextStyle(
                                      fontSize: 9, color: _white70),
                                ),
                              ],
                            ),
                          ),
                          // Sello circular
                          pw.Container(
                            width: 96,
                            height: 96,
                            alignment: pw.Alignment.center,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(color: _gold, width: 3),
                              color: _navy2,
                            ),
                            child: pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Column(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(
                                    '⚖',
                                    style: pw.TextStyle(
                                        fontSize: 20, color: _goldBright),
                                  ),
                                  pw.Text(
                                    'PENALEX',
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                      color: _goldBright,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  pw.Text(
                                    'CARRERA JUDICIAL',
                                    textAlign: pw.TextAlign.center,
                                    style: const pw.TextStyle(
                                        fontSize: 6.5, color: _white70),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                pw.Container(
                                  width: 100,
                                  height: 1,
                                  color: _gold,
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  codigo,
                                  style: pw.TextStyle(
                                      fontSize: 11,
                                      fontWeight: pw.FontWeight.bold,
                                      color: _white),
                                ),
                                pw.Text(
                                  'Código de verificación',
                                  style: const pw.TextStyle(
                                      fontSize: 9, color: _white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final filePath = path.join(
        dir.path,
        'certificado_penalex_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await File(filePath).writeAsBytes(await pdf.save());
      return filePath;
    } catch (e) {
      // ignore: avoid_print
      print('Error generando certificado: $e');
      return null;
    }
  }

  /// Código de verificación determinista a partir del UID y el XP.
  static String generarCodigo(String uid, int xp) {
    final base = '$uid-$xp-${DateTime.now().year}';
    final hash = base.hashCode.toUnsigned(32).toRadixString(16).toUpperCase();
    return 'PXL-${hash.padLeft(8, '0')}';
  }
}

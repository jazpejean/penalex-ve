import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Genera el certificado oficial de Penalex al alcanzar un rango significativo
/// en la carrera judicial del quiz. Diseño "diploma" (A4 horizontal): fondo
/// azul marino, doble marco dorado, logo de la marca, sello, código de
/// verificación y firmas. Pensado para compartirse en redes (marketing
/// orgánico): cada ascenso se comparte como PDF.
class QuizCertificateService {
  QuizCertificateService._();

  // Paleta "diploma judicial": papel marfil, tinta navy y oro viejo.
  static const _paper = PdfColor.fromInt(0xFFFBF8F1); // fondo marfil
  static const _paper2 = PdfColor.fromInt(0xFFF3EDE0); // textura superior
  static const _navy = PdfColor.fromInt(0xFF0F172A); // tinta principal
  static const _gold = PdfColor.fromInt(0xFFC5A059); // oro
  static const _goldDeep = PdfColor.fromInt(0xFF9A7A34); // oro para texto
  static const _goldSoft = PdfColor.fromInt(0xFFE3C98E); // oro claro
  static const _ink = PdfColor.fromInt(0xFF3A4454); // gris azulado
  static const _inkSoft = PdfColor.fromInt(0xFF6B7280); // gris

  static Future<String?> generarCertificado({
    required String nombre,
    required String rango,
    required int xp,
    required String codigo,
    String? etapa,
  }) async {
    try {
      final pdf = pw.Document();

      pw.ImageProvider? logo;
      try {
        final bytes = await rootBundle.load('assets/images/logo-horizontal.png');
        logo = pw.MemoryImage(bytes.buffer.asUint8List());
      } catch (_) {
        logo = null;
      }

      final ahora = DateTime.now();
      final fecha = '${ahora.day} de ${_mes(ahora.month)} de ${ahora.year}';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Stack(
            children: [
              // Fondo de papel con banda superior tenue
              pw.Positioned.fill(child: pw.Container(color: _paper)),
              pw.Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: pw.Container(height: 250, color: _paper2),
              ),

              // Filete navy superior e inferior + línea dorada
              pw.Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: pw.Container(height: 7, color: _navy),
              ),
              pw.Positioned(
                top: 7,
                left: 0,
                right: 0,
                child: pw.Container(height: 2, color: _gold),
              ),
              pw.Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: pw.Container(height: 7, color: _navy),
              ),
              pw.Positioned(
                bottom: 7,
                left: 0,
                right: 0,
                child: pw.Container(height: 2, color: _gold),
              ),

              // Marco doble
              pw.Positioned.fill(
                child: pw.Container(
                  margin: const pw.EdgeInsets.all(26),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _gold, width: 2.4),
                  ),
                ),
              ),
              pw.Positioned.fill(
                child: pw.Container(
                  margin: const pw.EdgeInsets.all(34),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _goldSoft, width: 0.7),
                  ),
                ),
              ),

              // Esquinas ornamentales
              ..._esquinas(),

              // Contenido
              pw.Positioned.fill(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(80, 46, 80, 34),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Logo sobre placa blanca (contraste en fondo navy)
                      if (logo != null) pw.Image(logo, height: 40),
                      pw.SizedBox(height: 20),

                      // Título
                      pw.Text(
                        'CERTIFICADO DE CARRERA JUDICIAL',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: _navy,
                          letterSpacing: 4.5,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'PENALEX VE · LEGALTECH & IA PENAL',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: _goldDeep,
                          letterSpacing: 3,
                        ),
                      ),

                      pw.SizedBox(height: 16),
                      _divisor(),

                      pw.SizedBox(height: 18),
                      pw.Text(
                        'Se otorga el presente certificado a',
                        style: const pw.TextStyle(fontSize: 12, color: _ink),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        nombre,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 38,
                          fontWeight: pw.FontWeight.bold,
                          color: _navy,
                          font: pw.Font.timesBold(),
                        ),
                      ),

                      pw.SizedBox(height: 16),
                      pw.Text(
                        'por haber alcanzado el rango de',
                        style: const pw.TextStyle(fontSize: 12, color: _ink),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        rango,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 25,
                          fontWeight: pw.FontWeight.bold,
                          color: _goldDeep,
                        ),
                      ),
                      if (etapa != null && etapa.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          etapa.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: _goldDeep,
                            letterSpacing: 2.2,
                          ),
                        ),
                      ],

                      pw.SizedBox(height: 14),
                      pw.Text(
                        'con $xp puntos de experiencia acumulados en la carrera judicial',
                        style: const pw.TextStyle(fontSize: 11, color: _ink),
                      ),

                      pw.SizedBox(height: 26),
                      _divisor(),
                      pw.SizedBox(height: 18),

                      // Sello | Firma | Código
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          _sello(),
                          pw.Column(
                            children: [
                              pw.Container(width: 150, height: 1, color: _goldDeep),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                'Dirección Académica',
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _navy,
                                ),
                              ),
                              pw.Text(
                                'Penalex VE',
                                style: const pw.TextStyle(
                                    fontSize: 8.5, color: _inkSoft),
                              ),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'Verificación',
                                style: const pw.TextStyle(
                                    fontSize: 8.5, color: _inkSoft),
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                codigo,
                                style: pw.TextStyle(
                                  fontSize: 13,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _navy,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              pw.Text(
                                'penalexve.com',
                                style: pw.TextStyle(
                                    fontSize: 8.5, color: _goldDeep),
                              ),
                            ],
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 12),
                      pw.Text(
                        'Expedido el $fecha · Documento verificable con el código indicado',
                        style: const pw.TextStyle(fontSize: 8.5, color: _inkSoft),
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
        'certificado_penalex_${ahora.millisecondsSinceEpoch}.pdf',
      );
      await File(filePath).writeAsBytes(await pdf.save());
      return filePath;
    } catch (e) {
      // ignore: avoid_print
      print('Error generando certificado: $e');
      return null;
    }
  }

  /// Divisor con rombo central.
  static pw.Widget _divisor() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Container(width: 120, height: 0.8, color: _goldDeep),
        pw.SizedBox(width: 9),
        pw.Transform.rotate(
          angle: 0.785398,
          child: pw.Container(width: 7, height: 7, color: _goldDeep),
        ),
        pw.SizedBox(width: 9),
        pw.Container(width: 120, height: 0.8, color: _goldDeep),
      ],
    );
  }

  /// Sello circular de la casa.
  static pw.Widget _sello() {
    return pw.Container(
      width: 78,
      height: 78,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: _navy, width: 2),
      ),
      child: pw.Container(
        margin: const pw.EdgeInsets.all(5),
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          border: pw.Border.all(color: _goldDeep, width: 0.7),
        ),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              '★',
              style: pw.TextStyle(fontSize: 14, color: _goldDeep),
            ),
            pw.Text(
              'PENALEX',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _navy,
                letterSpacing: 1.2,
              ),
            ),
            pw.Text(
              'VE',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _navy,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Esquinas ornamentales (pequeñas L doradas).
  static List<pw.Widget> _esquinas() {
    pw.Widget esquina({required double top, required double left}) {
      return pw.Positioned(
        top: top,
        left: left,
        child: pw.Container(
          width: 26,
          height: 26,
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: const pw.BorderSide(color: _goldDeep, width: 1),
              left: const pw.BorderSide(color: _goldDeep, width: 1),
            ),
          ),
        ),
      );
    }

    return [
      esquina(top: 18, left: 18),
      pw.Positioned(
        top: 18,
        right: 18,
        child: pw.Container(
          width: 26,
          height: 26,
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: const pw.BorderSide(color: _goldDeep, width: 1),
              right: const pw.BorderSide(color: _goldDeep, width: 1),
            ),
          ),
        ),
      ),
      pw.Positioned(
        bottom: 18,
        left: 18,
        child: pw.Container(
          width: 26,
          height: 26,
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: const pw.BorderSide(color: _goldDeep, width: 1),
              left: const pw.BorderSide(color: _goldDeep, width: 1),
            ),
          ),
        ),
      ),
      pw.Positioned(
        bottom: 18,
        right: 18,
        child: pw.Container(
          width: 26,
          height: 26,
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: const pw.BorderSide(color: _goldDeep, width: 1),
              right: const pw.BorderSide(color: _goldDeep, width: 1),
            ),
          ),
        ),
      ),
    ];
  }

  static String _mes(int m) {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return meses[(m - 1).clamp(0, 11)];
  }

  /// Código de verificación determinista a partir del UID y el XP.
  static String generarCodigo(String uid, int xp) {
    final base = '$uid-$xp-${DateTime.now().year}';
    final hash = base.hashCode.toUnsigned(32).toRadixString(16).toUpperCase();
    return 'PXL-${hash.padLeft(8, '0')}';
  }
}

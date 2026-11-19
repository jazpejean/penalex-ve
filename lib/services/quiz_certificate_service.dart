import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Genera el certificado oficial de Penalex al alcanzar un rango significativo
/// de la carrera judicial. Diseño "diploma de papel": fondo marfil, doble
/// marco, logo de la marca sobre fondo claro, tipografía grande y sello
/// estampado (rojo tinta) inclinado, el mismo sello que aparece en la
/// animación de ascenso. Pensado para compartirse (marketing orgánico).
class QuizCertificateService {
  QuizCertificateService._();

  static const _paper = PdfColor.fromInt(0xFFFCFAF5);
  static const _navy = PdfColor.fromInt(0xFF0F172A);
  static const _gold = PdfColor.fromInt(0xFFB08D57);
  static const _goldDeep = PdfColor.fromInt(0xFF8C6D2F);
  static const _ink = PdfColor.fromInt(0xFF4A5568);
  static const _inkSoft = PdfColor.fromInt(0xFF6B7280);
  // Rojo tinta del sello (mismo del mockup aprobado).
  static const _seal = PdfColor.fromInt(0xFF9E342C);

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
      final xpTexto = _miles(xp);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Stack(
            children: [
              pw.Positioned.fill(child: pw.Container(color: _paper)),

              // Doble marco
              pw.Positioned.fill(
                child: pw.Container(
                  margin: const pw.EdgeInsets.all(26),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _navy, width: 1.5),
                  ),
                ),
              ),
              pw.Positioned.fill(
                child: pw.Container(
                  margin: const pw.EdgeInsets.all(33),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _gold, width: 0.7),
                  ),
                ),
              ),

              // Esquinas
              _esquina(top: 20, left: 20, t: true, l: true),
              _esquina(top: 20, right: 20, t: true, r: true),
              _esquina(bottom: 20, left: 20, b: true, l: true),
              _esquina(bottom: 20, right: 20, b: true, r: true),

              // Sello estampado (rojo, inclinado, a la derecha)
              pw.Positioned(
                right: 42,
                bottom: 78,
                child: pw.Transform.rotate(
                  angle: -0.21,
                  child: _sello(rango),
                ),
              ),

              // Contenido
              pw.Positioned.fill(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(64, 36, 64, 30),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (logo != null) pw.Image(logo, height: 54),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        'ESCUELA DE DERECHO PENAL · VENEZUELA',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: _gold,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 3.4,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'CERTIFICADO',
                        style: pw.TextStyle(
                          font: pw.Font.timesBold(),
                          fontSize: 62,
                          color: _navy,
                          letterSpacing: 9,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'DE ASCENSO EN LA CARRERA JUDICIAL',
                        style: pw.TextStyle(
                          fontSize: 13,
                          color: _ink,
                          letterSpacing: 5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      pw.Container(width: 140, height: 1.6, color: _gold),
                      pw.SizedBox(height: 26),

                      pw.Text(
                        'Se otorga a',
                        style: const pw.TextStyle(fontSize: 15, color: _ink),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        nombre,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          font: pw.Font.timesBold(),
                          fontSize: 46,
                          color: _navy,
                        ),
                      ),
                      pw.SizedBox(height: 14),
                      pw.Text(
                        'por haber alcanzado el rango de',
                        style: const pw.TextStyle(fontSize: 15, color: _ink),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        rango,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          font: pw.Font.timesBold(),
                          fontSize: 26,
                          color: _goldDeep,
                        ),
                      ),
                      if (etapa != null && etapa.isNotEmpty) ...[
                        pw.SizedBox(height: 5),
                        pw.Text(
                          etapa.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: _inkSoft,
                            letterSpacing: 2.6,
                          ),
                        ),
                      ],
                      pw.SizedBox(height: 12),
                      pw.Text(
                        '$xpTexto puntos de experiencia · $fecha',
                        style: const pw.TextStyle(fontSize: 13, color: _ink),
                      ),
                    ],
                  ),
                ),
              ),

              // Pie: código y web
              pw.Positioned(
                left: 64,
                right: 64,
                bottom: 42,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          codigo,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: _navy,
                            letterSpacing: 0.8,
                          ),
                        ),
                        pw.Text(
                          '  ·  documento verificable',
                          style: const pw.TextStyle(
                              fontSize: 11, color: _inkSoft),
                        ),
                      ],
                    ),
                    pw.Text(
                      'penalexve.com',
                      style: const pw.TextStyle(fontSize: 12, color: _inkSoft),
                    ),
                  ],
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

  /// Sello circular estampado con el rango en el centro.
  static pw.Widget _sello(String rango) {
    final corto = rango
        .replaceAll('Juez ', '')
        .replaceAll('Magistrado ', '')
        .toUpperCase();
    return pw.Container(
      width: 190,
      height: 190,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: _seal, width: 6),
      ),
      child: pw.Container(
        margin: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          border: pw.Border.all(color: _seal, width: 2),
        ),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'PENALEX VE',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _seal,
                letterSpacing: 1.6,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              corto,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                font: pw.Font.timesBold(),
                fontSize: 18,
                color: _seal,
                lineSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'CARRERA JUDICIAL',
              style: pw.TextStyle(
                fontSize: 7.5,
                color: _seal,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _esquina({
    double? top,
    double? left,
    double? right,
    double? bottom,
    bool t = false,
    bool b = false,
    bool l = false,
    bool r = false,
  }) {
    const lado = pw.BorderSide(color: _gold, width: 1);
    return pw.Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: pw.Container(
        width: 30,
        height: 30,
        decoration: pw.BoxDecoration(
          border: pw.Border(
            top: t ? lado : pw.BorderSide.none,
            bottom: b ? lado : pw.BorderSide.none,
            left: l ? lado : pw.BorderSide.none,
            right: r ? lado : pw.BorderSide.none,
          ),
        ),
      ),
    );
  }

  static String _miles(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
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

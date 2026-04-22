import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../models/certificate.dart';

class CertificateService {
  static const Map<int, String> _certificateTitles = <int, String>{
    150: 'Secretario de Sala',
    500: 'Fiscal Titular / Defensor Público Titular',
    1050: 'Juez de Primera Instancia en lo Penal',
    1250: 'Juez de Corte de Apelaciones',
    1500: 'Magistrado del Tribunal Supremo de Justicia',
    1601: 'Presidente del Tribunal Supremo de Justicia',
  };

  static Future<Certificate> generateCertificate(String userName, int level, String userId) async {
    final String title = _certificateTitles[level] ?? 'Certificado de Avance';
    final DateTime date = DateTime.now();
    final String fileName = 'certificado_${userId}_${level}_${date.millisecondsSinceEpoch}.pdf';

    final pw.Document pdf = pw.Document();

    pw.Font? font;
    pw.Font? boldFont;
    try {
      final ByteData fontData = await rootBundle.load('assets/fonts/times_new_roman.ttf');
      final ByteData boldFontData = await rootBundle.load('assets/fonts/timesbd.ttf');
      font = pw.Font.ttf(fontData);
      boldFont = pw.Font.ttf(boldFontData);
    } on Exception catch (_) {}

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) => pw.Container(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              children: <pw.Widget>[
                pw.Text("REPÚBLICA BOLIVARIANA DE VENEZUELA",
                    style: pw.TextStyle(font: boldFont, fontSize: 18)),
                pw.SizedBox(height: 10),
                pw.Text("PODER JUDICIAL",
                    style: pw.TextStyle(font: boldFont, fontSize: 16)),
                pw.SizedBox(height: 20),
                pw.Text("EL TRIBUNAL SUPREMO DE JUSTICIA",
                    style: pw.TextStyle(font: boldFont, fontSize: 14)),
                pw.Text("(Simulacro Académico)",
                    style: pw.TextStyle(font: font, fontSize: 12)),
                pw.SizedBox(height: 40),
                pw.Text("HACE CONSTAR QUE:",
                    style: pw.TextStyle(font: boldFont, fontSize: 14)),
                pw.SizedBox(height: 20),
                pw.Text(userName.toUpperCase(),
                    style: pw.TextStyle(font: boldFont, fontSize: 16),
                    textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 20),
                pw.Text("HA ALCANZADO EL RANGO DE:",
                    style: pw.TextStyle(font: boldFont, fontSize: 14)),
                pw.SizedBox(height: 10),
                pw.Text(title.toUpperCase(),
                    style: pw.TextStyle(font: boldFont, fontSize: 18),
                    textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 20),
                pw.Text("NIVEL ALCANZADO: $level",
                    style: pw.TextStyle(font: font, fontSize: 12)),
                pw.SizedBox(height: 10),
                pw.Text("FECHA DE EXPEDICIÓN: ${date.day}/${date.month}/${date.year}",
                    style: pw.TextStyle(font: font, fontSize: 12)),
                pw.SizedBox(height: 40),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: <pw.Widget>[
                    pw.Column(children: <pw.Widget>[
                      pw.Text("___________________________",
                          style: pw.TextStyle(font: font, fontSize: 10)),
                      pw.Text("Presidente del TSJ",
                          style: pw.TextStyle(font: font, fontSize: 10)),
                    ]),
                    pw.Column(children: <pw.Widget>[
                      pw.Text("___________________________",
                          style: pw.TextStyle(font: font, fontSize: 10)),
                      pw.Text("Secretario",
                          style: pw.TextStyle(font: font, fontSize: 10)),
                    ]),
                  ],
                ),
              ],
            ),
          ),
      ),
    );

    final Directory output = await getApplicationDocumentsDirectory();
    final File file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return Certificate(
      titulo: title,
      fecha: date,
      urlPdf: file.path,
      nivelAlcanzado: level,
    );
  }

  static Future<void> downloadCertificate(String filePath) async {
    final PermissionStatus status = await Permission.storage.request();
    if (status.isGranted) {
      final Directory? downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final String fileName = filePath.split('/').last;
        final File destFile = File('${downloadsDir.path}/$fileName');
        final File sourceFile = File(filePath);
        await sourceFile.copy(destFile.path);
      }
    }
  }

  static Future<void> shareCertificate(String filePath, String rango) async {
    final String message = 'Acabo de obtener el rango de $rango en Penalex VE. ¡Atrévete a superarme! ⚖️ #PenalexVE #DerechoPenal';
    await Share.shareXFiles(<XFile>[XFile(filePath)], text: message);
  }

  static Future<void> generateAndDownloadCertificate(Certificate certificate) async {
    await downloadCertificate(certificate.urlPdf);
  }
}
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class PDFService {
  static Future<Uint8List?> _generarPDFBytes(String contenidoReporte) async {
    try {
      final pw.Document pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Header(
                level: 0,
                child: pw.Text("INFORME DE DOSIMETRÍA PENAL",
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Text("Generado: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Paragraph(text: contenidoReporte,
                  style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5)),
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.Align(
                child: pw.Text(
                  "Dosimetría Penal Venezolana - Herramienta técnica profesional\n"
                  "Conforme al Código Penal Venezolano",
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
      return await pdf.save();
    } on Exception catch (e) {
      debugPrint('Error generando PDF: $e');
      return null;
    }
  }

  static Future<File?> guardarPDF(String contenidoReporte, String nombreArchivo) async {
    try {
      if (Platform.isAndroid) {
        final PermissionStatus status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          final PermissionStatus status2 = await Permission.storage.request();
          if (!status2.isGranted) {
            debugPrint('Permiso de almacenamiento denegado');
            return null;
          }
        }
      }

      final Uint8List? bytes = await _generarPDFBytes(contenidoReporte);
      if (bytes == null) return null;

      Directory? directorio;
      if (Platform.isAndroid) {
        final Directory? downloadsDirectory = await getDownloadsDirectory();
        if (downloadsDirectory == null) return null;
        directorio = Directory('${downloadsDirectory.path}/Dosimetria');
        if (!await directorio.exists()) await directorio.create(recursive: true);
      } else {
        directorio = await getApplicationDocumentsDirectory();
      }

      final String rutaCompleta = '${directorio.path}/$nombreArchivo.pdf';
      final File file = File(rutaCompleta);
      // ignore: avoid_slow_async_io
      await file.writeAsBytes(bytes);
      return file;
    } on Exception catch (e) {
      debugPrint('Error guardando PDF: $e');
      return null;
    }
  }

  static Future<File?> generarPDF(String contenidoReporte, String nombreArchivo) async =>
      guardarPDF(contenidoReporte, nombreArchivo);

  static Future<void> compartirPDF(File archivo) async {
    try {
      await Share.shareXFiles(<XFile>[XFile(archivo.path)], text: 'Reporte de Dosimetría Penal');
    } on Exception catch (e) {
      debugPrint('Error compartiendo PDF: $e');
    }
  }

  static Future<void> abrirPDF(File archivo) async {
    try {
      await OpenFile.open(archivo.path);
    } on Exception catch (e) {
      debugPrint('Error abriendo PDF: $e');
    }
  }
}
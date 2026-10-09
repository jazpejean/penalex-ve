import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as path;
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../models/documento_escaneado.dart';

class PdfExportService {
  /// Exporta un documento escaneado a PDF
  /// Retorna la ruta del PDF generado o null si falla
  static Future<String?> exportarAPdf(DocumentoEscaneado documento) async {
    try {
      debugPrint('📄 Generando PDF para: ${documento.titulo}');

      final pdf = pw.Document();
      
      // Descargar todas las imágenes
      final List<Uint8List> imagenes = [];
      for (int i = 0; i < documento.paginasUrls.length; i++) {
        debugPrint('⬇️ Descargando página ${i + 1}/${documento.paginasUrls.length}...');
        final imageBytes = await _descargarImagen(documento.paginasUrls[i]);
        if (imageBytes != null) {
          imagenes.add(imageBytes);
        }
      }

      if (imagenes.isEmpty) {
        debugPrint('❌ No se pudo descargar ninguna imagen');
        return null;
      }

      // Agregar cada imagen como una página del PDF
      for (final imageBytes in imagenes) {
        final image = pw.MemoryImage(imageBytes);
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) {
              return pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      // Guardar el PDF
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${documento.titulo.replaceAll(RegExp(r'[^\w\s-]'), '_')}_$timestamp.pdf';
      final filePath = path.join(directory.path, fileName);
      
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      debugPrint('✅ PDF generado: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('❌ Error generando PDF: $e');
      return null;
    }
  }

  /// Exporta y abre el PDF
  static Future<bool> exportarYAbrir(DocumentoEscaneado documento) async {
    final pdfPath = await exportarAPdf(documento);
    if (pdfPath == null) return false;

    try {
      final result = await OpenFile.open(pdfPath);
      debugPrint('📱 Abriendo PDF: ${result.message}');
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('❌ Error abriendo PDF: $e');
      return false;
    }
  }

  /// Exporta y comparte el PDF
  static Future<bool> exportarYCompartir(DocumentoEscaneado documento) async {
    final pdfPath = await exportarAPdf(documento);
    if (pdfPath == null) return false;

    try {
      await Share.shareXFiles(
        [XFile(pdfPath)],
        subject: documento.titulo,
        text: 'Documento escaneado: ${documento.titulo}',
      );
      debugPrint('📤 PDF compartido');
      return true;
    } catch (e) {
      debugPrint('❌ Error compartiendo PDF: $e');
      return false;
    }
  }

  /// Descarga una imagen desde una URL
  static Future<Uint8List?> _descargarImagen(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      debugPrint('❌ Error descargando imagen: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error descargando imagen: $e');
      return null;
    }
  }

  /// Genera un PDF con texto OCR además de las imágenes
  static Future<String?> exportarAPdfConTexto(
    DocumentoEscaneado documento,
  ) async {
    try {
      debugPrint('📄 Generando PDF con texto para: ${documento.titulo}');

      final pdf = pw.Document();
      
      // Página inicial con título y metadata
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    documento.titulo,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Número de páginas: ${documento.numeroPaginas}'),
                pw.Text(
                  'Fecha de escaneo: ${_formatearFecha(documento.fechaCreacion)}',
                ),
                if (documento.textoOcr != null) ...[
                  pw.SizedBox(height: 40),
                  pw.Header(
                    level: 1,
                    child: pw.Text('Texto extraído (OCR)'),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    documento.textoOcr!,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ],
            );
          },
        ),
      );

      // Descargar y agregar imágenes
      for (int i = 0; i < documento.paginasUrls.length; i++) {
        debugPrint('⬇️ Descargando página ${i + 1}/${documento.paginasUrls.length}...');
        final imageBytes = await _descargarImagen(documento.paginasUrls[i]);
        
        if (imageBytes != null) {
          final image = pw.MemoryImage(imageBytes);
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Página ${i + 1}'),
                    pw.SizedBox(height: 10),
                    pw.Expanded(
                      child: pw.Image(image, fit: pw.BoxFit.contain),
                    ),
                  ],
                );
              },
            ),
          );
        }
      }

      // Guardar el PDF
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${documento.titulo.replaceAll(RegExp(r'[^\w\s-]'), '_')}_texto_$timestamp.pdf';
      final filePath = path.join(directory.path, fileName);
      
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      debugPrint('✅ PDF con texto generado: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('❌ Error generando PDF con texto: $e');
      return null;
    }
  }

  static String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }
}

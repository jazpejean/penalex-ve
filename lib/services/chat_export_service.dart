import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as path;
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../pages/asistente_legal_screen.dart'; // Importar ChatMessage, AttachedFile, FileType

/// Servicio para exportar conversaciones del asistente legal
class ChatExportService {
  /// Exporta una conversación completa a PDF
  static Future<String?> exportarConversacionAPDF({
    required List<ChatMessage> mensajes,
    String titulo = 'Conversación Legal',
  }) async {
    try {
      debugPrint('📄 Generando PDF de conversación: $titulo');

      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

      // Página de portada
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#0F172A'),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PENALEX VE',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#C5A059'),
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Asistente Legal con IA',
                        style: pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  titulo,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Fecha de exportación: ${dateFormat.format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Total de mensajes: ${mensajes.length}',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),
                pw.Text(
                  'CONTENIDO DE LA CONVERSACIÓN',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#0F172A'),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Páginas de conversación (simplificadas - una página por mensaje)
      for (int i = 0; i < mensajes.length; i++) {
        final mensaje = mensajes[i];
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Encabezado
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: mensaje.isUser ? PdfColor.fromHex('#FEF3C7') : PdfColor.fromHex('#F1F5F9'),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Text(
                          mensaje.isUser ? 'Usuario' : 'Asistente IA',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                        ),
                        pw.Spacer(),
                        pw.Text(
                          dateFormat.format(mensaje.timestamp),
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  
                  // Contenido
                  pw.Expanded(
                    child: pw.Text(mensaje.text, style: const pw.TextStyle(fontSize: 12, height: 1.5)),
                  ),
                  
                  // Pie
                  pw.Divider(),
                  pw.Text(
                    'Mensaje ${i + 1} de ${mensajes.length}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              );
            },
          ),
        );
      }

      // Guardar PDF
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'conversacion_legal_$timestamp.pdf';
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

  /// Exporta un mensaje individual a PDF
  static Future<String?> exportarMensajeAPDF(ChatMessage mensaje) async {
    return exportarConversacionAPDF(mensajes: [mensaje], titulo: 'Mensaje Legal');
  }

  /// Exporta y abre PDF
  static Future<bool> exportarYAbrir({
    required List<ChatMessage> mensajes,
    String titulo = 'Conversación Legal',
  }) async {
    final pdfPath = await exportarConversacionAPDF(mensajes: mensajes, titulo: titulo);
    if (pdfPath == null) return false;

    try {
      final result = await OpenFile.open(pdfPath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('❌ Error abriendo PDF: $e');
      return false;
    }
  }

  /// Exporta mensaje individual y abre
  static Future<bool> exportarMensajeYAbrir(ChatMessage mensaje) async {
    return exportarYAbrir(mensajes: [mensaje], titulo: 'Mensaje Legal');
  }
}

/// Extensión para exportar a formato Word (DOCX)
class ChatExportWordService {
  /// Exporta conversación a formato Word (HTML simple)
  static Future<String?> exportarConversacionAWord({
    required List<ChatMessage> mensajes,
    String titulo = 'Conversación Legal',
  }) async {
    try {
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
      final StringBuffer html = StringBuffer();

      html.writeln('<!DOCTYPE html><html><head><meta charset="UTF-8"><title>$titulo</title></head><body>');
      html.writeln('<h1>PENALEX VE</h1>');
      html.writeln('<h2>$titulo</h2>');
      html.writeln('<p>Fecha: ${dateFormat.format(DateTime.now())}</p><hr>');

      for (int i = 0; i < mensajes.length; i++) {
        final m = mensajes[i];
        html.writeln('<div style="margin: 20px 0; padding: 15px; background: ${m.isUser ? '#FEF3C7' : '#F1F5F9'};">');
        html.writeln('<b>${m.isUser ? 'Usuario' : 'Asistente IA'}</b> - ${dateFormat.format(m.timestamp)}');
        html.writeln('<p>${_escaparHTML(m.text)}</p>');
        html.writeln('</div>');
      }

      html.writeln('</body></html>');

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = path.join(directory.path, 'conversacion_$timestamp.doc');

      await File(filePath).writeAsString(html.toString());
      debugPrint('✅ Word generado: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('❌ Error generando Word: $e');
      return null;
    }
  }

  static String _escaparHTML(String texto) {
    return texto
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('\n', '<br>');
  }

  /// Exporta y abre documento Word
  static Future<bool> exportarYAbrir({
    required List<ChatMessage> mensajes,
    String titulo = 'Conversación Legal',
  }) async {
    final docPath = await exportarConversacionAWord(mensajes: mensajes, titulo: titulo);
    if (docPath == null) return false;

    try {
      final result = await OpenFile.open(docPath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('❌ Error abriendo Word: $e');
      return false;
    }
  }

  /// Exporta mensaje individual
  static Future<bool> exportarMensajeYAbrir(ChatMessage mensaje) async {
    return exportarYAbrir(mensajes: [mensaje], titulo: 'Mensaje Legal');
  }
}

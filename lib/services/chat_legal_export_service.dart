import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/chat_message.dart';

/// Exportación del Chat Legal a PDF y Word (HTML), con soporte de Markdown.
class ChatLegalExportService {
  static const _azulMarino = PdfColor.fromInt(0xFF0F172A);
  static const _dorado = PdfColor.fromInt(0xFFC5A059);

  // ---------------------------------------------------------------------------
  // PDF
  // ---------------------------------------------------------------------------

  static Future<String?> exportarAPDF(
    List<ChatMessage> mensajes, {
    String titulo = 'Conversación Legal',
    String? membreteUrl,
    String alineacion = 'centro',
    String tamano = 'medio',
  }) async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

      pw.ImageProvider? membreteImg;
      if (membreteUrl != null && membreteUrl.isNotEmpty) {
        membreteImg = await _descargarImagen(membreteUrl);
      }

      pdf.addPage(_portada(
        dateFormat,
        titulo,
        mensajes.length,
        membreteImg,
        alineacion,
        tamano,
      ));

      for (final m in mensajes) {
        pdf.addPage(_paginaMensaje(m, dateFormat));
      }

      final dir = await getApplicationDocumentsDirectory();
      final filePath = path.join(
        dir.path,
        'conversacion_legal_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await File(filePath).writeAsBytes(await pdf.save());
      return filePath;
    } catch (e) {
      debugPrint('❌ Error generando PDF: $e');
      return null;
    }
  }

  static pw.Page _portada(
    DateFormat dateFormat,
    String titulo,
    int totalMensajes,
    pw.ImageProvider? membreteImg,
    String alineacion,
    String tamano,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (membreteImg != null) ...[
            _membretePDF(membreteImg, alineacion, tamano),
            pw.SizedBox(height: 20),
          ],
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: _azulMarino,
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
                    color: _dorado,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Chat Legal con IA',
                  style: const pw.TextStyle(fontSize: 14, color: PdfColors.white),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 40),
          pw.Text(
            titulo,
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Fecha de exportación: ${dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.Text(
            'Total de mensajes: $totalMensajes',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static pw.Page _paginaMensaje(ChatMessage m, DateFormat dateFormat) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: m.isUser
                  ? const PdfColor.fromInt(0xFFFEF3C7)
                  : const PdfColor.fromInt(0xFFF1F5F9),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  m.isUser ? 'Usuario' : 'Asistente IA',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                    color: _azulMarino,
                  ),
                ),
                pw.Spacer(),
                pw.Text(
                  dateFormat.format(m.timestamp),
                  style:
                      const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Expanded(child: _renderMarkdown(m.content)),
          if (m.hasSources) ...[
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 6),
            pw.Text(
              'Fuentes:',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _azulMarino,
              ),
            ),
            ...m.sources.map(
              (s) => pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(
                  '• ${s.title} — ${s.reference}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Renderiza contenido Markdown como widgets de texto enriquecido en PDF.
  static pw.Widget _renderMarkdown(String content) {
    final lineas = content.split('\n');
    final widgets = <pw.Widget>[];

    for (var i = 0; i < lineas.length; i++) {
      final linea = lineas[i].trimRight();
      if (linea.trim().isEmpty) {
        widgets.add(pw.SizedBox(height: 8));
        continue;
      }

      // Encabezados (#, ##, ###)
      final headerMatch = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(linea);
      if (headerMatch != null) {
        final nivel = headerMatch.group(1)!.length;
        final texto = headerMatch.group(2)!.trim();
        widgets.add(pw.Padding(
          padding: pw.EdgeInsets.only(top: 8, bottom: 4),
          child: pw.Text(
            _markdownAPlano(texto),
            textAlign: nivel <= 1 ? pw.TextAlign.left : pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: nivel <= 1 ? 18 : (nivel <= 2 ? 16 : 14),
              fontWeight: pw.FontWeight.bold,
              color: _azulMarino,
            ),
          ),
        ));
        continue;
      }

      // Listas (-, *, •, 1., 2.)
      final bulletMatch = RegExp(r'^\s*([-*•]|\d+\.)\s+(.*)$').firstMatch(linea);
      if (bulletMatch != null) {
        final esOrdenada = RegExp(r'^\d+\.').hasMatch(linea);
        final texto = bulletMatch.group(2)!.trim();
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 12, bottom: 4),
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: esOrdenada ? '${bulletMatch.group(1)!} ' : '• ',
                  style: pw.TextStyle(
                    color: _dorado,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                ..._spansInline(texto),
              ],
            ),
          ),
        ));
        continue;
      }

      // Texto normal con negritas inline (justificado)
      widgets.add(pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            style: const pw.TextStyle(
              fontSize: 12,
              height: 1.5,
              color: PdfColors.black,
            ),
            children: _spansInline(linea),
          ),
        ),
      ));
    }

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: widgets);
  }

  /// Parsea negritas `**texto**` y código `` `texto` `` en spans.
  static List<pw.TextSpan> _spansInline(String texto) {
    final spans = <pw.TextSpan>[];
    final regex = RegExp(r'(\*\*[^*]+\*\*|`[^`]+`)');
    var last = 0;
    for (final match in regex.allMatches(texto)) {
      if (match.start > last) {
        spans.add(pw.TextSpan(text: texto.substring(last, match.start)));
      }
      final token = match.group(0)!;
      if (token.startsWith('**')) {
        spans.add(pw.TextSpan(
          text: token.substring(2, token.length - 2),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ));
      } else {
        spans.add(pw.TextSpan(
          text: token.substring(1, token.length - 1),
          style: pw.TextStyle(
            font: pw.Font.courier(),
          ),
        ));
      }
      last = match.end;
    }
    if (last < texto.length) {
      spans.add(pw.TextSpan(text: texto.substring(last)));
    }
    return spans;
  }

  /// Convierte Markdown a texto plano limpio (para copiar al portapapeles).
  static String markdownAPlano(String content) => _markdownAPlano(content);

  static String _markdownAPlano(String content) {
    return content
        .replaceAll(RegExp(r'```[^\n]*\n'), '')
        .replaceAll('```', '')
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        .replaceAll(RegExp(r'^#{1,6}\s+'), '')
        .replaceAll(RegExp(r'^\s*[-*•]\s+'), '• ')
        .trim();
  }

  // ---------------------------------------------------------------------------
  // Word (HTML con texto enriquecido)
  // ---------------------------------------------------------------------------

  static Future<String?> exportarAWord(
    List<ChatMessage> mensajes, {
    String titulo = 'Conversación Legal',
    String? membreteUrl,
    String alineacion = 'centro',
    String tamano = 'medio',
  }) async {
    try {
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
      final html = StringBuffer();
      html.writeln('<!DOCTYPE html><html><head><meta charset="UTF-8">'
          '<title>$titulo</title>'
          '<style>body{font-family:Georgia,serif;max-width:800px;margin:auto;'
          'padding:24px;color:#111}.header{background:#0F172A;color:#C5A059;'
          'padding:20px;border-radius:8px}.msg{margin:16px 0;padding:16px;'
          'border-radius:8px}.user{background:#FEF3C7}.assistant{background:#F1F5F9}'
          '.role{font-weight:bold}.time{color:#777;font-size:12px}'
          'p{text-align:justify}h1{color:#0F172A}'
          'h2,h3,h4{color:#0F172A;text-align:center;font-weight:bold}'
          'ul{padding-left:20px}</style></head><body>');
      if (membreteUrl != null && membreteUrl.isNotEmpty) {
        html.writeln('<div style="text-align:${_cssAlineacion(alineacion)};margin-bottom:16px">'
            '<img src="${_esc(membreteUrl)}" style="max-height:${_tamanoPx(tamano)}px;max-width:100%"/></div>');
      }
      html.writeln('<div class="header"><h1 style="color:#C5A059;margin:0">PENALEX VE</h1>'
          '<p style="margin:4px 0 0;color:#fff">Chat Legal con IA</p></div>');
      html.writeln('<h1>$titulo</h1>');
      html.writeln('<p style="color:#777">Exportado: ${dateFormat.format(DateTime.now())}</p>');

      for (final m in mensajes) {
        final clase = m.isUser ? 'user' : 'assistant';
        final rol = m.isUser ? 'Usuario' : 'Asistente IA';
        final body = md.markdownToHtml(m.content);
        html.writeln('<div class="msg $clase">');
        html.writeln('<span class="role">$rol</span> — '
            '<span class="time">${dateFormat.format(m.timestamp)}</span>');
        html.writeln(body);
        if (m.hasSources) {
          html.writeln('<hr><b>Fuentes:</b><ul>');
          for (final s in m.sources) {
            html.writeln('<li>${_esc(s.title)} — ${_esc(s.reference)}</li>');
          }
          html.writeln('</ul>');
        }
        html.writeln('</div>');
      }

      html.writeln('</body></html>');

      final dir = await getApplicationDocumentsDirectory();
      final filePath = path.join(
        dir.path,
        'conversacion_${DateTime.now().millisecondsSinceEpoch}.doc',
      );
      await File(filePath).writeAsString(html.toString());
      return filePath;
    } catch (e) {
      debugPrint('❌ Error generando Word: $e');
      return null;
    }
  }

  static double _tamanoPx(String tamano) {
    switch (tamano) {
      case 'pequeno':
        return 60;
      case 'grande':
        return 160;
      default:
        return 100;
    }
  }

  static String _cssAlineacion(String alineacion) {
    switch (alineacion) {
      case 'izquierda':
        return 'left';
      case 'derecha':
        return 'right';
      default:
        return 'center';
    }
  }

  static pw.Alignment _pdfAlineacion(String alineacion) {
    switch (alineacion) {
      case 'izquierda':
        return pw.Alignment.centerLeft;
      case 'derecha':
        return pw.Alignment.centerRight;
      default:
        return pw.Alignment.center;
    }
  }

  static pw.Widget _membretePDF(
    pw.ImageProvider img,
    String alineacion,
    String tamano,
  ) {
    return pw.Align(
      alignment: _pdfAlineacion(alineacion),
      child: pw.Image(img, height: _tamanoPx(tamano)),
    );
  }

  /// Exporta un texto Markdown suelto a PDF (para comparaciones/escritos).
  static Future<String?> exportarTextoAPDF(
    String contenido, {
    String titulo = 'Documento',
    String? membreteUrl,
    String alineacion = 'centro',
    String tamano = 'medio',
  }) async {
    try {
      final pdf = pw.Document();
      pw.ImageProvider? img;
      if (membreteUrl != null && membreteUrl.isNotEmpty) {
        img = await _descargarImagen(membreteUrl);
      }
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          if (img != null) ...[
            _membretePDF(img, alineacion, tamano),
            pw.SizedBox(height: 20),
          ],
          pw.Text(
            titulo,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: _azulMarino,
            ),
          ),
          pw.SizedBox(height: 12),
          _renderMarkdown(contenido),
        ],
      ));
      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          path.join(dir.path, 'documento_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await File(filePath).writeAsBytes(await pdf.save());
      return filePath;
    } catch (e) {
      debugPrint('❌ Error generando PDF (texto): $e');
      return null;
    }
  }

  static Future<pw.ImageProvider?> _descargarImagen(String url) async {
    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        return pw.MemoryImage(resp.bodyBytes);
      }
    } catch (e) {
      debugPrint('⚠️ No se pudo descargar el membrete: $e');
    }
    return null;
  }

  static String _esc(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

  /// Exporta un texto Markdown suelto (p. ej. un documento redactado) a Word
  /// (.doc con HTML enriquecido). Devuelve la ruta del archivo.
  static Future<String?> exportarTextoAWord(
    String contenido, {
    String titulo = 'Documento',
    String? membreteUrl,
    String alineacion = 'centro',
    String tamano = 'medio',
  }) async {
    try {
      final html = StringBuffer();
      html.writeln('<!DOCTYPE html><html><head><meta charset="UTF-8">'
          '<title>${_esc(titulo)}</title>'
          '<style>body{font-family:Georgia,serif;max-width:800px;margin:auto;'
          'padding:24px;color:#111}.header{background:#0F172A;color:#C5A059;'
          'padding:20px;border-radius:8px}'
          'p{text-align:justify}h1{color:#0F172A}'
          'h2,h3,h4{color:#0F172A;text-align:center;font-weight:bold}'
          'ul{padding-left:20px}'
          'blockquote{font-style:italic;color:#444;border-left:3px solid #C5A059;'
          'padding-left:12px}</style></head><body>');
      if (membreteUrl != null && membreteUrl.isNotEmpty) {
        html.writeln('<div style="text-align:${_cssAlineacion(alineacion)};margin-bottom:16px">'
            '<img src="${_esc(membreteUrl)}" style="max-height:${_tamanoPx(tamano)}px;max-width:100%"/></div>');
      }
      html.writeln('<div class="header"><h1 style="color:#C5A059;margin:0">'
          'PENALEX VE</h1></div>');
      html.writeln('<h1>${_esc(titulo)}</h1>');
      html.writeln(md.markdownToHtml(contenido));
      html.writeln('</body></html>');

      final dir = await getApplicationDocumentsDirectory();
      final nombreSeguro = titulo.replaceAll(RegExp(r'[^a-zA-Z0-9áéíóúñÁÉÍÓÚÑ ]'), '').trim();
      final filePath = path.join(
        dir.path,
        '${nombreSeguro.isEmpty ? 'documento' : nombreSeguro}_'
        '${DateTime.now().millisecondsSinceEpoch}.doc',
      );
      await File(filePath).writeAsString(html.toString());
      return filePath;
    } catch (e) {
      debugPrint('❌ Error generando Word (texto): $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Abrir
  // ---------------------------------------------------------------------------

  static Future<bool> abrir(String? filePath) async {
    if (filePath == null) return false;
    try {
      final result = await OpenFile.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('❌ Error abriendo archivo: $e');
      return false;
    }
  }
}

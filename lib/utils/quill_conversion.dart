import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:markdown/markdown.dart' as md;

/// Conversiones entre el formato Markdown (lo que guarda el chat) y el Delta
/// de Quill (lo que usa el editor de documentos).
class QuillConversion {
  /// Convierte texto Markdown en un Delta de Quill listo para el editor.
  ///
  /// Ruta: Markdown → HTML (paquete `markdown`) → Delta (HtmlToDelta).
  /// Soporta: títulos, negrita, cursiva, subrayado, listas, citas, código.
  static Delta markdownToDelta(String markdown) {
    try {
      final html = md.markdownToHtml(markdown);
      return HtmlToDelta().convert(html);
    } catch (e) {
      // Ante cualquier error de conversión, no perder el texto: se inserta
      // como texto plano.
      return Delta()..insert(markdown.isEmpty ? '\n' : markdown);
    }
  }

  /// Convierte un Delta de Quill de vuelta a Markdown para guardarlo en el
  /// chat. Conserva: títulos, negrita, cursiva, listas, citas y código.
  /// (El subrayado y la alineación se conservan en el .docx exportado desde
  /// el editor; en el chat no hay sintaxis estándar para ellos.)
  static String deltaToMarkdown(Delta delta) {
    final buf = StringBuffer();
    // Agrupar por línea: cada insert de '\n' cierra la línea actual.
    final lineRuns = <({String text, Map<String, dynamic> attrs})>[];
    final lineAttrs = <String, dynamic>{};

    void flushLine() {
      if (lineRuns.isEmpty) {
        buf.writeln();
      } else {
        buf.writeln(_lineToMarkdown(lineRuns, lineAttrs));
      }
      lineRuns.clear();
      lineAttrs.clear();
    }

    for (final op in delta.operations) {
      if (op.key != Operation.insertKey) continue;
      final data = op.data;
      if (data is String) {
        final attrs = op.attributes ?? const <String, dynamic>{};
        final parts = data.split('\n');
        for (var i = 0; i < parts.length; i++) {
          final text = parts[i];
          if (text.isNotEmpty) {
            lineRuns.add((text: text, attrs: attrs));
            lineAttrs
              ..clear()
              ..addAll(attrs);
          }
          if (i < parts.length - 1) {
            flushLine();
          }
        }
      }
    }
    flushLine();
    return buf.toString().trimRight();
  }

  static String _lineToMarkdown(
    List<({String text, Map<String, dynamic> attrs})> runs,
    Map<String, dynamic> attrs,
  ) {
    final header = attrs['header'];
    final prefix = switch (header) {
      1 => '# ',
      2 => '## ',
      3 => '### ',
      _ => '',
    };
    final list = attrs['list'];
    final listPrefix = switch (list) {
      'bullet' => '- ',
      'ordered' => '1. ',
      _ => '',
    };
    final quotePrefix = attrs['blockquote'] == true ? '> ' : '';

    final buf = StringBuffer(prefix.isEmpty ? (listPrefix.isEmpty ? quotePrefix : listPrefix) : prefix);
    for (final run in runs) {
      buf.write(_inlineToMarkdown(run.text, run.attrs));
    }
    return buf.toString();
  }

  static String _inlineToMarkdown(String text, Map<String, dynamic> attrs) {
    var t = text;
    final isCode = attrs['code'] == true;
    if (isCode) t = '`$t`';
    if (attrs['bold'] == true) t = '**$t**';
    if (attrs['italic'] == true) t = '*$t*';
    return t;
  }
}
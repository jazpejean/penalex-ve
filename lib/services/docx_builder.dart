import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';

/// Construye un paquete .docx (Open XML) válido a partir de un Delta de
/// Quill. Lógica 100% pura (sin Flutter ni sistema de archivos) para poder
/// ser verificada con tests unitarios.
///
/// El .docx es un ZIP con: [Content_Types].xml, _rels/.rels,
/// word/document.xml, word/_rels/document.xml.rels, word/styles.xml,
/// word/numbering.xml y (opcional) el membrete en word/media/.
class DocxBuilder {
  /// Construye los bytes del .docx a partir del [delta].
  ///
  /// [membreteBytes] y [membreteExt] incrustan el logo del abogado.
  static List<int> build(
    Delta delta, {
    List<int>? membreteBytes,
    String membreteExt = 'png',
  }) {
    final docXml = _construirDocumentoXml(delta);

    final archive = Archive();

    // --- [Content_Types].xml ---
    final contentTypes = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..writeln('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">')
      ..writeln('<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>')
      ..writeln('<Default Extension="xml" ContentType="application/xml"/>')
      ..writeln('<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>')
      ..writeln('<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>')
      ..writeln('<Override PartName="/word/numbering.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/>');
    if (membreteBytes != null) {
      final imgType = membreteExt == 'png'
          ? 'image/png'
          : (membreteExt == 'webp' ? 'image/webp' : 'image/jpeg');
      contentTypes
          .writeln('<Default Extension="$membreteExt" ContentType="$imgType"/>');
    }
    contentTypes.writeln('</Types>');
    archive.addFile(ArchiveFile(
        '[Content_Types].xml',
        contentTypes.length,
        utf8.encode(contentTypes.toString())));

    // --- _rels/.rels ---
    final rootRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
        '</Relationships>';
    archive.addFile(ArchiveFile('_rels/.rels', rootRels.length, utf8.encode(rootRels)));

    // --- word/document.xml ---
    archive.addFile(
        ArchiveFile('word/document.xml', docXml.length, utf8.encode(docXml)));

    // --- word/_rels/document.xml.rels (relación con el membrete) ---
    final docRels = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">');
    if (membreteBytes != null) {
      docRels.write('<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/membrete.$membreteExt"/>');
    }
    docRels.write('</Relationships>');
    archive.addFile(ArchiveFile('word/_rels/document.xml.rels',
        docRels.length, utf8.encode(docRels.toString())));

    // --- word/styles.xml ---
    archive.addFile(ArchiveFile(
        'word/styles.xml', _stylesXml().length, utf8.encode(_stylesXml())));

    // --- word/numbering.xml (listas numeradas y viñetas) ---
    archive.addFile(ArchiveFile('word/numbering.xml',
        _numberingXml().length, utf8.encode(_numberingXml())));

    // --- Membrete en word/media/ ---
    if (membreteBytes != null) {
      archive.addFile(ArchiveFile('word/media/membrete.$membreteExt',
          membreteBytes.length, membreteBytes));
    }

    final zipEncoder = ZipEncoder();
    return zipEncoder.encode(archive)!;
  }

  // -------------------------------------------------------------------------
  // document.xml
  // -------------------------------------------------------------------------

  /// Traduce el Delta de Quill a párrafos Word (w:p / w:r / w:t).
  ///
  /// Soporta: negrita, cursiva, subrayado, títulos H1-H3, listas
  /// (numeradas/viñetas), justificación y citas. Atributos según la
  /// convención de Quill (header, bold, italic, underline, list, align,
  /// blockquote).
  static String _construirDocumentoXml(Delta delta) {
    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buf.writeln('<w:document '
        'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
        'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">');
    buf.writeln('<w:body>');

    final runs = <_Run>[];
    final lineAttrs = <String, dynamic>{};

    void flushLine() {
      final p = _construirParrafo(runs, lineAttrs);
      if (p.isNotEmpty) {
        buf.writeln(p);
      }
      runs.clear();
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
            runs.add(_Run(text, attrs));
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

    buf.writeln('<w:sectPr>'
        '<w:pgSz w:w="12240" w:h="15840"/>'
        '<w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" '
        'w:header="720" w:footer="720" w:gutter="0"/>'
        '</w:sectPr>');
    buf.writeln('</w:body></w:document>');
    return buf.toString();
  }

  static String _construirParrafo(
      List<_Run> runs, Map<String, dynamic> lineAttrs) {
    if (runs.isEmpty) return '';

    final buf = StringBuffer();
    buf.write('<w:p>');
    buf.write('<w:pPr>');

    final header = lineAttrs['header'];
    if (header is int && header >= 1 && header <= 3) {
      buf.write('<w:pStyle w:val="Heading${header}"/>');
    }

    if (lineAttrs['blockquote'] == true) {
      buf.write('<w:pStyle w:val="Cita"/>');
    }

    final align = lineAttrs['align'];
    final wAlign = switch (align) {
      'center' => 'center',
      'right' => 'right',
      'justify' => 'both',
      _ => 'left',
    };
    if (wAlign != 'left') {
      buf.write('<w:jc w:val="$wAlign"/>');
    }

    final list = lineAttrs['list'];
    if (list == 'ordered') {
      buf.write('<w:numPr><w:ilvl w:val="0"/>'
          '<w:numId w:val="1"/></w:numPr>');
    } else if (list == 'bullet') {
      buf.write('<w:numPr><w:ilvl w:val="0"/>'
          '<w:numId w:val="2"/></w:numPr>');
    }

    buf.write('<w:spacing w:after="120" w:line="360" '
        'w:lineRule="auto"/>');

    buf.write('</w:pPr>');

    for (final run in runs) {
      buf.write(_construirRun(run));
    }

    buf.write('</w:p>');
    return buf.toString();
  }

  static String _construirRun(_Run run) {
    final buf = StringBuffer();
    buf.write('<w:r>');
    final attrs = run.attrs;

    final hasStyle = attrs['bold'] == true ||
        attrs['italic'] == true ||
        attrs['underline'] == true;
    if (hasStyle) {
      buf.write('<w:rPr>');
      if (attrs['bold'] == true) buf.write('<w:b/>');
      if (attrs['italic'] == true) buf.write('<w:i/>');
      if (attrs['underline'] == true) {
        buf.write('<w:u w:val="single"/>');
      }
      buf.write('</w:rPr>');
    }

    final text = _xmlEscape(run.text);
    buf.write('<w:t xml:space="preserve">$text</w:t>');
    buf.write('</w:r>');
    return buf.toString();
  }

  static String _xmlEscape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  // -------------------------------------------------------------------------
  // styles.xml y numbering.xml
  // -------------------------------------------------------------------------

  static String _stylesXml() {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        '<w:docDefaults>'
        '<w:rPrDefault><w:rPr>'
        '<w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:cs="Times New Roman"/>'
        '<w:sz w:val="24"/><w:szCs w:val="24"/>'
        '</w:rPr></w:rPrDefault>'
        '<w:pPrDefault><w:pPr>'
        '<w:spacing w:after="120" w:line="360" w:lineRule="auto"/>'
        '</w:pPr></w:pPrDefault>'
        '</w:docDefaults>'
        '<w:style w:type="paragraph" w:default="1" w:styleId="Normal">'
        '<w:name w:val="Normal"/></w:style>'
        '<w:style w:type="paragraph" w:styleId="Heading1">'
        '<w:name w:val="heading 1"/>'
        '<w:basedOn w:val="Normal"/><w:next w:val="Normal"/>'
        '<w:pPr><w:spacing w:before="240" w:after="120"/></w:pPr>'
        '<w:rPr><w:b/><w:sz w:val="36"/><w:szCs w:val="36"/></w:rPr>'
        '</w:style>'
        '<w:style w:type="paragraph" w:styleId="Heading2">'
        '<w:name w:val="heading 2"/>'
        '<w:basedOn w:val="Normal"/><w:next w:val="Normal"/>'
        '<w:pPr><w:spacing w:before="200" w:after="120"/></w:pPr>'
        '<w:rPr><w:b/><w:sz w:val="30"/><w:szCs w:val="30"/></w:rPr>'
        '</w:style>'
        '<w:style w:type="paragraph" w:styleId="Heading3">'
        '<w:name w:val="heading 3"/>'
        '<w:basedOn w:val="Normal"/><w:next w:val="Normal"/>'
        '<w:pPr><w:spacing w:before="160" w:after="120"/></w:pPr>'
        '<w:rPr><w:b/><w:sz w:val="26"/><w:szCs w:val="26"/></w:rPr>'
        '</w:style>'
        '<w:style w:type="paragraph" w:styleId="Cita">'
        '<w:name w:val="Cita"/>'
        '<w:basedOn w:val="Normal"/>'
        '<w:pPr><w:pBdr><w:left w:val="single" w:sz="12" w:space="8" w:color="C5A059"/></w:pBdr>'
        '<w:ind w:left="360"/></w:pPr>'
        '<w:rPr><w:i/></w:rPr>'
        '</w:style>'
        '</w:styles>';
  }

  static String _numberingXml() {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        // numerada (numId 1)
        '<w:abstractNum w:abstractNumId="0">'
        '<w:multiLevelType w:val="hybridMultilevel"/>'
        '<w:lvl w:ilvl="0"><w:start w:val="1"/>'
        '<w:numFmt w:val="decimal"/><w:lvlText w:val="%1."/>'
        '<w:lvlJc w:val="left"/><w:pPr><w:ind w:left="720" w:hanging="360"/></w:pPr>'
        '</w:lvl></w:abstractNum>'
        '<w:num w:numId="1"><w:abstractNumId w:val="0"/></w:num>'
        // viñeta (numId 2)
        '<w:abstractNum w:abstractNumId="1">'
        '<w:multiLevelType w:val="hybridMultilevel"/>'
        '<w:lvl w:ilvl="0"><w:start w:val="1"/>'
        '<w:numFmt w:val="bullet"/><w:lvlText w:val="•"/>'
        '<w:lvlJc w:val="left"/><w:pPr><w:ind w:left="720" w:hanging="360"/></w:pPr>'
        '</w:lvl></w:abstractNum>'
        '<w:num w:numId="2"><w:abstractNumId w:val="1"/></w:num>'
        '</w:numbering>';
  }
}

/// Un run (fragmento de texto con atributos) dentro de un párrafo.
class _Run {
  final String text;
  final Map<String, dynamic> attrs;

  _Run(this.text, this.attrs);
}
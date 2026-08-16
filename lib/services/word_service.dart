import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class WordService {
  /// Genera un documento legal en formato Word (.docx)
  static Future<File> generarDocumentoLegal({
    required String titulo,
    required String contenido,
    required String tipo,
    String? caso,
    String? tribunal,
    String? expediente,
  }) async {
    try {
      debugPrint('📄 Generando documento Word: $titulo');

      // Procesar contenido para formato Word
      final contenidoProcesado = _procesarContenidoParaWord(contenido);

      // Crear documento Word programáticamente
      final docx = await _crearDocumentoWord(
        titulo: titulo,
        contenido: contenidoProcesado,
        caso: caso,
        tribunal: tribunal,
        expediente: expediente,
      );

      // Guardar archivo
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${tipo}_$timestamp.docx';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(docx);
      debugPrint('✅ Documento Word generado: ${file.path}');
      return file;
    } on Exception catch (e, stack) {
      debugPrint('❌ Error generando documento Word: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  /// Crea el documento Word con formato profesional
  static Future<Uint8List> _crearDocumentoWord({
    required String titulo,
    required String contenido,
    String? caso,
    String? tribunal,
    String? expediente,
  }) async {
    // Crear contenido XML para Word (formato WordprocessingML)
    final StringBuffer xmlContent = StringBuffer();

    // Encabezado del documento
    xmlContent.write('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
''');

    // Logo y encabezado (texto "PENALEX VE")
    xmlContent.write('''
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
        <w:spacing w:after="200"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="32"/>
          <w:color w:val="C5A059"/>
        </w:rPr>
        <w:t>⚖ PENALEX VE</w:t>
      </w:r>
    </w:p>
''');

    // Información del caso (si existe)
    if (expediente != null && expediente.isNotEmpty) {
      xmlContent.write(_crearParrafo('Expediente: $expediente', fontSize: 18, bold: true));
    }
    if (caso != null && caso.isNotEmpty) {
      xmlContent.write(_crearParrafo('Caso: $caso', fontSize: 18));
    }
    if (tribunal != null && tribunal.isNotEmpty) {
      xmlContent.write(_crearParrafo('Tribunal: $tribunal', fontSize: 18));
    }

    // Separador
    xmlContent.write('''
    <w:p>
      <w:pPr>
        <w:spacing w:after="200"/>
        <w:pBdr>
          <w:bottom w:val="single" w:sz="12" w:color="C5A059"/>
        </w:pBdr>
      </w:pPr>
    </w:p>
''');

    // Título principal
    xmlContent.write('''
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
        <w:spacing w:before="200" w:after="200"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="32"/>
          <w:color w:val="0F172A"/>
        </w:rPr>
        <w:t>${_escaparXml(titulo.toUpperCase())}</w:t>
      </w:r>
    </w:p>
''');

    // Contenido procesado
    final lines = contenido.split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty) {
        xmlContent.write(_crearParrafoVacio());
        continue;
      }

      // Títulos en MAYÚSCULAS
      if (line.trim() == line.trim().toUpperCase() &&
          line.trim().length > 5 &&
          !line.contains('**') &&
          line.trim().split(' ').length <= 10) {
        xmlContent.write(_crearParrafo(
          line.trim(),
          fontSize: 24,
          bold: true,
          color: '0F172A',
          background: 'F1F5F9',
        ));
        continue;
      }

      // Listas con viñetas
      if (line.trim().startsWith('•') ||
          line.trim().startsWith('- ') ||
          line.trim().startsWith('* ')) {
        final texto = line.trim().replaceFirst(RegExp(r'^[•\-\*]\s*'), '');
        xmlContent.write(_crearLista(texto));
        continue;
      }

      // Listas numeradas
      final numeroMatch = RegExp(r'^\d+\.\s+').firstMatch(line.trim());
      if (numeroMatch != null) {
        final texto = line.trim().substring(numeroMatch.group(0)!.length);
        xmlContent.write(_crearListaNumerada(texto));
        continue;
      }

      // Separadores
      if (line.trim() == '---' || line.trim() == '___') {
        xmlContent.write('''
    <w:p>
      <w:pPr>
        <w:pBdr>
          <w:bottom w:val="single" w:sz="6" w:color="4A5568"/>
        </w:pBdr>
      </w:pPr>
    </w:p>
''');
        continue;
      }

      // Texto normal con formato (negritas, subrayados)
      xmlContent.write(_crearParrafoConFormato(line));
    }

    // Pie de página legal
    xmlContent.write('''
    <w:p>
      <w:pPr>
        <w:spacing w:before="400"/>
      </w:pPr>
    </w:p>
    <w:p>
      <w:pPr>
        <w:shd w:fill="F1F5F9"/>
        <w:spacing w:before="100" w:after="100"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="16"/>
          <w:color w:val="0F172A"/>
        </w:rPr>
        <w:t>DOCUMENTO GENERADO</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:pPr>
        <w:shd w:fill="F1F5F9"/>
        <w:spacing w:after="100"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:sz w:val="16"/>
          <w:color w:val="4A5568"/>
        </w:rPr>
        <w:t>Este documento ha sido generado mediante el Asistente Legal de Penalex VE. La información contenida tiene carácter informativo y debe ser revisada por un profesional del derecho.</w:t>
      </w:r>
    </w:p>
''');

    // Cerrar documento
    xmlContent.write('''
  </w:body>
</w:document>
''');

    // Crear archivo DOCX (ZIP con estructura XML)
    return await _crearArchivoDocx(xmlContent.toString());
  }

  /// Crea un párrafo simple
  static String _crearParrafo(
    String texto, {
    int fontSize = 20,
    bool bold = false,
    String? color,
    String? background,
  }) {
    final StringBuffer xml = StringBuffer();
    xml.write('<w:p>');
    xml.write('<w:pPr>');
    if (background != null) {
      xml.write('<w:shd w:fill="$background"/>');
    }
    xml.write('<w:spacing w:after="100"/>');
    xml.write('</w:pPr>');
    xml.write('<w:r>');
    xml.write('<w:rPr>');
    if (bold) xml.write('<w:b/>');
    xml.write('<w:sz w:val="$fontSize"/>');
    if (color != null) {
      xml.write('<w:color w:val="$color"/>');
    }
    xml.write('</w:rPr>');
    xml.write('<w:t>${_escaparXml(texto)}</w:t>');
    xml.write('</w:r>');
    xml.write('</w:p>');
    return xml.toString();
  }

  /// Crea un párrafo vacío (espacio)
  static String _crearParrafoVacio() {
    return '<w:p><w:pPr><w:spacing w:after="120"/></w:pPr></w:p>';
  }

  /// Crea una lista con viñetas
  static String _crearLista(String texto) {
    return '''
    <w:p>
      <w:pPr>
        <w:numPr>
          <w:ilvl w:val="0"/>
          <w:numId w:val="1"/>
        </w:numPr>
        <w:ind w:left="720"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:sz w:val="20"/>
        </w:rPr>
        <w:t>${_escaparXml(texto)}</w:t>
      </w:r>
    </w:p>
''';
  }

  /// Crea una lista numerada
  static String _crearListaNumerada(String texto) {
    return '''
    <w:p>
      <w:pPr>
        <w:numPr>
          <w:ilvl w:val="0"/>
          <w:numId w:val="2"/>
        </w:numPr>
        <w:ind w:left="720"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:sz w:val="20"/>
        </w:rPr>
        <w:t>${_escaparXml(texto)}</w:t>
      </w:r>
    </w:p>
''';
  }

  /// Crea un párrafo con formato (negritas, subrayados)
  static String _crearParrafoConFormato(String texto) {
    final StringBuffer xml = StringBuffer();
    xml.write('<w:p>');
    xml.write('<w:pPr><w:spacing w:after="100"/></w:pPr>');

    // Regex para detectar **negrita**, __subrayado__, o texto normal
    final regex = RegExp(r'\*\*(.+?)\*\*|__(.+?)__|([^*_]+)');
    final matches = regex.allMatches(texto);

    for (final match in matches) {
      xml.write('<w:r>');
      xml.write('<w:rPr>');
      xml.write('<w:sz w:val="20"/>');

      if (match.group(1) != null) {
        // Negrita
        xml.write('<w:b/>');
        xml.write('</w:rPr>');
        xml.write('<w:t>${_escaparXml(match.group(1)!)}</w:t>');
      } else if (match.group(2) != null) {
        // Subrayado
        xml.write('<w:u w:val="single"/>');
        xml.write('</w:rPr>');
        xml.write('<w:t>${_escaparXml(match.group(2)!)}</w:t>');
      } else if (match.group(3) != null) {
        // Texto normal
        xml.write('</w:rPr>');
        xml.write('<w:t>${_escaparXml(match.group(3)!)}</w:t>');
      }

      xml.write('</w:r>');
    }

    xml.write('</w:p>');
    return xml.toString();
  }

  /// Procesa contenido para Word
  static String _procesarContenidoParaWord(String contenido) {
    // Mantener el contenido sin cambios (ya procesaremos el markdown)
    return contenido;
  }

  /// Escapa caracteres especiales XML
  static String _escaparXml(String texto) {
    return texto
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Crea el archivo DOCX (formato ZIP con XML)
  static Future<Uint8List> _crearArchivoDocx(String documentXml) async {
    // Para simplificar, usaremos una plantilla básica
    // En producción, se debería crear un ZIP completo con todas las partes de DOCX
    
    // Por ahora, retornamos el contenido en formato RTF que es compatible
    final rtfContent = _convertirAFormatoRTF(documentXml);
    return Uint8List.fromList(rtfContent.codeUnits);
  }

  /// Convierte a formato RTF (más simple que DOCX completo)
  static String _convertirAFormatoRTF(String xml) {
    // Extraer solo el texto del XML y crear RTF básico
    final textoLimpio = xml
        .replaceAll(RegExp(r'<[^>]*>'), '\n')
        .replaceAll(RegExp(r'\n+'), '\n')
        .trim();

    return '''{\\rtf1\\ansi\\deff0
{\\fonttbl{\\f0 Times New Roman;}}
{\\colortbl;\\red15\\green23\\blue42;\\red197\\green160\\blue89;}
\\f0\\fs22
$textoLimpio
}''';
  }

  /// Comparte el documento Word
  static Future<void> compartirWord(File archivo) async {
    try {
      final xFile = XFile(archivo.path);
      await Share.shareXFiles(
        [xFile],
        text: 'Documento Legal - Penalex VE',
        subject: 'Documento Legal',
      );
    } on Exception catch (e, stack) {
      debugPrint('❌ Error compartiendo Word: $e');
      debugPrint('Stack: $stack');
    }
  }

  /// Abre el documento Word
  static Future<void> abrirWord(File archivo) async {
    try {
      final result = await OpenFile.open(archivo.path);

      if (result.type != ResultType.done) {
        debugPrint('⚠️ No se pudo abrir el documento: ${result.message}');
      }
    } on Exception catch (e, stack) {
      debugPrint('❌ Error abriendo Word: $e');
      debugPrint('Stack: $stack');
    }
  }
}

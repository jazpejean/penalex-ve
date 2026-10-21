import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

import 'package:penalex_ve/services/docx_builder.dart';

/// Verifica que el .docx generado es un ZIP OOXML válido (cero margen de
/// error: si el XML está mal formado o faltan partes, Word no abre el archivo).
void main() {
  group('DocxBuilder', () {
    test('genera un ZIP válido con todas las partes OOXML requeridas', () {
      final delta = Delta()
        ..insert('SOLICITUD DE LIBERTAD\n', {'header': 1})
        ..insert('Ciudadano Juez. ')
        ..insert('negrita', {'bold': true})
        ..insert(' y ')
        ..insert('cursiva', {'italic': true})
        ..insert('.\n')
        ..insert('Primer argumento\n', {'list': 'ordered'})
        ..insert('Segundo argumento\n', {'list': 'ordered'})
        ..insert('Cita textual', {'blockquote': true})
        ..insert('\n')
        ..insert('Centrado', {'align': 'center'})
        ..insert('\n');

      final bytes = DocxBuilder.build(delta);

      // Es un ZIP legible
      final archive = ZipDecoder().decodeBytes(bytes);
      final names = archive.files.map((f) => f.name).toList();

      expect(names, contains('[Content_Types].xml'));
      expect(names, contains('_rels/.rels'));
      expect(names, contains('word/document.xml'));
      expect(names, contains('word/_rels/document.xml.rels'));
      expect(names, contains('word/styles.xml'));
      expect(names, contains('word/numbering.xml'));
    });

    test('document.xml es XML bien formado y traduce el Delta', () {
      final delta = Delta()
        ..insert('TÍTULO\n', {'header': 1})
        ..insert('**texto normal**\n')
        ..insert('item\n', {'list': 'bullet'});

      final bytes = DocxBuilder.build(delta);
      final archive = ZipDecoder().decodeBytes(bytes);
      final docFile = archive.files.firstWhere((f) => f.name == 'word/document.xml');
      docFile.decompress();
      final docXml = utf8.decode(docFile.content as List<int>);

      // No debe lanzar: XML bien formado
      final parsed = XmlDocument.parse(docXml);
      expect(parsed.rootElement.name.local, 'document');

      // Contiene el título como párrafo con estilo Heading1
      expect(docXml, contains('<w:pStyle w:val="Heading1"/>'));
      // Contiene el texto escapado
      expect(docXml, contains('texto normal'));
      // Contiene la viñeta (numId 2)
      expect(docXml, contains('<w:numId w:val="2"/>'));
    });

    test('escapa caracteres XML especiales en el texto', () {
      final delta = Delta()..insert('Art. 5 < & > "texto"\n');

      final bytes = DocxBuilder.build(delta);
      final archive = ZipDecoder().decodeBytes(bytes);
      final docFile =
          archive.files.firstWhere((f) => f.name == 'word/document.xml');
      docFile.decompress();
      final docXml = utf8.decode(docFile.content as List<int>);

      expect(docXml, contains('Art. 5 &lt; &amp; &gt; &quot;texto&quot;'));
      // XML sigue bien formado
      XmlDocument.parse(docXml);
    });

    test('incrusta el membrete cuando se provee', () {
      final delta = Delta()..insert('Hola\n');
      final membreteBytes = [0x89, 0x50, 0x4E, 0x47, 1, 2, 3];

      final bytes = DocxBuilder.build(
        delta,
        membreteBytes: membreteBytes,
        membreteExt: 'png',
      );
      final archive = ZipDecoder().decodeBytes(bytes);
      final names = archive.files.map((f) => f.name).toList();

      expect(names, contains('word/media/membrete.png'));
      expect(names, contains('word/_rels/document.xml.rels'));
    });

    test('escribe un archivo .docx que abre como ZIP (integración con IO)', () {
      final delta = Delta()
        ..insert('Escrito de apelación\n', {'header': 1})
        ..insert('Cuerpo del escrito.\n');

      final bytes = DocxBuilder.build(delta);

      // Firmas esperadas de un ZIP: "PK\x03\x04" (o "PK\x05\x06" vacío)
      expect(bytes[0], 0x50); // P
      expect(bytes[1], 0x4B); // K

      // Regenerar el ZIP desde disco para validar integridad
      final tmp = File(
          '${Directory.systemTemp.path}/test_${DateTime.now().millisecondsSinceEpoch}.docx');
      tmp.writeAsBytesSync(bytes);
      final onDisk = tmp.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(onDisk);
      expect(archive.files.length, greaterThanOrEqualTo(5));
      tmp.deleteSync();
    });
  });
}
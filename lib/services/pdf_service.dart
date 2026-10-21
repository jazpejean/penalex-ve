import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class PDFService {
  // Colores institucionales según especificación
  static const azulMarino = PdfColor.fromInt(0xFF0F172A); // Azul marino institucional
  static const dorado = PdfColor.fromInt(0xFFC5A059); // Dorado/Bronce institucional
  static const grisClaro = PdfColor.fromInt(0xFFF2F2F2); // Fondo alterno
  static const grisPie = PdfColor.fromInt(0xFFF9F9F9); // Fondo del pie
  static const grisOscuro = PdfColor.fromInt(0xFF4A5568); // Texto secundario
  static const grisMuyClaro = PdfColor.fromInt(0xFFF1F5F9); // Fondo muy claro
  static const negro = PdfColors.black;
  static const blanco = PdfColors.white;

  /// Logo de mazo de juez en dorado (vectorial idéntico a Icons.gavel_rounded)
  static pw.Widget _buildLogoMazo({double size = 50}) {
    return pw.Container(
      width: size,
      height: size,
      child: pw.CustomPaint(
        size: PdfPoint(size, size),
        painter: (PdfGraphics canvas, PdfPoint sizePoint) {
          final w = sizePoint.x;
          final h = sizePoint.y;
          
          // Configurar color dorado
          canvas
            ..setFillColor(dorado)
            ..setStrokeColor(dorado);
          
          // Escala para ajustar al tamaño
          final scale = w / 24; // Material Icons son 24x24 base
          
          // Cabeza del mazo (rectángulo rotado en la parte superior)
          canvas.drawRect(
            w * 0.15, // x
            h * 0.12, // y
            w * 0.55, // width
            h * 0.22, // height
          );
          canvas.fillPath();
          
          // Mango del mazo (línea diagonal desde la cabeza hacia abajo-derecha)
          canvas
            ..moveTo(w * 0.42, h * 0.34)
            ..lineTo(w * 0.70, h * 0.62)
            ..lineTo(w * 0.62, h * 0.70)
            ..lineTo(w * 0.34, h * 0.42)
            ..closePath();
          canvas.fillPath();
          
          // Base/yunque (rectángulo horizontal en la parte inferior)
          canvas.drawRect(
            w * 0.55, // x
            h * 0.65, // y
            w * 0.35, // width
            h * 0.15, // height
          );
          canvas.fillPath();
          
          // Agregar pequeños detalles decorativos al mango
          canvas
            ..setStrokeColor(dorado)
            ..setLineWidth(scale * 0.3)
            ..moveTo(w * 0.45, h * 0.37)
            ..lineTo(w * 0.67, h * 0.59)
            ..strokePath();
          
          canvas
            ..moveTo(w * 0.39, h * 0.43)
            ..lineTo(w * 0.61, h * 0.65)
            ..strokePath();
        },
      ),
    );
  }

  /// Genera PDF profesional de Informe Técnico de Dosimetría Jurídica
  static Future<Uint8List?> generarInformeTecnicoPDF({
    required String contenidoReporte,
    String expediente = 'S/N',
    String acusado = 'No especificado',
  }) async {
    try {
      debugPrint('📄 Generando Informe Técnico de Dosimetría Jurídica...');
      final pdf = pw.Document();

      // Parsear el contenido
      final lines = contenidoReporte.split('\n');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            final List<pw.Widget> widgets = [];

            // ========== ENCABEZADO ==========
            widgets.add(
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Logo del mazo (izquierda)
                  _buildLogoMazo(size: 45),
                  
                  // Info del caso (derecha)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Nº de Expediente: $expediente',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: grisOscuro,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Acusado(s): $acusado',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: grisOscuro,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
            
            widgets.add(pw.SizedBox(height: 20));
            
            // ========== TÍTULO PRINCIPAL ==========
            widgets.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 12),
                child: pw.Text(
                  'INFORME TÉCNICO DE DOSIMETRÍA JURÍDICA',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: grisOscuro,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            );
            
            widgets.add(
              pw.Container(
                height: 2,
                color: grisOscuro,
              ),
            );
            
            widgets.add(pw.SizedBox(height: 20));

            // ========== PROCESAR CONTENIDO ==========
            int i = 0;
            while (i < lines.length) {
              final line = lines[i];
              
              if (line.trim().isEmpty) {
                widgets.add(pw.SizedBox(height: 5));
                i++;
                continue;
              }
              
              // Títulos de sección (##)
              if (line.startsWith('##')) {
                final titulo = line.replaceAll('#', '').trim();
                widgets.add(pw.SizedBox(height: 15));
                widgets.add(
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        left: pw.BorderSide(color: dorado, width: 4),
                      ),
                      color: grisMuyClaro,
                    ),
                    child: pw.Text(
                      titulo,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: grisOscuro,
                      ),
                    ),
                  ),
                );
                widgets.add(pw.SizedBox(height: 10));
                i++;
                continue;
              }
              
              // Subtítulos (###)
              if (line.startsWith('###')) {
                final subtitulo = line.replaceAll('#', '').trim();
                widgets.add(pw.SizedBox(height: 10));
                widgets.add(
                  pw.Text(
                    subtitulo,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: grisOscuro,
                    ),
                  ),
                );
                widgets.add(pw.SizedBox(height: 6));
                i++;
                continue;
              }
              
              // TABLAS
              if (line.trim().startsWith('|') && line.trim().endsWith('|')) {
                final List<List<String>> tableData = [];
                
                while (i < lines.length && lines[i].trim().startsWith('|')) {
                  final row = lines[i]
                      .split('|')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty && e.replaceAll('-', '').isNotEmpty)
                      .toList();
                  
                  if (row.isNotEmpty) {
                    tableData.add(row);
                  }
                  i++;
                }
                
                if (tableData.isNotEmpty) {
                  final List<pw.TableRow> tableRows = [];
                  
                  for (int rowIdx = 0; rowIdx < tableData.length; rowIdx++) {
                    final row = tableData[rowIdx];
                    final isHeader = rowIdx == 0;
                    
                    tableRows.add(
                      pw.TableRow(
                        decoration: isHeader
                            ? const pw.BoxDecoration(color: dorado)
                            : pw.BoxDecoration(
                                color: rowIdx % 2 == 1 ? grisMuyClaro : blanco,
                              ),
                        children: row.map((cell) {
                          String cleanCell = cell.replaceAll('**', '');
                          
                          return pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              cleanCell,
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
                                color: isHeader ? negro : grisOscuro,
                              ),
                              textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }
                  
                  widgets.add(
                    pw.Table(
                      border: pw.TableBorder.all(color: grisOscuro.shade(0.3), width: 0.5),
                      children: tableRows,
                    ),
                  );
                  widgets.add(pw.SizedBox(height: 12));
                }
                continue;
              }
              
              // BLOQUES DE CÓDIGO
              if (line.trim() == '```') {
                i++;
                final List<String> codeLines = [];
                
                while (i < lines.length && lines[i].trim() != '```') {
                  codeLines.add(lines[i]);
                  i++;
                }
                i++;
                
                widgets.add(
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: grisMuyClaro,
                      border: pw.Border.all(color: grisOscuro.shade(0.3)),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: codeLines.map((codeLine) {
                        return pw.Text(
                          codeLine,
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: grisOscuro,
                            font: pw.Font.courier(),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
                widgets.add(pw.SizedBox(height: 10));
                continue;
              }
              
              // PENA DEFINITIVA (Quote >)
              if (line.trim().startsWith('>')) {
                final text = line.replaceFirst('>', '').trim().replaceAll('**', '');
                widgets.add(pw.SizedBox(height: 15));
                widgets.add(
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(15),
                    decoration: const pw.BoxDecoration(
                      color: dorado,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'PENA DEFINITIVA',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: negro,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          text,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: negro,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
                widgets.add(pw.SizedBox(height: 15));
                i++;
                continue;
              }
              
              // LISTAS
              if (line.trim().startsWith('•') || line.trim().startsWith('-')) {
                widgets.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 4,
                          height: 4,
                          margin: const pw.EdgeInsets.only(top: 5, right: 8),
                          decoration: const pw.BoxDecoration(
                            color: dorado,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            line.replaceFirst(RegExp(r'^[•\-]\s*'), ''),
                            style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                i++;
                continue;
              }
              
              // SEPARADORES
              if (line.trim() == '---' || line.trim().startsWith('───')) {
                widgets.add(pw.SizedBox(height: 8));
                widgets.add(
                  pw.Container(
                    height: 1,
                    color: grisOscuro.shade(0.3),
                  ),
                );
                widgets.add(pw.SizedBox(height: 8));
                i++;
                continue;
              }
              
              // TEXTO NORMAL
              String cleanLine = line.replaceAll('**', '');
              
              if (cleanLine.trim().isNotEmpty) {
                widgets.add(
                  pw.Text(
                    cleanLine,
                    style: const pw.TextStyle(
                      fontSize: 9,
                      lineSpacing: 1.4,
                      color: negro,
                    ),
                    textAlign: pw.TextAlign.justify,
                  ),
                );
                widgets.add(pw.SizedBox(height: 3));
              }
              
              i++;
            }

            // ========== AVISO LEGAL ==========
            widgets.add(pw.SizedBox(height: 20));
            widgets.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: grisOscuro.shade(0.4), width: 1),
                  color: grisMuyClaro,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'AVISO LEGAL',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: grisOscuro,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Este informe es una herramienta de asistencia técnica generada automáticamente. El resultado aquí expresado constituye una estimación basada en los parámetros introducidos y no sustituye el criterio jurídico, la interpretación de la norma ni la valoración del juez de la causa. El uso de esta herramienta es responsabilidad exclusiva del profesional del derecho.',
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: grisOscuro,
                        lineSpacing: 1.3,
                      ),
                      textAlign: pw.TextAlign.justify,
                    ),
                  ],
                ),
              ),
            );

            return widgets;
          },
          footer: (pw.Context context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(top: 15),
              padding: const pw.EdgeInsets.only(top: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: grisOscuro.shade(0.3), width: 1)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Dosimetría Penal Venezolana | Conforme al Código Penal y Leyes Especiales',
                    style: pw.TextStyle(fontSize: 7, color: grisOscuro.shade(0.6)),
                  ),
                  pw.Text(
                    'Pág. ${context.pageNumber}/${context.pagesCount}',
                    style: pw.TextStyle(fontSize: 7, color: grisOscuro.shade(0.6)),
                  ),
                ],
              ),
            );
          },
        ),
      );

      debugPrint('✅ Informe Técnico generado exitosamente');
      return await pdf.save();
    } on Exception catch (e, stack) {
      debugPrint('❌ Error generando Informe Técnico: $e');
      debugPrint('Stack: $stack');
      return null;
    }
  }

  static Future<Uint8List?> _generarPDFBytes(
    String contenidoReporte, {
    String expediente = 'S/N',
    String acusado = 'No especificado',
  }) async {
    return generarInformeTecnicoPDF(
      contenidoReporte: contenidoReporte,
      expediente: expediente,
      acusado: acusado,
    );
  }

  // 🛠️ FUNCIÓN PRINCIPAL PARA GUARDAR PDF
  static Future<File?> guardarPDF(
    String contenidoReporte,
    String nombreArchivo, {
    String expediente = 'S/N',
    String acusado = 'No especificado',
  }) async {
    try {
      debugPrint('💾 Iniciando guardado de PDF...');
      
      // Generar bytes del PDF
      final bytes = await _generarPDFBytes(
        contenidoReporte,
        expediente: expediente,
        acusado: acusado,
      );
      if (bytes == null) {
        debugPrint('❌ No se pudieron generar los bytes del PDF');
        return null;
      }

      // Determinar directorio según plataforma
      Directory directorio;
      String rutaCompleta;

      if (!kIsWeb && Platform.isAndroid) {
        try {
          directorio = Directory('/storage/emulated/0/Download/Dosimetria');
          if (!await directorio.exists()) {
            await directorio.create(recursive: true);
          }
          rutaCompleta = '${directorio.path}/$nombreArchivo.pdf';
        } catch (e) {
          directorio = await getApplicationDocumentsDirectory();
          final dosimetriaDir = Directory('${directorio.path}/Dosimetria');
          if (!await dosimetriaDir.exists()) {
            await dosimetriaDir.create(recursive: true);
          }
          rutaCompleta = '${dosimetriaDir.path}/$nombreArchivo.pdf';
        }
      } else {
        directorio = await getApplicationDocumentsDirectory();
        final dosimetriaDir = Directory('${directorio.path}/Dosimetria');
        if (!await dosimetriaDir.exists()) {
          await dosimetriaDir.create(recursive: true);
        }
        rutaCompleta = '${dosimetriaDir.path}/$nombreArchivo.pdf';
      }

      // Guardar archivo
      final file = File(rutaCompleta);
      await file.writeAsBytes(bytes);
      debugPrint('✅ PDF guardado exitosamente en: ${file.path}');
      return file;
    } on Exception catch (e, stack) {
      debugPrint('❌ Error guardando PDF: $e');
      debugPrint('Stack: $stack');
      return null;
    }
  }

  // Alias para compatibilidad
  static Future<File?> generarPDF(
    String contenidoReporte,
    String nombreArchivo, {
    String expediente = 'S/N',
    String acusado = 'No especificado',
  }) async {
    return guardarPDF(
      contenidoReporte,
      nombreArchivo,
      expediente: expediente,
      acusado: acusado,
    );
  }

  /// Genera un documento legal en formato PDF con formato profesional
  static Future<File> generarDocumentoLegal({
    required String titulo,
    required String contenido,
    required String tipo,
    String? caso,
    String? tribunal,
    String? expediente,
  }) async {
    try {
      debugPrint('📄 Generando documento legal: $titulo');
      final pdf = pw.Document();

      // Parsear el contenido línea por línea
      final lines = contenido.split('\n');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.legal,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            final List<pw.Widget> widgets = [];

            // ========== ENCABEZADO CON LOGO ==========
            widgets.add(
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Logo del mazo dorado (izquierda)
                  _buildLogoMazo(size: 50),
                  
                  // Información del caso (derecha)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (expediente != null && expediente.isNotEmpty)
                        pw.Text(
                          'Expediente: $expediente',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: grisOscuro,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      if (caso != null && caso.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Caso: $caso',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: grisOscuro,
                          ),
                        ),
                      ],
                      if (tribunal != null && tribunal.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Tribunal: $tribunal',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: grisOscuro,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
            
            widgets.add(pw.SizedBox(height: 25));
            
            // ========== TÍTULO PRINCIPAL ==========
            widgets.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 14),
                child: pw.Text(
                  titulo.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: azulMarino,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            );
            
            widgets.add(
              pw.Container(
                height: 2,
                color: dorado,
              ),
            );
            
            widgets.add(pw.SizedBox(height: 20));

            // ========== PROCESAR CONTENIDO CON FORMATO ==========
            int i = 0;
            while (i < lines.length) {
              final line = lines[i];
              
              // Saltar líneas vacías
              if (line.trim().isEmpty) {
                widgets.add(pw.SizedBox(height: 6));
                i++;
                continue;
              }
              
              // TÍTULOS EN MAYÚSCULAS (considerados como títulos de sección)
              if (line.trim() == line.trim().toUpperCase() && 
                  line.trim().length > 5 && 
                  !line.contains('**') &&
                  line.trim().split(' ').length <= 10) {
                widgets.add(pw.SizedBox(height: 15));
                widgets.add(
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: pw.BoxDecoration(
                      color: grisMuyClaro,
                      border: pw.Border(
                        left: pw.BorderSide(color: dorado, width: 4),
                      ),
                    ),
                    child: pw.Text(
                      line.trim(),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: azulMarino,
                      ),
                    ),
                  ),
                );
                widgets.add(pw.SizedBox(height: 10));
                i++;
                continue;
              }
              
              // LISTAS CON VIÑETAS (•, -, *)
              if (line.trim().startsWith('•') || 
                  line.trim().startsWith('- ') || 
                  line.trim().startsWith('* ')) {
                final texto = line.trim().replaceFirst(RegExp(r'^[•\-\*]\s*'), '');
                widgets.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 20, bottom: 5),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 5,
                          height: 5,
                          margin: const pw.EdgeInsets.only(top: 6, right: 10),
                          decoration: const pw.BoxDecoration(
                            color: dorado,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.Expanded(
                          child: _procesarTextoConFormato(texto),
                        ),
                      ],
                    ),
                  ),
                );
                i++;
                continue;
              }
              
              // LISTAS NUMERADAS (1., 2., etc.)
              final numeroMatch = RegExp(r'^\d+\.\s+').firstMatch(line.trim());
              if (numeroMatch != null) {
                final numero = numeroMatch.group(0)!;
                final texto = line.trim().substring(numero.length);
                widgets.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 20, bottom: 5),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 25,
                          child: pw.Text(
                            numero,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: dorado,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          child: _procesarTextoConFormato(texto),
                        ),
                      ],
                    ),
                  ),
                );
                i++;
                continue;
              }
              
              // SEPARADORES (---, ___)
              if (line.trim() == '---' || line.trim().startsWith('───') || line.trim() == '___') {
                widgets.add(pw.SizedBox(height: 10));
                widgets.add(
                  pw.Container(
                    height: 1,
                    color: grisOscuro.shade(0.3),
                  ),
                );
                widgets.add(pw.SizedBox(height: 10));
                i++;
                continue;
              }
              
              // TEXTO NORMAL CON FORMATO (negritas, subrayados)
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: _procesarTextoConFormato(line),
                ),
              );
              
              i++;
            }

            // ========== PIE DE PÁGINA LEGAL ==========
            widgets.add(pw.SizedBox(height: 30));
            widgets.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: grisOscuro.shade(0.4), width: 1),
                  color: grisMuyClaro,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DOCUMENTO GENERADO',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: azulMarino,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Este documento ha sido generado mediante el Asistente Legal de Penalex VE. La información contenida tiene carácter informativo y debe ser revisada por un profesional del derecho.',
                      style: pw.TextStyle(
                        fontSize: 7,
                        color: grisOscuro,
                        lineSpacing: 1.3,
                      ),
                      textAlign: pw.TextAlign.justify,
                    ),
                  ],
                ),
              ),
            );

            return widgets;
          },
          footer: (pw.Context context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(top: 15),
              padding: const pw.EdgeInsets.only(top: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: grisOscuro.shade(0.3), width: 1),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      _buildLogoMazo(size: 12),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        'Penalex VE | Asistente Legal',
                        style: pw.TextStyle(
                          fontSize: 7,
                          color: grisOscuro.shade(0.6),
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Página ${context.pageNumber} de ${context.pagesCount}',
                    style: pw.TextStyle(
                      fontSize: 7,
                      color: grisOscuro.shade(0.6),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Guardar archivo
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${tipo}_$timestamp.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(await pdf.save());
      debugPrint('✅ Documento legal generado: ${file.path}');
      return file;
    } on Exception catch (e, stack) {
      debugPrint('❌ Error generando documento legal: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  /// Procesa texto con formato markdown (negritas, subrayados)
  static pw.Widget _procesarTextoConFormato(String texto) {
    final List<pw.InlineSpan> spans = [];
    
    // Regex para detectar **negrita**, __subrayado__, o texto normal
    final regex = RegExp(r'\*\*(.+?)\*\*|__(.+?)__|([^*_]+)');
    final matches = regex.allMatches(texto);
    
    for (final match in matches) {
      if (match.group(1) != null) {
        // Negrita
        spans.add(
          pw.TextSpan(
            text: match.group(1)!,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: negro,
            ),
          ),
        );
      } else if (match.group(2) != null) {
        // Subrayado
        spans.add(
          pw.TextSpan(
            text: match.group(2)!,
            style: pw.TextStyle(
              decoration: pw.TextDecoration.underline,
              fontSize: 10,
              color: negro,
            ),
          ),
        );
      } else if (match.group(3) != null) {
        // Texto normal
        spans.add(
          pw.TextSpan(
            text: match.group(3)!,
            style: pw.TextStyle(
              fontSize: 10,
              color: negro,
            ),
          ),
        );
      }
    }
    
    return pw.RichText(
      text: pw.TextSpan(children: spans),
      textAlign: pw.TextAlign.justify,
    );
  }

  static Future<void> compartirPDF(File archivo) async {
    try {
      final xFile = XFile(archivo.path);
      await Share.shareXFiles(
        [xFile],
        text: 'Reporte de Dosimetría Penal Venezolana',
        subject: 'Informe Dosimetría',
      );
    } on Exception catch (e, stack) {
      debugPrint('❌ Error compartiendo PDF: $e');
      debugPrint('Stack: $stack');
    }
  }

  static Future<void> abrirPDF(File archivo) async {
    try {
      final result = await OpenFile.open(archivo.path);
      
      if (result.type != ResultType.done) {
        debugPrint('⚠️ No se pudo abrir el PDF: ${result.message}');
      }
    } on Exception catch (e, stack) {
      debugPrint('❌ Error abriendo PDF: $e');
      debugPrint('Stack: $stack');
    }
  }
}

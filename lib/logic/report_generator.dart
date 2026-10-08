import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/delito.dart';
import '../utils/pena_utils.dart';
import 'dosimetria_engine.dart';

class ComputoData {
  ComputoData({
    required this.fechaDetencion,
    required this.tiempoDetenidoTexto,
    required this.tiempoRestanteTexto,
    required this.fechaCumplimiento,
    this.fechaCondena,
  });

  final DateTime fechaDetencion;
  final String tiempoDetenidoTexto;
  final String tiempoRestanteTexto;
  final DateTime fechaCumplimiento;
  final DateTime? fechaCondena;
}

class ReportGenerator {
  // Paleta Institucional
  static final PdfColor navyBlue = PdfColor.fromHex('#0F172A');
  static final PdfColor goldAccent = PdfColor.fromHex('#C5A059');
  static final PdfColor lightGray = PdfColor.fromHex('#F2F2F2');
  static final PdfColor footerGray = PdfColor.fromHex('#F9F9F9');

  static String _fraccionTexto(double valor) {
    const double epsilon = 0.001;
    if ((valor - 1 / 6).abs() < epsilon) return '1/6';
    if ((valor - 1 / 4).abs() < epsilon) return '1/4';
    if ((valor - 1 / 3).abs() < epsilon) return '1/3';
    if ((valor - 0.5).abs() < epsilon) return '1/2';
    if ((valor - 2 / 3).abs() < epsilon) return '2/3';
    if ((valor - 0.75).abs() < epsilon) return '3/4';
    return valor.toStringAsFixed(2);
  }

  static String _formatearFecha(DateTime fecha) {
    final String dia = fecha.day.toString().padLeft(2, '0');
    final String mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  /// Cargar logo desde assets
  static Future<pw.MemoryImage?> _cargarLogo() async {
    try {
      final imageBytes = await rootBundle.load('assets/images/logo.png');
      final imageData = imageBytes.buffer.asUint8List();
      return pw.MemoryImage(imageData);
    } catch (e) {
      // Si falla, retornar null y usar el logo dibujado como fallback
      return null;
    }
  }

  /// Logo de mazo - Dibujado con formas básicas para garantizar renderizado
  static pw.Widget _buildLogoGavel({double size = 50}) {
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        color: navyBlue,
        shape: pw.BoxShape.circle,
      ),
      child: pw.Center(
        child: pw.Container(
          width: size * 0.55,
          height: size * 0.55,
          child: pw.Stack(
            children: [
              // Mango del mazo (horizontal)
              pw.Positioned(
                left: size * 0.05,
                top: size * 0.24,
                child: pw.Container(
                  width: size * 0.35,
                  height: size * 0.08,
                  decoration: pw.BoxDecoration(
                    color: goldAccent,
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                ),
              ),
              // Cabeza del mazo (cuadrado)
              pw.Positioned(
                right: size * 0.05,
                top: size * 0.15,
                child: pw.Container(
                  width: size * 0.18,
                  height: size * 0.25,
                  decoration: pw.BoxDecoration(
                    color: goldAccent,
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<pw.Document> generarReportePDF({
    required List<Delito> delitos,
    required TipoConcurso concurso,
    required bool admisionHechos,
    required double fraccionAdmision,
    ComputoData? computo,
    String expediente = 'S/N',
    String acusado = 'No especificado',
    String articuloConcurso = '', // Artículo aplicado desde ConcursoPage
  }) async {
    final pdf = pw.Document();
    final DateTime fecha = DateTime.now();

    // Cargar logo
    final logo = await _cargarLogo();

    // Usar el MISMO motor de dosimetría que la pantalla: el cálculo del PDF
    // siempre coincide con el de la app y trae los pasos para el desglose.
    final ResultadoConcurso resConcurso =
        DosimetriaEngine.calcularConcursoDetallado(
      delitos: delitos,
      concurso: concurso,
      admisionHechos: admisionHechos,
      fraccionAdmision: fraccionAdmision,
    );
    final double penaConcurso = resConcurso.total;

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          // HEADER
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Logo + Nombre
              pw.Row(
                children: [
                  // Usar logo real si está disponible, sino usar el dibujado
                  logo != null
                      ? pw.Container(
                          width: 50,
                          height: 50,
                          decoration: pw.BoxDecoration(
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          child: pw.Image(logo, fit: pw.BoxFit.contain),
                        )
                      : _buildLogoGavel(size: 50),
                  pw.SizedBox(width: 12),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PENALEX VE',
                        style: pw.TextStyle(
                          color: navyBlue,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 2.5,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Container(
                        width: 140,
                        height: 2,
                        color: goldAccent,
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'DOSIMETRÍA PENAL',
                        style: pw.TextStyle(
                          color: goldAccent,
                          fontSize: 8,
                          letterSpacing: 3,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('N° Expediente: $expediente',
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Fecha: ${fecha.day}/${fecha.month}/${fecha.year}',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Acusado: $acusado',
                      style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ],
          ),
          pw.Divider(color: navyBlue, thickness: 2),
          pw.SizedBox(height: 10),

          // TÍTULO
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: goldAccent, width: 2),
                bottom: pw.BorderSide(color: goldAccent, width: 2),
              ),
            ),
            child: pw.Center(
              child: pw.Text(
                'INFORME TÉCNICO DE DOSIMETRÍA JURÍDICA',
                style: pw.TextStyle(
                    color: navyBlue,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.5),
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          // 1. DELITOS PROCESADOS
          pw.Text('1. DELITOS PROCESADOS',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: navyBlue,
                  fontSize: 12)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerDecoration: pw.BoxDecoration(color: navyBlue),
            headerStyle: pw.TextStyle(
                color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            headers: ['#', 'Delito', 'Pena mín', 'Pena máx', 'Término medio'],
            data: delitos.asMap().entries.map((entry) {
              final i = entry.key + 1;
              final d = entry.value;
              return [
                i.toString(),
                d.nombre.isEmpty ? 'SIN ESPECIFICAR' : d.nombre,
                PenaUtils.formatPena(d.penaMin),
                PenaUtils.formatPena(d.penaMax),
                PenaUtils.formatPena(d.terminoMedio),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),

          // 2. DESGLOSE INDIVIDUAL
          pw.Text('2. DESGLOSE INDIVIDUAL DE LA PENA',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: navyBlue,
                  fontSize: 12)),
          pw.SizedBox(height: 10),

          // Desglose por cada delito
          ...delitos.asMap().entries.map((entry) {
            final i = entry.key + 1;
            final d = entry.value;
            final penaInd = d.calcularPenaIndividualizada();

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                    '$i. ${d.nombre.isEmpty ? "SIN ESPECIFICAR" : d.nombre.toUpperCase()}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Text(
                    'Marco penal: ${PenaUtils.formatPena(d.penaMin)} - ${PenaUtils.formatPena(d.penaMax)}',
                    style: const pw.TextStyle(fontSize: 9)),
                pw.Text(
                    'Término medio (Art. 37 CP): ${PenaUtils.formatPena(d.terminoMedio)}',
                    style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 5),

                // Modificadores
                pw.Text('Modificadores aplicados:',
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold)),

                // Grado de ejecución
                if (d.gradoEjecucion != GradoEjecucion.consumado)
                  pw.Text(
                      '- Grado de ejecución: ${d.gradoEjecucion == GradoEjecucion.frustrado ? "Frustrado (Art. 80 CP) - 1/3" : "Tentativa (Art. 82 CP) - ${_fraccionTexto(d.fraccionEjecucion)}"}',
                      style: const pw.TextStyle(fontSize: 8)),

                // Participación
                if (d.participacionEspecifica == 'Cómplice No Necesario')
                  pw.Text(
                      '- Participación: Cómplice no necesario (Art. 84 CP) - 1/2',
                      style: const pw.TextStyle(fontSize: 8)),

                // Delito continuado
                if (d.delitoContinuado)
                  pw.Text(
                      '- Delito continuado (Art. 99 CP): +${_fraccionTexto(d.fraccionContinuidad)}',
                      style: const pw.TextStyle(fontSize: 8)),

                // Ajustes adicionales (leyes especiales, pueden superar los límites)
                ...d.ajustesAdicionales.map((AjusteAdicional a) => pw.Text(
                    '- Ajuste adicional (ley especial): ${a.esAgravante ? "Agravante" : "Atenuante"}${a.nombre.isEmpty ? "" : " (${a.nombre})"}: ${_fraccionTexto(a.fraccion)}',
                    style: const pw.TextStyle(fontSize: 8))),

                // Modificador manual (formato AA/MM/DD)
                if (d.modificadorManual != 0)
                  pw.Text(
                      '- ${d.modificadorManual > 0 ? "Agravante (Art. 77 CP)" : "Atenuante (Art. 74 CP)"}: ${d.modificadorManual > 0 ? "+" : ""}${DosimetriaEngine.formatYMD(d.modificadorManual.abs())}',
                      style: const pw.TextStyle(fontSize: 8)),

                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      vertical: 8, horizontal: 12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border.all(color: goldAccent, width: 1.5),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('PENA INDIVIDUALIZADA:',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                              color: navyBlue)),
                      pw.Text(PenaUtils.formatPena(penaInd),
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                              color: goldAccent)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 15),
              ],
            );
          }),

          // 3. CONCURSO DE DELITOS
          pw.Text('3. CONCURSO DE DELITOS',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: navyBlue,
                  fontSize: 12)),
          pw.SizedBox(height: 10),

          // Tipo de concurso aplicado (Art. 86/87/88/98 CP o delito único)
          pw.Text('Tipo de concurso aplicado: ${resConcurso.articuloAplicado}',
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: navyBlue)),
          pw.SizedBox(height: 6),

          // Cálculo paso a paso del motor (idéntico al de la pantalla)
          pw.Text('Cálculo aplicado:',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 3),
          ...resConcurso.pasos.map((String paso) =>
              pw.Text('- $paso', style: const pw.TextStyle(fontSize: 8))),
          pw.SizedBox(height: 15),

          // 4. ADMISIÓN DE HECHOS
          if (admisionHechos) ...[
            pw.Text('4. ADMISIÓN DE HECHOS (Art. 375 COPP)',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: navyBlue,
                    fontSize: 12)),
            pw.SizedBox(height: 10),
            pw.Text('Rebaja aplicada: ${_fraccionTexto(fraccionAdmision)}',
                style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 15),
          ],

          // 5. PENA DEFINITIVA
          pw.Text('${admisionHechos ? "5" : "4"}. PENA DEFINITIVA A IMPONER',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: navyBlue,
                  fontSize: 12)),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: navyBlue,
              border: pw.Border.all(color: goldAccent, width: 3),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'PENA IMPUESTA',
                  style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: goldAccent,
                      letterSpacing: 2),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  PenaUtils.formatPena(penaConcurso),
                  style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      letterSpacing: 1),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // 6. CÓMPUTO (si existe)
          if (computo != null) ...[
            pw.Text('${admisionHechos ? "6" : "5"}. CÓMPUTO DE PENA',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: navyBlue,
                    fontSize: 12)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: navyBlue),
              children: [
                pw.TableRow(children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Fecha de detención',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(_formatearFecha(computo.fechaDetencion),
                          style: const pw.TextStyle(fontSize: 9))),
                ]),
                if (computo.fechaCondena != null)
                  pw.TableRow(children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Fecha de condena',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(_formatearFecha(computo.fechaCondena!),
                            style: const pw.TextStyle(fontSize: 9))),
                  ]),
                pw.TableRow(children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Tiempo detenido',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(computo.tiempoDetenidoTexto,
                          style: const pw.TextStyle(fontSize: 9))),
                ]),
                pw.TableRow(children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Tiempo restante',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(computo.tiempoRestanteTexto,
                          style: const pw.TextStyle(fontSize: 9))),
                ]),
                pw.TableRow(children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Fecha de cumplimiento estimada',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(_formatearFecha(computo.fechaCumplimiento),
                          style: const pw.TextStyle(fontSize: 9))),
                ]),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // DISCLAIMER
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: lightGray,
              border: pw.Border.all(color: navyBlue, width: 1.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('AVISO LEGAL',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: navyBlue,
                        fontSize: 10)),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Este informe es una herramienta de asistencia técnica generada automáticamente. '
                  'El resultado aquí expresado constituye una estimación basada en los parámetros introducidos '
                  'y no sustituye el criterio jurídico, la interpretación de la norma ni la valoración del juez de la causa. '
                  'La individualización judicial de la pena debe ser expresa, motivada y matemáticamente verificable (Véase sentencia N° 268, de fecha 28-05-2025, Sala de Casación Penal del TSJ). '
                  'El uso de esta herramienta es responsabilidad exclusiva del profesional del derecho.',
                  style: pw.TextStyle(fontSize: 8, color: navyBlue),
                  textAlign: pw.TextAlign.justify,
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text('Penalex VE - Dosimetría Penal Venezolana',
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: navyBlue)),
                ),
                pw.Center(
                  child: pw.Text('Conforme al Código Penal y Leyes Especiales',
                      style: pw.TextStyle(fontSize: 8, color: navyBlue)),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf;
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/sentencia_model.dart';
import 'jurisprudencia_service.dart';

/// Convierte la copia HTML alojada en R2 (copia fiel del TSJ) en un PDF
/// perfectamente estructurado:
///
/// * Párrafos continuos y justificados (sin los saltos de línea del TXT).
/// * Encabezado centrado del tribunal (Sala, fecha y era) como en el original.
/// * Ficha técnica con los datos de la sentencia (Nº, ponente, delito...).
/// * Respeto de la alineación (centrada, derecha, justificada) y de las
///   sangrías del documento original.
/// * Numeración de páginas.
///
/// Sólo se usa el HTML de R2; el TXT queda reservado al RAG (IA).
class SentenciaPdfService {
  // ────────────────────────────────────────────────────────────────
  // API pública
  // ────────────────────────────────────────────────────────────────

  /// Genera el PDF y devuelve la ruta del archivo (o `null` si falla).
  /// En Web no hay `dart:io`, así que devuelve `null` (la UI abre el HTML).
  static Future<String?> exportarSentenciaAPdf(SentenciaModel sentencia) async {
    if (kIsWeb) return null;

    final urlHtml = sentencia.urlHTML.trim();
    if (urlHtml.isEmpty || urlHtml == 'null') return null;

    try {
      final html = await _descargarHTML(urlHtml);
      if (html == null || html.trim().isEmpty) {
        debugPrint('❌ El HTML de R2 está vacío o no se pudo descargar');
        return null;
      }

      final bloques = _parsearHTML(html);
      if (bloques.isEmpty) {
        debugPrint('❌ No se pudo extraer contenido del HTML');
        return null;
      }

      // ⚖️ Criterios jurisprudenciales de la sentencia (oficiales + IA)
      List<Map<String, dynamic>> criterios = const [];
      try {
        criterios = await JurisprudenciaService()
            .doctrinasDeSentencia(sentencia.id);
      } catch (e) {
        debugPrint('⚠️ No se pudieron cargar criterios para el PDF: $e');
      }

      final pdf = pw.Document();
      pdf.addPage(_construirPaginas(
        sentencia,
        bloques,
        criterios: criterios,
      ));

      final dir = await getApplicationDocumentsDirectory();
      final ruta = path.join(dir.path, _nombreArchivo(sentencia));
      await File(ruta).writeAsBytes(await pdf.save());

      debugPrint('✅ PDF de sentencia generado: $ruta');
      return ruta;
    } catch (e) {
      debugPrint('❌ Error generando PDF de sentencia: $e');
      return null;
    }
  }

  /// Genera el PDF y lo abre con el visor del sistema.
  static Future<bool> exportarYAbrir(SentenciaModel sentencia) async {
    final ruta = await exportarSentenciaAPdf(sentencia);
    if (ruta == null) return false;
    try {
      final resultado = await OpenFile.open(ruta);
      debugPrint('📱 Abriendo PDF: ${resultado.message}');
      return resultado.type == ResultType.done;
    } catch (e) {
      debugPrint('❌ Error abriendo PDF: $e');
      return false;
    }
  }

  /// Genera el PDF y abre la hoja de compartir del sistema.
  static Future<bool> exportarYCompartir(SentenciaModel sentencia) async {
    final ruta = await exportarSentenciaAPdf(sentencia);
    if (ruta == null) return false;
    try {
      await Share.shareFiles(
        [ruta],
        subject: 'Sentencia Nº ${sentencia.numeroSentencia}',
        text: '⚖️ Sentencia Nº ${sentencia.numeroSentencia} (${sentencia.sala})',
      );
      debugPrint('📤 PDF de sentencia compartido');
      return true;
    } catch (e) {
      debugPrint('❌ Error compartiendo PDF: $e');
      return false;
    }
  }

  // ────────────────────────────────────────────────────────────────
  // Descarga del HTML (R2)
  // ────────────────────────────────────────────────────────────────

  static Future<String?> _descargarHTML(String url) async {
    try {
      final resp = await http
          .get(
            Uri.parse(url),
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            },
          )
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) return resp.body;
      debugPrint('❌ HTML no disponible: HTTP ${resp.statusCode}');
    } catch (e) {
      debugPrint('❌ Error descargando HTML: $e');
    }
    return null;
  }

  // ────────────────────────────────────────────────────────────────
  // Parseo del HTML del TSJ a bloques estructurados
  // ────────────────────────────────────────────────────────────────

  static final RegExp _selectorBloque = RegExp(
    r'^(p|div|h[1-6]|li|td|th|blockquote|pre|center|table)$',
    caseSensitive: false,
  );

  static List<_Bloque> _parsearHTML(String html) {
    final doc = parser.parse(html);
    final body = doc.body;
    if (body == null) return [];

    final elementos = body.querySelectorAll(
      'p, div, h1, h2, h3, h4, h5, h6, li, td, th, blockquote, pre, center',
    );

    final bloques = <_Bloque>[];
    for (final el in elementos) {
      final nombre = el.localName ?? '';
      // Saltar nodos de Word/VML: o:p, v:shape, w:*, etc.
      if (nombre.contains(':')) continue;
      // Si contiene otros bloques anidados, sus descendientes ya lo cubren.
      final tieneBloquesAnidados = el.nodes.any((n) =>
          n is dom.Element &&
          n.localName != null &&
          _selectorBloque.hasMatch(n.localName!));
      if (tieneBloquesAnidados) continue;

      final segmentos = _extraerSegmentos(el);
      final texto = segmentos.map((s) => s.texto).join().trim();
      if (texto.isEmpty) continue;

      bloques.add(_Bloque(
        segmentos,
        alineacion: _alineacionDe(el),
        margenIzquierdo: _margenIzquierdoDe(el),
        esTitulo: _esTitulo(el),
        mayusculas: _aplicaMayusculas(el),
      ));
    }
    return bloques;
  }

  /// Extrae el texto enriquecido de un nodo respetando `<b>`/`<i>` y
  /// descartando imágenes, `o:p`, VML y comentarios condicionales de Word.
  static List<_Segmento> _extraerSegmentos(
    dom.Node nodo, {
    bool bold = false,
    bool italic = false,
  }) {
    final resultado = <_Segmento>[];
    if (nodo is dom.Text) {
      // Normalizar espacios: elimina los saltos de línea del HTML y los
      // &nbsp; de Word (mso-spacerun) para obtener párrafos continuos.
      final t = nodo.text
          .replaceAll('\u00a0', ' ')
          .replaceAll(RegExp(r'\s+'), ' ');
      if (t.trim().isNotEmpty) {
        resultado.add(_Segmento(t, bold: bold, italic: italic));
      }
    } else if (nodo is dom.Element) {
      final tag = (nodo.localName ?? '').toLowerCase();
      if (tag.contains(':')) return resultado; // o:p, v:shape, w:*...
      if (tag == 'img' || tag == 'script' || tag == 'style') return resultado;
      final esBold = bold || tag == 'b' || tag == 'strong';
      final esItalic = italic || tag == 'i' || tag == 'em';
      for (final hijo in nodo.nodes) {
        resultado.addAll(_extraerSegmentos(hijo, bold: esBold, italic: esItalic));
      }
    }
    return resultado;
  }

  static String _alineacionDe(dom.Element el) {
    // p.MsoTitle (título de sentencia del TSJ) lleva text-align:center en
    // su hoja de estilos; package:html no la evalúa, así que la aplicamos.
    final clase = el.attributes['class'] ?? '';
    if (clase.toLowerCase().contains('msotitle')) return 'center';

    final attr = el.attributes['align'];
    if (attr != null) {
      final a = attr.toLowerCase();
      if (const {'left', 'center', 'right', 'justify'}.contains(a)) return a;
    }
    final style = el.attributes['style'] ?? '';
    final m = RegExp(
      r'text-align\s*:\s*(left|center|right|justify)',
      caseSensitive: false,
    ).firstMatch(style);
    if (m != null) return m.group(1)!.toLowerCase();
    return 'left';
  }

  /// `true` si el elemento (o algún descendiente) aplica
  /// `text-transform:uppercase`, como en los títulos generados por Word.
  static bool _aplicaMayusculas(dom.Element el) {
    if ((el.attributes['style'] ?? '')
        .toLowerCase()
        .contains('text-transform:uppercase')) {
      return true;
    }
    return el.querySelectorAll('*').any((n) => (n.attributes['style'] ?? '')
        .toLowerCase()
        .contains('text-transform:uppercase'));
  }

  /// Indica si el elemento es un título de documento del TSJ: encabezados
  /// `<h1>`/`<h2>` (a menudo con `text-transform:uppercase`) o la clase
  /// `MsoTitle` de Word.
  static bool _esTitulo(dom.Element el) {
    final tag = (el.localName ?? '').toLowerCase();
    if (tag == 'h1' || tag == 'h2') return true;
    final clase = (el.attributes['class'] ?? '').toLowerCase();
    return clase.contains('msotitle');
  }

  static double _margenIzquierdoDe(dom.Element el) {
    final style = el.attributes['style'] ?? '';
    final m = RegExp(
      r'margin-left\s*:\s*([\d.]+)\s*(pt|px|cm|mm|in)',
      caseSensitive: false,
    ).firstMatch(style);
    if (m != null) {
      final valor = double.tryParse(m.group(1)!) ?? 0;
      final unidad = m.group(2)!;
      return switch (unidad) {
        'cm' => valor * 28.35,
        'mm' => valor * 2.835,
        'in' => valor * 72,
        _ => valor, // pt o px ≈ 1 pt
      };
    }
    return 0;
  }

  // ────────────────────────────────────────────────────────────────
  // Construcción del PDF
  // ────────────────────────────────────────────────────────────────

  static pw.MultiPage _construirPaginas(
    SentenciaModel sentencia,
    List<_Bloque> bloques, {
    List<Map<String, dynamic>> criterios = const [],
  }) {
    final veces = pw.Font.times();
    final vecesBold = pw.Font.timesBold();
    final vecesItalic = pw.Font.timesItalic();

    // Encabezado del documento: los bloques cortos del inicio que actúan
    // como cabecera (Sala en MsoTitle, línea de ponente, fecha y era) se
    // renderizan como tal, como en el original del TSJ.
    var corte = 0;
    while (corte < bloques.length &&
        corte < 6 &&
        _esBloqueDeCabecera(bloques[corte])) {
      corte++;
    }
    final encabezado = bloques.sublist(0, corte);
    final cuerpo = bloques.sublist(corte);

    final filasFicha = _filasFicha(sentencia, encabezado);

    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 40),
      footer: (context) => _pieDePagina(context, veces),
      build: (context) => [
        // ── Cabecera del tribunal ────────────────────────────────
        for (var i = 0; i < encabezado.length; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.RichText(
              text: pw.TextSpan(
                style: pw.TextStyle(
                  font: i == 0
                      ? vecesBold
                      : _esLineaDePonente(encabezado[i])
                          ? vecesBold
                          : veces,
                  fontSize: i == 0 ? 14 : 11.5,
                  letterSpacing: i == 0 ? 1.2 : 0.4,
                  color: PdfColors.black,
                ),
                children: [
                  for (final s in encabezado[i].segmentos)
                    pw.TextSpan(
                      text: encabezado[i].mayusculas
                          ? s.texto.toUpperCase()
                          : s.texto,
                    ),
                ],
              ),
              textAlign: _alineacionPdf(encabezado[i].alineacion),
              overflow: pw.TextOverflow.span,
            ),
          ),

        // ── Ficha técnica (sólo si hay datos útiles) ─────────────
        if (filasFicha.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          _fichaTecnica(filasFicha, veces, vecesBold),
          pw.SizedBox(height: 16),
        ],

        // ── Criterios jurisprudenciales (si la sentencia los tiene) ──
        if (criterios.isNotEmpty) ...[
          _seccionCriteriosPdf(criterios, veces, vecesBold, vecesItalic),
          pw.SizedBox(height: 16),
        ],

        // ── Cuerpo del documento ─────────────────────────────────
        for (final b in cuerpo)
          _widgetBloque(b, veces, vecesBold, vecesItalic),
      ],
    );
  }

  static bool _esLineaDePonente(_Bloque b) => RegExp(
        r'^magistrado[- ]?ponente',
        caseSensitive: false,
      ).hasMatch(b.texto);

  /// `true` si el bloque actúa como cabecera del documento original:
  /// centrado (fecha, era), título (`h1`/`h2`/`MsoTitle`, a menudo en
  /// mayúsculas) o la línea de ponente que encabeza el fallo.
  static bool _esBloqueDeCabecera(_Bloque b) {
    final t = b.texto;
    if (t.length >= 60) return false;
    if (b.alineacion == 'center') return true;
    if (b.esTitulo) return true;
    if (t == t.toUpperCase()) return true;
    return _esLineaDePonente(b);
  }

  /// Fila etiqueta → valor para la ficha técnica. Se omiten la Sala, la
  /// Fecha y el Ponente cuando ya aparecen en la cabecera del documento
  /// original, para no duplicar información.
  static List<(String, String)> _filasFicha(
    SentenciaModel s,
    List<_Bloque> encabezado,
  ) {
    final hayCabecera = encabezado.isNotEmpty;
    final textosCabecera = encabezado.map((b) => b.texto.toLowerCase()).join(' ');
    final cabeceraMuestraPonente =
        hayCabecera && textosCabecera.contains('ponente');

    final filas = <(String, String)>[
      ('Sentencia Nº', s.numeroSentencia),
      if (!hayCabecera) ('Sala', s.sala),
      if (!hayCabecera) ('Fecha', s.fechaSentencia),
      if (!cabeceraMuestraPonente) ('Ponente', s.ponente),
      ('Tipo', s.tipoSentencia),
      ('Materia', s.materia),
      ('Delito', s.delito),
      ('Decisión', s.decision),
      ('Partes', s.partes),
    ];
    return filas
        .where((f) => f.$2.isNotEmpty && f.$2 != 'null')
        .toList();
  }

  static pw.Widget _fichaTecnica(
    List<(String, String)> filas,
    pw.Font veces,
    pw.Font vecesBold,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500, width: 0.7),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final f in filas)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 105,
                    child: pw.Text(
                      f.$1.toUpperCase(),
                      style: pw.TextStyle(
                        font: vecesBold,
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      f.$2,
                      style: pw.TextStyle(
                        font: veces,
                        fontSize: 9.5,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Sección "CRITERIOS JURISPRUDENCIALES" del PDF: los criterios de la Sala
  /// para esta sentencia (extractos OFICIALES de la página de jurisprudencias
  /// del TSJ cuando existen — tipo 'jurisprudencia' —, o los extraídos por IA).
  static pw.Widget _seccionCriteriosPdf(
    List<Map<String, dynamic>> criterios,
    pw.Font veces,
    pw.Font vecesBold,
    pw.Font vecesItalic,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '⚖️ CRITERIOS JURISPRUDENCIALES (${criterios.length})',
          style: pw.TextStyle(
            font: vecesBold,
            fontSize: 11,
            color: PdfColors.grey900,
          ),
        ),
        pw.SizedBox(height: 6),
        for (var i = 0; i < criterios.length; i++) ...[
          _widgetCriterioPdf(i + 1, criterios[i], veces, vecesBold, vecesItalic),
          if (i < criterios.length - 1) pw.SizedBox(height: 8),
        ],
      ],
    );
  }

  static pw.Widget _widgetCriterioPdf(
    int indice,
    Map<String, dynamic> c,
    pw.Font veces,
    pw.Font vecesBold,
    pw.Font vecesItalic,
  ) {
    final texto = (c['texto_ratio'] ?? '').toString().trim();
    final evidencia = (c['parrafo_evidencia'] ?? '').toString().trim();
    final tipo = (c['tipo'] ?? '').toString();
    final esOficial = tipo == 'jurisprudencia';
    final cita =
        (evidencia.isNotEmpty && evidencia != 'null' && evidencia != texto)
            ? evidencia
            : '';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: esOficial ? PdfColors.amber : PdfColors.grey400,
          width: 0.6,
        ),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 16,
                child: pw.Text(
                  '$indice.',
                  style: pw.TextStyle(
                    font: vecesBold,
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  esOficial
                      ? 'Criterio oficial de la Sala'
                      : 'Criterio de la Sala',
                  style: pw.TextStyle(
                    font: vecesBold,
                    fontSize: 8.5,
                    color: esOficial ? PdfColors.amber : PdfColors.grey600,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 16),
            child: pw.Text(
              texto,
              style: pw.TextStyle(
                font: veces,
                fontSize: 9.5,
                color: PdfColors.black,
                lineSpacing: 1.2,
              ),
            ),
          ),
          if (cita.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 16),
              child: pw.Text(
                '«${cita.length > 900 ? '${cita.substring(0, 900)}…' : cita}»',
                style: pw.TextStyle(
                  font: vecesItalic,
                  fontSize: 8.5,
                  color: PdfColors.grey600,
                  lineSpacing: 1.15,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _widgetBloque(
    _Bloque b,
    pw.Font veces,
    pw.Font vecesBold,
    pw.Font vecesItalic,
  ) {
    return pw.Padding(
      // Respetar la sangría izquierda del documento original.
      padding: pw.EdgeInsets.only(
        bottom: 9,
        left: b.margenIzquierdo * 0.6,
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          style: pw.TextStyle(font: veces, fontSize: 11.5, color: PdfColors.black),
          children: [
            for (final s in b.segmentos)
              pw.TextSpan(
                text: s.texto,
                style: pw.TextStyle(
                  font: s.bold
                      ? (s.italic ? pw.Font.timesBoldItalic() : vecesBold)
                      : (s.italic ? vecesItalic : veces),
                ),
              ),
          ],
        ),
        textAlign: _alineacionPdf(b.alineacion),
        overflow: pw.TextOverflow.span,
      ),
    );
  }

  static pw.TextAlign _alineacionPdf(String a) => switch (a) {
        'center' => pw.TextAlign.center,
        'right' => pw.TextAlign.right,
        'justify' => pw.TextAlign.justify,
        _ => pw.TextAlign.left,
      };

  static pw.Widget _pieDePagina(pw.Context context, pw.Font veces) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: pw.TextStyle(
          font: veces,
          fontSize: 9,
          color: PdfColors.grey600,
        ),
      ),
    );
  }

  static String _nombreArchivo(SentenciaModel s) {
    final base = (s.numeroSentencia.trim().isEmpty
            ? s.id
            : s.numeroSentencia)
        .replaceAll(RegExp(r'[^\w\s-]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    return 'sentencia_${base}_${DateTime.now().millisecondsSinceEpoch}.pdf';
  }
}

// ──────────────────────────────────────────────────────────────────
// Modelos internos de parseo
// ──────────────────────────────────────────────────────────────────

class _Segmento {
  final String texto;
  final bool bold;
  final bool italic;

  _Segmento(this.texto, {this.bold = false, this.italic = false});
}

class _Bloque {
  final List<_Segmento> segmentos;
  final String alineacion;
  final double margenIzquierdo;
  final bool esTitulo;
  final bool mayusculas;

  _Bloque(
    this.segmentos, {
    required this.alineacion,
    required this.margenIzquierdo,
    this.esTitulo = false,
    this.mayusculas = false,
  });

  String get texto => segmentos.map((s) => s.texto).join().trim();
}

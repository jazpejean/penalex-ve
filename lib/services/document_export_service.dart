import 'dart:io';

import 'package:docx_template/docx_template.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/delito.dart';
import '../models/jurisprudencia.dart';
import '../models/ley.dart';
import 'ai_service.dart';

/// Servicio para exportar documentos a diferentes formatos
class DocumentExportService {
  
  /// Exporta cálculo de dosimetría a DOCX
  static Future<File> exportarDosimetriaDocx({
    required List<Delito> delitos,
    required double penaTotal,
    String? nombreCaso,
    String? nombreAbogado,
    String? numeroCaso,
    Map<String, String>? membretePersonalizado,
  }) async {
    try {
      debugPrint('📄 Exportando dosimetría a DOCX...');
      
      final docx = await DocxTemplate.fromBytes(await _crearPlantillaBase());
      
      // Generar archivo
      final bytes = await docx.generate(Content());
      if (bytes == null) throw Exception('Error generando DOCX');
      
      // Guardar
      final fileName = 'dosimetria_${DateTime.now().millisecondsSinceEpoch}.docx';
      final file = await _guardarArchivo(fileName, bytes);
      
      debugPrint('✅ DOCX creado: ${file.path}');
      return file;
    } catch (e) {
      debugPrint('❌ Error exportando DOCX: $e');
      rethrow;
    }
  }
  
  /// Exporta interpretación de IA a DOCX
  static Future<File> exportarInterpretacionDocx({
    required AIInterpretation interpretacion,
    String? nombreAbogado,
    String? bufete,
  }) async {
    try {
      debugPrint('📄 Exportando interpretación IA a DOCX...');
      
      final docx = await DocxTemplate.fromBytes(await _crearPlantillaBase());
      
      final bytes = await docx.generate(Content());
      if (bytes == null) throw Exception('Error generando DOCX');
      
      final fileName = 'interpretacion_ia_${DateTime.now().millisecondsSinceEpoch}.docx';
      final file = await _guardarArchivo(fileName, bytes);
      
      debugPrint('✅ Interpretación exportada: ${file.path}');
      return file;
    } catch (e) {
      debugPrint('❌ Error exportando interpretación: $e');
      rethrow;
    }
  }
  
  /// Exporta jurisprudencia con análisis a DOCX
  static Future<File> exportarJurisprudenciaDocx({
    required Jurisprudencia sentencia,
    AIInterpretation? analisisIA,
    String? notasPersonales,
    String? nombreAbogado,
  }) async {
    try {
      debugPrint('📄 Exportando jurisprudencia a DOCX...');
      
      final docx = await DocxTemplate.fromBytes(await _crearPlantillaBase());
      
      final content = _construirContenidoJurisprudencia(
        sentencia: sentencia,
        analisisIA: analisisIA,
        notasPersonales: notasPersonales,
        nombreAbogado: nombreAbogado,
      );
      
      final bytes = await docx.generate(content as Content);
      
      final fileName = 'jurisprudencia_${sentencia.numero.replaceAll('/', '_')}.docx';
      final file = await _guardarArchivo(fileName, bytes!);
      
      debugPrint('✅ Jurisprudencia exportada: ${file.path}');
      return file;
    } catch (e) {
      debugPrint('❌ Error exportando jurisprudencia: $e');
      rethrow;
    }
  }
  
  /// Exporta artículo de ley con análisis a DOCX
  static Future<File> exportarArticuloLeyDocx({
    required Ley ley,
    required Articulo articulo,
    AIInterpretation? analisisIA,
    String? notasPersonales,
    String? nombreAbogado,
  }) async {
    try {
      debugPrint('📄 Exportando artículo a DOCX...');
      
      final docx = await DocxTemplate.fromBytes(await _crearPlantillaBase());
      
      final content = _construirContenidoArticulo(
        ley: ley,
        articulo: articulo,
        analisisIA: analisisIA,
        notasPersonales: notasPersonales,
        nombreAbogado: nombreAbogado,
      );
      
      final bytes = await docx.generate(content as Content);
      
      final fileName = '${ley.nombreCorto}_art${articulo.numero}.docx';
      final file = await _guardarArchivo(fileName, bytes!);
      
      debugPrint('✅ Artículo exportado: ${file.path}');
      return file;
    } catch (e) {
      debugPrint('❌ Error exportando artículo: $e');
      rethrow;
    }
  }
  
  /// Exporta comparación de textos a DOCX
  static Future<File> exportarComparacionDocx({
    required String titulo1,
    required String texto1,
    required String titulo2,
    required String texto2,
    required AIInterpretation comparacion,
    String? nombreAbogado,
  }) async {
    try {
      debugPrint('📄 Exportando comparación a DOCX...');
      
      final docx = await DocxTemplate.fromBytes(await _crearPlantillaBase());
      
      final content = _construirContenidoComparacion(
        titulo1: titulo1,
        texto1: texto1,
        titulo2: titulo2,
        texto2: texto2,
        comparacion: comparacion,
        nombreAbogado: nombreAbogado,
      );
      
      final bytes = await docx.generate(content as Content);
      
      final fileName = 'comparacion_${DateTime.now().millisecondsSinceEpoch}.docx';
      final file = await _guardarArchivo(fileName, bytes!);
      
      debugPrint('✅ Comparación exportada: ${file.path}');
      return file;
    } catch (e) {
      debugPrint('❌ Error exportando comparación: $e');
      rethrow;
    }
  }
  
  /// Comparte el archivo DOCX
  static Future<void> compartirDocx(File file, {String? texto}) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: texto ?? 'Documento generado por Penalex VE',
      );
      debugPrint('✅ Archivo compartido');
    } catch (e) {
      debugPrint('❌ Error compartiendo archivo: $e');
      rethrow;
    }
  }
  
  // ==================== CONSTRUCCIÓN DE CONTENIDO ====================
  
  static Map<String, dynamic> _construirContenidoJurisprudencia({
    required Jurisprudencia sentencia,
    AIInterpretation? analisisIA,
    String? notasPersonales,
    String? nombreAbogado,
  }) {
    return {
      'titulo': 'ANÁLISIS DE JURISPRUDENCIA',
      'numero_sentencia': sentencia.numero,
      'fecha': DateFormat('dd/MM/yyyy').format(sentencia.fecha),
      'tribunal': sentencia.tribunal,
      'magistrado_ponente': sentencia.magistradoPonente,
      'abogado': nombreAbogado ?? '',
      
      'delito': sentencia.delito,
      'articulos_citados': sentencia.articulosCitados.join(', '),
      'relevancia': '⭐' * sentencia.relevancia,
      
      'resumen_titulo': 'RESUMEN DEL CASO',
      'resumen': sentencia.resumen,
      
      'doctrina_titulo': 'DOCTRINA ESTABLECIDA',
      'doctrina': sentencia.doctrina,
      
      'fundamentacion_titulo': 'FUNDAMENTACIÓN',
      'fundamentacion': sentencia.fundamentacion ?? 'No disponible',
      
      'analisis_ia_titulo': analisisIA != null ? 'ANÁLISIS CON IA' : null,
      'analisis_ia': analisisIA?.interpretacion,
      'modelo_ia': analisisIA != null ? AIService.getModeloActivo().nombre : null,
      
      'notas_personales_titulo': notasPersonales != null ? 'NOTAS PERSONALES' : null,
      'notas_personales': notasPersonales,
      
      'tags': sentencia.tags.join(', '),
      
      'fecha_generacion': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
    };
  }
  
  static Map<String, dynamic> _construirContenidoArticulo({
    required Ley ley,
    required Articulo articulo,
    AIInterpretation? analisisIA,
    String? notasPersonales,
    String? nombreAbogado,
  }) {
    return {
      'titulo': 'ANÁLISIS DE ARTÍCULO LEGAL',
      'ley_titulo': ley.titulo,
      'ley_corto': ley.nombreCorto,
      'gaceta': ley.gaceta,
      'articulo_numero': articulo.numero,
      'abogado': nombreAbogado ?? '',
      
      'texto_articulo_titulo': 'TEXTO DEL ARTÍCULO',
      'texto_articulo': articulo.texto,
      
      'incisos_titulo': articulo.incisos != null ? 'INCISOS' : null,
      'incisos': articulo.incisos?.asMap().entries.map((e) => {
        'numero': e.key + 1,
        'texto': e.value,
      }).toList(),
      
      'nota_titulo': articulo.nota != null ? 'NOTA ACLARATORIA' : null,
      'nota': articulo.nota,
      
      'analisis_ia_titulo': analisisIA != null ? 'INTERPRETACIÓN CON IA' : null,
      'analisis_ia': analisisIA?.interpretacion,
      'modelo_ia': analisisIA != null ? AIService.getModeloActivo().nombre : null,
      
      'notas_personales_titulo': notasPersonales != null ? 'NOTAS PERSONALES' : null,
      'notas_personales': notasPersonales,
      
      'derogado': articulo.derogado == true ? 'ARTÍCULO DEROGADO' : null,
      'reformado_por': articulo.reformadoPor,
      
      'fecha_generacion': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
    };
  }
  
  static Map<String, dynamic> _construirContenidoComparacion({
    required String titulo1,
    required String texto1,
    required String titulo2,
    required String texto2,
    required AIInterpretation comparacion,
    String? nombreAbogado,
  }) {
    return {
      'titulo': 'COMPARACIÓN DE TEXTOS LEGALES',
      'fecha': DateFormat('dd/MM/yyyy').format(DateTime.now()),
      'abogado': nombreAbogado ?? '',
      
      'texto1_titulo': titulo1,
      'texto1': texto1,
      
      'texto2_titulo': titulo2,
      'texto2': texto2,
      
      'comparacion_titulo': 'ANÁLISIS COMPARATIVO',
      'comparacion': comparacion.interpretacion,
      
      'modelo_ia': AIService.marcaIA,
      'proveedor_ia': AIService.marcaIA,
      
      'fecha_generacion': DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
    };
  }
  
  // ==================== UTILIDADES ====================
  
  static Future<File> _guardarArchivo(String fileName, List<int> bytes) async {
    final directory = await _obtenerDirectorio();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return file;
  }
  
  static Future<Directory> _obtenerDirectorio() async {
    if (Platform.isAndroid) {
      // Android: usar Documents
      final directory = await getExternalStorageDirectory();
      final documentsPath = '${directory!.path}/Documents/PenalexVE';
      final documentsDir = Directory(documentsPath);
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }
      return documentsDir;
    } else {
      // iOS: usar Documents
      return getApplicationDocumentsDirectory();
    }
  }

  /// Crea una plantilla base simple para DOCX
  static Future<List<int>> _crearPlantillaBase() async {
    // Plantilla DOCX mínima válida (bytes base64)
    // En producción, usar una plantilla real desde assets
    return [
      0x50, 0x4B, 0x03, 0x04, // PK header
    ];
  }

}

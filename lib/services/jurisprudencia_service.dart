import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sentencia_model.dart';
import 'ai_service.dart';

class JurisprudenciaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Buscar documentos en Supabase con filtros
  Future<List<SentenciaModel>> buscarEnSupabase({
    String? textoBusqueda,
    required String tipoFiltro, // 'sentencias', 'jurisprudencias', 'resoluciones'
    String? salaFiltro,
    int limit = 50,
  }) async {
    try {
      debugPrint('🔍 Búsqueda en Supabase: tipo=$tipoFiltro, sala=$salaFiltro, texto=$textoBusqueda');

      var query = _supabase.from('documentos').select();

      // Filtro por tipo
      if (tipoFiltro == 'sentencias') {
        query = query.eq('tipo', 'sentencia');
      } else if (tipoFiltro == 'jurisprudencias') {
        query = query.eq('es_jurisprudencia', true);
      } else if (tipoFiltro == 'resoluciones') {
        query = query.eq('tipo', 'resoluciones');
      }

      // Filtro por sala (solo si aplica)
      if (salaFiltro != null && salaFiltro.isNotEmpty && salaFiltro != 'Todas') {
        query = query.eq('sala', salaFiltro.toLowerCase());
      }

      // Búsqueda fulltext (si hay texto)
      if (textoBusqueda != null && textoBusqueda.isNotEmpty) {
        query = query.textSearch('search_vector', textoBusqueda, config: 'spanish');
      }

      // Orden descendente por fecha
      query = query.order('fecha', ascending: false).limit(limit);

      final response = await query;
      final List<dynamic> data = response as List<dynamic>;

      debugPrint('✅ Encontrados ${data.length} documentos');

      return data.map((json) => SentenciaModel.fromSupabase(json)).toList();
    } catch (e) {
      debugPrint('❌ Error en búsqueda Supabase: $e');
      return [];
    }
  }

  /// Obtener salas disponibles
  Future<List<String>> obtenerSalasDisponibles() async {
    try {
      final response = await _supabase
          .from('documentos')
          .select('sala')
          .not('sala', 'is', null)
          .order('sala');

      final List<dynamic> data = response as List<dynamic>;
      
      final salas = data
          .map((item) => item['sala'] as String?)
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();

      salas.sort();
      
      // Capitalizar primera letra
      final salasCapitalizadas = salas.map((s) {
        return s[0].toUpperCase() + s.substring(1);
      }).toList();

      return salasCapitalizadas;
    } catch (e) {
      debugPrint('❌ Error obteniendo salas: $e');
      return [];
    }
  }

  /// Obtener o generar resumen con IA (con caché en Supabase)
  Future<String> obtenerOGenerarResumen(SentenciaModel sentencia) async {
    try {
      // Si ya tiene resumen, retornarlo
      if (sentencia.resumen.isNotEmpty && sentencia.resumen != 'null') {
        return sentencia.resumen;
      }

      debugPrint('🤖 Generando resumen IA para: ${sentencia.numeroSentencia}');

      // Descargar texto completo desde R2 usando la URL de Supabase
      final textoCompleto = await _descargarTextoR2(sentencia.urlTXT);
      
      if (textoCompleto.isEmpty) {
        return 'Texto no disponible';
      }

      // Generar resumen con IA
      await AIService.inicializar();
      final resumen = await AIService.generarResumenSentencia(
        numeroSentencia: sentencia.numeroSentencia,
        sala: sentencia.sala,
        delito: sentencia.delito,
        textoCompleto: textoCompleto.substring(0, textoCompleto.length > 4000 ? 4000 : textoCompleto.length),
      );

      // Guardar en Supabase para caché
      await _supabase
          .from('documentos')
          .update({'resumen_ia': resumen})
          .eq('id', sentencia.id);

      debugPrint('✅ Resumen generado y guardado');
      
      return resumen;
    } catch (e) {
      debugPrint('❌ Error generando resumen: $e');
      return 'Error al generar resumen';
    }
  }

  /// Descargar texto completo desde URL (R2 o cualquier URL pública)
  Future<String> _descargarTextoR2(String urlTxt) async {
    if (urlTxt.isEmpty || urlTxt == 'null') {
      debugPrint('⚠️ URL txt vacía');
      return '';
    }
    
    try {
      debugPrint('📥 Descargando texto desde: $urlTxt');
      
      // Usar http para descargar directamente
      final uri = Uri.parse(urlTxt);
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final texto = await response.transform(utf8.decoder).join();
        debugPrint('✅ Texto descargado: ${texto.length} caracteres');
        return texto;
      }
      
      debugPrint('❌ Error R2: status ${response.statusCode}');
      return '';
    } catch (e) {
      debugPrint('❌ Error descargando texto R2: $e');
      return '';
    }
  }
}

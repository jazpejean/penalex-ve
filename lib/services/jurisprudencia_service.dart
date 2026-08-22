import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/sentencia_model.dart';
import 'ai_service.dart';

class JurisprudenciaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Caché local de expansiones semánticas para evitar llamadas repetidas a DeepSeek
  static final Map<String, List<String>> _cacheExpansiones = {};

  /// API key de DeepSeek
  static String get _deepseekApiKey => dotenv.env['DEEPSEEK_API_KEY'] ?? '';

  /// Buscar documentos en Supabase con filtros
  Future<List<SentenciaModel>> buscarEnSupabase({
    String? textoBusqueda,
    required String tipoFiltro, // 'sentencias', 'jurisprudencias', 'resoluciones'
    String? salaFiltro,
    int? anioFiltro,
    int limit = 50,
  }) async {
    try {
      debugPrint('🔍 Búsqueda en Supabase: tipo=$tipoFiltro, sala=$salaFiltro, año=$anioFiltro, texto=$textoBusqueda');

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

      // Filtro por año
      if (anioFiltro != null) {
        query = query.ilike('fecha', '%$anioFiltro%');
      }

      // Búsqueda semántica inteligente (si hay texto)
      if (textoBusqueda != null && textoBusqueda.isNotEmpty) {
        // Expandir la consulta con términos relacionados usando DeepSeek
        final terminosExpandidos = await _expandirConsultaSemantica(textoBusqueda);
        debugPrint('🧠 Términos expandidos: $terminosExpandidos');

        // Construir búsqueda fulltext con todos los términos (OR)
        final tsQuery = terminosExpandidos.join(' | ');
        query = query.textSearch('search_vector', tsQuery, config: 'spanish', type: TextSearchType.plain);
      }

      // Orden descendente por fecha y límite
      final response = await query.order('fecha', ascending: false).limit(limit);
      final List<dynamic> data = response as List<dynamic>;

      debugPrint('✅ Encontrados ${data.length} documentos (búsqueda principal)');

      // Si la búsqueda principal no dio suficientes resultados, intentar fallback con ilike
      if (data.length < 5 && textoBusqueda != null && textoBusqueda.isNotEmpty) {
        debugPrint('🔄 Pocos resultados, intentando búsqueda ampliada con ilike...');
        final resultadosFallback = await _busquedaAmpliadaIlike(
          textoBusqueda: textoBusqueda,
          tipoFiltro: tipoFiltro,
          salaFiltro: salaFiltro,
          anioFiltro: anioFiltro,
          limit: limit,
          idsExcluir: data.map((d) => d['id'].toString()).toSet(),
        );
        data.addAll(resultadosFallback);
        debugPrint('✅ Total con fallback: ${data.length} documentos');
      }

      return data.map((json) => SentenciaModel.fromSupabase(json)).toList();
    } catch (e) {
      debugPrint('❌ Error en búsqueda Supabase: $e');
      return [];
    }
  }

  /// Alias para compatibilidad con pantallas existentes
  Future<List<SentenciaModel>> buscarDocumentos({
    String? textoBusqueda,
    String? tipo,
    String? sala,
    int? anio,
    int limit = 50,
  }) async {
    // Convertir tipo a tipoFiltro
    String tipoFiltro = 'sentencias';
    if (tipo == 'jurisprudencia') {
      tipoFiltro = 'jurisprudencias';
    } else if (tipo == 'resoluciones') {
      tipoFiltro = 'resoluciones';
    } else if (tipo == 'sentencia') {
      tipoFiltro = 'sentencias';
    }
    
    return buscarEnSupabase(
      textoBusqueda: textoBusqueda,
      tipoFiltro: tipoFiltro,
      salaFiltro: sala,
      anioFiltro: anio,
      limit: limit,
    );
  }

  /// Obtener lista de años disponibles (generada del 2000 al año actual)
  Future<List<int>> obtenerAniosDisponibles() async {
    final currentYear = DateTime.now().year;
    return List.generate(currentYear - 1999, (index) => currentYear - index);
  }

  /// Expande una consulta de búsqueda usando DeepSeek para obtener términos relacionados
  /// Ejemplo: "matar" → ["matar", "homicidio", "asesinato", "muerte", "occiso"]
  Future<List<String>> _expandirConsultaSemantica(String consulta) async {
    // Verificar caché
    final cacheKey = consulta.toLowerCase().trim();
    if (_cacheExpansiones.containsKey(cacheKey)) {
      debugPrint('📦 Usando expansión en caché para: $cacheKey');
      return _cacheExpansiones[cacheKey]!;
    }

    try {
      if (_deepseekApiKey.isEmpty) {
        debugPrint('⚠️ No hay API key de DeepSeek, usando consulta original');
        return [consulta];
      }

      final response = await http.post(
        Uri.parse('https://api.deepseek.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_deepseekApiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'Eres un experto en derecho penal venezolano. '
                  'Tu tarea es expandir un término de búsqueda legal con sinónimos y conceptos relacionados. '
                  'Responde SOLO con una lista de términos separados por comas, sin explicaciones. '
                  'Máximo 8 términos. Incluye el término original. '
                  'Ejemplo: si el input es "matar", responde: "matar, homicidio, asesinato, muerte, occiso, victima fatal, dar muerte, privar de vida"',
            },
            {
              'role': 'user',
              'content': consulta,
            },
          ],
          'temperature': 0.3,
          'max_tokens': 100,
          'stream': false,
        }),
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('⏰ Timeout expandiendo consulta, usando original');
          return http.Response('{}', 408);
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          final contenido = data['choices'][0]['message']['content'] as String;
          
          // Parsear términos separados por comas
          final terminos = contenido
              .split(',')
              .map((t) => t.trim().toLowerCase())
              .where((t) => t.isNotEmpty && t.length > 1)
              .toList();

          if (terminos.isNotEmpty) {
            // Guardar en caché
            _cacheExpansiones[cacheKey] = terminos;
            debugPrint('🧠 DeepSeek expandió "$consulta" → $terminos');
            return terminos;
          }
        }
      }

      debugPrint('⚠️ No se pudo expandir, usando consulta original');
      return [consulta];
    } catch (e) {
      debugPrint('❌ Error expandiendo consulta semántica: $e');
      return [consulta];
    }
  }

  /// Búsqueda ampliada con ilike en múltiples columnas (fallback cuando fulltext no basta)
  Future<List<dynamic>> _busquedaAmpliadaIlike({
    required String textoBusqueda,
    required String tipoFiltro,
    String? salaFiltro,
    int? anioFiltro,
    int limit = 50,
    Set<String> idsExcluir = const {},
  }) async {
    try {
      // Obtener términos expandidos (ya deberían estar en caché)
      final terminos = await _expandirConsultaSemantica(textoBusqueda);

      // Construir filtro OR con ilike para múltiples columnas y términos
      // Usamos la función or() de Supabase con ilike en delito, resumen, extracto, partes, decision
      final List<String> orConditions = [];
      for (final termino in terminos) {
        orConditions.add('delito.ilike.%$termino%');
        orConditions.add('resumen_ia.ilike.%$termino%');
        orConditions.add('extracto.ilike.%$termino%');
        orConditions.add('partes.ilike.%$termino%');
        orConditions.add('decision.ilike.%$termino%');
        orConditions.add('ponente.ilike.%$termino%');
      }

      var query = _supabase.from('documentos').select();

      // Aplicar filtros de tipo
      if (tipoFiltro == 'sentencias') {
        query = query.eq('tipo', 'sentencia');
      } else if (tipoFiltro == 'jurisprudencias') {
        query = query.eq('es_jurisprudencia', true);
      } else if (tipoFiltro == 'resoluciones') {
        query = query.eq('tipo', 'resoluciones');
      }

      // Filtro por sala
      if (salaFiltro != null && salaFiltro.isNotEmpty && salaFiltro != 'Todas') {
        query = query.eq('sala', salaFiltro.toLowerCase());
      }

      // Filtro por año
      if (anioFiltro != null) {
        query = query.ilike('fecha', '%$anioFiltro%');
      }

      // Aplicar búsqueda OR en múltiples columnas
      query = query.or(orConditions.join(','));

      final response = await query.order('fecha', ascending: false).limit(limit);
      final List<dynamic> data = response as List<dynamic>;

      // Excluir IDs que ya encontramos en la búsqueda principal
      if (idsExcluir.isNotEmpty) {
        data.removeWhere((item) => idsExcluir.contains(item['id'].toString()));
      }

      debugPrint('🔄 Fallback ilike encontró ${data.length} resultados adicionales');
      return data;
    } catch (e) {
      debugPrint('❌ Error en búsqueda ampliada ilike: $e');
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

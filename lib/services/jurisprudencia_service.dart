import 'dart:convert';
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
  /// Detección de referencia EXACTA de sentencia en la consulta del usuario
  /// (número, expediente o id completo). Si el usuario conoce la sentencia,
  /// debe encontrarse SIEMPRE — nunca depender del fulltext para eso.
  /// Devuelve el filtro a aplicar o null si la consulta no es una referencia.
  Map<String, dynamic>? _detectarReferenciaExacta(String consulta) {
    final q = consulta.trim();
    if (q.isEmpty) return null;

    // URL del historico del TSJ: extraer el id = nombre del archivo sin
    // extensión (la regla idDe del worker, igual a como quedó en la BD).
    // Ej: https://historico.tsj.gob.ve/decisiones/scp/enero/02-190100-9918.HTM
    //     -> id 02-190100-9918. Un abogado pega la URL tal cual la copia
    //     del portal de jurisprudencias; la sentencia DEBE encontrarse.
    final urlMatch = RegExp(
        r'https?://historico\.tsj\.gob\.ve/decisiones/[^/\s]+/[^/\s]+/([^/\s]+)\.(?:HTM|HTML|htm|html)\b',
        caseSensitive: false).firstMatch(q);
    if (urlMatch != null) {
      final idUrl = urlMatch.group(1)!.replaceAll(RegExp(r'[\s.]+$'), '');
      if (RegExp(r'^[A-Za-z0-9][A-Za-z0-9\-]{2,40}$').hasMatch(idUrl)) {
        return {'id': idUrl};
      }
    }

    // Patrón de id completo: NNN-DDMMAA-código (ej: 315-090904-C040292,
    // 0001-070103-02-3004, 999-20709-2009-09-0597). El número de sentencia
    // + fecha (4-6 dígitos) + cualquier código alfanumérico con guiones.
    final idMatch = RegExp(r'^\d{1,4}-\d{4,6}-[A-Za-z0-9\-]+$').hasMatch(q);
    if (idMatch) return {'id': q};

    // Patrón de expediente: letras+números con guiones (ej: C04-0292, A24-385,
    // AA01-V-2004-000123). Un abogado lo conoce y lo teclea tal cual.
    final expMatch = RegExp(
        r'^[A-Za-z]{1,4}[\d]{1,4}-[A-Za-z]{0,2}[\d-]{2,12}$').hasMatch(q);
    if (expMatch) return {'expediente': q};

    // Número de sentencia solo (ej: "142", "sentencia 142"): lo combinamos
    // con sala/año si el usuario los menciona, si no, filtro por número a secas.
    final numMatch = RegExp(r'(?:sentencia\s*(?:n[°ºo]?|numero|núm\.?)?\s*)?(\d{1,4})',
        caseSensitive: false).firstMatch(q);
    if (numMatch != null && q.replaceAll(RegExp(r'\d|\s|sentencia|n[°ºo]|numero|núm|de|del|la|el|sala|casación|constitucional|penal|año|de\s', caseSensitive: false), '').isEmpty) {
      return {'num_sentencia': numMatch.group(1)};
    }
    return null;
  }

  Future<List<SentenciaModel>> buscarEnSupabase({
    String? textoBusqueda,
    required String tipoFiltro, // 'sentencias', 'jurisprudencias', 'resoluciones'
    String? salaFiltro,
    int? anioFiltro,
    int? mesFiltro,
    int? diaFiltro,
    int limit = 50,
    int offset = 0,
    void Function(String mensaje)? onError,
  }) async {
    try {
      debugPrint('🔍 Búsqueda en Supabase: tipo=$tipoFiltro, sala=$salaFiltro, año=$anioFiltro, texto=$textoBusqueda');

      // Términos expandidos (DeepSeek) para el ranking por relevancia.
      // Se rellenan dentro del bloque de texto; vacíos si no hay consulta.
      List<String> terminosExpandidos = <String>[];

      var query = _supabase.from('sentencias').select();

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

      // Filtro por año/mes/día
      if (diaFiltro != null && anioFiltro != null && mesFiltro != null) {
        final m = mesFiltro.toString().padLeft(2, '0');
        final d = diaFiltro.toString().padLeft(2, '0');
        query = query.ilike('fecha', '$anioFiltro-$m-$d%');
      } else if (mesFiltro != null && anioFiltro != null) {
        final m = mesFiltro.toString().padLeft(2, '0');
        query = query.ilike('fecha', '$anioFiltro-$m%');
      } else if (anioFiltro != null) {
        query = query.ilike('fecha', '%$anioFiltro%');
      }

      // Búsqueda semántica inteligente (si hay texto)
      if (textoBusqueda != null && textoBusqueda.isNotEmpty) {
        // PRIMERO: si el usuario conoce la sentencia (número/expediente/id),
        // búsqueda EXACTA — nunca debe fallar por depender del fulltext.
        final ref = _detectarReferenciaExacta(textoBusqueda);
        if (ref != null) {
          debugPrint('🔎 Referencia exacta detectada: $ref');
          for (final entry in ref.entries) {
            query = query.eq(entry.key, entry.value);
          }
          // Si el usuario menciona un año ("142 de 2011"), filtrarlo también.
          final anioEnTexto = RegExp(r'\b(19\d{2}|20\d{2})\b')
              .firstMatch(textoBusqueda)
              ?.group(1);
          if (anioEnTexto != null) {
            query = query.ilike('fecha', '%$anioEnTexto%');
            debugPrint('📅 Año detectado en la consulta: $anioEnTexto');
          }
          // Si hay sala/año además, se respetan (ya aplicados arriba).
          final response = await query
              .order('fecha', ascending: false)
              .order('num_sentencia', ascending: false)
              .range(offset, offset + limit - 1);
          final List<dynamic> data = response as List<dynamic>;
          debugPrint('✅ Referencia exacta: ${data.length} resultado(s)');
          return data
              .map((json) => SentenciaModel.fromSupabase(json))
              .toList();
        }

        // Expandir la consulta con términos relacionados usando DeepSeek
        terminosExpandidos = await _expandirConsultaSemantica(textoBusqueda);
        debugPrint('🧠 Términos expandidos: $terminosExpandidos');

        // Construir búsqueda fulltext con todos los términos (OR).
        // 'websearch' interpreta "a OR b" como disyunción (antes se usaba
        // 'plain', que hacía AND de todos los términos y devolvía casi nada).
        final tsQuery = terminosExpandidos
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .join(' OR ');
        query = query.textSearch(
          'search_vector',
          tsQuery,
          config: 'spanish',
          type: TextSearchType.websearch,
        );
      }

      // Orden descendente por fecha y por número de sentencia (guía del
      // Super Buscador); la reordenación por relevancia se hace en Dart con
      // [terminosExpandidos]. Paginación con .range() para el lazy load.
      final response = await query
          .order('fecha', ascending: false)
          .order('num_sentencia', ascending: false)
          .range(offset, offset + limit - 1);
      List<dynamic> data = response as List<dynamic>;

      debugPrint('✅ Encontrados ${data.length} documentos (búsqueda principal)');

      // Ranking por relevancia real: los términos expandidos pesan según
      // cuántos aparecen en el documento (delito, resumen, decisión, número,
      // expediente). Deja de ser "los 50 más recientes".
      if (data.length > 1 && textoBusqueda != null && textoBusqueda.isNotEmpty) {
        data.sort((a, b) {
          final ra = _scoreRelevancia(a, terminosExpandidos);
          final rb = _scoreRelevancia(b, terminosExpandidos);
          if (rb != ra) return rb.compareTo(ra);
          return (b['fecha'] ?? '').toString().compareTo((a['fecha'] ?? '').toString());
        });
      }

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

      // Re-sort final: el fallback ilike pudo añadir filas fuera de orden.
      if (data.length > 1 && textoBusqueda != null && textoBusqueda.isNotEmpty) {
        data.sort((a, b) {
          final ra = _scoreRelevancia(a, terminosExpandidos);
          final rb = _scoreRelevancia(b, terminosExpandidos);
          if (rb != ra) return rb.compareTo(ra);
          return (b['fecha'] ?? '').toString().compareTo((a['fecha'] ?? '').toString());
        });
      }

      return data.map((json) => SentenciaModel.fromSupabase(json)).toList();
    } catch (e) {
      debugPrint('❌ Error en búsqueda Supabase: $e');
      onError?.call('No se pudo consultar la base de sentencias. Verifica tu conexión.');
      return [];
    }
  }

  /// Puntúa un documento según cuántos términos expandidos (normalizados,
  /// sin acentos) aparecen en sus campos de texto. Sirve para ordenar los
  /// resultados por relevancia real en lugar de solo por fecha.
  int _scoreRelevancia(Map<String, dynamic> doc, List<String> terminos) {
    if (terminos.isEmpty) return 0;
    final texto = _normalizar([
      doc['delito'],
      doc['resumen'],
      doc['decision'],
      doc['expediente'],
      doc['num_sentencia'],
      doc['sala'],
      doc['ponente'],
    ]
        .whereType<String>()
        .join(' ')
        .toLowerCase());
    var score = 0;
    for (final t in terminos) {
      final norm = _normalizar(t.toLowerCase());
      if (norm.length >= 3 && texto.contains(norm)) score++;
    }
    return score;
  }

  /// Normaliza texto sin diacríticos (á→a, é→e, …) para comparar términos.
  static String _normalizar(String s) {
    const con = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const sin = 'aaaaaeeeeiiiiooooouuuuunc';
    final sb = StringBuffer();
    for (final ch in s.split('')) {
      final idx = con.indexOf(ch);
      sb.write(idx >= 0 ? sin[idx] : ch);
    }
    return sb.toString();
  }

  /// Busca doctrinas (criterios de la Sala extraídos por IA) relevantes.
  ///
  /// La tabla `doctrinas` tiene search_vector propio (spanish) + texto_ratio,
  /// parrafo_evidencia e instrumento. Usa el mismo patrón que sentencias:
  /// expansión semántica -> fulltext -> fallback ilike en columnas reales.
  Future<List<Map<String, dynamic>>> buscarDoctrinas({
    String? textoBusqueda,
    int limit = 6,
  }) async {
    if (textoBusqueda == null || textoBusqueda.trim().isEmpty) return [];
    try {
      // Select base (referencia_citada incluida: la migración ya aplicada en
      // la BD o pendiente — por eso el fallback de abajo es resiliente).
      const selectConRef = 'id, sentencia_id, tipo, texto_ratio, parrafo_evidencia, '
          'instrumento, articulo_numero, resumen, referencia_citada';
      const selectSinRef = 'id, sentencia_id, tipo, texto_ratio, parrafo_evidencia, '
          'instrumento, articulo_numero, resumen';

      var query = _supabase
          .from('doctrinas')
          .select(selectConRef);

      final terminosExpandidos = await _expandirConsultaSemantica(textoBusqueda);
      final tsQuery = terminosExpandidos
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .join(' OR ');
      if (tsQuery.isNotEmpty) {
        query = query.textSearch(
          'search_vector',
          tsQuery,
          config: 'spanish',
          type: TextSearchType.websearch,
        );
      }
      var response = await query.limit(limit);
      var data = (response as List<dynamic>)
          .cast<Map<String, dynamic>>();
      if (data.isEmpty) {
        // Migración pendiente (columna referencia_citada inexistente): reintentar
        // sin ella para no romper el RAG.
        var q0 = _supabase.from('doctrinas').select(selectSinRef);
        if (tsQuery.isNotEmpty) {
          q0 = q0.textSearch(
            'search_vector',
            tsQuery,
            config: 'spanish',
            type: TextSearchType.websearch,
          );
        }
        response = await q0.limit(limit);
        data = (response as List<dynamic>).cast<Map<String, dynamic>>();
      }

      // Fallback ilike si el fulltext no dio suficientes resultados
      if (data.length < 3) {
        final orConditions = <String>[];
        for (final termino in terminosExpandidos) {
          orConditions.add('texto_ratio.ilike.%$termino%');
          orConditions.add('parrafo_evidencia.ilike.%$termino%');
          orConditions.add('instrumento.ilike.%$termino%');
        }
        var q2 = _supabase
            .from('doctrinas')
            .select('id, sentencia_id, tipo, texto_ratio, parrafo_evidencia, '
                'instrumento, articulo_numero, resumen');
        if (orConditions.isNotEmpty) {
          q2 = q2.or(orConditions.join(','));
        }
        final extra = await q2.limit(limit);
        final extraMaps = (extra as List<dynamic>).cast<Map<String, dynamic>>();
        final idsVistos = data.map((d) => d['id']).toSet();
        for (final d in extraMaps) {
          if (!idsVistos.contains(d['id'])) data.add(d);
          if (data.length >= limit) break;
        }
      }
      return data;
    } catch (e) {
      debugPrint('⚠️ buscarDoctrinas: $e');
      return [];
    }
  }

  /// Conteo del corpus completo (sentencias + jurisprudencias + resoluciones)
  Future<int> contarSentencias() async {
    try {
      final res = await _supabase
          .from('sentencias')
          .select('id')
          .count(CountOption.exact);
      return res.count;
    } catch (e) {
      return 0;
    }
  }

  /// Alias para compatibilidad con pantallas existentes
  Future<List<SentenciaModel>> buscarDocumentos({
    String? textoBusqueda,
    String? tipo,
    String? sala,
    int? anio,
    int? mes,
    int? dia,
    int limit = 50,
    void Function(String mensaje)? onError,
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
      mesFiltro: mes,
      diaFiltro: dia,
      limit: limit,
      onError: onError,
    );
  }

  /// Meses (1-12) que tienen al menos una sentencia en [anio].
  Future<List<int>> obtenerMesesDisponibles(int anio) async {
    try {
      final resp = await _supabase
          .from('sentencias')
          .select('fecha')
          .ilike('fecha', '$anio-%')
          .limit(10000);
      final meses = <int>{};
      for (final r in resp as List) {
        final f = r['fecha'] as String?;
        if (f != null && f.length >= 7) {
          final m = int.tryParse(f.substring(5, 7));
          if (m != null) meses.add(m);
        }
      }
      return meses.toList()..sort();
    } catch (e) {
      debugPrint('❌ Error obteniendo meses: $e');
      return [];
    }
  }

  /// Días (1-31) que tienen al menos una sentencia en [anio]/[mes].
  Future<List<int>> obtenerDiasDisponibles(int anio, int mes) async {
    try {
      final prefijo = '$anio-${mes.toString().padLeft(2, '0')}-';
      final resp = await _supabase
          .from('sentencias')
          .select('fecha')
          .ilike('fecha', '$prefijo%')
          .limit(10000);
      final dias = <int>{};
      for (final r in resp as List) {
        final f = r['fecha'] as String?;
        if (f != null && f.length >= 10) {
          final d = int.tryParse(f.substring(8, 10));
          if (d != null) dias.add(d);
        }
      }
      return dias.toList()..sort();
    } catch (e) {
      debugPrint('❌ Error obteniendo días: $e');
      return [];
    }
  }

  /// Obtener lista de años disponibles (generada del 2000 al año actual)
  Future<List<int>> obtenerAniosDisponibles() async {
    final currentYear = DateTime.now().year;
    return List.generate(currentYear - 1999, (index) => currentYear - index);
  }

  /// Expande una consulta de búsqueda usando DeepSeek para obtener términos relacionados
  /// Ejemplo: "matar" → ["matar", "homicidio", "asesinato", "muerte", "occiso"]
  Future<List<String>> _expandirConsultaSemantica(String consulta) async {
    // Si la consulta trae un número (artículo), NO expandir: la expansión
    // añade ruido (ej. 'homicidio 406' -> 'hurto 451') porque el número es ambiguo.
    if (RegExp(r'\d').hasMatch(consulta)) {
      return [consulta];
    }
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
      // Columnas reales de la tabla `sentencias` (delito/resumen_ia no existen:
      // una columna inexistente en or() hace fallar TODA la búsqueda ampliada).
      final List<String> orConditions = [];
      for (final termino in terminos) {
        orConditions.add('decision.ilike.%$termino%');
        orConditions.add('partes.ilike.%$termino%');
        orConditions.add('extracto.ilike.%$termino%');
        orConditions.add('ponente.ilike.%$termino%');
      }

      var query = _supabase.from('sentencias').select();

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
          .from('sentencias')
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

      // Guardar en Supabase para caché (columna real: extracto; resumen_ia no existe)
      await _supabase
          .from('sentencias')
          .update({'extracto': resumen})
          .eq('id', sentencia.id);

      debugPrint('✅ Resumen generado y guardado');
      
      return resumen;
    } catch (e) {
      debugPrint('❌ Error generando resumen: $e');
      return 'Error al generar resumen';
    }
  }

  /// Descarga el texto completo de una sentencia desde su URL pública
  /// (compatible Android, iOS y Web).
  Future<String> descargarTextoCompleto(String urlTxt) =>
      _descargarTextoR2(urlTxt);

  /// Descargar texto completo desde URL (R2 o cualquier URL pública)
  ///
  /// Usa el paquete `http` (no `dart:io`) para ser compatible con Web.
  Future<String> _descargarTextoR2(String urlTxt) async {
    if (urlTxt.isEmpty || urlTxt == 'null') {
      debugPrint('⚠️ URL txt vacía');
      return '';
    }
    
    try {
      debugPrint('📥 Descargando texto desde: $urlTxt');
      
      final uri = Uri.parse(urlTxt);
      final response = await http.get(uri).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('⏰ Timeout descargando R2');
          return http.Response('', 408);
        },
      );
      
      if (response.statusCode == 200) {
        final texto = utf8.decode(response.bodyBytes);
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

  /// Doctrinas (criterios) de UNA sentencia, para la ficha técnica.
  ///
  /// Devuelve los criterios de la Sala para esa sentencia — tanto los
  /// extractos OFICIALES de la página de jurisprudencias del TSJ
  /// (tipo = 'jurisprudencia') como los extraídos por IA. Ordenados por tipo
  /// (oficiales primero) y fecha de creación.
  Future<List<Map<String, dynamic>>> doctrinasDeSentencia(
    String sentenciaId, {
    int limit = 20,
  }) async {
    try {
      final res = await _supabase
          .from('doctrinas')
          .select(
            'id, sentencia_id, tipo, texto_ratio, parrafo_evidencia, '
            'instrumento, articulo_numero, resumen, referencia_citada',
          )
          .eq('sentencia_id', sentenciaId)
          .order('created_at', ascending: true)
          .limit(limit);
      final data = (res as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList();
      // Oficiales (jurisprudencia) primero, luego el resto.
      data.sort((a, b) {
        final aOff = (a['tipo'] ?? '') == 'jurisprudencia' ? 0 : 1;
        final bOff = (b['tipo'] ?? '') == 'jurisprudencia' ? 0 : 1;
        return aOff.compareTo(bOff);
      });
      return data;
    } catch (e) {
      debugPrint('⚠️ doctrinasDeSentencia: $e');
      return [];
    }
  }

  /// Citas a DOCTRINA ACADÉMICA (autor/obra) de UNA sentencia.
  ///
  /// Tabla `doctrinas_academicas` (extraídas por IA con cita textual literal).
  /// Si la tabla aún no existe en la BD (migración pendiente), devuelve [].
  Future<List<Map<String, dynamic>>> citasDoctrinalesDeSentencia(
    String sentenciaId, {
    int limit = 12,
  }) async {
    try {
      final res = await _supabase
          .from('doctrinas_academicas')
          .select(
            'id, sentencia_id, autor, obra, pagina, parrafo_evidencia',
          )
          .eq('sentencia_id', sentenciaId)
          .order('created_at', ascending: true)
          .limit(limit);
      return (res as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      // Migración pendiente (tabla inexistente): no romper la ficha técnica.
      debugPrint('⚠️ citasDoctrinalesDeSentencia: $e');
      return [];
    }
  }

  /// Busca citas a DOCTRINA ACADÉMICA (autor/obra/página) relevantes a una
  /// consulta, para el RAG del redactor y del chat legal.
  ///
  /// Estrategia: expansión semántica (DeepSeek) → fulltext sobre search_vector
  /// → fallback ilike sobre autor/obra/parrafo_evidencia. Resiliente: ante
  /// cualquier error devuelve [] (no rompe el RAG).
  Future<List<Map<String, dynamic>>> buscarDoctrinasAcademicas({
    String? textoBusqueda,
    int limit = 6,
  }) async {
    if (textoBusqueda == null || textoBusqueda.trim().isEmpty) return [];
    try {
      const select = 'id, sentencia_id, autor, obra, pagina, parrafo_evidencia';

      var query = _supabase.from('doctrinas_academicas').select(select);

      final terminosExpandidos = await _expandirConsultaSemantica(textoBusqueda);
      final tsQuery = terminosExpandidos
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .join(' OR ');
      if (tsQuery.isNotEmpty) {
        query = query.textSearch(
          'search_vector',
          tsQuery,
          config: 'spanish',
          type: TextSearchType.websearch,
        );
      }
      var response = await query.limit(limit);
      var data = (response as List<dynamic>).cast<Map<String, dynamic>>();

      // Fallback ilike si el fulltext no dio suficientes resultados.
      if (data.length < 3) {
        final orConditions = <String>[];
        for (final termino in terminosExpandidos) {
          orConditions.add('autor.ilike.%$termino%');
          orConditions.add('obra.ilike.%$termino%');
          orConditions.add('parrafo_evidencia.ilike.%$termino%');
        }
        var q2 = _supabase.from('doctrinas_academicas').select(select);
        if (orConditions.isNotEmpty) {
          q2 = q2.or(orConditions.join(','));
        }
        final extra = await q2.limit(limit);
        final extraMaps = (extra as List<dynamic>).cast<Map<String, dynamic>>();
        final idsVistos = data.map((d) => d['id']).toSet();
        for (final d in extraMaps) {
          if (!idsVistos.contains(d['id'])) data.add(d);
          if (data.length >= limit) break;
        }
      }
      return data;
    } catch (e) {
      debugPrint('⚠️ buscarDoctrinasAcademicas: $e');
      return [];
    }
  }
}

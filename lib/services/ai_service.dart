import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Servicio de IA para interpretar textos legales
/// Soporta OpenAI, Google Gemini, Anthropic Claude, y DeepSeek
class AIService {
  // Configuración (debe estar en .env o Firebase Remote Config)
  static String _openAIKey = '';
  static String _geminiKey = '';
  static String _claudeKey = '';
  static String _deepseekKey = '';
  
  // Modelo activo (configurable por administrador)
  static AIModel _modeloActivo = AIModel.deepseekChat;
  
  // Cache de configuración
  static final Map<String, dynamic> _configCache = {};
  
  /// Inicializa el servicio con la API key de DeepSeek desde .env
  static Future<void> inicializar() async {
    try {
      // Cargar API key desde variables de entorno
      const deepseekKey = String.fromEnvironment('DEEPSEEK_API_KEY');
      if (deepseekKey.isNotEmpty) {
        _deepseekKey = deepseekKey;
        debugPrint('✅ DeepSeek API Key cargada');
      } else {
        // Fallback: intenta cargar desde constante
        _deepseekKey = 'sk-0a9f652b7fd549db937ca806959ab6c1';
        debugPrint('⚠️ Usando DeepSeek API Key de respaldo');
      }
    } catch (e) {
      debugPrint('❌ Error inicializando AIService: $e');
    }
  }
  
  /// Método general para consultas de chat/redacción (usado por DocumentChatService)
  static Future<String> procesarConsultaGeneral(String prompt) async {
    try {
      debugPrint('🤖 Procesando consulta general');
      return await _llamarIA(prompt);
    } catch (e) {
      debugPrint('❌ Error en consulta general: $e');
      throw Exception('Error procesando consulta: $e');
    }
  }
  
  /// Interpreta una ley o artículo específico
  static Future<AIInterpretation> interpretarLey({
    required String tituloLey,
    required String articulo,
    required String textoArticulo,
    String? contextoAdicional,
  }) async {
    try {
      debugPrint('🤖 Interpretando ley: $tituloLey - $articulo');
      
      final String prompt = _construirPromptLey(
        tituloLey: tituloLey,
        articulo: articulo,
        textoArticulo: textoArticulo,
        contextoAdicional: contextoAdicional,
      );
      
      final String respuesta = await _llamarIA(prompt);
      
      return AIInterpretation(
        tipo: TipoInterpretacion.ley,
        titulo: '$tituloLey - $articulo',
        textoOriginal: textoArticulo,
        interpretacion: respuesta,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error interpretando ley: $e');
      rethrow;
    }
  }
  
  /// Interpreta una sentencia o jurisprudencia
  static Future<AIInterpretation> interpretarJurisprudencia({
    required String numeroSentencia,
    required String tribunal,
    required String resumen,
    required String doctrina,
    String? preguntaEspecifica,
  }) async {
    try {
      debugPrint('🤖 Interpretando jurisprudencia: $numeroSentencia');
      
      final String prompt = _construirPromptJurisprudencia(
        numeroSentencia: numeroSentencia,
        tribunal: tribunal,
        resumen: resumen,
        doctrina: doctrina,
        preguntaEspecifica: preguntaEspecifica,
      );
      
      final String respuesta = await _llamarIA(prompt);
      
      return AIInterpretacion(
        tipo: TipoInterpretacion.jurisprudencia,
        titulo: numeroSentencia,
        textoOriginal: '$resumen\n\n$doctrina',
        interpretacion: respuesta,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error interpretando jurisprudencia: $e');
      rethrow;
    }
  }
  
  /// Compara dos sentencias o artículos
  static Future<AIInterpretation> compararTextos({
    required String titulo1,
    required String texto1,
    required String titulo2,
    required String texto2,
    String? aspectoComparacion,
  }) async {
    try {
      debugPrint('🤖 Comparando: $titulo1 vs $titulo2');
      
      final String prompt = _construirPromptComparacion(
        titulo1: titulo1,
        texto1: texto1,
        titulo2: titulo2,
        texto2: texto2,
        aspectoComparacion: aspectoComparacion,
      );
      
      final String respuesta = await _llamarIA(prompt);
      
      return AIInterpretation(
        tipo: TipoInterpretacion.comparacion,
        titulo: 'Comparación: $titulo1 vs $titulo2',
        textoOriginal: 'Texto 1:\n$texto1\n\nTexto 2:\n$texto2',
        interpretacion: respuesta,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error comparando textos: $e');
      rethrow;
    }
  }
  
  /// Pregunta libre sobre un texto legal
  static Future<AIInterpretation> preguntarSobreTexto({
    required String titulo,
    required String texto,
    required String pregunta,
  }) async {
    try {
      debugPrint('🤖 Pregunta sobre: $titulo');
      
      final String prompt = _construirPromptPregunta(
        titulo: titulo,
        texto: texto,
        pregunta: pregunta,
      );
      
      final String respuesta = await _llamarIA(prompt);
      
      return AIInterpretation(
        tipo: TipoInterpretacion.pregunta,
        titulo: pregunta,
        textoOriginal: texto,
        interpretacion: respuesta,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error procesando pregunta: $e');
      rethrow;
    }
  }
  
  /// Resume un texto legal extenso
  static Future<AIInterpretation> resumirTexto({
    required String titulo,
    required String texto,
    NivelResumen nivel = NivelResumen.medio,
  }) async {
    try {
      debugPrint('🤖 Resumiendo: $titulo');
      
      final String prompt = _construirPromptResumen(
        titulo: titulo,
        texto: texto,
        nivel: nivel,
      );
      
      final String respuesta = await _llamarIA(prompt);
      
      return AIInterpretation(
        tipo: TipoInterpretacion.resumen,
        titulo: 'Resumen: $titulo',
        textoOriginal: texto,
        interpretacion: respuesta,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Error resumiendo texto: $e');
      rethrow;
    }
  }
  
  /// Llama a la API de IA según el modelo configurado
  static Future<String> _llamarIA(String prompt) async {
    debugPrint('🤖 Usando modelo: ${_modeloActivo.nombre}');
    
    switch (_modeloActivo) {
      case AIModel.gpt4:
      case AIModel.gpt4Turbo:
      case AIModel.gpt35Turbo:
        return _llamarOpenAI(prompt, _modeloActivo.modelId);
      
      case AIModel.geminiPro:
      case AIModel.gemini15Pro:
        return _llamarGemini(prompt, _modeloActivo.modelId);
      
      case AIModel.claude3Opus:
      case AIModel.claude3Sonnet:
      case AIModel.claude3Haiku:
        return _llamarClaude(prompt, _modeloActivo.modelId);
      
      case AIModel.deepseekChat:
      case AIModel.deepseekCoder:
        return _llamarDeepSeek(prompt, _modeloActivo.modelId);
    }
  }
  
  /// OpenAI GPT (soporte múltiples modelos)
  static Future<String> _llamarOpenAI(String prompt, String model) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_openAIKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': _obtenerSystemPrompt(),
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.3,
        'max_tokens': 2000,
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.statusCode} - ${response.body}');
    }
    
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['choices'][0]['message']['content'] as String;
  }
  
  /// Google Gemini (soporte múltiples modelos)
  static Future<String> _llamarGemini(String prompt, String model) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiKey',
    );
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': '${_obtenerSystemPrompt()}\n\n$prompt'}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 2000,
        },
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
    }
    
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }
  
  /// Anthropic Claude (soporte múltiples modelos)
  static Future<String> _llamarClaude(String prompt, String model) async {
    final url = Uri.parse('https://api.anthropic.com/v1/messages');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _claudeKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': model,
        'max_tokens': 2000,
        'system': _obtenerSystemPrompt(),
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          },
        ],
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Claude API error: ${response.statusCode} - ${response.body}');
    }
    
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['content'][0]['text'] as String;
  }
  
  /// DeepSeek (compatible con OpenAI API)
  static Future<String> _llamarDeepSeek(String prompt, String model) async {
    final url = Uri.parse('https://api.deepseek.com/v1/chat/completions');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_deepseekKey',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': _obtenerSystemPrompt(),
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.3,
        'max_tokens': 2000,
        'stream': false,
      }),
    ).timeout(
      const Duration(seconds: 120),
      onTimeout: () {
        throw Exception('Timeout: La solicitud a DeepSeek tomó demasiado tiempo.');
      },
    );
    
    if (response.statusCode != 200) {
      throw Exception('DeepSeek API error: ${response.statusCode} - ${response.body}');
    }
    
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['choices'][0]['message']['content'] as String;
  }
  
  /// System prompt especializado en derecho penal venezolano
  static String _obtenerSystemPrompt() {
    return '''Eres un asistente legal especializado en derecho penal venezolano. Tu función es interpretar textos legales (leyes, artículos, sentencias) de manera clara, precisa y profesional.

INSTRUCCIONES:
1. Interpreta el texto desde la perspectiva del derecho penal venezolano
2. Usa un lenguaje técnico pero accesible para abogados
3. Cita artículos relevantes cuando sea pertinente
4. Estructura tu respuesta de forma clara (usa secciones si es necesario)
5. Sé preciso y conciso (máximo 500 palabras)
6. Si el texto tiene ambigüedades, señálalas
7. Si hay jurisprudencia relevante implícita, menciónala
8. Nunca inventes información - si no estás seguro, indícalo

FORMATO DE RESPUESTA:
- Usa párrafos cortos
- Destaca conceptos clave
- Incluye ejemplos prácticos cuando ayude a la comprensión
- Termina con "Implicaciones prácticas" si es relevante

RESTRICCIONES:
- No des consejos legales específicos de casos
- No sustituyes a un abogado
- Eres una herramienta de interpretación y análisis

CONTEXTO: Venezuela - Sistema penal continental - Código Penal Venezolano vigente''';
  }
  
  /// Construye prompt para interpretar una ley
  static String _construirPromptLey({
    required String tituloLey,
    required String articulo,
    required String textoArticulo,
    String? contextoAdicional,
  }) {
    return '''Interpreta el siguiente artículo legal:

LEY: $tituloLey
ARTÍCULO: $articulo

TEXTO:
$textoArticulo

${contextoAdicional != null ? '\nCONTEXTO ADICIONAL:\n$contextoAdicional' : ''}

Proporciona:
1. Explicación clara del artículo
2. Elementos principales que establece
3. Relación con otros artículos (si aplica)
4. Implicaciones prácticas
5. Ejemplos de aplicación''';
  }
  
  /// Construye prompt para interpretar jurisprudencia
  static String _construirPromptJurisprudencia({
    required String numeroSentencia,
    required String tribunal,
    required String resumen,
    required String doctrina,
    String? preguntaEspecifica,
  }) {
    return '''Interpreta la siguiente sentencia:

SENTENCIA: $numeroSentencia
TRIBUNAL: $tribunal

RESUMEN:
$resumen

DOCTRINA:
$doctrina

${preguntaEspecifica != null ? '\nPREGUNTA ESPECÍFICA:\n$preguntaEspecifica' : ''}

Proporciona:
1. Ratio decidendi (fundamento jurídico central)
2. Doctrina establecida
3. Criterios interpretativos relevantes
4. Aplicabilidad práctica
5. Precedentes relacionados (si los conoces)''';
  }
  
  /// Construye prompt para comparar textos
  static String _construirPromptComparacion({
    required String titulo1,
    required String texto1,
    required String titulo2,
    required String texto2,
    String? aspectoComparacion,
  }) {
    return '''Compara los siguientes textos legales:

TEXTO 1: $titulo1
$texto1

TEXTO 2: $titulo2
$texto2

${aspectoComparacion != null ? '\nASPECTO A COMPARAR:\n$aspectoComparacion' : ''}

Proporciona:
1. Similitudes principales
2. Diferencias clave
3. Criterios que varían
4. Cuál es más aplicable en qué situaciones
5. Posibles conflictos normativos''';
  }
  
  /// Construye prompt para pregunta libre
  static String _construirPromptPregunta({
    required String titulo,
    required String texto,
    required String pregunta,
  }) {
    return '''Responde la siguiente pregunta sobre el texto legal:

TEXTO: $titulo
$texto

PREGUNTA:
$pregunta

Responde de forma directa, precisa y fundamentada en el texto proporcionado.''';
  }
  
  /// Construye prompt para resumir
  static String _construirPromptResumen({
    required String titulo,
    required String texto,
    required NivelResumen nivel,
  }) {
    final String instruccionNivel = switch (nivel) {
      NivelResumen.breve => 'Resumen ultra-breve (máximo 100 palabras)',
      NivelResumen.medio => 'Resumen conciso (máximo 250 palabras)',
      NivelResumen.detallado => 'Resumen detallado (máximo 500 palabras)',
    };
    
    return '''Resume el siguiente texto legal:

TÍTULO: $titulo

TEXTO:
$texto

INSTRUCCIÓN: $instruccionNivel

Incluye:
1. Ideas principales
2. Conceptos clave
3. Conclusiones relevantes''';
  }
  
  // ==================== CONFIGURACIÓN DINÁMICA ====================
  
  /// Cambia el modelo activo
  static Future<void> setModelo(AIModel modelo) async {
    _modeloActivo = modelo;
    debugPrint('🔄 Modelo cambiado a: ${modelo.nombre}');
    
    // Guardar en Firebase Remote Config o SharedPreferences
    try {
      await _guardarConfiguracion('modelo_activo', modelo.modelId);
    } catch (e) {
      debugPrint('⚠️ No se pudo guardar configuración: $e');
    }
  }
  
  /// Obtiene el modelo actual
  static AIModel getModeloActivo() => _modeloActivo;
  
  /// Obtiene todos los modelos disponibles
  static List<AIModel> getModelosDisponibles() => AIModel.values;
  
  /// Configura las API keys
  static void configurarKeys({
    String? openAI,
    String? gemini,
    String? claude,
    String? deepseek,
  }) {
    if (openAI != null) _openAIKey = openAI;
    if (gemini != null) _geminiKey = gemini;
    if (claude != null) _claudeKey = claude;
    if (deepseek != null) _deepseekKey = deepseek;
    debugPrint('🔑 API Keys actualizadas');
  }
  
  /// Carga configuración desde Firebase Remote Config
  static Future<void> cargarConfiguracion() async {
    try {
      // Aquí puedes cargar desde Firebase Remote Config
      // final remoteConfig = FirebaseRemoteConfig.instance;
      // await remoteConfig.fetchAndActivate();
      // _openAIKey = remoteConfig.getString('openai_key');
      // etc.
      
      debugPrint('✅ Configuración cargada');
    } catch (e) {
      debugPrint('⚠️ Error cargando configuración: $e');
    }
  }
  
  /// Guarda configuración
  static Future<void> _guardarConfiguracion(String key, String value) async {
    _configCache[key] = value;
    // Aquí puedes guardar en SharedPreferences o Firebase
  }
  
  /// Obtiene información del modelo actual
  static Map<String, dynamic> getInfoModelo() => {
    'nombre': _modeloActivo.nombre,
    'proveedor': _modeloActivo.proveedor.nombre,
    'costoPor1000Tokens': _modeloActivo.costoPor1000Tokens,
    'descripcion': _modeloActivo.descripcion,
    'velocidad': _modeloActivo.velocidad.name,
    'calidad': _modeloActivo.calidad.name,
  };
  
  /// Verifica si un modelo está disponible (tiene API key)
  static bool isModeloDisponible(AIModel modelo) {
    switch (modelo.proveedor) {
      case ProveedorIA.openai:
        return _openAIKey != 'YOUR_OPENAI_API_KEY' && _openAIKey.isNotEmpty;
      case ProveedorIA.gemini:
        return _geminiKey != 'YOUR_GEMINI_API_KEY' && _geminiKey.isNotEmpty;
      case ProveedorIA.claude:
        return _claudeKey != 'YOUR_CLAUDE_API_KEY' && _claudeKey.isNotEmpty;
      case ProveedorIA.deepseek:
        return _deepseekKey != 'YOUR_DEEPSEEK_API_KEY' && _deepseekKey.isNotEmpty;
    }
  }
  
  /// Obtiene modelos disponibles (con API key configurada)
  static List<AIModel> getModelosConAPIKey() {
    return AIModel.values.where((modelo) => isModeloDisponible(modelo)).toList();
  }

  /// Chat legal conversacional con contexto
  static Future<AIInterpretation> chatLegalConversacional({
    required String pregunta,
    String? contexto,
    Map<String, dynamic>? fuentes,
  }) async {
    debugPrint('🤖 Chat conversacional - Pregunta: ${pregunta.length > 50 ? pregunta.substring(0, 50) : pregunta}...');

    final prompt = '''
Eres un asistente legal especializado en derecho penal venezolano. Responde de forma conversacional, clara y precisa.

${contexto != null ? 'CONTEXTO DE LA CONVERSACIÓN:\n$contexto\n' : ''}

PREGUNTA DEL USUARIO:
$pregunta

INSTRUCCIONES:
- Responde de forma conversacional y natural
- Cita las fuentes relevantes cuando sea apropiado
- Si el contexto anterior es relevante, úsalo para dar continuidad
- Si no tienes información suficiente, dilo claramente
- Mantén un tono profesional pero accesible

RESPUESTA:''';

    final respuesta = await _llamarIA(prompt);

    return AIInterpretation(
      tipo: TipoInterpretacion.pregunta,
      titulo: 'Chat Legal',
      textoOriginal: pregunta,
      interpretacion: respuesta,
      timestamp: DateTime.now(),
    );
  }

  /// Genera resumen de sentencia para cards (corto, 2-3 líneas)
  static Future<String> generarResumenSentencia({
    required String numeroSentencia,
    required String sala,
    required String delito,
    required String textoCompleto,
  }) async {
    debugPrint('📝 Generando resumen corto para sentencia: $numeroSentencia');

    final prompt = '''Eres un asistente legal experto. Resume esta sentencia del TSJ en MÁXIMO 2 líneas (120 palabras):

SENTENCIA: $numeroSentencia
SALA: $sala
DELITO: ${delito.isNotEmpty ? delito : 'No especificado'}

TEXTO:
${textoCompleto.substring(0, textoCompleto.length > 3000 ? 3000 : textoCompleto.length)}

INSTRUCCIONES:
- Resume EN 2 LÍNEAS lo más importante
- Menciona el tema principal y la decisión
- Lenguaje claro y directo
- Sin introducción ni conclusión
- Formato: texto plano (sin "Resumen:" ni marcadores)

Resumen:''';

    try {
      final respuesta = await _llamarIA(prompt);
      return respuesta.trim();
    } catch (e) {
      debugPrint('❌ Error generando resumen: $e');
      return 'Sentencia del TSJ - $sala - $numeroSentencia';
    }
  }

  /// Análisis profundo de sentencia con IA
  static Future<AnalisisProfundoSentencia> analizarSentenciaProfundo({
    required String numeroSentencia,
    required String sala,
    required String delito,
    required String ponente,
    required String resumen,
    required String decision,
    required String partes,
    required String contenidoCompleto,
  }) async {
    debugPrint('🤖 Análisis profundo de sentencia: $numeroSentencia');

    // Prompt para análisis profundo
    final prompt = '''
Eres un experto en análisis jurisprudencial venezolano. Analiza en profundidad la siguiente sentencia:

DATOS DE LA SENTENCIA:
- Número: $numeroSentencia
- Sala: $sala
- Delito: $delito
- Ponente: $ponente
- Partes: $partes
- Decisión: $decision

RESUMEN:
$resumen

CONTENIDO COMPLETO:
${contenidoCompleto.length > 3000 ? contenidoCompleto.substring(0, 3000) + '...' : contenidoCompleto}

GENERA UN ANÁLISIS ESTRUCTURADO CON:

## 📋 RESUMEN EJECUTIVO
[Resume en 2-3 párrafos los aspectos más importantes del caso]

## ⚖️ RATIO DECIDENDI
[Identifica el razonamiento jurídico fundamental que sustenta la decisión]

## 🔑 PRECEDENTES Y CITAS CLAVE
[Lista los precedentes citados o principios jurídicos aplicados]

## 💡 ARGUMENTOS LEGALES PRINCIPALES
[Enumera los 3-5 argumentos más sólidos presentados por el tribunal]

## 📊 IMPACTO Y APLICABILIDAD
[Explica en qué casos futuros podría aplicarse esta sentencia]

## ⚠️ PUNTOS CRÍTICOS
[Señala aspectos controversiales, disidencias o interpretaciones particulares]

## 🎯 RECOMENDACIONES PRÁCTICAS
[Sugiere cómo usar esta sentencia en la práctica legal]

Mantén un lenguaje técnico pero accesible. Usa formato markdown.''';

    final respuesta = await _llamarIA(prompt);

    // Parsear respuesta estructurada
    return AnalisisProfundoSentencia(
      numeroSentencia: numeroSentencia,
      resumenEjecutivo: _extraerSeccion(respuesta, 'RESUMEN EJECUTIVO'),
      ratioDecidendi: _extraerSeccion(respuesta, 'RATIO DECIDENDI'),
      precedentesClave: _extraerSeccion(respuesta, 'PRECEDENTES Y CITAS CLAVE'),
      argumentosPrincipales: _extraerSeccion(respuesta, 'ARGUMENTOS LEGALES PRINCIPALES'),
      impactoAplicabilidad: _extraerSeccion(respuesta, 'IMPACTO Y APLICABILIDAD'),
      puntosCriticos: _extraerSeccion(respuesta, 'PUNTOS CRÍTICOS'),
      recomendacionesPracticas: _extraerSeccion(respuesta, 'RECOMENDACIONES PRÁCTICAS'),
      analisisCompleto: respuesta,
      timestamp: DateTime.now(),
    );
  }

  /// Extrae una sección del análisis
  static String _extraerSeccion(String texto, String seccion) {
    final regex = RegExp(
      '##.*?$seccion.*?\n(.*?)(?=##|\$)',
      multiLine: true,
      dotAll: true,
    );
    final match = regex.firstMatch(texto);
    return match?.group(1)?.trim() ?? 'No disponible';
  }

  /// Genera escrito legal con IA
  static Future<AIInterpretation> generarEscritoLegal({
    required String tipo,
    required String prompt,
  }) async {
    debugPrint('📝 Generando escrito legal...');

    final respuesta = await _llamarIA(prompt);

    return AIInterpretation(
      tipo: TipoInterpretacion.resumen,
      titulo: 'Escrito Legal',
      textoOriginal: prompt,
      interpretacion: respuesta,
      timestamp: DateTime.now(),
    );
  }

  /// Genera estrategias legales comparativas (usado por ComparadorService)
  static Future<String> generarEstrategiaLegal(String prompt) async {
    debugPrint('⚖️ Generando estrategias legales comparativas...');
    return await _llamarIA(prompt);
  }

  /// Expande un query de búsqueda a términos legales relevantes (Búsqueda Semántica)
  static Future<List<String>> expandirQueryLegal(String query) async {
    try {
      await inicializar();
      
      debugPrint('🔍 Expandiendo query: $query');
      
      final String prompt = '''Eres un asistente legal venezolano experto. El usuario busca jurisprudencias con: "$query"

Genera términos legales relevantes del Código Penal venezolano que deberían encontrar sentencias relacionadas.

REGLAS:
1. Incluye sinónimos legales precisos
2. Usa terminología del Código Penal venezolano
3. Máximo 8 términos
4. Responde SOLO con términos separados por comas (sin explicaciones)

EJEMPLOS:
- "matar a alguien" → homicidio, asesinato, homicidio calificado, privación de vida, homicidio simple, parricidio
- "robar" → hurto, robo, hurto agravado, robo agravado, sustracción, apropiación indebida
- "golpear" → lesiones personales, agresión física, lesiones leves, lesiones graves, lesiones gravísimas

Consulta: "$query"
Términos legales:''';

      final respuesta = await _llamarDeepSeek(prompt, 'deepseek-chat');
      
      // Parsear respuesta (eliminar espacios y separar por comas)
      final terminos = respuesta
          .split(',')
          .map((t) => t.trim().toLowerCase())
          .where((t) => t.isNotEmpty)
          .toList();
      
      // Agregar el query original si no está incluido
      if (!terminos.contains(query.toLowerCase())) {
        terminos.insert(0, query.toLowerCase());
      }
      
      debugPrint('✅ Query expandido: $query → ${terminos.join(", ")}');
      return terminos;
      
    } catch (e) {
      debugPrint('❌ Error expandiendo query: $e');
      // Fallback: retornar solo el query original
      return [query.toLowerCase()];
    }
  }
}

/// Proveedores de IA
enum ProveedorIA {
  openai,
  gemini,
  claude,
  deepseek;
  
  String get nombre {
    switch (this) {
      case ProveedorIA.openai:
        return 'OpenAI';
      case ProveedorIA.gemini:
        return 'Google Gemini';
      case ProveedorIA.claude:
        return 'Anthropic Claude';
      case ProveedorIA.deepseek:
        return 'DeepSeek';
    }
  }
}

/// Modelos de IA disponibles
enum AIModel {
  // OpenAI
  gpt4('gpt-4', 'GPT-4', ProveedorIA.openai, 0.03, 'Máxima calidad, razonamiento profundo', Velocidad.media, Calidad.excelente),
  gpt4Turbo('gpt-4-turbo-preview', 'GPT-4 Turbo', ProveedorIA.openai, 0.01, 'Balance calidad/velocidad', Velocidad.rapida, Calidad.excelente),
  gpt35Turbo('gpt-3.5-turbo', 'GPT-3.5 Turbo', ProveedorIA.openai, 0.0005, 'Económico y rápido', Velocidad.muyRapida, Calidad.buena),
  
  // Google Gemini
  geminiPro('gemini-pro', 'Gemini Pro', ProveedorIA.gemini, 0.0, 'Gratis, buen rendimiento', Velocidad.rapida, Calidad.muyBuena),
  gemini15Pro('gemini-1.5-pro', 'Gemini 1.5 Pro', ProveedorIA.gemini, 0.001, 'Contexto largo, económico', Velocidad.rapida, Calidad.excelente),
  
  // Anthropic Claude
  claude3Opus('claude-3-opus-20240229', 'Claude 3 Opus', ProveedorIA.claude, 0.015, 'Máxima inteligencia', Velocidad.media, Calidad.excelente),
  claude3Sonnet('claude-3-sonnet-20240229', 'Claude 3 Sonnet', ProveedorIA.claude, 0.003, 'Balance ideal', Velocidad.rapida, Calidad.excelente),
  claude3Haiku('claude-3-haiku-20240307', 'Claude 3 Haiku', ProveedorIA.claude, 0.00025, 'Ultra rápido y económico', Velocidad.muyRapida, Calidad.buena),
  
  // DeepSeek
  deepseekChat('deepseek-chat', 'DeepSeek Chat', ProveedorIA.deepseek, 0.00014, 'Muy económico, buena calidad', Velocidad.rapida, Calidad.buena),
  deepseekCoder('deepseek-coder', 'DeepSeek Coder', ProveedorIA.deepseek, 0.00014, 'Especializado en código/lógica', Velocidad.rapida, Calidad.buena);
  
  const AIModel(
    this.modelId,
    this.nombre,
    this.proveedor,
    this.costoPor1000Tokens,
    this.descripcion,
    this.velocidad,
    this.calidad,
  );
  
  final String modelId;
  final String nombre;
  final ProveedorIA proveedor;
  final double costoPor1000Tokens;
  final String descripcion;
  final Velocidad velocidad;
  final Calidad calidad;
  
  /// Costo estimado por interpretación (asumiendo ~1500 tokens)
  double get costoEstimadoPorInterpretacion => (costoPor1000Tokens * 1.5);
}

/// Velocidad del modelo
enum Velocidad {
  muyRapida,
  rapida,
  media,
  lenta;
}

/// Calidad del modelo
enum Calidad {
  buena,
  muyBuena,
  excelente;
}

/// Tipos de interpretación
enum TipoInterpretacion {
  ley,
  jurisprudencia,
  comparacion,
  pregunta,
  resumen,
}

/// Niveles de resumen
enum NivelResumen {
  breve,
  medio,
  detallado,
}

/// Modelo de interpretación de IA
class AIInterpretation {
  final TipoInterpretacion tipo;
  final String titulo;
  final String textoOriginal;
  final String interpretacion;
  final DateTime timestamp;
  
  AIInterpretation({
    required this.tipo,
    required this.titulo,
    required this.textoOriginal,
    required this.interpretacion,
    required this.timestamp,
  });
  
  Map<String, dynamic> toMap() => {
    'tipo': tipo.name,
    'titulo': titulo,
    'textoOriginal': textoOriginal,
    'interpretacion': interpretacion,
    'timestamp': timestamp.toIso8601String(),
  };
  
  factory AIInterpretation.fromMap(Map<String, dynamic> map) => AIInterpretation(
    tipo: TipoInterpretacion.values.firstWhere((e) => e.name == map['tipo']),
    titulo: map['titulo'] as String,
    textoOriginal: map['textoOriginal'] as String,
    interpretacion: map['interpretacion'] as String,
    timestamp: DateTime.parse(map['timestamp'] as String),
  );
}

// Alias para compatibilidad
typedef AIInterpretacion = AIInterpretation;


/// Modelo de análisis profundo de sentencia
class AnalisisProfundoSentencia {
  final String numeroSentencia;
  final String resumenEjecutivo;
  final String ratioDecidendi;
  final String precedentesClave;
  final String argumentosPrincipales;
  final String impactoAplicabilidad;
  final String puntosCriticos;
  final String recomendacionesPracticas;
  final String analisisCompleto;
  final DateTime timestamp;

  AnalisisProfundoSentencia({
    required this.numeroSentencia,
    required this.resumenEjecutivo,
    required this.ratioDecidendi,
    required this.precedentesClave,
    required this.argumentosPrincipales,
    required this.impactoAplicabilidad,
    required this.puntosCriticos,
    required this.recomendacionesPracticas,
    required this.analisisCompleto,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'numeroSentencia': numeroSentencia,
    'resumenEjecutivo': resumenEjecutivo,
    'ratioDecidendi': ratioDecidendi,
    'precedentesClave': precedentesClave,
    'argumentosPrincipales': argumentosPrincipales,
    'impactoAplicabilidad': impactoAplicabilidad,
    'puntosCriticos': puntosCriticos,
    'recomendacionesPracticas': recomendacionesPracticas,
    'analisisCompleto': analisisCompleto,
    'timestamp': timestamp.toIso8601String(),
  };
}

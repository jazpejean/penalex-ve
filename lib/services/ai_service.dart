import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Servicio de IA para interpretar textos legales
/// Soporta OpenAI, Google Gemini, Anthropic Claude, y DeepSeek
class AIService {
  /// Marca visible del asistente (Ulpiano). El proveedor técnico real
  /// (DeepSeek u otro) solo aparece en la configuración de administración.
  static const String marcaIA = 'Ulpiano';

  // Configuración (debe estar en .env o Firebase Remote Config)
  static String _deepseekKey = '';
  
  // Modelo activo (proveedor único: DeepSeek)
  static AIModel _modeloActivo = AIModel.deepseekChat;
  
  // Cache de configuración
  static final Map<String, dynamic> _configCache = {};
  
  /// Inicializa el servicio con la API key de DeepSeek desde .env
  static Future<void> inicializar() async {
    try {
      // Cargar API key desde .env (flutter_dotenv)
      _deepseekKey = dotenv.env['DEEPSEEK_API_KEY'] ??
          'sk-0a9f652b7fd549db937ca806959ab6c1';
      debugPrint('✅ DeepSeek API Key cargada desde .env');
    } catch (e) {
      debugPrint('❌ Error inicializando AIService: $e');
    }
  }
  
  /// Genera el análisis profundo estructurado de una sentencia:
  /// Problema Jurídico / Tesis de la Sala / Implicación Práctica.
  static Future<String> generarAnalisisJurisprudencial(
      String ratioDecidendi, String textoCompleto) async {
    await inicializar();
    final ratio = ratioDecidendi.length > 3500
        ? ratioDecidendi.substring(0, 3500)
        : ratioDecidendi;
    final texto =
        textoCompleto.length > 3500 ? textoCompleto.substring(0, 3500) : textoCompleto;
    final prompt = 'Eres un analista de jurisprudencia penal venezolana. Analiza '
        'la sentencia y redacta EXACTAMENTE tres secciones con formato markdown '
        '(títulos con "##"):\n\n'
        '## Problema Jurídico\n[plantea la cuestión jurídica que resuelve la sala]\n\n'
        '## Tesis de la Sala\n[el criterio o ratio decidendi, redactado como máxima]\n\n'
        '## Implicación Práctica\n[qué significa para los operadores jurídicos]\n\n'
        'Fundaméntate SOLO en los textos de abajo. No inventes normas ni citas. '
        'Lenguaje técnico, conciso, en español.\n\n'
        'RATIO DECIDENDI:\n$ratio\n\n'
        'TEXTO:\n$texto';
    try {
      return await _llamarIA(prompt);
    } catch (e) {
      debugPrint('❌ Error generando análisis: $e');
      return '';
    }
  }

  /// Genera un resumen corto de un texto jurídico (sentencias sin resumen).
  static Future<String> generarResumen(String texto) async {
    await inicializar();
    final prompt = 'Resume el siguiente texto jurídico venezolano en 2-3 '
        'oraciones claras y concisas, en español, mencionando el delito y la '
        'decisión si aparecen:\n\n$texto';
    try {
      return await _llamarIA(prompt);
    } catch (e) {
      debugPrint('❌ Error generando resumen: $e');
      return '';
    }
  }

  /// Genera una "Tesis Jurisprudencial" (máxima penal de autoridad, estilo
  /// Rionero) de 3-5 líneas a partir del ratio decidendi.
  static Future<String> generarTesisJurisprudencial(String ratioDecidendi) async {
    await inicializar();
    final texto = ratioDecidendi.length > 3500
        ? ratioDecidendi.substring(0, 3500)
        : ratioDecidendi;
    final prompt = 'Eres un redactor de fichas jurisprudenciales penales '
        'venezolanas. A partir del RATIO DECIDENDI, redacta UNA TESIS '
        'JURISPRUDENCIAL (máxima penal de autoridad) de 3 a 5 líneas, densa y '
        'contundente, sin relleno ni encabezados. Usa fórmulas imperativas o '
        'descriptivas de alto nivel técnico penal, por ejemplo: '
        '"Estaremos en presencia de...", "Las Cortes de Apelaciones deben...", '
        '"La omisión de pronunciamiento sobre...", "No constituye violación '
        'del debido proceso...". No uses comillas, no cites número de sentencia. '
        'Responde SOLO con el párrafo.\n\nRATIO DECIDENDI:\n$texto';
    try {
      return await _llamarIA(prompt);
    } catch (e) {
      debugPrint('❌ Error generando tesis: $e');
      return '';
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
  
  /// Llama a la API de IA (proveedor único: DeepSeek).
  static Future<String> _llamarIA(String prompt) async {
    debugPrint('🤖 Usando modelo: ${_modeloActivo.nombre}');
    return _llamarDeepSeek(prompt, _modeloActivo.modelId);
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
    String? deepseek,
  }) {
    if (deepseek != null) _deepseekKey = deepseek;
    debugPrint('🔑 API Key DeepSeek actualizada');
  }
  
  /// Carga configuración desde Firebase Remote Config
  static Future<void> cargarConfiguracion() async {
    try {
      // Aquí puedes cargar desde Firebase Remote Config
      // final remoteConfig = FirebaseRemoteConfig.instance;
      // await remoteConfig.fetchAndActivate();
      // _deepseekKey = remoteConfig.getString('deepseek_key');
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
  
  /// Verifica si un modelo está disponible (tiene API key DeepSeek).
  static bool isModeloDisponible(AIModel modelo) {
    return _deepseekKey != 'YOUR_DEEPSEEK_API_KEY' && _deepseekKey.isNotEmpty;
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
${contenidoCompleto.length > 3000 ? '${contenidoCompleto.substring(0, 3000)}...' : contenidoCompleto}

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
  deepseek;

  String get nombre {
    switch (this) {
      case ProveedorIA.deepseek:
        return 'DeepSeek';
    }
  }
}

/// Modelos de IA disponibles (solo DeepSeek: proveedor único de Penalex VE)
enum AIModel {
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

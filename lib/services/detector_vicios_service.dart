import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../data/catalogo_vicios_procesales.dart';
import '../models/chat_message.dart';
import 'ulpiano_service.dart';

/// Vicio detectado por la IA (análisis estructurado en JSON).
class VicioIA {
  final String titulo;
  final String norma;
  final String gravedad;
  final String momento;
  final String accion;
  final String evidencia;
  final String confianza; // alta | media | baja

  const VicioIA({
    required this.titulo,
    required this.norma,
    required this.gravedad,
    required this.momento,
    required this.accion,
    required this.evidencia,
    required this.confianza,
  });

  factory VicioIA.fromJson(Map<String, dynamic> j) => VicioIA(
        titulo: (j['titulo'] ?? '').toString(),
        norma: (j['norma'] ?? '').toString(),
        gravedad: (j['gravedad'] ?? '').toString(),
        momento: (j['momento'] ?? '').toString(),
        accion: (j['accion'] ?? '').toString(),
        evidencia: (j['evidencia'] ?? '').toString(),
        confianza: (j['confianza'] ?? 'media').toString().toLowerCase(),
      );
}

/// Resultado del análisis estructurado con IA.
class AnalisisViciosIA {
  final List<VicioIA> vicios;
  final String resumen;
  final String prioridad;
  final String? error;

  const AnalisisViciosIA({
    this.vicios = const [],
    this.resumen = '',
    this.prioridad = '',
    this.error,
  });

  bool get ok => error == null;
}

/// Detector de vicios procesales.
///
/// Tres motores complementarios:
/// 1. **Determinístico**: patrones en el texto cruzados con el catálogo
///    (rápido, offline, sin costo).
/// 2. **IA estructurada**: el modelo devuelve JSON con los vicios
///    clasificados (norma, gravedad, momento, acción, evidencia).
/// 3. **IA + RAG**: análisis profundo con jurisprudencia y normas (Ulpiano).
///
/// El resultado es una HERRAMIENTA DE APOYO: siempre debe verificarse contra
/// el expediente y las fuentes oficiales.
class DetectorViciosService {
  DetectorViciosService._();

  static const String _apiUrl = 'https://api.deepseek.com/v1/chat/completions';

  /// Normaliza el texto: minúsculas y sin acentos, para que los patrones
  /// encuentren variantes ("detención" / "detencion").
  static String _normalizar(String texto) {
    const conAcento = 'áéíóúüñÁÉÍÓÚÜÑ';
    const sinAcento = 'aeiouunAEIOUUN';
    var salida = texto.toLowerCase();
    for (var i = 0; i < conAcento.length; i++) {
      salida = salida.replaceAll(conAcento[i], sinAcento[i].toLowerCase());
    }
    return salida.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Detecta vicios por coincidencia de patrones en el texto.
  static List<VicioDetectado> detectarDeterministico(String texto) {
    final textoNormal = _normalizar(texto);
    if (textoNormal.trim().isEmpty) return const [];

    final resultados = <VicioDetectado>[];

    for (final vicio in CatalogoViciosProcesales.completos) {
      var coincidencias = 0;
      String? evidencia;

      for (final patron in vicio.patrones) {
        final patronNormal = _normalizar(patron);
        final idx = textoNormal.indexOf(patronNormal);
        if (idx >= 0) {
          coincidencias++;
          evidencia ??= _extraerEvidencia(textoNormal, idx, patronNormal.length);
        }
      }

      if (coincidencias > 0) {
        resultados.add(VicioDetectado(
          vicio: vicio,
          evidencia: evidencia ?? '',
          coincidencias: coincidencias,
        ));
      }
    }

    resultados.sort((a, b) {
      final gravedadA =
          a.vicio.gravedad.toLowerCase().contains('absoluta') ? 1 : 0;
      final gravedadB =
          b.vicio.gravedad.toLowerCase().contains('absoluta') ? 1 : 0;
      if (gravedadA != gravedadB) return gravedadB.compareTo(gravedadA);
      return b.coincidencias.compareTo(a.coincidencias);
    });

    return resultados;
  }

  static String _extraerEvidencia(String texto, int idx, int largo) {
    final inicio = (idx - 90).clamp(0, texto.length);
    final fin = (idx + largo + 90).clamp(0, texto.length);
    var fragmento = texto.substring(inicio, fin).trim();
    if (inicio > 0) fragmento = '…$fragmento';
    if (fin < texto.length) fragmento = '$fragmento…';
    return fragmento;
  }

  /// ANÁLISIS ESTRUCTURADO: pide a la IA un JSON con los vicios detectados.
  /// Devuelve vicios clasificados (no texto libre) para mostrarlos en tarjetas.
  static Future<AnalisisViciosIA> analizarConIAEstructurado(
    String texto, {
    String contextoExpediente = '',
  }) async {
    final apiKey = dotenv.env['DEEPSEEK_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      return const AnalisisViciosIA(
        error: 'Falta DEEPSEEK_API_KEY en el archivo .env',
      );
    }
    if (texto.trim().length < 40) {
      return const AnalisisViciosIA(
        error: 'El texto es demasiado corto para analizar.',
      );
    }

    final ctx = contextoExpediente.trim().isEmpty
        ? ''
        : '\nCONTEXTO DEL EXPEDIENTE:\n$contextoExpediente\n';

    const systemPrompt =
        'Eres un experto en derecho procesal penal venezolano que detecta '
        'vicios procesales en autos, actas y sentencias.\n\n'
        'CATALOGO DE REFERENCIA (usa solo normas reales):\n'
        '- COPP arts. 174 (licitud), 175 (nulidades absolutas), 176-178 '
        '(saneamiento y convalidacion), 179 (declaracion), 180 (efectos), '
        '191-193 (inspeccion de personas y vehiculos), 196-198 (allanamiento), '
        '317 (registro del juicio).\n'
        '- CRBV arts. 25, 44, 47 y 49.\n'
        '- Ley Organica sobre el Derecho de las Mujeres a una Vida Libre de '
        'Violencia, arts. 6.2, 13.3, 91 y 99 (careo, notificaciones, '
        'interprete bilingue).\n\n'
        'REGLAS:\n'
        '1. Detecta SOLO vicios que el texto permita sostener; no inventes hechos.\n'
        '2. Cada vicio debe citar la norma exacta y una evidencia textual breve.\n'
        '3. Gravedad: "Nulidad absoluta" o "Nulidad relativa".\n'
        '4. Indica el momento procesal para alegarlo y la accion concreta.\n'
        '5. Confianza: alta, media o baja segun la claridad del texto.\n'
        '6. Responde UNICAMENTE con JSON valido, sin markdown ni texto extra.';

    final userPrompt = '''
Analiza el documento y devuelve este JSON exacto:
{
  "resumen": "resumen breve del documento en 2-3 lineas",
  "vicios": [
    {
      "titulo": "nombre del vicio",
      "norma": "norma exacta (ley y articulo)",
      "gravedad": "Nulidad absoluta o Nulidad relativa",
      "momento": "cuando alegarlo",
      "accion": "accion procesal concreta",
      "evidencia": "cita textual breve del documento",
      "confianza": "alta | media | baja"
    }
  ],
  "prioridad": "que atacar primero y por que"
}
Si no hay vicios, deja "vicios" como lista vacia.

DOCUMENTO:
"""
$texto
"""
$ctx
''';

    try {
      final resp = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': 'deepseek-chat',
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': userPrompt},
              ],
              'temperature': 0.1,
              'max_tokens': 4000,
              'response_format': {'type': 'json_object'},
              'stream': false,
            }),
          )
          .timeout(const Duration(seconds: 150));

      if (resp.statusCode != 200) {
        final cuerpo = resp.body;
        return AnalisisViciosIA(
          error:
              'API ${resp.statusCode}: ${cuerpo.length > 200 ? cuerpo.substring(0, 200) : cuerpo}',
        );
      }

      final data =
          jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      String content = '';
      if (choices != null && choices.isNotEmpty) {
        final primero = choices.first;
        if (primero is Map<String, dynamic>) {
          final msg = primero['message'];
          if (msg is Map<String, dynamic>) {
            content = (msg['content'] ?? '').toString();
          }
        }
      }
      if (content.trim().isEmpty) {
        return const AnalisisViciosIA(error: 'La IA no devolvio contenido.');
      }

      // El modelo puede envolver el JSON en ```json ... ```
      var limpio = content.trim();
      final inicio = limpio.indexOf('{');
      final fin = limpio.lastIndexOf('}');
      if (inicio >= 0 && fin > inicio) {
        limpio = limpio.substring(inicio, fin + 1);
      }

      final parsed = jsonDecode(limpio) as Map<String, dynamic>;
      final lista = (parsed['vicios'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(VicioIA.fromJson)
          .where((v) => v.titulo.isNotEmpty)
          .toList();

      return AnalisisViciosIA(
        vicios: lista,
        resumen: (parsed['resumen'] ?? '').toString(),
        prioridad: (parsed['prioridad'] ?? '').toString(),
      );
    } catch (e) {
      debugPrint('❌ Análisis estructurado IA: $e');
      return AnalisisViciosIA(error: 'No se pudo completar el analisis: $e');
    }
  }

  /// Análisis profundo con Ulpiano (IA + RAG de jurisprudencia y normas).
  static Future<({String analisis, List<MessageSource> fuentes})> analizarConIA(
    String texto, {
    String contextoExpediente = '',
  }) async {
    final bloqueExpediente = contextoExpediente.trim().isEmpty
        ? ''
        : '\nCONTEXTO DEL EXPEDIENTE (causa activa del abogado):\n$contextoExpediente\n';
    final consulta = '''
Actúa como experto en derecho procesal penal venezolano. Analiza el siguiente
documento (auto, acta o sentencia) y DETECTA LOS VICIOS PROCESALES que contiene.

Reglas:
1. Cita SIEMPRE la norma exacta (COPP, CRBV u otra ley) de cada vicio.
2. Indica si el vicio genera nulidad ABSOLUTA o RELATIVA, y el momento procesal
   para alegarlo.
3. Señala la acción procesal concreta que corresponde (nulidad, apelación,
   hábeas corpus, exclusión de prueba, etc.).
4. Distingue los HECHOS del documento de tus INFERENCIAS; no inventes hechos.
5. Si no hay vicio evidente, dilo con claridad.
6. Cierra con una lista priorizada: qué atacar primero y por qué.
$bloqueExpediente
DOCUMENTO A ANALIZAR:
"""
$texto
"""
''';

    try {
      final r = await UlpianoService().generarRespuesta(
        consulta: consulta,
        contextoConversacion: '',
      );
      return (analisis: r.respuesta, fuentes: r.fuentes);
    } catch (e) {
      debugPrint('❌ Detector vicios IA: $e');
      return (
        analisis:
            'No se pudo completar el análisis con IA. Verifica tu conexión y '
            'que la clave de IA esté configurada.\n\nDetalle: $e',
        fuentes: const <MessageSource>[],
      );
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Servicio de VISIÓN de DeepSeek (modelo `deepseek-flash`).
///
/// Permite enviar imágenes (fotos de autos, sentencias, actas o capturas) al
/// modelo multimodal y recibir texto o un análisis jurídico directamente,
/// sin depender del OCR local.
///
/// Documentación oficial: https://api-docs.deepseek.com/guides/vision
/// - Modelo: `deepseek-flash` (soporta Vision)
/// - Formatos: JPEG, PNG, GIF, WebP
/// - Imagen inline en base64 (data URL) o URL pública
/// - Límite por imagen: 32 MiB; request: 48 MiB; hasta 600 imágenes
/// - Máximo ~1024 tokens por imagen
class DeepSeekVisionService {
  DeepSeekVisionService._();

  static const String _baseUrl = 'https://api.deepseek.com/v1';
  static String get _apiKey => dotenv.env['DEEPSEEK_API_KEY'] ?? '';

  /// Modelo multimodal con soporte de visión.
  static const String modeloVision = 'deepseek-flash';

  static const Duration _timeout = Duration(seconds: 180);

  static bool get disponible => _apiKey.isNotEmpty;

  /// Codifica una imagen local como data URL base64.
  ///
  /// Detecta el MIME por la extensión; si no se reconoce, usa JPEG.
  static Future<String?> _dataUrl(String ruta) async {
    try {
      final archivo = File(ruta);
      if (!await archivo.exists()) return null;
      final bytes = await archivo.readAsBytes();
      if (bytes.isEmpty) return null;
      final ext = ruta.split('.').last.toLowerCase();
      final mime = switch (ext) {
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
      return 'data:$mime;base64,${base64Encode(bytes)}';
    } catch (e) {
      debugPrint('⚠️ Vision: no se pudo leer $ruta: $e');
      return null;
    }
  }

  /// Envía una o varias imágenes con una instrucción y devuelve el texto.
  ///
  /// [rutasImagenes] rutas locales de las imágenes.
  /// [instruccion] qué debe hacer el modelo con ellas.
  /// [systemPrompt] rol del asistente (opcional).
  /// [detalle] `low` (más rápido/barato) u `original` (máxima precisión).
  static Future<String> analizarImagenes({
    required List<String> rutasImagenes,
    required String instruccion,
    String? systemPrompt,
    String detalle = 'original',
    double temperatura = 0.2,
  }) async {
    if (_apiKey.isEmpty) {
      return '⚠️ Falta la clave DEEPSEEK_API_KEY. Configúrala en el archivo .env.';
    }
    if (rutasImagenes.isEmpty) {
      return '⚠️ No se recibieron imágenes.';
    }

    final bloques = <Map<String, dynamic>>[
      {'type': 'text', 'text': instruccion},
    ];

    for (final ruta in rutasImagenes) {
      final dataUrl = await _dataUrl(ruta);
      if (dataUrl == null) continue;
      bloques.add({
        'type': 'image_url',
        'image_url': {'url': dataUrl, 'detail': detalle},
      });
    }

    if (bloques.length <= 1) {
      return '⚠️ No se pudo leer ninguna imagen válida (JPEG, PNG, GIF o WebP).';
    }

    final mensajes = <Map<String, dynamic>>[
      if (systemPrompt != null && systemPrompt.trim().isNotEmpty)
        {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': bloques},
    ];

    try {
      final resp = await http
          .post(
            Uri.parse('$_baseUrl/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': modeloVision,
              'messages': mensajes,
              'temperature': temperatura,
              'stream': false,
            }),
          )
          .timeout(_timeout);

      if (resp.statusCode != 200) {
        debugPrint('❌ Vision API ${resp.statusCode}: ${resp.body}');
        return '❌ Error de la API de visión (${resp.statusCode}). '
            'Intenta de nuevo en unos segundos.';
      }

      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        return '❌ La API no devolvió contenido.';
      }
      final msg = choices.first['message'] as Map<String, dynamic>?;
      final contenido = msg?['content'];
      if (contenido is String && contenido.trim().isNotEmpty) {
        return contenido.trim();
      }
      return '❌ La API devolvió una respuesta vacía.';
    } catch (e) {
      debugPrint('❌ Vision error: $e');
      return '❌ No se pudo conectar con el modelo de visión.\nDetalle: $e';
    }
  }

  /// Transcribe el texto de una imagen de documento (acta, auto, sentencia).
  static Future<String> transcribirDocumento({
    required List<String> rutasImagenes,
  }) {
    return analizarImagenes(
      rutasImagenes: rutasImagenes,
      systemPrompt:
          'Eres un experto en transcripción de documentos jurídicos '
          'venezolanos. Transcribe el texto de forma FIEL, sin inventar ni '
          'resumir. Conserva números, fechas, nombres y artículos tal como '
          'aparecen. Si una parte es ilegible, indícalo con [ilegible].',
      instruccion:
          'Transcribe el texto completo de este documento jurídico. '
          'Devuélvelo como texto plano, sin comentarios añadidos.',
    );
  }

  /// Analiza una imagen de documento y detecta vicios procesales.
  static Future<String> analizarViciosEnImagen({
    required List<String> rutasImagenes,
    String contextoExpediente = '',
  }) {
    final ctx = contextoExpediente.trim().isEmpty
        ? ''
        : '\nCONTEXTO DEL EXPEDIENTE:\n$contextoExpediente\n';
    return analizarImagenes(
      rutasImagenes: rutasImagenes,
      systemPrompt:
          'Eres experto en derecho procesal penal venezolano. Analizas '
          'documentos (autos, actas, sentencias) y detectas vicios procesales '
          'con su norma exacta (COPP, CRBV u otra ley), su gravedad (nulidad '
          'absoluta o relativa), el momento para alegarla y la acción procesal. '
          'No inventes hechos: distingue lo que dice el documento de tus '
          'inferencias. Si no hay vicio evidente, dilo.',
      instruccion:
          'Lee este documento y DETECTA LOS VICIOS PROCESALES que contiene. '
          'Estructura la respuesta: 1) resumen breve del documento; 2) lista '
          'de vicios con norma, gravedad y acción; 3) prioridad de ataque.'
          '$ctx',
    );
  }
}

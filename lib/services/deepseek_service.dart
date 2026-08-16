import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Servicio para integración con DeepSeek API
/// Proporciona generación de documentos legales usando IA
class DeepSeekService {
  static const String _baseUrl = 'https://api.deepseek.com/v1';
  static String get _apiKey => dotenv.env['DEEPSEEK_API_KEY'] ?? 'sk-0a9f652b7fd549db937ca806959ab6c1';
  
  /// Timeout para peticiones HTTP (2 minutos para documentos largos)
  static const Duration _timeout = Duration(seconds: 120);
  
  /// Modelos disponibles de DeepSeek
  static const String modelChat = 'deepseek-chat';
  static const String modelCoder = 'deepseek-coder';
  
  /// Genera un documento legal usando DeepSeek
  /// 
  /// [systemPrompt] - Contexto del sistema (rol del asistente)
  /// [userPrompt] - Instrucciones del usuario
  /// [model] - Modelo a usar (por defecto: deepseek-chat)
  /// [temperature] - Creatividad (0.0-2.0, por defecto: 0.7)
  /// [maxTokens] - Límite de tokens en respuesta (por defecto: 4000)
  static Future<String> generateDocument({
    required String systemPrompt,
    required String userPrompt,
    String model = modelChat,
    double temperature = 0.7,
    int maxTokens = 4000,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': systemPrompt,
            },
            {
              'role': 'user',
              'content': userPrompt,
            },
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
          'stream': false,
        }),
      ).timeout(
        _timeout,
        onTimeout: () {
          throw Exception('Timeout: La generación del documento tomó demasiado tiempo. Intenta con un documento más corto.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          final content = data['choices'][0]['message']['content'] as String;
          
          // Log de uso de tokens (solo en debug)
          if (kDebugMode) {
            final usage = data['usage'];
            debugPrint('🤖 DeepSeek - Tokens usados:');
            debugPrint('   Prompt: ${usage['prompt_tokens']}');
            debugPrint('   Completación: ${usage['completion_tokens']}');
            debugPrint('   Total: ${usage['total_tokens']}');
          }
          
          return content.trim();
        } else {
          throw Exception('Respuesta vacía de DeepSeek');
        }
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Error desconocido';
        throw Exception('Error DeepSeek (${response.statusCode}): $errorMessage');
      }
    } on http.ClientException catch (e) {
      debugPrint('❌ Error de conexión DeepSeek: $e');
      throw Exception('Error de conexión: Verifica tu conexión a internet. Si el problema persiste, el servicio podría estar temporalmente no disponible.');
    } catch (e) {
      debugPrint('❌ Error en DeepSeek: $e');
      rethrow;
    }
  }

  /// Chat simple con DeepSeek (sin sistema)
  static Future<String> chat({
    required String message,
    List<Map<String, String>>? conversationHistory,
    String model = modelChat,
    double temperature = 0.7,
    int maxTokens = 2000,
  }) async {
    try {
      final messages = <Map<String, String>>[];
      
      // Agregar historial si existe
      if (conversationHistory != null) {
        messages.addAll(conversationHistory);
      }
      
      // Agregar mensaje actual
      messages.add({'role': 'user', 'content': message});

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
          'stream': false,
        }),
      ).timeout(
        _timeout,
        onTimeout: () {
          throw Exception('Timeout: La solicitud tomó demasiado tiempo.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'] as String;
        } else {
          throw Exception('Respuesta vacía');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Error ${response.statusCode}: ${errorData['error']?['message']}');
      }
    } on http.ClientException catch (e) {
      debugPrint('❌ Error de conexión en chat: $e');
      throw Exception('Error de conexión: Verifica tu conexión a internet.');
    } catch (e) {
      debugPrint('❌ Error en chat: $e');
      rethrow;
    }
  }

  /// Streaming de respuestas (para mostrar palabra por palabra)
  static Stream<String> generateDocumentStream({
    required String systemPrompt,
    required String userPrompt,
    String model = modelChat,
    double temperature = 0.7,
    int maxTokens = 4000,
  }) async* {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/chat/completions'),
      );
      
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      });
      
      request.body = jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': temperature,
        'max_tokens': maxTokens,
        'stream': true,
      });

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
          // Procesar cada línea del stream
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final jsonData = line.substring(6).trim();
              if (jsonData == '[DONE]') continue;
              
              try {
                final data = jsonDecode(jsonData);
                final content = data['choices']?[0]?['delta']?['content'];
                if (content != null) {
                  yield content as String;
                }
              } catch (e) {
                // Ignorar líneas que no son JSON válido
                continue;
              }
            }
          }
        }
      } else {
        throw Exception('Error ${streamedResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en streaming: $e');
      rethrow;
    }
  }

  /// Verifica la conexión con DeepSeek
  static Future<bool> testConnection() async {
    try {
      final response = await chat(
        message: 'Hola',
        maxTokens: 10,
      );
      return response.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Test de conexión falló: $e');
      return false;
    }
  }
}

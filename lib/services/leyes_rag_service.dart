/// Servicio RAG (Retrieval-Augmented Generation) para el Repositorio de Leyes.
///
/// Recupera artículos relevantes de las leyes (desde Supabase Storage) y los
/// usa como contexto para responder consultas legales con DeepSeek, citando
/// la fuente normativa (Ley, Título, Capítulo y Artículo).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/ley_estructurada.dart';
import 'deepseek_service.dart';
import 'leyes_repositorio_service.dart';

class LeyesRAGService {
  LeyesRAGService._();
  static final LeyesRAGService _instance = LeyesRAGService._();
  factory LeyesRAGService() => _instance;

  final LeyesRepositorioService _repo = LeyesRepositorioService();

  /// URL del worker penalex-auth-bridge (misma que usa el puente de identidad).
  static String get _workerUrl => dotenv.env['BRIDGE_URL'] ?? '';

  /// Búsqueda semántica de artículos en Qdrant (colección articulos_vectores)
  /// vía el worker. Devuelve [] si no hay worker configurado o falla.
  Future<List<ResultadoLey>> _buscarSemantica(String consulta,
      {int limite = 6}) async {
    final url = _workerUrl;
    if (url.isEmpty) return [];
    try {
      final res = await http
          .post(
            Uri.parse('$url/buscar/semantica'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'query': consulta,
              'categoria': 'articulo',
              'limite': limite,
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final resultados = (body['resultados'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      return resultados.map((r) {
        final reg = RegistroArticulo(
          slug: (r['ley'] as String? ?? '').toLowerCase().replaceAll(' ', '-'),
          leyNombre: r['ley'] as String? ?? '',
          titulo: r['titulo'] as String?,
          capitulo: r['capitulo'] as String?,
          identificador: r['articulo'] as String? ?? '',
          tipoNorma: 'Artículo',
          encabezado: r['encabezado'] as String?,
          texto: r['texto'] as String? ?? '',
        );
        return ResultadoLey(
          registro: reg,
          puntaje: (r['score'] as num? ?? 0).toDouble(),
          extracto: (r['encabezado'] as String? ?? ''),
        );
      }).toList();
    } catch (e) {
      debugPrint('⚠️ semántica leyes falló: $e');
      return [];
    }
  }

  /// Recupera artículos relevantes a [consulta] (parte "Retrieval" del RAG).
  ///
  /// Semántica Qdrant primero (artículos_vectores, bge-m3); si no hay worker
  /// o no devuelve resultados, fallback al scoring de keywords local.
  Future<List<ResultadoLey>> buscarRelevantes(
    String consulta, {
    int limite = 6,
  }) async {
    if (consulta.trim().isEmpty) return [];
    try {
      final sem = await _buscarSemantica(consulta, limite: limite);
      if (sem.isNotEmpty) {
        debugPrint('⚖️ RAG leyes semántica: ${sem.length} artículos');
        return sem;
      }
      return await _repo.buscar(consulta, limite: limite);
    } catch (e) {
      debugPrint('❌ LeyesRAGService.buscarRelevantes: $e');
      return [];
    }
  }

  /// Formatea los artículos recuperados como bloque de contexto para el prompt.
  String construirContexto(List<ResultadoLey> resultados) {
    if (resultados.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < resultados.length; i++) {
      final r = resultados[i];
      buffer.writeln('FUENTE NORMATIVA ${i + 1}:');
      buffer.writeln('- Ley: ${r.registro.leyNombre}');
      if (r.registro.titulo != null) {
        buffer.writeln('- Título: ${r.registro.titulo}');
      }
      if (r.registro.capitulo != null) {
        buffer.writeln('- Capítulo: ${r.registro.capitulo}');
      }
      if (r.registro.encabezado != null) {
        buffer.writeln(
            '- ${r.registro.tipoNorma} ${r.registro.identificador}: ${r.registro.encabezado}');
      }
      buffer.writeln('- Texto: ${r.registro.texto}');
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  /// Responde una consulta usando el contexto normativo recuperado.
  ///
  /// Si se pasa [contextoAdicional] (p. ej. el texto de un artículo ya
  /// seleccionado), se antepone a las fuentes recuperadas.
  Future<RespuestaLey> responder(String consulta,
      {String? contextoAdicional}) async {
    final resultados = await buscarRelevantes(consulta);
    var contexto = construirContexto(resultados);
    if (contextoAdicional != null && contextoAdicional.trim().isNotEmpty) {
      final extra = 'CONTEXTO ADICIONAL (artículo consultado):\n'
          '$contextoAdicional\n';
      contexto = contexto.isEmpty ? extra : '$extra\n$contexto';
    }

    if (contexto.isEmpty) {
      return RespuestaLey(
        respuesta: 'No encontré artículos relevantes para tu consulta en el '
            'repositorio de leyes. Intenta con otros términos.',
        fuentes: const [],
      );
    }

    const systemPrompt = 'Eres un asistente jurídico especializado en derecho '
        'penal venezolano. Responde ÚNICAMENTE con base en las FUENTES '
        'NORMATIVAS que se te proporcionan. Cita siempre el artículo y la ley '
        'correspondiente (ej. "Artículo 406 del Código Penal"). Si la '
        'información no está en las fuentes, dilo claramente.\n'
        'FORMATO DE RESPUESTA: usa Markdown. Usa "##" para subtítulos, '
        '"**negritas**" para conceptos y artículos clave, y listas "-" cuando '
        'enumeres. Explica el artículo en lenguaje claro, indica la pena, '
        'requisito o consecuencia cuando aplique, y cita textualmente el '
        'artículo relevante. No inventes normas ni jurisprudencia.';

    final userPrompt = 'CONSULTA DEL USUARIO: $consulta\n\n'
        'FUENTES NORMATIVAS DISPONIBLES:\n$contexto';

    try {
      final respuesta = await DeepSeekService.generateDocument(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        temperature: 0.3,
        maxTokens: 1200,
      );
      return RespuestaLey(respuesta: respuesta, fuentes: resultados);
    } catch (e) {
      debugPrint('❌ LeyesRAGService.responder: $e');
      return RespuestaLey(
        respuesta: 'No fue posible generar la respuesta en este momento. '
            'Estas son las fuentes más relevantes para tu consulta.',
        fuentes: resultados,
      );
    }
  }
}

class RespuestaLey {
  final String respuesta;
  final List<ResultadoLey> fuentes;

  const RespuestaLey({required this.respuesta, required this.fuentes});
}

/// Referencia corta de un artículo (para citas en la UI).
String referenciaCorta(RegistroArticulo reg) {
  final partes = <String>[
    if (reg.tipoNorma == 'Artículo') 'Artículo ${reg.identificador}',
    reg.leyNombre,
  ];
  return partes.join(' · ');
}

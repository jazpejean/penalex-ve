/// Servicio RAG (Retrieval-Augmented Generation).
///
/// Recupera jurisprudencia REAL del TSJ desde Supabase y la convierte en:
/// - Contexto para prompts de IA (chat, redactor, comparador).
/// - Fuentes citables ([MessageSource]) para el chat legal.
/// - Listas de sentencias para el módulo de "relacionadas" en leyes.
library;

import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/sentencia_model.dart';
import 'jurisprudencia_service.dart';

class RAGService {
  RAGService._();

  static final JurisprudenciaService _jurisprudenciaService =
      JurisprudenciaService();

  /// Busca jurisprudencias reales del TSJ relevantes a una consulta en Supabase.
  ///
  /// Internamente usa búsqueda semántica (DeepSeek) + fulltext + fallback `ilike`.
  /// Nunca lanza excepción: ante cualquier error devuelve una lista vacía.
  static Future<List<SentenciaModel>> buscarJurisprudenciaRelevante({
    required String consulta,
    int limit = 5,
    String? salaFiltro,
  }) async {
    if (consulta.trim().isEmpty) return [];

    try {
      final sentencias = await _jurisprudenciaService.buscarEnSupabase(
        textoBusqueda: consulta.trim(),
        tipoFiltro: 'sentencias',
        salaFiltro: salaFiltro,
        limit: limit,
      );

      // Descartar resultados sin número de sentencia (poco útiles como cita).
      return sentencias
          .where((s) => s.numeroSentencia.isNotEmpty && s.numeroSentencia != 'null')
          .take(limit)
          .toList();
    } catch (e) {
      debugPrint('❌ RAGService.buscarJurisprudenciaRelevante: $e');
      return [];
    }
  }

  /// Formatea una lista de sentencias como bloque de contexto para prompts.
  static String construirContextoJurisprudencial(List<SentenciaModel> sentencias) {
    if (sentencias.isEmpty) return '';

    final buffer = StringBuffer();
    for (var i = 0; i < sentencias.length; i++) {
      buffer.writeln(_formatearSentencia(sentencias[i], i + 1));
    }
    return buffer.toString().trim();
  }

  /// Convierte sentencias reales en fuentes citables para el chat.
  static List<MessageSource> construirFuentes(List<SentenciaModel> sentencias) {
    return sentencias.map((s) {
      final contenido = _contenidoUtil(s);
      final url = _urlUtil(s);
      return MessageSource(
        type: SourceType.jurisprudencia,
        title: 'Sentencia Nº ${s.numeroSentencia}',
        reference:
            '${s.sala} · Ponente: ${s.ponente} · ${s.fechaSentencia}',
        url: url,
        excerpt: contenido.length > 300
            ? '${contenido.substring(0, 300)}...'
            : contenido,
      );
    }).toList();
  }

  /// Conveniencia: recupera sentencias + contexto + fuentes en una sola llamada.
  static Future<
      ({
        List<SentenciaModel> sentencias,
        String contexto,
        List<MessageSource> fuentes,
      })> obtenerContextoYFuentes({
    required String consulta,
    int limit = 5,
    String? salaFiltro,
  }) async {
    final sentencias = await buscarJurisprudenciaRelevante(
      consulta: consulta,
      limit: limit,
      salaFiltro: salaFiltro,
    );
    return (
      sentencias: sentencias,
      contexto: construirContextoJurisprudencial(sentencias),
      fuentes: construirFuentes(sentencias),
    );
  }

  /// Texto corto y útil de una sentencia (resumen IA > extracto > decisión).
  static String _contenidoUtil(SentenciaModel s) {
    final criterio = s.ratioDecidendi.trim();
    if (criterio.isNotEmpty && criterio != 'null') {
      return criterio.length > 700 ? criterio.substring(0, 700) : criterio;
    }
    final resumen = s.resumen.trim();
    if (resumen.isNotEmpty && resumen != 'null') {
      return resumen.length > 700 ? resumen.substring(0, 700) : resumen;
    }
    final extracto = s.extracto.trim();
    if (extracto.isNotEmpty && extracto != 'null') {
      return extracto.length > 700 ? extracto.substring(0, 700) : extracto;
    }
    return s.delito.trim();
  }

  /// URL para abrir la sentencia, priorizando las copias propias en R2
  /// (estables) antes que el servidor del TSJ (que suele tener fallas).
  static String? _urlUtil(SentenciaModel s) {
    final url = s.urlParaVer;
    return url.isEmpty ? null : url;
  }

  static String _formatearSentencia(SentenciaModel s, int indice) {
    final criterio = _limpio(s.ratioDecidendi);
    final resumen = _limpio(s.resumen);
    final extracto = _limpio(s.extracto);

    final buffer = StringBuffer()
      ..writeln('JURISPRUDENCIA $indice:')
      ..writeln('- Nº de sentencia: ${s.numeroSentencia}')
      ..writeln('- Sala: ${s.sala}')
      ..writeln('- Ponente: ${s.ponente}')
      ..writeln('- Fecha: ${s.fechaSentencia}')
      ..writeln('- Delito/Tema: ${s.delito}');

    if (criterio.isNotEmpty) {
      final corto = criterio.length > 900 ? '${criterio.substring(0, 900)}...' : criterio;
      buffer.writeln('- CRITERIO DE LA SALA (ratio decidendi): $corto');
    } else if (resumen.isNotEmpty) {
      final corto = resumen.length > 900 ? '${resumen.substring(0, 900)}...' : resumen;
      buffer.writeln('- CRITERIO DE LA SALA: $corto');
    }
    if (extracto.isNotEmpty) {
      final cita = extracto.length > 700 ? '${extracto.substring(0, 700)}...' : extracto;
      buffer.writeln('- CITA TEXTUAL: "$cita"');
    }

    return buffer.toString();
  }

  static String _limpio(String v) {
    final t = v.trim();
    return (t.isEmpty || t == 'null') ? '' : t;
  }
}

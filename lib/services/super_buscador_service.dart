import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/doctrina_academica_model.dart';
import '../models/sentencia_model.dart';
import 'jurisprudencia_service.dart';

/// Resultado de una página del Super Buscador.
class ResultadoSuperBusqueda {
  final List<SentenciaModel> sentencias;
  final List<DoctrinaAcademicaModel> doctrinas;
  final bool usoSemantica;
  final bool tieneMas;

  const ResultadoSuperBusqueda({
    this.sentencias = const [],
    this.doctrinas = const [],
    this.usoSemantica = false,
    this.tieneMas = false,
  });
}

/// Super Buscador de Penalex: búsqueda híbrida sobre 4 categorías.
///
/// Fusiona con RRF (Reciprocal Rank Fusion, k=60) dos fuentes:
///   1. Full-Text Search en Supabase (`search_vector`, español).
///   2. Búsqueda semántica en Qdrant Cloud vía el worker
///      `penalex-auth-bridge` (POST /buscar/semantica) — las credenciales
///      de Qdrant y de Workers AI viven SOLO en el worker, nunca en el APK.
///
/// Si el FTS no da resultados pero la semántica sí, se devuelven los
/// resultados semánticos con `usoSemantica = true` para que la UI muestre
/// la etiqueta "Resultados por búsqueda semántica".
class SuperBuscadorService {
  SuperBuscadorService({JurisprudenciaService? jurisprudencia})
      : _jurisprudencia = jurisprudencia ?? JurisprudenciaService();

  final JurisprudenciaService _jurisprudencia;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// URL del worker penalex-auth-bridge (misma que usa el puente de identidad).
  static String get _workerUrl => dotenv.env['BRIDGE_URL'] ?? '';

  /// Traduce el nombre largo de sala (lo que guarda la UI) al código corto
  /// que usa Qdrant en el payload (`scp`, `scon`, …).
  static String? _codigoSala(String? sala) {
    if (sala == null || sala.isEmpty) return null;
    final s = sala.toLowerCase();
    const mapa = {
      'sala de casación penal': 'scp',
      'sala constitucional': 'scon',
      'sala de casación social': 'scs',
      'sala de casación civil': 'scc',
      'sala político administrativa': 'spa',
      'sala electoral': 'se',
      'sala plena': 'sp',
    };
    for (final entry in mapa.entries) {
      if (s.contains(entry.key)) return entry.value;
    }
    // Si ya viene como código corto (scp, scon, …), usarlo tal cual.
    if (RegExp(r'^[a-z]{1,4}$').hasMatch(s)) return s;
    return null;
  }

  /// Categorías del Super Buscador (mismas que la UI).
  static const List<String> categorias = [
    'Sentencias',
    'Jurisprudencias',
    'Resoluciones',
    'Doctrinas',
  ];

  /// Busca una página con la búsqueda híbrida (RRF).
  ///
  /// [categoria]: 'Sentencias' | 'Jurisprudencias' | 'Resoluciones' | 'Doctrinas'
  /// [offset]:    inicio de la página (0 para la primera).
  /// [limit]:     tamaño de página (default 20, como la especificación).
  Future<ResultadoSuperBusqueda> buscar({
    String texto = '',
    required String categoria,
    String? sala,
    int? anio,
    bool soloTextoCompleto = false,
    int offset = 0,
    int limit = 20,
  }) async {
    final textoLimpio = texto.trim();
    final esDoctrina = categoria == 'Doctrinas';

    // 1) FTS en Supabase (paginado). Para doctrinas se consulta la tabla
    //    doctrinas_academicas (autor/obra/parrafo_evidencia).
    final fts = await _buscarFts(
      texto: textoLimpio,
      categoria: categoria,
      sala: sala,
      anio: anio,
      soloTextoCompleto: soloTextoCompleto,
      offset: offset,
      limit: limit,
    );

    // 2) Búsqueda semántica en Qdrant (solo si hay texto).
    final semantica = textoLimpio.isEmpty
        ? <Map<String, dynamic>>[]
        : await _buscarSemantica(
            texto: textoLimpio,
            esDoctrina: esDoctrina,
            sala: _codigoSala(sala),
            anio: anio,
            limite: 40,
          );

    // 3) RRF: fusionar ambas fuentes (dedupe por documento_id).
    final fusion = _rrf(fts, semantica, esDoctrina: esDoctrina);

    // 4) Fallback semántico: si el FTS no dio nada pero Qdrant sí,
    //    devolver los resultados semánticos con la etiqueta.
    if (fusion.isEmpty && semantica.isNotEmpty) {
      final porSemantica = await _cargarPorSemantica(
        semantica,
        esDoctrina: esDoctrina,
        limit: limit,
      );
      return ResultadoSuperBusqueda(
        sentencias: esDoctrina ? const [] : porSemantica.sentencias,
        doctrinas: esDoctrina ? porSemantica.doctrinas : const [],
        usoSemantica: true,
        tieneMas: semantica.length > limit,
      );
    }

    return ResultadoSuperBusqueda(
      sentencias: esDoctrina ? const [] : fusion.sentencias,
      doctrinas: esDoctrina ? fusion.doctrinas : const [],
      usoSemantica: false,
      tieneMas: fusion.tieneMas,
    );
  }

  // -------------------------------------------------------------------------
  // Full-Text Search (Supabase)
  // -------------------------------------------------------------------------

  Future<({List<SentenciaModel> sentencias, List<DoctrinaAcademicaModel> doctrinas})>
      _buscarFts({
    required String texto,
    required String categoria,
    String? sala,
    int? anio,
    required bool soloTextoCompleto,
    required int offset,
    required int limit,
  }) async {
    try {
      if (categoria == 'Doctrinas') {
        var query = _supabase.from('doctrinas_academicas').select();

        if (texto.isNotEmpty) {
          final terminos = texto.split(RegExp(r'\s+')).where((t) => t.length > 2);
          final tsQuery = terminos.join(' OR ');
          if (tsQuery.isNotEmpty) {
            query = query.textSearch(
              'search_vector',
              tsQuery,
              config: 'spanish',
              type: TextSearchType.websearch,
            );
          }
        }

        final data = (await query
                .order('created_at', ascending: false)
                .range(offset, offset + limit - 1))
            as List<dynamic>;
        final doctrinas = <DoctrinaAcademicaModel>[
          for (final d in data) DoctrinaAcademicaModel.fromSupabase(d as Map<String, dynamic>),
        ];
        return (sentencias: <SentenciaModel>[], doctrinas: doctrinas);
      }

      // Categorías de sentencias: reutiliza la búsqueda FTS existente
      // (detección de referencia exacta, expansión semántica, ranking).
      String tipoFiltro = 'sentencias';
      if (categoria == 'Jurisprudencias') {
        tipoFiltro = 'jurisprudencias';
      } else if (categoria == 'Resoluciones') {
        tipoFiltro = 'resoluciones';
      }

      var sentencias = await _jurisprudencia.buscarEnSupabase(
        textoBusqueda: texto.isEmpty ? null : texto,
        tipoFiltro: tipoFiltro,
        salaFiltro: sala,
        anioFiltro: anio,
        limit: limit,
        offset: offset,
      );

      // "Solo texto completo": quedan las que tienen copia en R2 (txt o html).
      if (soloTextoCompleto) {
        sentencias = sentencias
            .where((s) =>
                s.urlTXT.isNotEmpty ||
                s.urlHTML.isNotEmpty ||
                s.contenidoCompleto.isNotEmpty)
            .toList();
      }

      return (sentencias: sentencias, doctrinas: <DoctrinaAcademicaModel>[]);
    } catch (e) {
      debugPrint('❌ SuperBuscador FTS: $e');
      return (
        sentencias: <SentenciaModel>[],
        doctrinas: <DoctrinaAcademicaModel>[],
      );
    }
  }

  // -------------------------------------------------------------------------
  // Semántica (Qdrant vía worker)
  // -------------------------------------------------------------------------

  /// Consulta el worker: embedding bge-m3 + top-k de Qdrant.
  Future<List<Map<String, dynamic>>> _buscarSemantica({
    required String texto,
    required bool esDoctrina,
    String? sala,
    int? anio,
    int limite = 40,
  }) async {
    final url = _workerUrl;
    if (url.isEmpty) {
      debugPrint('⚠️ BRIDGE_URL no configurada; semántica desactivada');
      return [];
    }
    try {
      final res = await http
          .post(
            Uri.parse('$url/buscar/semantica'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'query': texto,
              'categoria': esDoctrina ? 'doctrina' : 'sentencia',
              if (sala != null) 'sala': sala,
              if (anio != null) 'anio': anio,
              'limite': limite,
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) {
        debugPrint('⚠️ semántica HTTP ${res.statusCode}');
        return [];
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (body['resultados'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      debugPrint('⚠️ semántica falló: $e');
      return [];
    }
  }

  /// Cuando el FTS no dio nada, traer los documentos que Qdrant sí encontró.
  Future<ResultadoSuperBusqueda> _cargarPorSemantica(
    List<Map<String, dynamic>> semantica, {
    required bool esDoctrina,
    required int limit,
  }) async {
    try {
      if (esDoctrina) {
        final ids = semantica
            .map((s) => s['doctrina_id']?.toString())
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .take(limit)
            .toList();
        if (ids.isEmpty) return const ResultadoSuperBusqueda();
        final data = (await _supabase
                .from('doctrinas_academicas')
                .select()
                .inFilter('id', ids))
            as List<dynamic>;
        final mapa = {
          for (final d in data.cast<Map<String, dynamic>>())
            d['id']?.toString(): d,
        };
        // Mantener el orden de relevancia que dio Qdrant.
        final doctrinas = ids
            .map((id) => mapa[id])
            .whereType<Map<String, dynamic>>()
            .map(DoctrinaAcademicaModel.fromSupabase)
            .toList();
        return ResultadoSuperBusqueda(
          doctrinas: doctrinas,
          usoSemantica: true,
          tieneMas: semantica.length > limit,
        );
      }

      final ids = semantica
          .map((s) => s['documento_id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .take(limit)
          .toList();
      if (ids.isEmpty) return const ResultadoSuperBusqueda();
      final data = (await _supabase
              .from('sentencias')
              .select()
              .inFilter('id', ids))
          as List<dynamic>;
      final mapa = {
        for (final d in data.cast<Map<String, dynamic>>()) d['id']?.toString(): d,
      };
      final sentencias = ids
          .map((id) => mapa[id])
          .whereType<Map<String, dynamic>>()
          .map(SentenciaModel.fromSupabase)
          .toList();
      return ResultadoSuperBusqueda(
        sentencias: sentencias,
        usoSemantica: true,
        tieneMas: semantica.length > limit,
      );
    } catch (e) {
      debugPrint('❌ cargarPorSemantica: $e');
      return const ResultadoSuperBusqueda();
    }
  }

  // -------------------------------------------------------------------------
  // RRF (Reciprocal Rank Fusion)
  // -------------------------------------------------------------------------

  static const double _k = 60;

  /// Fusiona FTS + semántica por documento_id con RRF.
  ///
  /// [fts] y [semantica] vienen ordenados por relevancia (rank 1 = mejor).
  /// `tieneMas` se conserva del FTS: si la página FTS vino completa, puede
  /// haber más páginas (lazy load sigue paginando FTS).
  ({List<SentenciaModel> sentencias, List<DoctrinaAcademicaModel> doctrinas, bool tieneMas})
      _rrf(
    ({List<SentenciaModel> sentencias, List<DoctrinaAcademicaModel> doctrinas}) fts,
    List<Map<String, dynamic>> semantica, {
    required bool esDoctrina,
  }) {
    // Si no hay semántica (o no hay texto), devolver el FTS tal cual.
    if (semantica.isEmpty) {
      return (
        sentencias: fts.sentencias,
        doctrinas: fts.doctrinas,
        tieneMas: fts.sentencias.length == 20 || fts.doctrinas.length == 20,
      );
    }

    final scores = <String, double>{};
    final ordenSemantica = <String>[];

    // Aporte de Qdrant: 1/(k + rank).
    for (var i = 0; i < semantica.length; i++) {
      final id = esDoctrina
          ? (semantica[i]['doctrina_id']?.toString() ?? '')
          : (semantica[i]['documento_id']?.toString() ?? '');
      if (id.isEmpty) continue;
      scores[id] = (scores[id] ?? 0) + 1 / (_k + i + 1);
      ordenSemantica.add(id);
    }

    // Aporte del FTS (ya ordenado por relevancia dentro de su página).
    final ordenFts = <String>[];
    for (var i = 0; i < fts.sentencias.length; i++) {
      final id = fts.sentencias[i].id;
      scores[id] = (scores[id] ?? 0) + 1 / (_k + i + 1);
      ordenFts.add(id);
    }

    // Fusionar: primero por score RRF, luego por posición en semántica,
    // luego por posición en FTS (orden estable).
    final idsOrdenados = (ordenSemantica + ordenFts).toSet().toList()
      ..sort((a, b) {
        final sa = scores[a] ?? 0;
        final sb = scores[b] ?? 0;
        if (sa != sb) return sb.compareTo(sa);
        return ordenSemantica.indexOf(a) - ordenSemantica.indexOf(b);
      });

    if (esDoctrina) {
      final mapa = {for (final d in fts.doctrinas) d.id: d};
      final doctrinas = idsOrdenados
          .map((id) => mapa[id])
          .whereType<DoctrinaAcademicaModel>()
          .toList();
      return (
        sentencias: const [],
        doctrinas: doctrinas,
        tieneMas: fts.doctrinas.length == 20,
      );
    }

    final mapa = {for (final s in fts.sentencias) s.id: s};
    final sentencias = idsOrdenados
        .map((id) => mapa[id])
        .whereType<SentenciaModel>()
        .toList();
    return (
      sentencias: sentencias,
      doctrinas: const [],
      tieneMas: fts.sentencias.length == 20,
    );
  }
}
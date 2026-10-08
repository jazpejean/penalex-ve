/// Servicio para comparar estrategias legales con IA.
/// Persistencia en Supabase; fundamentación con los repositorios completos de
/// leyes (COPP vigente) y jurisprudencia (TSJ).
library;

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message.dart';
import '../models/estrategia_legal.dart';
import 'ai_service.dart';
import 'ai_analytics_service.dart';
import 'rag_service.dart';
import 'leyes_repositorio_service.dart';

class ComparadorService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static final _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  static String? get _currentUserId => _firebaseAuth.currentUser?.uid;

  /// Genera múltiples estrategias legales para un caso usando IA + Tracking.
  Future<List<EstrategiaLegal>> generarEstrategiasParaCaso({
    required String casoId,
    required String descripcionCaso,
    required List<String> delitos,
    required String etapaProcesal,
    int cantidadEstrategias = 3,
  }) async {
    return await AIAnalyticsService.trackOperation(
      toolName: AIToolName.comparadorEstrategias,
      actionType: AIActionType.comparison,
      metadata: {
        'caso_id': casoId,
        'delitos_count': delitos.length,
        'etapa_procesal': etapaProcesal,
        'cantidad_estrategias': cantidadEstrategias,
      },
      operation: () async {
        // 🔍 RAG: jurisprudencia real del TSJ.
        List<MessageSource> fuentesRAG = [];
        String jurisprudenciaReal = '';
        try {
          final rag = await RAGService.obtenerContextoYFuentes(
            consulta: '$descripcionCaso ${delitos.join(', ')}',
            limit: 5,
          );
          fuentesRAG = rag.fuentes;
          jurisprudenciaReal = rag.contexto;
          debugPrint('⚖️ RAG comparador: ${rag.sentencias.length} sentencias reales');
        } catch (e) {
          debugPrint('⚠️ RAG comparador (jurisprudencia) no disponible: $e');
        }

        // 📚 RAG: artículos de ley vigente relevantes (COPP y demás leyes).
        String leyesReales = '';
        try {
          final resultados = await LeyesRepositorioService().buscar(
            '$descripcionCaso ${delitos.join(' ')}',
            limite: 6,
          );
          if (resultados.isNotEmpty) {
            final buffer = StringBuffer();
            for (final r in resultados) {
              final reg = r.registro;
              final texto = '${reg.encabezado ?? ''} ${reg.texto}'.trim();
              final corto = texto.length > 400 ? '${texto.substring(0, 400)}...' : texto;
              buffer.writeln('- Art. ${reg.identificador} de ${reg.leyNombre}: $corto');
            }
            leyesReales = buffer.toString().trim();
          }
        } catch (e) {
          debugPrint('⚠️ RAG comparador (leyes) no disponible: $e');
        }

        final bloqueJurisprudencia = jurisprudenciaReal.isNotEmpty
            ? '\n**JURISPRUDENCIA REAL DEL TSJ (cita SOLO estas, NO inventes):**\n$jurisprudenciaReal\n'
            : '';
        final bloqueLeyes = leyesReales.isNotEmpty
            ? '\n**LEYES VIGENTES APLICABLES (cita SOLO artículos vigentes, NO inventes):**\n$leyesReales\n'
            : '';

        final prompt = '''
Eres un abogado penalista venezolano experto. Analiza el siguiente caso y genera $cantidadEstrategias estrategias legales DIFERENTES y VIABLES.

**CASO:**
- ID: $casoId
- Descripción: $descripcionCaso
- Delitos: ${delitos.join(', ')}
- Etapa Procesal: $etapaProcesal$bloqueLeyes$bloqueJurisprudencia
**INSTRUCCIONES:**
1. Genera $cantidadEstrategias estrategias legales diferentes (ej: negociación, recurso apelación, medidas cautelares, etc.)
2. Para CADA estrategia incluye:
   - Tipo de estrategia (defensaTecnica, negociacion, recursoApelacion, accionTutela, medidasCautelares, libertadProvisional, nulidad, prescripcion, atenuantes, transaccionPenal)
   - Título claro y específico
   - Descripción detallada (200-300 palabras)
   - Probabilidad de éxito (0.0 a 1.0)
   - 3-5 beneficios concretos con impacto (0.0 a 1.0)
   - 2-4 riesgos con nivel (bajo/medio/alto/muyAlto) y probabilidad (0.0 a 1.0)
   - Requisitos legales necesarios (basados en las LEYES VIGENTES de arriba)
   - Pasos procedimentales (orden cronológico)
   - Duración estimada en días
   - Costo estimado (Bajo/Medio/Alto con rango en USD)
3. Fundamento jurídico: usa SOLO los artículos vigentes listados en "LEYES VIGENTES APLICABLES" y SOLO las sentencias listadas en "JURISPRUDENCIA REAL DEL TSJ". No inventes artículos, números, ponentes ni fechas.
4. Asegúrate que cada estrategia sea REALMENTE DIFERENTE en enfoque y táctica

**FORMATO JSON ESTRICTO:**
Responde SOLO con un array JSON válido, sin texto adicional:

[
  {
    "tipo": "negociacion",
    "titulo": "Negociación con Fiscal para Reducción de Cargos",
    "descripcion": "Estrategia de negociación...",
    "probabilidadExito": 0.65,
    "beneficios": [
      {"descripcion": "Reducción de pena hasta 50%", "impacto": 0.8}
    ],
    "riesgos": [
      {"descripcion": "Fiscal podría rechazar oferta", "nivel": "medio", "probabilidad": 0.3}
    ],
    "requisitos": ["Aceptación de hechos", "Reparación del daño"],
    "pasos": ["1. Reunión con fiscal", "2. Propuesta formal"],
    "jurisprudencia": [],
    "duracionEstimadaDias": 45,
    "costoEstimado": "Bajo (500 - 1,500 USD)"
  }
]

IMPORTANTE: Responde SOLO el JSON, sin código de markdown ni explicaciones.
''';

        try {
          final response = await AIService.generarEstrategiaLegal(prompt);
          final estrategiasJson = _parseJsonResponse(response);

          if (estrategiasJson is! List || estrategiasJson.isEmpty) {
            debugPrint('⚠️ JSON vacío/inválido, usando estrategias por defecto');
            return _generarEstrategiasDefault(casoId);
          }

          final estrategias = <EstrategiaLegal>[];
          for (var i = 0; i < estrategiasJson.length; i++) {
            final item = estrategiasJson[i];
            if (item is! Map<String, dynamic>) continue;

            final costo =
                _parseCosto(item['costoEstimado'] as String? ?? 'Medio');

            estrategias.add(EstrategiaLegal(
              id: '${casoId}_estrategia_${DateTime.now().millisecondsSinceEpoch}_$i',
              tipo: _parseTipoEstrategia(item['tipo'] as String?),
              titulo: item['titulo'] ?? 'Estrategia ${i + 1}',
              descripcion: item['descripcion'] ?? '',
              probabilidadExito:
                  (item['probabilidadExito'] ?? 0.5).toDouble().clamp(0.0, 1.0),
              beneficios: _parseBeneficios(item['beneficios']),
              riesgos: _parseRiesgos(item['riesgos']),
              requisitos: _parseListaString(item['requisitos']),
              pasos: _parseListaString(item['pasos']),
              jurisprudencia: fuentesRAG.isNotEmpty
                  ? _construirJurisprudenciaDesdeRAG(fuentesRAG)
                  : _parseJurisprudencia(item['jurisprudencia']),
              duracionEstimadaDias: item['duracionEstimadaDias'] ?? 30,
              costoEstimado: item['costoEstimado'] ?? 'Medio',
              costoMinimoUSD: costo.minimo,
              costoMaximoUSD: costo.maximo,
              categoriaCosto: costo.categoria,
              fechaCreacion: DateTime.now(),
              generadaPorIA: true,
            ));
          }

          if (estrategias.isEmpty) {
            return _generarEstrategiasDefault(casoId);
          }
          return estrategias;
        } catch (e) {
          debugPrint('Error generando estrategias: $e');
          return _generarEstrategiasDefault(casoId);
        }
      },
    );
  }

  /// Crea una comparación y la guarda en Supabase.
  Future<ComparacionEstrategias> crearComparacion({
    required String titulo,
    required String casoId,
    required List<EstrategiaLegal> estrategias,
    String? notas,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Usuario no autenticado');

    final id = 'comp_${DateTime.now().millisecondsSinceEpoch}_${casoId.hashCode}';
    final comparacion = ComparacionEstrategias(
      id: id,
      titulo: titulo,
      casoId: casoId,
      estrategias: estrategias,
      fechaCreacion: DateTime.now(),
      notas: notas,
    );

    await _supabase.from('estrategias_comparaciones').insert({
      'id': id,
      'user_id': userId,
      'titulo': titulo,
      'caso_id': casoId,
      'estrategias': comparacion.estrategias.map((e) => e.toMap()).toList(),
      'notas': notas,
      'fecha_creacion': DateTime.now().toIso8601String(),
    });

    return comparacion;
  }

  /// Obtiene una comparación por ID.
  Future<ComparacionEstrategias?> obtenerComparacion(String id) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return null;
      final response = await _supabase
          .from('estrategias_comparaciones')
          .select()
          .eq('id', id)
          .eq('user_id', userId)
          .maybeSingle();
      if (response == null) return null;
      return ComparacionEstrategias.fromMap(_aMapaComparacion(response));
    } catch (e) {
      debugPrint('❌ Error obteniendo comparación: $e');
      return null;
    }
  }

  /// Obtiene todas las comparaciones del usuario (fetch, sin realtime).
  Future<List<ComparacionEstrategias>> obtenerComparaciones() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return [];
      final response = await _supabase
          .from('estrategias_comparaciones')
          .select()
          .eq('user_id', userId)
          .order('fecha_creacion', ascending: false);
      return response
          .map((item) => ComparacionEstrategias.fromMap(_aMapaComparacion(item)))
          .toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo comparaciones: $e');
      return [];
    }
  }

  /// Elimina una comparación.
  Future<void> eliminarComparacion(String id) async {
    try {
      await _supabase
          .from('estrategias_comparaciones')
          .delete()
          .eq('id', id);
    } catch (e) {
      debugPrint('❌ Error eliminando comparación: $e');
    }
  }

  /// Actualiza las notas de una comparación.
  Future<void> actualizarNotas(String id, String notas) async {
    try {
      await _supabase
          .from('estrategias_comparaciones')
          .update({'notas': notas})
          .eq('id', id);
    } catch (e) {
      debugPrint('❌ Error actualizando notas: $e');
    }
  }

  /// Convierte una fila de Supabase (con `estrategias` jsonb) al formato
  /// que espera [ComparacionEstrategias.fromMap].
  Map<String, dynamic> _aMapaComparacion(Map<String, dynamic> row) {
    return {
      'id': row['id'] ?? '',
      'titulo': row['titulo'] ?? '',
      'casoId': row['caso_id'] ?? '',
      'estrategias': row['estrategias'] ?? [],
      'fechaCreacion': row['fecha_creacion'] ?? DateTime.now().toIso8601String(),
      'notas': row['notas'],
    };
  }

  // --- Métodos auxiliares privados ---

  dynamic _parseJsonResponse(String response) {
    try {
      var cleaned = response.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      return _parseJson(cleaned.trim());
    } catch (e) {
      debugPrint('Error parsing JSON: $e');
      return null;
    }
  }

  dynamic _parseJson(String jsonString) {
    // 1. Intento directo.
    try {
      return jsonDecode(jsonString);
    } catch (_) {}

    // 2. Extraer el primer array u objeto JSON del texto.
    final match = RegExp(r'(\[[\s\S]*\]|\{[\s\S]*\})').firstMatch(jsonString);
    if (match != null) {
      try {
        return jsonDecode(match.group(0)!);
      } catch (_) {}
    }
    return null;
  }

  TipoEstrategia _parseTipoEstrategia(String? tipo) {
    if (tipo == null) return TipoEstrategia.defensaTecnica;
    try {
      return TipoEstrategia.values.firstWhere(
        (e) => e.name.toLowerCase() == tipo.toLowerCase(),
        orElse: () => TipoEstrategia.defensaTecnica,
      );
    } catch (e) {
      return TipoEstrategia.defensaTecnica;
    }
  }

  List<Beneficio> _parseBeneficios(dynamic beneficiosJson) {
    if (beneficiosJson == null || beneficiosJson is! List) return [];
    return beneficiosJson
        .map<Beneficio?>((b) {
          if (b is! Map<String, dynamic>) return null;
          return Beneficio(
            descripcion: b['descripcion'] ?? '',
            impacto: (b['impacto'] ?? 0.5).toDouble().clamp(0.0, 1.0),
          );
        })
        .whereType<Beneficio>()
        .toList();
  }

  List<Riesgo> _parseRiesgos(dynamic riesgosJson) {
    if (riesgosJson == null || riesgosJson is! List) return [];
    return riesgosJson
        .map<Riesgo?>((r) {
          if (r is! Map<String, dynamic>) return null;
          return Riesgo(
            descripcion: r['descripcion'] ?? '',
            nivel: _parseNivelRiesgo(r['nivel']),
            probabilidad: (r['probabilidad'] ?? 0.3).toDouble().clamp(0.0, 1.0),
          );
        })
        .whereType<Riesgo>()
        .toList();
  }

  NivelRiesgo _parseNivelRiesgo(dynamic nivel) {
    if (nivel == null || nivel is! String) return NivelRiesgo.medio;
    switch (nivel.toLowerCase()) {
      case 'bajo':
        return NivelRiesgo.bajo;
      case 'alto':
        return NivelRiesgo.alto;
      case 'muyalto':
      case 'muy alto':
        return NivelRiesgo.muyAlto;
      default:
        return NivelRiesgo.medio;
    }
  }

  /// Parsea un costo estimado ("Bajo (500 - 1,500 USD)") a valores numéricos.
  ({double minimo, double maximo, String categoria}) _parseCosto(String costo) {
    final lower = costo.toLowerCase();
    String categoria = 'medio';
    if (lower.contains('alto')) {
      categoria = 'alto';
    } else if (lower.contains('bajo')) {
      categoria = 'bajo';
    }

    final numeros = RegExp(r'\d[\d,.]*').allMatches(costo).map((m) {
      final n = m.group(0)!.replaceAll(',', '');
      return double.tryParse(n) ?? 0;
    }).toList();

    double minimo = 0, maximo = 0;
    if (numeros.length >= 2) {
      minimo = numeros[0];
      maximo = numeros[1];
    } else if (numeros.length == 1) {
      maximo = numeros[0];
    }
    return (minimo: minimo, maximo: maximo, categoria: categoria);
  }

  List<String> _parseListaString(dynamic lista) {
    if (lista == null || lista is! List) return [];
    return lista.map((e) => e.toString()).toList();
  }

  List<JurisprudenciaRespaldo> _parseJurisprudencia(dynamic jurisprudenciaJson) {
    if (jurisprudenciaJson == null || jurisprudenciaJson is! List) return [];
    return jurisprudenciaJson
        .map<JurisprudenciaRespaldo?>((j) {
          if (j is! Map<String, dynamic>) return null;

          DateTime fecha;
          try {
            final fechaStr = j['fecha'] as String?;
            fecha = fechaStr != null
                ? DateTime.parse(fechaStr)
                : DateTime.now().subtract(const Duration(days: 365));
          } catch (e) {
            fecha = DateTime.now().subtract(const Duration(days: 365));
          }

          return JurisprudenciaRespaldo(
            sentenciaId: j['sentenciaId'] ?? '',
            ponente: j['ponente'] ?? '',
            fecha: fecha,
            extracto: j['extracto'] ?? '',
            relevancia: (j['relevancia'] ?? 0.7).toDouble().clamp(0.0, 1.0),
          );
        })
        .whereType<JurisprudenciaRespaldo>()
        .toList();
  }

  /// Convierte fuentes RAG (sentencias reales del TSJ) en respaldo jurídico.
  List<JurisprudenciaRespaldo> _construirJurisprudenciaDesdeRAG(
      List<MessageSource> fuentes) {
    return fuentes.map((f) {
      DateTime fecha = DateTime.now().subtract(const Duration(days: 365));
      final match = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(f.reference);
      if (match != null) {
        final parseada = DateTime.tryParse(
            '${match.group(3)}-${match.group(2)}-${match.group(1)}');
        if (parseada != null) fecha = parseada;
      }
      return JurisprudenciaRespaldo(
        sentenciaId: f.title,
        ponente: _extraerPonente(f.reference),
        fecha: fecha,
        extracto: f.excerpt ?? '',
        relevancia: 0.85,
      );
    }).toList();
  }

  String _extraerPonente(String referencia) {
    final match = RegExp(r'Ponente:\s*([^·]+)').firstMatch(referencia);
    return match?.group(1)?.trim() ?? '';
  }

  /// Genera estrategias por defecto cuando falla la IA. Sin jurisprudencia
  /// inventada (se deja vacía).
  List<EstrategiaLegal> _generarEstrategiasDefault(String casoId) {
    return [
      EstrategiaLegal(
        id: '${casoId}_default_1',
        tipo: TipoEstrategia.defensaTecnica,
        titulo: 'Defensa Técnica Integral',
        descripcion:
            'Estrategia procesal completa que abarca todas las fases del juicio, '
            'desde la investigación hasta el juicio oral. Incluye análisis exhaustivo '
            'de pruebas, presentación de testigos de descargo y argumentación jurídica '
            'sólida basada en el COPP y jurisprudencia del TSJ.',
        probabilidadExito: 0.60,
        beneficios: const [
          Beneficio(descripcion: 'Cobertura completa del proceso', impacto: 0.9),
          Beneficio(descripcion: 'Mayor control sobre el caso', impacto: 0.8),
          Beneficio(descripcion: 'Posibilidad de absolución total', impacto: 0.7),
        ],
        riesgos: const [
          Riesgo(descripcion: 'Duración extensa del proceso', nivel: NivelRiesgo.medio, probabilidad: 0.6),
          Riesgo(descripcion: 'Costos legales elevados', nivel: NivelRiesgo.medio, probabilidad: 0.5),
        ],
        requisitos: const ['Pruebas documentales suficientes', 'Testigos disponibles', 'Presupuesto para honorarios'],
        pasos: const [
          '1. Análisis exhaustivo del expediente',
          '2. Recolección de pruebas de descargo',
          '3. Preparación de testigos',
          '4. Audiencia preliminar',
          '5. Juicio oral',
        ],
        jurisprudencia: const [],
        duracionEstimadaDias: 180,
        costoEstimado: 'Alto (3,000 - 8,000 USD)',
        costoMinimoUSD: 3000,
        costoMaximoUSD: 8000,
        categoriaCosto: 'alto',
        fechaCreacion: DateTime.now(),
      ),
      EstrategiaLegal(
        id: '${casoId}_default_2',
        tipo: TipoEstrategia.negociacion,
        titulo: 'Negociación con Ministerio Público',
        descripcion:
            'Acuerdo procesal con el Ministerio Público para obtener reducción '
            'de cargos o pena a cambio de aceptación de hechos, colaboración '
            'con la justicia o reparación del daño, conforme al procedimiento '
            'de admisión de los hechos.',
        probabilidadExito: 0.70,
        beneficios: const [
          Beneficio(descripcion: 'Reducción de pena hasta 50%', impacto: 0.95),
          Beneficio(descripcion: 'Evita juicio oral público', impacto: 0.8),
          Beneficio(descripcion: 'Menor duración procesal', impacto: 0.85),
        ],
        riesgos: const [
          Riesgo(descripcion: 'Requiere aceptación de hechos', nivel: NivelRiesgo.medio, probabilidad: 1.0),
          Riesgo(descripcion: 'Fiscal puede rechazar propuesta', nivel: NivelRiesgo.medio, probabilidad: 0.3),
        ],
        requisitos: const ['Delito admite negociación', 'Reparación del daño', 'Conformidad del imputado'],
        pasos: const [
          '1. Reunión con fiscal del caso',
          '2. Propuesta formal de acuerdo',
          '3. Negociación de términos',
          '4. Audiencia de aprobación judicial',
          '5. Sentencia',
        ],
        jurisprudencia: const [],
        duracionEstimadaDias: 45,
        costoEstimado: 'Medio (1,000 - 3,000 USD)',
        costoMinimoUSD: 1000,
        costoMaximoUSD: 3000,
        categoriaCosto: 'medio',
        fechaCreacion: DateTime.now(),
      ),
      EstrategiaLegal(
        id: '${casoId}_default_3',
        tipo: TipoEstrategia.medidasCautelares,
        titulo: 'Solicitud de Medidas Cautelares Sustitutivas',
        descripcion:
            'Petición ante el tribunal para sustituir la privación judicial '
            'preventiva de libertad por medidas cautelares sustitutivas, '
            'conforme a los artículos 242 y siguientes del COPP.',
        probabilidadExito: 0.55,
        beneficios: const [
          Beneficio(descripcion: 'Libertad durante el proceso', impacto: 1.0),
          Beneficio(descripcion: 'Continuidad laboral/familiar', impacto: 0.9),
          Beneficio(descripcion: 'Mejor preparación de la defensa', impacto: 0.7),
        ],
        riesgos: const [
          Riesgo(descripcion: 'Tribunal puede denegar la solicitud', nivel: NivelRiesgo.medio, probabilidad: 0.45),
          Riesgo(descripcion: 'Incumplimiento causa revocatoria', nivel: NivelRiesgo.alto, probabilidad: 0.2),
        ],
        requisitos: const [
          'Arraigo en la comunidad',
          'Sin riesgo de fuga u obstaculización',
          'Delito admite medidas sustitutivas',
        ],
        pasos: const [
          '1. Escrito de solicitud fundamentado',
          '2. Audiencia ante el juez de control',
          '3. Presentación de pruebas de arraigo',
          '4. Decisión judicial',
          '5. Cumplimiento de condiciones',
        ],
        jurisprudencia: const [],
        duracionEstimadaDias: 15,
        costoEstimado: 'Bajo-Medio (500 - 2,000 USD)',
        costoMinimoUSD: 500,
        costoMaximoUSD: 2000,
        categoriaCosto: 'bajo',
        fechaCreacion: DateTime.now(),
      ),
    ];
  }
}

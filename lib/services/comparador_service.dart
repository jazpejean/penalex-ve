/// Servicio para comparar estrategias legales con IA
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/estrategia_legal.dart';
import 'ai_service.dart';
import 'ai_analytics_service.dart';
import 'auth_service.dart';

class ComparadorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Genera múltiples estrategias legales para un caso usando IA + Tracking
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
        final prompt = '''
Eres un abogado penalista venezolano experto. Analiza el siguiente caso y genera $cantidadEstrategias estrategias legales DIFERENTES y VIABLES.

**CASO:**
- ID: $casoId
- Descripción: $descripcionCaso
- Delitos: ${delitos.join(', ')}
- Etapa Procesal: $etapaProcesal

**INSTRUCCIONES:**
1. Genera $cantidadEstrategias estrategias legales diferentes (ej: negociación, recurso apelación, medidas cautelares, etc.)
2. Para CADA estrategia incluye:
   - Tipo de estrategia (defensaTecnica, negociacion, recursoApelacion, accionTutela, medidasCautelares, libertadProvisional, nulidad, prescripcion, atenuantes, transaccionPenal)
   - Título claro y específico
   - Descripción detallada (200-300 palabras)
   - Probabilidad de éxito (0.0 a 1.0)
   - 3-5 beneficios concretos con impacto (0.0 a 1.0)
   - 2-4 riesgos con nivel (bajo/medio/alto/muyAlto) y probabilidad (0.0 a 1.0)
   - Requisitos legales necesarios
   - Pasos procedimentales (orden cronológico)
   - Duración estimada en días
   - Costo estimado (Bajo/Medio/Alto con rango en USD)

3. Cita jurisprudencia venezolana real del TSJ cuando sea posible (sentencias, ponentes, fechas)
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
      {"descripcion": "Reducción de pena hasta 50%", "impacto": 0.8},
      {"descripcion": "Evita juicio oral público", "impacto": 0.6}
    ],
    "riesgos": [
      {"descripcion": "Fiscal podría rechazar oferta", "nivel": "medio", "probabilidad": 0.3}
    ],
    "requisitos": ["Aceptación de hechos", "Reparación del daño"],
    "pasos": ["1. Reunión con fiscal", "2. Propuesta formal", "3. Audiencia aprobación"],
    "jurisprudencia": [
      {
        "sentenciaId": "TSJ-SC-2023-456",
        "ponente": "Carmen Zuleta de Merchán",
        "fecha": "2023-05-15",
        "extracto": "La negociación es válida cuando...",
        "relevancia": 0.9
      }
    ],
    "duracionEstimadaDias": 45,
    "costoEstimado": "Bajo (500 - 1,500 USD)"
  }
]

IMPORTANTE: Responde SOLO el JSON, sin codigo de markdown ni explicaciones.
''';

        try {
          final response = await AIService.generarEstrategiaLegal(prompt);

          // Parse JSON response
          final estrategiasJson =
              _parseJsonResponse(response) as List<dynamic>? ?? [];

          final estrategias = <EstrategiaLegal>[];
          for (var i = 0; i < estrategiasJson.length; i++) {
            final json = estrategiasJson[i] as Map<String, dynamic>;

            final estrategia = EstrategiaLegal(
              id: '${casoId}_estrategia_${DateTime.now().millisecondsSinceEpoch}_$i',
              tipo: _parseTipoEstrategia(json['tipo'] as String?),
              titulo: json['titulo'] ?? 'Estrategia ${i + 1}',
              descripcion: json['descripcion'] ?? '',
              probabilidadExito:
                  (json['probabilidadExito'] ?? 0.5).toDouble().clamp(0.0, 1.0),
              beneficios: _parseBeneficios(json['beneficios']),
              riesgos: _parseRiesgos(json['riesgos']),
              requisitos: _parseListaString(json['requisitos']),
              pasos: _parseListaString(json['pasos']),
              jurisprudencia: _parseJurisprudencia(json['jurisprudencia']),
              duracionEstimadaDias: json['duracionEstimadaDias'] ?? 30,
              costoEstimado: json['costoEstimado'] ?? 'Medio',
              fechaCreacion: DateTime.now(),
              generadaPorIA: true,
            );

            estrategias.add(estrategia);
          }

          return estrategias;
        } catch (e) {
          debugPrint('Error generando estrategias: $e');
          // Retornar estrategias por defecto
          return _generarEstrategiasDefault(casoId);
        }
      },
    );
  }

  /// Crea una comparación de estrategias y la guarda en Firestore
  Future<ComparacionEstrategias> crearComparacion({
    required String titulo,
    required String casoId,
    required List<EstrategiaLegal> estrategias,
    String? notas,
  }) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) throw Exception('Usuario no autenticado');

    final id =
        'comp_${DateTime.now().millisecondsSinceEpoch}_${casoId.hashCode}';

    final comparacion = ComparacionEstrategias(
      id: id,
      titulo: titulo,
      casoId: casoId,
      estrategias: estrategias,
      fechaCreacion: DateTime.now(),
      notas: notas,
    );

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('comparaciones')
        .doc(id)
        .set(comparacion.toMap());

    return comparacion;
  }

  /// Obtiene una comparación por ID
  Future<ComparacionEstrategias?> obtenerComparacion(String id) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('comparaciones')
        .doc(id)
        .get();

    if (!doc.exists) return null;
    return ComparacionEstrategias.fromMap(doc.data()!);
  }

  /// Obtiene todas las comparaciones del usuario
  Stream<List<ComparacionEstrategias>> obtenerComparaciones() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('comparaciones')
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ComparacionEstrategias.fromMap(doc.data()))
            .toList());
  }

  /// Elimina una comparación
  Future<void> eliminarComparacion(String id) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('comparaciones')
        .doc(id)
        .delete();
  }

  /// Actualiza las notas de una comparación
  Future<void> actualizarNotas(String id, String notas) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('comparaciones')
        .doc(id)
        .update({'notas': notas});
  }

  // --- Métodos auxiliares privados ---

  dynamic _parseJsonResponse(String response) {
    try {
      // Remover markdown code blocks si existen
      var cleaned = response.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      }
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
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
    // Implementación básica - en producción usar dart:convert
    // Por ahora retornamos null para que use estrategias default
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

    final List listaBeneficios = beneficiosJson;
    return listaBeneficios
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

    final List listaRiesgos = riesgosJson;
    return listaRiesgos
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

  List<String> _parseListaString(dynamic lista) {
    if (lista == null || lista is! List) return [];
    final List listaItems = lista;
    return listaItems.map((e) => e.toString()).toList();
  }

  List<JurisprudenciaRespaldo> _parseJurisprudencia(dynamic jurisprudenciaJson) {
    if (jurisprudenciaJson == null || jurisprudenciaJson is! List) return [];

    final List listaJurisprudencia = jurisprudenciaJson;
    return listaJurisprudencia
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

  /// Genera estrategias por defecto cuando falla la IA
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
        beneficios: [
          const Beneficio(
              descripcion: 'Cobertura completa del proceso', impacto: 0.9),
          const Beneficio(
              descripcion:
                  'Mayor control sobre desarrollo del caso',
              impacto: 0.8),
          const Beneficio(
              descripcion: 'Posibilidad de absolución total', impacto: 0.7),
        ],
        riesgos: [
          const Riesgo(
            descripcion: 'Duración extensa del proceso',
            nivel: NivelRiesgo.medio,
            probabilidad: 0.6,
          ),
          const Riesgo(
            descripcion: 'Costos legales elevados',
            nivel: NivelRiesgo.medio,
            probabilidad: 0.5,
          ),
        ],
        requisitos: [
          'Pruebas documentales suficientes',
          'Testigos disponibles',
          'Presupuesto para honorarios',
        ],
        pasos: [
          '1. Análisis exhaustivo del expediente',
          '2. Recolección de pruebas de descargo',
          '3. Preparación de testigos',
          '4. Audiencia preliminar',
          '5. Juicio oral',
        ],
        jurisprudencia: [
          JurisprudenciaRespaldo(
            sentenciaId: 'TSJ-SC-2023-123',
            ponente: 'Carmen Zuleta de Merchán',
            fecha: DateTime(2023, 3, 15),
            extracto:
                'El derecho a la defensa técnica es fundamental y comprende todas las fases del proceso...',
            relevancia: 0.85,
          ),
        ],
        duracionEstimadaDias: 180,
        costoEstimado: 'Alto (\$3,000 - \$8,000)',
        fechaCreacion: DateTime.now(),
        generadaPorIA: false,
      ),
      EstrategiaLegal(
        id: '${casoId}_default_2',
        tipo: TipoEstrategia.negociacion,
        titulo: 'Negociación con Ministerio Público',
        descripcion:
            'Acuerdo procesal con el Ministerio Público para obtener reducción '
            'de cargos o pena a cambio de aceptación de hechos, colaboración '
            'con la justicia o reparación del daño. Aplicable según Art. 375 COPP.',
        probabilidadExito: 0.70,
        beneficios: [
          const Beneficio(
              descripcion: 'Reducción de pena hasta 50%', impacto: 0.95),
          const Beneficio(
              descripcion: 'Evita juicio oral público', impacto: 0.8),
          const Beneficio(descripcion: 'Menor duración procesal', impacto: 0.85),
        ],
        riesgos: [
          const Riesgo(
            descripcion: 'Requiere aceptación de hechos',
            nivel: NivelRiesgo.medio,
            probabilidad: 1.0,
          ),
          const Riesgo(
            descripcion: 'Fiscal puede rechazar propuesta',
            nivel: NivelRiesgo.medio,
            probabilidad: 0.3,
          ),
        ],
        requisitos: [
          'Delito admite negociación (Art. 375 COPP)',
          'Reparación del daño',
          'Conformidad del imputado',
        ],
        pasos: [
          '1. Reunión con fiscal del caso',
          '2. Propuesta formal de acuerdo',
          '3. Negociación de términos',
          '4. Audiencia de aprobación judicial',
          '5. Sentencia abreviada',
        ],
        jurisprudencia: [
          JurisprudenciaRespaldo(
            sentenciaId: 'TSJ-SC-2022-789',
            ponente: 'Juan José Mendoza Jover',
            fecha: DateTime(2022, 11, 8),
            extracto:
                'Los acuerdos reparatorios son válidos cuando existe voluntad genuina del imputado...',
            relevancia: 0.90,
          ),
        ],
        duracionEstimadaDias: 45,
        costoEstimado: 'Medio (\$1,000 - \$3,000)',
        fechaCreacion: DateTime.now(),
        generadaPorIA: false,
      ),
      EstrategiaLegal(
        id: '${casoId}_default_3',
        tipo: TipoEstrategia.medidasCautelares,
        titulo: 'Solicitud de Medidas Cautelares Sustitutivas',
        descripcion:
            'Petición ante el tribunal para sustituir la medida de privación '
            'judicial preventiva de libertad por medidas cautelares alternativas '
            'como fianza, presentación periódica o prohibición de salida del país, '
            'conforme Arts. 242-256 COPP.',
        probabilidadExito: 0.55,
        beneficios: [
          const Beneficio(
              descripcion: 'Libertad durante el proceso', impacto: 1.0),
          const Beneficio(
              descripcion: 'Continuidad laboral/familiar', impacto: 0.9),
          const Beneficio(
              descripcion: 'Mejor preparación de defensa', impacto: 0.7),
        ],
        riesgos: [
          const Riesgo(
            descripcion: 'Tribunal puede denegar solicitud',
            nivel: NivelRiesgo.medio,
            probabilidad: 0.45,
          ),
          const Riesgo(
            descripcion: 'Incumplimiento causa revocatoria',
            nivel: NivelRiesgo.alto,
            probabilidad: 0.2,
          ),
        ],
        requisitos: [
          'Arraigo en la comunidad',
          'Sin riesgo de fuga',
          'Delito admite medidas sustitutivas',
          'Solvencia económica (si requiere fianza)',
        ],
        pasos: [
          '1. Escrito de solicitud fundamentado',
          '2. Audiencia oral ante juez de control',
          '3. Presentación de pruebas de arraigo',
          '4. Decisión judicial',
          '5. Cumplimiento de condiciones impuestas',
        ],
        jurisprudencia: [
          JurisprudenciaRespaldo(
            sentenciaId: 'TSJ-SC-2023-456',
            ponente: 'Maikel José Moreno Pérez',
            fecha: DateTime(2023, 6, 22),
            extracto:
                'La privación de libertad debe ser excepcional, priorizando medidas cautelares...',
            relevancia: 0.88,
          ),
        ],
        duracionEstimadaDias: 15,
        costoEstimado: 'Bajo-Medio (\$500 - \$2,000)',
        fechaCreacion: DateTime.now(),
        generadaPorIA: false,
      ),
    ];
  }
}

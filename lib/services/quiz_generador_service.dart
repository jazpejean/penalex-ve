import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/caso_quiz.dart';
import 'ai_service.dart';
import 'leyes_repositorio_service.dart';
import 'quiz_storage_service.dart';
import 'quiz_sync_service.dart';
import 'rag_service.dart';

/// Genera casos hipotéticos del quiz con IA (DeepSeek), fundamentados en el
/// repositorio de leyes y jurisprudencia. Los lotes generados se guardan en
/// Storage (cache), por lo que cada caso se paga en tokens UNA sola vez.
///
/// Diseño "sin materias": cada lote mezcla casos hipotéticos de TODO el
/// derecho penal venezolano (teoría del delito, personas, propiedad, COPP,
/// especiales) — nunca preguntas teóricas, siempre escenarios aplicados.
class QuizGeneradorService {
  static bool _generando = false;

  /// Recarga el banco personal en background si está por debajo del umbral
  /// (evita lag y gasto innecesario de tokens: solo genera cuando hace falta).
  static Future<void> recargarBanco({int umbral = 60, int cantidad = 20}) async {
    if (_generando) return;
    _generando = true;
    try {
      final casos = await QuizStorageService().listarCasos();
      if (casos.length >= umbral) return;
      // 1º) Importar los lotes YA VALIDADOS del worker (cero error por
      // construcción; sin revisión humana). El cron del worker genera 20/día.
      final importados = await QuizSyncService.sincronizarPendientes();
      if (importados > 0) {
        final trasSync = await QuizStorageService().listarCasos();
        if (trasSync.length >= umbral) return;
      }
      // 2º) Respaldo local (DeepSeek) SOLO si no hay lotes pendientes.
      final lote = await generarLote(cantidad: cantidad, dificultad: 2);
      await QuizStorageService().guardarBatch(lote);
    } catch (e) {
      debugPrint('❌ Error recargando banco: $e');
    } finally {
      _generando = false;
    }
  }

  /// Genera un lote de [cantidad] casos hipotéticos MIXTOS (sin materias).
  static Future<List<CasoQuiz>> generarLote({
    int cantidad = 20,
    required int dificultad,
  }) async {
    const materia = 'Derecho Penal Venezolano completo: teoría del delito '
        '(tentativa, legítima defensa, autoría, participación, error), delitos '
        'contra las personas (homicidio, lesiones, femicidio, aborto, '
        'secuestro), delitos contra la propiedad (hurto, robo, estafa, '
        'extorsión, apropiación indebida), derecho procesal penal (COPP: '
        'flagrancia, medidas cautelares, pruebas, apelación), y delitos '
        'especiales (drogas, corrupción, informáticos, lavado de activos, '
        'trata). Mezcla las áreas SIN separarlas: un lote debe cubrir varias.';

    // 📚 Contexto de leyes vigentes
    String leyesContexto = '';
    try {
      final resultados = await LeyesRepositorioService().buscar(
        'delito pena artículo',
        limite: 5,
      );
      if (resultados.isNotEmpty) {
        final buffer = StringBuffer();
        for (final r in resultados) {
          final reg = r.registro;
          final texto = '${reg.encabezado ?? ''} ${reg.texto}'.trim();
          final corto = texto.length > 350 ? '${texto.substring(0, 350)}...' : texto;
          buffer.writeln('- Art. ${reg.identificador} de ${reg.leyNombre}: $corto');
        }
        leyesContexto = buffer.toString().trim();
      }
    } catch (e) {
      debugPrint('⚠️ RAG leyes quiz no disponible: $e');
    }

    // ⚖️ Contexto de jurisprudencia real
    String jurisContexto = '';
    try {
      final rag = await RAGService.obtenerContextoYFuentes(
        consulta: 'delito sentencia penal',
        limit: 3,
      );
      jurisContexto = rag.contexto;
    } catch (e) {
      debugPrint('⚠️ RAG jurisprudencia quiz no disponible: $e');
    }

    final prompt = '''
Eres un profesor de Derecho Penal Venezolano. Genera EXACTAMENTE $cantidad casos hipotéticos ORIGINALES de: $materia.

**REGLAS:**
1. Cada caso debe ser una situación narrativa breve y realista (3-5 líneas), con nombres de personas ficticias. PROHIBIDO hacer preguntas de memoria tipo "¿cuántos días...?" o "¿en qué artículo...?": SIEMPRE narra un caso concreto con hechos.
2. Incluye 4 opciones (A-D), SOLO UNA correcta. Varía la posición de la correcta.
3. Dificultad: ${dificultad == 1 ? 'FÁCIL (conceptos básicos)' : dificultad == 2 ? 'MEDIA (requiere distinguir figuras)' : 'DIFÍCIL (casos límite y agravantes)'}.
4. En "fundamentacion" escribe 2-3 frases explicando POR QUÉ la opción correcta es la correcta.
5. En "articulos" cita SOLO artículos VIGENTES de las leyes de abajo (formato "Art. N NombreLey").
6. En "sentencias" cita SOLO sentencias REALES de la jurisprudencia de abajo (formato breve: "Sentencia Nº X · Sala · fecha"). Si no hay sentencia aplicable, deja la lista vacía. NUNCA inventes números ni fechas.
7. No repitas casos. Cada uno debe ser distinto. El lote debe mezclar VARIAS áreas del derecho penal (no todos del mismo tema).
8. VERIFICA que la respuesta correcta sea jurídicamente cierta según las LEYES VIGENTES de abajo. Si dudas del dato (plazos, penas, artículos), NO incluyas esa pregunta y genera otra.

**LEYES VIGENTES DISPONIBLES (cita solo estas):**
$leyesContexto

**JURISPRUDENCIA REAL DISPONIBLE (cita solo esta):**
$jurisContexto

**FORMATO JSON ESTRICTO (solo JSON, sin markdown):**
[
  {
    "delito_base": "Tentativa de Hurto",
    "contexto": "José intenta robar un celular...",
    "opciones": ["Hurto consumado", "Tentativa", "Apropiación indebida", "Acto preparatorio impune"],
    "respuesta_correcta": 1,
    "dificultad": 2,
    "fundamentacion": "Explicación breve del porqué...",
    "articulos": ["Art. 80 Código Penal", "Art. 453 Código Penal"],
    "sentencias": []
  }
]
''';

    final respuesta = await AIService.procesarConsultaGeneral(prompt);
    final json = _parseJson(respuesta);
    if (json == null || json is! List || json.isEmpty) {
      debugPrint('⚠️ El generador no devolvió JSON válido');
      return [];
    }

    final casos = <CasoQuiz>[];
    for (var i = 0; i < json.length; i++) {
      final item = json[i];
      if (item is! Map<String, dynamic>) continue;
      final opciones = (item['opciones'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList();
      if (opciones.length != 4) continue;
      casos.add(CasoQuiz(
        id: 'caso_u_${DateTime.now().millisecondsSinceEpoch}_$i',
        nivel: 0, // sin nivel numérico: progresión por carrera judicial
        tramo: 0, // sin materias: todo el penal se mezcla
        delitoBase: item['delito_base']?.toString() ?? '',
        contextoNarrativo: item['contexto']?.toString() ?? '',
        opciones: opciones,
        respuestaCorrecta:
            (item['respuesta_correcta'] as num?)?.toInt() ?? 0,
        dificultad: (item['dificultad'] as num?)?.toInt() ?? dificultad,
        fundamentacion: item['fundamentacion']?.toString() ?? '',
        articulos: (item['articulos'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        sentencias: (item['sentencias'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
      ));
    }

    debugPrint('🧠 Lote generado: ${casos.length} casos (mixto, sin materias)');
    return casos;
  }

  static dynamic _parseJson(String raw) {
    var s = raw.trim();
    if (s.startsWith('```json')) s = s.substring(7);
    if (s.startsWith('```')) s = s.substring(3);
    if (s.endsWith('```')) s = s.substring(0, s.length - 3);
    try {
      return jsonDecode(s);
    } catch (_) {}
    final match = RegExp(r'(\[[\s\S]*\])').firstMatch(s);
    if (match != null) {
      try {
        return jsonDecode(match.group(0)!);
      } catch (_) {}
    }
    return null;
  }
}

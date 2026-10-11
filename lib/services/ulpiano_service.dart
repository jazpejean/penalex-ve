import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import 'ai_service.dart';
import 'leyes_rag_service.dart';
import 'rag_service.dart';

/// Modos (habilidades) de Ulpiano, el asistente jurídico de Penalex VE.
enum UlpianoModo { consultar, redactar, analizar, calcular, citar }

extension UlpianoModoInfo on UlpianoModo {
  String get nombre {
    switch (this) {
      case UlpianoModo.consultar:
        return 'Consulta';
      case UlpianoModo.redactar:
        return 'Redacción';
      case UlpianoModo.analizar:
        return 'Análisis';
      case UlpianoModo.calcular:
        return 'Cálculo';
      case UlpianoModo.citar:
        return 'Cita';
    }
  }

  /// Ejemplo corto que el usuario puede ver/tocar en la pantalla de bienvenida.
  String get ejemplo {
    switch (this) {
      case UlpianoModo.consultar:
        return '¿Qué ha dicho la Sala sobre el art. 457 del COPP?';
      case UlpianoModo.redactar:
        return 'Redacta una solicitud de medida cautelar sustitutiva';
      case UlpianoModo.analizar:
        return 'Analiza este auto y dime sus debilidades';
      case UlpianoModo.calcular:
        return '¿Cuántos años le corresponden por robo agravado?';
      case UlpianoModo.citar:
        return 'Cita la sentencia 01-190100-9903 en formato correcto';
    }
  }
}

/// Orquestador de Ulpiano: clasifica la intención del usuario, recupera
/// contexto (normas + jurisprudencia) y construye un prompt especializado
/// por modo, siempre exigiendo citas verificables y prohibiendo inventar
/// fuentes.
class UlpianoService {
  UlpianoService._();
  static final UlpianoService _instance = UlpianoService._();
  factory UlpianoService() => _instance;

  /// Clasifica la consulta en uno de los 5 modos de Ulpiano.
  static UlpianoModo classificarModo(String consulta) {
    final c = consulta.toLowerCase();
    const redactar = [
      'redacta', 'escribe', 'escrito', 'demanda', 'recurso', 'solicitud',
      'auto de', 'informe', 'borrador', 'promoción', 'apelación', 'apelacion',
      'querella', 'denuncia', 'fundamenta', 'contesta', 'oposición', 'oposicion',
      'presenta', 'consign', 'escrito de', 'oficio', 'acuerdo reparatorio',
    ];
    const calcular = [
      'cuánto', 'cuanto', 'pena', 'años', 'anos', 'dosific', 'computo',
      'cómputo', 'atenuante', 'agravante', 'calcular', 'cálculo', 'lapsos',
      'plazo', 'máxima', 'maxima', 'mínima', 'minima', 'prescripción',
      'prescripcion', 'proporcionalidad',
    ];
    const analizar = [
      'analiza', 'analiz', 'revisa', 'examina', 'lee este', 'documento',
      'adjunto', 'dictamen', 'resumen', 'resume', 'detecta', 'debilidades',
      'problemas', 'expediente', 'interpreta', 'evalúa', 'evalua', 'fortalezas',
    ];
    const citar = [
      'cita', 'citación', 'citacion', 'formato de cita', 'referencia',
      'cómo cito', 'como cito', 'cita la sentencia', 'cita del artículo',
      'bibliográfica', 'bibliografica', 'citar',
    ];

    int matches(List<String> words) => words.where(c.contains).length;

    final scores = {
      UlpianoModo.redactar: matches(redactar),
      UlpianoModo.calcular: matches(calcular),
      UlpianoModo.analizar: matches(analizar),
      UlpianoModo.citar: matches(citar),
    };
    final best = scores.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return best.isNotEmpty ? best.first.key : UlpianoModo.consultar;
  }

  /// Instrucciones especializadas por modo (el "cerebro" de Ulpiano).
  static String _instruccionesModo(UlpianoModo modo, String consulta) {
    switch (modo) {
      case UlpianoModo.redactar:
        return '''
MODO: REDACCIÓN JURÍDICA.
El usuario quiere que REDACTES un documento legal. Haz lo siguiente:
- Estructura el escrito como lo haría un abogado venezolano: ciudadano Juez (o destinatario), identificación de las partes, capítulos/consideraciones, petitorio y cierre.
- Usa lenguaje forense formal, preciso y sobrio (no coloquial).
- Fundamenta cada petición con el artículo de la ley vigente (Código Penal, COPP) y, si hay jurisprudencia disponible arriba, cita la sentencia de la Sala que respalde el criterio (número, sala, ponente, fecha).
- Si no se conocen los datos del caso (nombres, expediente), deja espacios en blanco con guiones bajos o [DATOS DEL CASO] para que el abogado los complete.
- Entrega el texto completo del escrito listo para copiar, sin comentarios fuera del documento. No inventes artículos ni sentencias.''';
      case UlpianoModo.calcular:
        return '''
MODO: CÁLCULO DE PENA / DOSIMETRÍA.
El usuario quiere calcular o conocer penas, límites, atenuantes o agravantes. Haz lo siguiente:
- Aplica la dosimetría del Código Penal venezolano (límites mínimo y máximo, término medio, atenuantes y agravantes) y las reglas del COPP cuando apliquen.
- Muestra el cálculo paso a paso: delito → artículo → pena en abstracto → circunstancias → pena concreta (en años y meses).
- Si hay jurisprudencia disponible, indica si la Sala ha fijado criterios sobre la pena de ese delito.
- Distingue claramente lo que es doctrina legal de tu propio razonamiento. No inventes artículos. Si falta el tipo penal exacto, pide el dato. No des consejos fuera del cálculo.''';
      case UlpianoModo.analizar:
        return '''
MODO: ANÁLISIS DE DOCUMENTO O CASO.
El usuario quiere que ANALICES un documento/caso (puede venir como texto adjunto). Haz lo siguiente:
- Resume el documento en puntos claros: qué es, quiénes intervienen, qué se pide/decide.
- Identifica los fundamentos legales citados (artículos, sentencias) y verifícalos contra las fuentes disponibles.
- Señala debilidades, riesgos procesales y posibles líneas de defensa o argumentación, con base legal.
- Sugiere qué artículo o sentencia conviene citar para reforzar.
- No inventes contenido del documento: si no puedes leer algo, dilo. No inventes jurisprudencia. Distingue hecho de derecho.''';
      case UlpianoModo.citar:
        return '''
MODO: GENERACIÓN DE CITAS JURÍDICAS.
El usuario quiere una cita en formato correcto. Haz lo siguiente:
- Si menciona una sentencia, preséntala en formato académico-forense venezolano: Tribunal/Sala, número de sentencia, fecha (día de mes de año), ponente, expediente, y URL si está disponible en las fuentes.
- Si menciona un artículo, cítalo con su ley (ej. "Artículo 457 del Código Orgánico Procesal Penal").
- Usa SOLO los datos que aparecen en las fuentes proporcionadas. Si falta algún dato (ponente, fecha), indícalo como [DATO FALTANTE] en vez de inventarlo.
- Ofrece la cita completa y una versión abreviada (tipo "SCP, nº X, fecha, ponente").''';
      case UlpianoModo.consultar:
        return '''
MODO: CONSULTA JURÍDICA.
El usuario quiere información sobre ley, jurisprudencia o doctrina. Haz lo siguiente:
- Responde con base en las FUENTES REALES proporcionadas (normas y sentencias del TSJ).
- Cita los artículos con su ley y las sentencias por número, sala, ponente y fecha.
- Si la jurisprudencia recuperada trata de otro delito/artículo distinto al preguntado, descártala y dilo: "no encontré jurisprudencia específica".
- Explica en lenguaje claro, indicando la pena, requisitos o consecuencias cuando aplique.
- NO inventes normas, sentencias ni doctrina que no estén en las fuentes.''';
    }
  }

  /// Construye el prompt completo de Ulpiano.
  static String construirPrompt({
    required String consulta,
    required UlpianoModo modo,
    required String contextoConversacion,
    required String contextoJurisprudencia,
    required String contextoNormativo,
    String contextoEstilos = '',
  }) {
    final jurisprudenciaInstr = contextoJurisprudencia.isNotEmpty
        ? '''
JURISPRUDENCIA REAL DISPONIBLE (recuperada de la base del TSJ):
$contextoJurisprudencia

INSTRUCCIONES SOBRE LA JURISPRUDENCIA:
- Cita SOLO las sentencias que traten EXACTAMENTE el delito/artículo consultado.
- Si una sentencia recuperada trata de otro tema, DESCÁRTALA y no la cites.
- Si ninguna sentencia es pertinente, dilo claramente.
- Cita por número de sentencia, sala, ponente y fecha.
- NO inventes sentencias que no estén listadas aquí.
'''
        : '';

    final normasInstr = contextoNormativo.isNotEmpty
        ? '''
NORMAS RECUPERADAS DEL REPOSITORIO DE LEYES:
$contextoNormativo

INSTRUCCIONES SOBRE LAS NORMAS:
- Usa estas normas como base normativa (cita Ley y artículo).
- NO inventes artículos que no estén aquí.
'''
        : '';

    final estilosInstr = contextoEstilos.isNotEmpty
        ? '''
MODELOS DE ESTILO (escritos reales del banco de estilos — guía de estructura y estilo):
$contextoEstilos

INSTRUCCIONES SOBRE LOS MODELOS:
- Imita la estructura, el tono y el formato forense de estos modelos, adaptándolos al escrito solicitado.
- Si el escrito solicitado no tiene un modelo exacto, combina las estructuras conservando el estilo forense venezolano.
- NO copies nombres, expedientes, cédulas ni datos personales de los modelos.
'''
        : '';

    return '''
Eres Ulpiano, el asistente jurídico de Penalex VE, especializado en derecho penal venezolano (Código Penal, COPP y jurisprudencia de la Sala de Casación Penal y la Sala Constitucional del TSJ).

${_instruccionesModo(modo, consulta)}

Contexto de la conversación:
$contextoConversacion

$jurisprudenciaInstr
$normasInstr
$estilosInstr
Nueva consulta del usuario:
$consulta

FORMATO DE RESPUESTA (Markdown):
- Usa **negritas** para conceptos clave, artículos y penas.
- Usa encabezados (##) para separar secciones largas.
- Usa listas con guiones (-) para enumerar requisitos o puntos.
- Líneas en blanco entre párrafos; evita tablas y bloques de código.
- Cuando cites una fuente, hazlo de forma verificable (Ley + artículo; sentencia con número, sala, ponente y fecha).
- Si no tienes certeza, dilo; nunca inventes leyes, artículos ni sentencias.''';
  }

  /// Responde una consulta como Ulpiano: clasifica modo, recupera RAG
  /// (jurisprudencia + normas) y devuelve respuesta con fuentes citadas.
  Future<({String respuesta, List<MessageSource> fuentes})> generarRespuesta({
    required String consulta,
    required String contextoConversacion,
  }) async {
    try {
      await AIService.inicializar();
      final modo = classificarModo(consulta);
      debugPrint('🏛️ Ulpiano · modo detectado: ${modo.nombre}');

      // RAG: jurisprudencia real del TSJ
      List<MessageSource> fuentes = [];
      String contextoJurisprudencia = '';
      try {
        final rag = await RAGService.obtenerContextoYFuentes(
          consulta: consulta,
          limit: 5,
        );
        fuentes = rag.fuentes;
        contextoJurisprudencia = rag.contexto;
        debugPrint(
            '⚖️ Ulpiano RAG jurisprudencia: ${rag.sentencias.length} sentencias');
      } catch (e) {
        debugPrint('⚠️ RAG jurisprudencia no disponible: $e');
      }

      // RAG: normas (leyes) del repositorio
      String contextoNormativo = '';
      try {
        final leyesRag = LeyesRAGService();
        final resultados = await leyesRag.buscarRelevantes(consulta, limite: 6);
        if (resultados.isNotEmpty) {
          contextoNormativo = leyesRag.construirContexto(resultados);
          final normasFuentes = resultados.map((r) {
            final reg = r.registro;
            final excerpt = (reg.encabezado != null && reg.encabezado!.isNotEmpty
                    ? reg.encabezado!
                    : reg.texto)
                .replaceAll('\n', ' ')
                .trim();
            return MessageSource(
              type: SourceType.articulo,
              title: '${reg.leyNombre} · ${reg.identificador}',
              reference: '${reg.tipoNorma} ${reg.identificador}'.trim(),
              excerpt: excerpt.length > 160
                  ? '${excerpt.substring(0, 160)}…'
                  : excerpt,
            );
          }).toList();
          fuentes = [...fuentes, ...normasFuentes];
        }
      } catch (e) {
        debugPrint('⚠️ RAG leyes no disponible: $e');
      }

      // Estilos de referencia (solo al redactar): modelos reales del banco
      // como guía de estructura y estilo.
      final prompt = construirPrompt(
        consulta: consulta,
        modo: modo,
        contextoConversacion: contextoConversacion,
        contextoJurisprudencia: contextoJurisprudencia,
        contextoNormativo: contextoNormativo,
      );

      final respuesta = await AIService.procesarConsultaGeneral(prompt);
      return (respuesta: respuesta, fuentes: fuentes);
    } catch (e) {
      debugPrint('❌ Error en Ulpiano: $e');
      return (
        respuesta:
            '❌ Lo siento, ocurrió un error al procesar tu consulta. Por favor, intenta de nuevo.\n\nError: $e',
        fuentes: <MessageSource>[],
      );
    }
  }
}
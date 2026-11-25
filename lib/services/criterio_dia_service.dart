import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sentencia_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_service.dart';

/// Tip jurídico curado. Cada uno lleva su base legal verificada en el corpus.
class TipDelDia {
  const TipDelDia({
    required this.titulo,
    required this.texto,
    required this.baseLegal,
  });

  final String titulo;
  final String texto;
  final String baseLegal;

  String get textoParaCompartir =>
      '$titulo\n\n$texto\n\nBase legal: $baseLegal\n\nPenalex VE';
}

/// Criterio y minuta del día.
///
/// La selección es determinista por fecha: el mismo día da el mismo criterio
/// para todos, y no depende de la hora en que se abra la app.
class CriterioDiaService {
  CriterioDiaService._();

  static SupabaseClient get _db => Supabase.instance.client;

  /// Semilla del día (año, mes y día). Cambia a medianoche.
  static int get _semilla {
    final DateTime hoy = DateTime.now();
    return hoy.year * 10000 + hoy.month * 100 + hoy.day;
  }

  /// Tips curados. Se rota uno por día.
  static const List<TipDelDia> tips = <TipDelDia>[
    TipDelDia(
      titulo: '¿Delincuencia organizada con un solo sujeto?',
      texto:
          'Sí es posible. El artículo exige tres o más personas asociadas, '
          'pero también considera delincuencia organizada la actividad de una '
          'sola persona que actúa como órgano de una persona jurídica o '
          'asociativa, con la intención de cometer los delitos de la ley. '
          'Revisa si el acta individualiza la estructura detrás del sujeto.',
      baseLegal: 'Art. 4 numeral 9, Ley Orgánica Contra la Delincuencia '
          'Organizada y Financiamiento al Terrorismo',
    ),
    TipDelDia(
      titulo: 'El término medio no es la mitad de la pena',
      texto:
          'El término medio se obtiene sumando el límite mínimo y el máximo '
          'y dividiendo entre dos. Con pena de 12 a 18 años, el término medio '
          'es 15, no 9. Verifica el cálculo antes de individualizar.',
      baseLegal: 'Art. 37 del Código Penal',
    ),
    TipDelDia(
      titulo: 'La prescripción ordinaria corre desde el hecho',
      texto:
          'La prescripción de la acción penal empieza desde el día de la '
          'perpetración del hecho, no desde la detención ni desde la '
          'acusación. En delitos continuados, desde que cesó la continuación.',
      baseLegal: 'Art. 109 del Código Penal',
    ),
    TipDelDia(
      titulo: 'Atenuantes: no basta con invocarlas',
      texto:
          'Las atenuantes deben estar probadas y el tribunal debe razonar su '
          'incidencia en la pena. Invocarlas sin prueba no obliga a rebajar '
          'el término medio.',
      baseLegal: 'Art. 74 del Código Penal',
    ),
    TipDelDia(
      titulo: 'Concurso real: se suman las penas',
      texto:
          'En el concurso real de delitos las penas se suman, con el límite '
          'del artículo 80. No se toma la más grave como regla general. '
          'Verifica si el tribunal aplicó la acumulación.',
      baseLegal: 'Arts. 87 y 88 del Código Penal',
    ),
  ];

  static TipDelDia get tipDelDia => tips[_semilla % tips.length];

  /// Tip generado automáticamente a partir de una sentencia real.
  ///
  /// No pasa por revisión humana, pero no se publica si el modelo no cita una
  /// base legal. Se guarda por día para no repetir la llamada.
  static Future<TipDelDia?> tipDesdeSentencia(SentenciaModel s) async {
    final String clave = 'tip_dia_$_semilla';
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? guardado = prefs.getString(clave);
      if (guardado != null) {
        final Map<String, dynamic> m =
            jsonDecode(guardado) as Map<String, dynamic>;
        return TipDelDia(
          titulo: (m['titulo'] ?? '').toString(),
          texto: (m['texto'] ?? '').toString(),
          baseLegal: (m['baseLegal'] ?? '').toString(),
        );
      }
    } catch (_) {}

    final String material = s.ratioDecidendi.isNotEmpty
        ? s.ratioDecidendi
        : (s.resumen.isNotEmpty ? s.resumen : s.extracto);
    if (material.trim().isEmpty) return null;

    final String prompt = '''
Eres un abogado penalista venezolano. A partir de esta sentencia, escribe un
tip breve para abogados: una regla práctica que se desprenda del fallo.

Devuelve SOLO un objeto JSON, sin markdown:
{"titulo": "...", "texto": "...", "baseLegal": "Art. X de ..."}

Reglas:
- No inventes artículos. Usa solo los que aparecen en el texto.
- Si la sentencia no permite un tip claro, devuelve las tres claves vacías.
- Máximo tres frases. Español de Venezuela.

Sentencia Nº ${s.numeroSentencia} (${s.sala}, ${s.fechaSentencia}):
$material
''';

    try {
      final String respuesta = await AIService.procesarConsultaGeneral(prompt);
      final int inicio = respuesta.indexOf('{');
      final int fin = respuesta.lastIndexOf('}');
      if (inicio < 0 || fin <= inicio) return null;
      final Map<String, dynamic> m =
          jsonDecode(respuesta.substring(inicio, fin + 1))
              as Map<String, dynamic>;
      final String titulo = (m['titulo'] ?? '').toString().trim();
      final String texto = (m['texto'] ?? '').toString().trim();
      final String base = (m['baseLegal'] ?? '').toString().trim();
      if (titulo.isEmpty || texto.isEmpty || base.isEmpty) return null;
      final TipDelDia tip = TipDelDia(
        titulo: titulo,
        texto: texto,
        baseLegal: base,
      );
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        clave,
        jsonEncode(<String, String>{
          'titulo': tip.titulo,
          'texto': tip.texto,
          'baseLegal': tip.baseLegal,
        }),
      );
      return tip;
    } catch (e) {
      debugPrint('No se pudo generar el tip automático: $e');
      return null;
    }
  }

  /// Sentencia de alto valor del día. Se toma del archivo histórico, así que
  /// hay criterio aunque el TSJ no publique nada ese día. Las jurisprudencias
  /// tienen prioridad; si no hay, entra cualquier sentencia con resumen.
  static Future<SentenciaModel?> criterioDelDia() async {
    try {
      final List<dynamic> filas = await _db
          .from('sentencias')
          .select('*')
          .order('fecha_sentencia', ascending: false)
          .limit(150);
      final List<SentenciaModel> candidatas = <SentenciaModel>[
        for (final dynamic f in filas)
          SentenciaModel.fromSupabase(f as Map<String, dynamic>),
      ]..removeWhere((SentenciaModel s) =>
          s.resumen.trim().isEmpty || s.resumen == 'null');
      if (candidatas.isEmpty) return null;
      final List<SentenciaModel> jurisprudencias = candidatas
          .where((SentenciaModel s) => s.esJurisprudencia)
          .toList();
      final List<SentenciaModel> pool =
          jurisprudencias.isNotEmpty ? jurisprudencias : candidatas;
      return pool[_semilla % pool.length];
    } catch (e) {
      debugPrint('No se pudo cargar el criterio del día: $e');
      return null;
    }
  }

  /// Minuta: lo publicado hoy antes de las 8:00. Si no hay nada, las más
  /// recientes de alto valor y `nuevas` queda en false.
  static Future<({List<SentenciaModel> sentencias, bool nuevas})>
      minutaDelDia({int limite = 5}) async {
    final DateTime ahora = DateTime.now();
    final DateTime inicioDia = DateTime(ahora.year, ahora.month, ahora.day);
    final DateTime corteOcho = DateTime(ahora.year, ahora.month, ahora.day, 8);
    try {
      final List<dynamic> hoy = await _db
          .from('sentencias')
          .select('*')
          .eq('es_jurisprudencia', true)
          .gte('created_at', inicioDia.toIso8601String())
          .lte('created_at', corteOcho.toIso8601String())
          .order('created_at', ascending: false)
          .limit(limite);
      if (hoy.isNotEmpty) {
        return (
          sentencias: <SentenciaModel>[
            for (final dynamic f in hoy)
              SentenciaModel.fromSupabase(f as Map<String, dynamic>),
          ],
          nuevas: true,
        );
      }
      final List<dynamic> filas = await _db
          .from('sentencias')
          .select('*')
          .eq('es_jurisprudencia', true)
          .order('fecha_sentencia', ascending: false)
          .limit(limite);
      return (
        sentencias: <SentenciaModel>[
          for (final dynamic f in filas)
            SentenciaModel.fromSupabase(f as Map<String, dynamic>),
        ],
        nuevas: false,
      );
    } catch (e) {
      debugPrint('No se pudo cargar la minuta: $e');
      return (sentencias: <SentenciaModel>[], nuevas: false);
    }
  }
}

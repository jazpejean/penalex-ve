import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sentencia_model.dart';

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

  /// Sentencia de alto valor del día: jurisprudencia, con resumen.
  static Future<SentenciaModel?> criterioDelDia() async {
    try {
      final List<dynamic> filas = await _db
          .from('sentencias')
          .select('*')
          .eq('es_jurisprudencia', true)
          .order('fecha_sentencia', ascending: false)
          .limit(40);
      if (filas.isEmpty) return null;
      final List<SentenciaModel> candidatas = <SentenciaModel>[
        for (final dynamic f in filas)
          SentenciaModel.fromSupabase(f as Map<String, dynamic>),
      ]..removeWhere((SentenciaModel s) =>
          s.resumen.trim().isEmpty || s.resumen == 'null');
      if (candidatas.isEmpty) return null;
      return candidatas[_semilla % candidatas.length];
    } catch (e) {
      debugPrint('No se pudo cargar el criterio del día: $e');
      return null;
    }
  }

  /// Minuta: lo publicado hoy antes de las 8:00. Si no hay nada, las más
  /// recientes de alto valor.
  static Future<List<SentenciaModel>> minutaDelDia({int limite = 5}) async {
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
        return <SentenciaModel>[
          for (final dynamic f in hoy)
            SentenciaModel.fromSupabase(f as Map<String, dynamic>),
        ];
      }
      final List<dynamic> filas = await _db
          .from('sentencias')
          .select('*')
          .eq('es_jurisprudencia', true)
          .order('fecha_sentencia', ascending: false)
          .limit(limite);
      return <SentenciaModel>[
        for (final dynamic f in filas)
          SentenciaModel.fromSupabase(f as Map<String, dynamic>),
      ];
    } catch (e) {
      debugPrint('No se pudo cargar la minuta: $e');
      return <SentenciaModel>[];
    }
  }
}

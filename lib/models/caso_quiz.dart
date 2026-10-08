import 'dart:math';

/// Caso hipotético del quiz, almacenado como JSON en Supabase Storage.
/// Incluye la fundamentación (artículos + sentencias) para mostrarla al acertar.
class CasoQuiz {
  final String id;
  final int nivel; // tramo de nivel al que pertenece
  final int tramo; // 1=parte general, 2=personas, 3=propiedad, 4=COPP, 5=especiales
  final String delitoBase;
  final String contextoNarrativo;
  final List<String> opciones;
  final int respuestaCorrecta;
  final int dificultad; // 1-3
  final String fundamentacion;
  final List<String> articulos; // ej. "Art. 405 Código Penal"
  final List<String> sentencias; // ej. "Sentencia Nº ... · Sala ... · fecha"

  const CasoQuiz({
    required this.id,
    required this.nivel,
    required this.tramo,
    required this.delitoBase,
    required this.contextoNarrativo,
    required this.opciones,
    required this.respuestaCorrecta,
    this.dificultad = 2,
    this.fundamentacion = '',
    this.articulos = const [],
    this.sentencias = const [],
  });

  factory CasoQuiz.fromJson(Map<String, dynamic> json) => CasoQuiz(
        id: json['id'] as String,
        nivel: (json['nivel'] as num?)?.toInt() ?? 1,
        tramo: (json['tramo'] as num?)?.toInt() ?? 1,
        delitoBase: json['delito_base'] as String? ?? '',
        contextoNarrativo: json['contexto'] as String? ?? '',
        opciones: (json['opciones'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        respuestaCorrecta: (json['respuesta_correcta'] as num?)?.toInt() ?? 0,
        dificultad: (json['dificultad'] as num?)?.toInt() ?? 2,
        fundamentacion: json['fundamentacion'] as String? ?? '',
        articulos:
            (json['articulos'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
        sentencias:
            (json['sentencias'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nivel': nivel,
        'tramo': tramo,
        'delito_base': delitoBase,
        'contexto': contextoNarrativo,
        'opciones': opciones,
        'respuesta_correcta': respuestaCorrecta,
        'dificultad': dificultad,
        'fundamentacion': fundamentacion,
        'articulos': articulos,
        'sentencias': sentencias,
      };

  /// Devuelve una copia con las opciones barajadas (anti-predecible).
  CasoQuiz conOpcionesBarajadas(Random rng) {
    final indices = List<int>.generate(opciones.length, (i) => i)..shuffle(rng);
    final nuevasOpciones = indices.map((i) => opciones[i]).toList();
    final nuevaCorrecta = indices.indexOf(respuestaCorrecta);
    return CasoQuiz(
      id: id,
      nivel: nivel,
      tramo: tramo,
      delitoBase: delitoBase,
      contextoNarrativo: contextoNarrativo,
      opciones: nuevasOpciones,
      respuestaCorrecta: nuevaCorrecta,
      dificultad: dificultad,
      fundamentacion: fundamentacion,
      articulos: articulos,
      sentencias: sentencias,
    );
  }
}

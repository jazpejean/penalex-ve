class Question {

  Question({
    required this.id,
    required this.nivel,
    required this.pregunta,
    required this.opciones,
    required this.respuestaCorrecta,
    required this.fundamentacion,
  });

    factory Question.fromDocument(Map<String, dynamic> doc, String id) => 
      Question(
      id: id,
      nivel: (doc['nivel'] as int?) ?? 0,
      pregunta: (doc['pregunta'] as String?) ?? '',
      opciones: List<String>.from(
          (doc['opciones'] as List<dynamic>?) ?? <dynamic>[],),
      respuestaCorrecta: (doc['respuesta_correcta'] as int?) ?? 0,
      fundamentacion: (doc['fundamentacion'] as String?) ?? '',
    );
  final String id;
  final int nivel;
  final String pregunta;
  final List<String> opciones;
  final int respuestaCorrecta;
  final String fundamentacion;
}
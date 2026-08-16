class Question {

  Question({
    required this.id,
    required this.nivel,
    required this.pregunta,
    required this.opciones,
    required this.respuestaCorrecta,
    required this.fundamentacion,
  });

    factory Question.fromDocument(Map<String, dynamic> doc, String id) {
    // Manejo flexible de campos para compatibilidad
    final dynamic opcionesData = doc['opciones'] ?? <dynamic>[];
    final List<String> opcionesList = opcionesData is List
        ? opcionesData.map((item) => item.toString()).toList()
        : <String>[];
    
    return Question(
      id: id,
      nivel: (doc['nivel'] as num?)?.toInt() ?? 0,
      pregunta: (doc['pregunta'] as String?) ?? 'Pregunta no disponible',
      opciones: opcionesList,
      respuestaCorrecta: (doc['respuesta_correcta'] as num?)?.toInt() ?? 0,
      fundamentacion: (doc['fundamentacion'] as String?) ?? '',
    );
  }
  
  final String id;
  final int nivel;
  final String pregunta;
  final List<String> opciones;
  final int respuestaCorrecta;
  final String fundamentacion;
}
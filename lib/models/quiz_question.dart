import 'package:cloud_firestore/cloud_firestore.dart';

class QuizQuestion {

  QuizQuestion({
    required this.id,
    required this.nivel,
    required this.pregunta,
    required this.opciones,
    required this.respuestaCorrecta,
    required this.fundamentacion,
  });

  factory QuizQuestion.fromDocument(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final dynamic opcionesData = data["opciones"] ?? data["options"] ?? <dynamic>[];
    final List<String> opcionesList = opcionesData is List
        ? opcionesData.map((item) => item.toString()).toList()
        : <String>[];
    final int respuestaIndex = (data["respuesta_correcta"] as num?)?.toInt() ??
        (data["respuestaCorrecta"] as num?)?.toInt() ??
        (data["correctAnswer"] as num?)?.toInt() ??
        0;

    return QuizQuestion(
      id: doc.id,
      nivel: (data["nivel"] as num?)?.toInt() ??
          (data["level"] as num?)?.toInt() ??
          0,
      pregunta: data["pregunta"]?.toString() ??
          data["question"]?.toString() ??
          "Pregunta no disponible",
      opciones: List<String>.from(opcionesList),
      respuestaCorrecta: respuestaIndex,
      fundamentacion: data["fundamentacion"]?.toString() ??
          data["fundamentación"]?.toString() ??
          "",
    );
  }
  final String id;
  final int nivel;
  final String pregunta;
  final List<String> opciones;
  final int respuestaCorrecta;
  final String fundamentacion;
}

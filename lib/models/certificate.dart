import 'package:cloud_firestore/cloud_firestore.dart';

class Certificate {

  Certificate({
    required this.titulo,
    required this.fecha,
    required this.urlPdf,
    required this.nivelAlcanzado,
    this.maxScore = 0,
  });

  factory Certificate.fromMap(Map<String, dynamic> map) => Certificate(
      titulo: (map['titulo'] as String?) ?? '',
      fecha: (map['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      urlPdf: (map['url_pdf'] as String?) ?? '',
      nivelAlcanzado: (map['nivel_alcanzado'] as num?)?.toInt() ?? 0,
      maxScore: (map['maxScore'] as num?)?.toInt() ?? 0,
    );
  final String titulo;
  final DateTime fecha;
  final String urlPdf;
  final int nivelAlcanzado;
  final int maxScore;

  // Getters para compatibilidad con achievements_screen
  String get rankName => titulo;
  DateTime get dateObtained => fecha;

  Map<String, dynamic> toMap() => <String, dynamic>{
      "titulo": titulo,
      "fecha": Timestamp.fromDate(fecha),
      "url_pdf": urlPdf,
      "nivel_alcanzado": nivelAlcanzado,
      "maxScore": maxScore,
    };
}
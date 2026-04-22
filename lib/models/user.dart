import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {

  UserModel({
    required this.uid,
    required this.nombre,
    required this.nivelActual,
    required this.puntosTotales,
    required this.rangoActual,
    required this.fechaRegistro,
    this.puntuacionMaxima = 0,
    this.rachaMaxima = 0,
    this.preguntasRespondidas = 0,
    this.preguntasCorrectas = 0,
    this.tiempoPromedioRespuesta = 0.0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
      uid: (map['uid'] as String?) ?? '',
      nombre: (map['nombre'] as String?) ?? '',
      nivelActual: (map['nivelActual'] as num?)?.toInt() ?? 0,
      puntosTotales: (map['puntosTotales'] as num?)?.toInt() ?? 0,
      rangoActual: (map['rangoActual'] as String?) ?? 'Alguacil',
      fechaRegistro: (map['fechaRegistro'] as Timestamp?)?.toDate() ?? DateTime.now(),
      puntuacionMaxima: (map['puntuacionMaxima'] as num?)?.toInt() ?? 0,
      rachaMaxima: (map['rachaMaxima'] as num?)?.toInt() ?? 0,
      preguntasRespondidas: (map['preguntasRespondidas'] as num?)?.toInt() ?? 0,
      preguntasCorrectas: (map['preguntasCorrectas'] as num?)?.toInt() ?? 0,
      tiempoPromedioRespuesta: (map['tiempoPromedioRespuesta'] as num?)?.toDouble() ?? 0.0,
    );
  final String uid;
  final String nombre;
  final int nivelActual;
  final int puntosTotales;
  final String rangoActual;
  final DateTime fechaRegistro;
  final int puntuacionMaxima;
  final int rachaMaxima;
  final int preguntasRespondidas;
  final int preguntasCorrectas;
  final double tiempoPromedioRespuesta;

  UserModel copyWith({
    String? uid,
    String? nombre,
    int? nivelActual,
    int? puntosTotales,
    String? rangoActual,
    DateTime? fechaRegistro,
    int? puntuacionMaxima,
    int? rachaMaxima,
    int? preguntasRespondidas,
    int? preguntasCorrectas,
    double? tiempoPromedioRespuesta,
  }) => UserModel(
      uid: uid ?? this.uid,
      nombre: nombre ?? this.nombre,
      nivelActual: nivelActual ?? this.nivelActual,
      puntosTotales: puntosTotales ?? this.puntosTotales,
      rangoActual: rangoActual ?? this.rangoActual,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      puntuacionMaxima: puntuacionMaxima ?? this.puntuacionMaxima,
      rachaMaxima: rachaMaxima ?? this.rachaMaxima,
      preguntasRespondidas: preguntasRespondidas ?? this.preguntasRespondidas,
      preguntasCorrectas: preguntasCorrectas ?? this.preguntasCorrectas,
      tiempoPromedioRespuesta: tiempoPromedioRespuesta ?? this.tiempoPromedioRespuesta,
    );

  Map<String, dynamic> toMap() => <String, dynamic>{
      "uid": uid,
      "nombre": nombre,
      "nivelActual": nivelActual,
      "puntosTotales": puntosTotales,
      "rangoActual": rangoActual,
      "fechaRegistro": Timestamp.fromDate(fechaRegistro),
      "puntuacionMaxima": puntuacionMaxima,
      "rachaMaxima": rachaMaxima,
      "preguntasRespondidas": preguntasRespondidas,
      "preguntasCorrectas": preguntasCorrectas,
      "tiempoPromedioRespuesta": tiempoPromedioRespuesta,
    };
}
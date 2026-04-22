import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {

  ReportModel({
    required this.id,
    required this.nombre,
    required this.fecha,
    required this.contenido,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map, String id) {
    final fechaValue = map["fecha"];
    final DateTime fecha = fechaValue is Timestamp
        ? fechaValue.toDate()
        : DateTime.tryParse(map["fecha"]?.toString() ?? "") ?? DateTime.now();

    return ReportModel(
      id: id,
      nombre: (map["nombre"] as String?) ?? "Reporte sin nombre",
      fecha: fecha,
      contenido: (map["contenido"] as String?) ?? "",
    );
  }
  final String id;
  final String nombre;
  final DateTime fecha;
  final String contenido;

  Map<String, dynamic> toMap() => <String, dynamic>{
      "nombre": nombre,
      "fecha": fecha.toIso8601String(),
      "contenido": contenido,
    };
}

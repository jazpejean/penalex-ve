import 'package:cloud_firestore/cloud_firestore.dart';
import 'delito.dart';

class CalculationModel {

  CalculationModel({
    required this.id,
    required this.nombre,
    required this.fecha,
    required this.delitos,
    required this.concurso,
    required this.admisionHechos,
    required this.fraccionAdmision,
  });

    factory CalculationModel.fromMap(Map<String, dynamic> map) {
    final dynamic fechaValue = map["fecha"];
    DateTime fecha;
    if (fechaValue is DateTime) {
      fecha = fechaValue;
    } else if (fechaValue is Timestamp) {
      fecha = fechaValue.toDate();
        } else if (fechaValue is Map<String, dynamic> && 
        fechaValue["_seconds"] != null) {
      fecha = DateTime.fromMillisecondsSinceEpoch(
          (fechaValue["_seconds"] as int) * 1000); // ignore: require_trailing_commas
    } else {
      final String fechaString = map["fecha"]?.toString() ?? "";
      fecha = DateTime.tryParse(fechaString) ?? DateTime.now();
    }

    return CalculationModel(
      id: (map["id"] as String?) ?? "",
      nombre: (map["nombre"] as String?) ?? "Sin nombre",
      fecha: fecha,
      delitos: (map["delitos"] as List<dynamic>?)
              ?.map((Object? d) => Delito.fromMap(d as Map<String, dynamic>))
              .toList() ??
          <Delito>[],
      concurso: TipoConcurso.values[(map["concurso"] as int?) ?? 0],
      admisionHechos: (map["admisionHechos"] as bool?) ?? false,
      fraccionAdmision: (map["fraccionAdmision"] as num?)?.toDouble() ?? 
          0.3333,
    );
  }
  final String id;
  final String nombre;
  final DateTime fecha;
  final List<Delito> delitos;
  final TipoConcurso concurso;
  final bool admisionHechos;
  final double fraccionAdmision;

  Map<String, dynamic> toMap() => <String, dynamic>{
      "id": id,
      "nombre": nombre,
      "fecha": fecha.toIso8601String(),
      "delitos": delitos.map((Delito d) => d.toMap()).toList(),
      "concurso": concurso.index,
      "admisionHechos": admisionHechos,
      "fraccionAdmision": fraccionAdmision,
    };
}
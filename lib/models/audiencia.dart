class Audiencia {

  Audiencia({
    required this.id,
    required this.expediente,
    required this.tribunal,
    required this.imputado,
    required this.cedula,
    required this.fiscalia,
    required this.delitos,
    required this.fecha,
    required this.hora,
    required this.tipo,
    required this.notas,
  });

  factory Audiencia.fromJson(Map<String, dynamic> json) => Audiencia(
      id: json['id']?.toString() ?? '',
      expediente: json['expediente']?.toString() ?? '',
      tribunal: json['tribunal']?.toString(),
      imputado: json['imputado']?.toString() ?? '',
      cedula: json['cedula']?.toString(),
      fiscalia: json['fiscalia']?.toString(),
      delitos: json['delitos']?.toString(),
            fecha: DateTime.parse(
          json['fecha']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      hora: json['hora']?.toString() ?? '',
      tipo: json['tipo']?.toString(),
      notas: json['notas']?.toString(),
    );
  final String id;
  final String expediente;
  final String? tribunal;
  final String imputado;
  final String? cedula;
  final String? fiscalia;
  final String? delitos;
  final DateTime fecha;
  final String hora;
  final String? tipo;
  final String? notas;

  Map<String, dynamic> toJson() => <String, dynamic>{
      "id": id,
      "expediente": expediente,
      "tribunal": tribunal,
      "imputado": imputado,
      "cedula": cedula,
      "fiscalia": fiscalia,
      "delitos": delitos,
      "fecha": fecha.toIso8601String(),
      "hora": hora,
      "tipo": tipo,
      "notas": notas,
    };
}
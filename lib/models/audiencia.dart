/// Audiencia judicial del usuario (agenda personal de Penalex VE).
///
/// Vive en Supabase (`agenda_eventos`), con `user_id` = UID de Firebase.
/// [tribunalId] vincula la audiencia con su tribunal real del catálogo
/// (tabla `tribunales`), lo que permite abrir la ficha con foto/mapa/ruta.
class Audiencia {
  Audiencia({
    required this.id,
    required this.expediente,
    required this.tribunal,
    this.tribunalId,
    required this.imputado,
    required this.cedula,
    required this.fiscalia,
    required this.delitos,
    required this.fecha,
    required this.hora,
    required this.tipo,
    required this.notas,
    this.recordatorioMinutos = 0,
  });

  factory Audiencia.fromJson(Map<String, dynamic> json) => Audiencia(
        id: json['id']?.toString() ?? '',
        expediente: json['expediente']?.toString() ?? '',
        tribunal: json['tribunal']?.toString(),
        tribunalId: json['tribunal_id']?.toString(),
        imputado: json['imputado']?.toString() ?? '',
        cedula: json['cedula']?.toString(),
        fiscalia: json['fiscalia']?.toString(),
        delitos: json['delitos']?.toString(),
        fecha: DateTime.tryParse(json['fecha']?.toString() ?? '') ??
            DateTime.now(),
        hora: json['hora']?.toString() ?? '',
        tipo: json['tipo']?.toString(),
        notas: json['notas']?.toString(),
        recordatorioMinutos:
            (json['recordatorio_minutos'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String expediente;
  final String? tribunal;
  final String? tribunalId;
  final String imputado;
  final String? cedula;
  final String? fiscalia;
  final String? delitos;
  final DateTime fecha;
  final String hora;
  final String? tipo;
  final String? notas;
  final int recordatorioMinutos;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'expediente': expediente,
        'tribunal': tribunal,
        'tribunal_id': tribunalId,
        'imputado': imputado,
        'cedula': cedula,
        'fiscalia': fiscalia,
        'delitos': delitos,
        'fecha': fecha.toIso8601String(),
        'hora': hora,
        'tipo': tipo,
        'notas': notas,
        'recordatorio_minutos': recordatorioMinutos,
      };
}
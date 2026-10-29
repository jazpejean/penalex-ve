/// Expediente (portafolio de una causa penal).
///
/// Se crea automáticamente al agendar una audiencia con número de
/// expediente (tabla `expedientes` en Supabase). Agrupa los datos de la
/// causa y sirve de portafolio para los documentos del caso (vínculo con
/// `documentos_escaneados.expediente_id`).
class Expediente {
  final String id;
  final String userId;
  final String numeroExpediente;
  final String imputado;
  final String? cedula;
  final String? delitos;
  final String? tribunalId;
  final String? tribunalNombre;
  final String? estadoProcesal;
  final DateTime? fechaAudiencia;
  final DateTime createdAt;

  Expediente({
    required this.id,
    required this.userId,
    required this.numeroExpediente,
    required this.imputado,
    this.cedula,
    this.delitos,
    this.tribunalId,
    this.tribunalNombre,
    this.estadoProcesal,
    this.fechaAudiencia,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'user_id': userId,
        'numero_expediente': numeroExpediente,
        'imputado': imputado,
        'cedula': cedula,
        'delitos': delitos,
        'tribunal_id': tribunalId,
        'tribunal_nombre': tribunalNombre,
        'estado_procesal': estadoProcesal,
        'fecha_audiencia': fechaAudiencia?.toUtc().toIso8601String(),
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  factory Expediente.fromJson(Map<String, dynamic> json) => Expediente(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        numeroExpediente: json['numero_expediente'] as String,
        imputado: json['imputado'] as String,
        cedula: json['cedula'] as String?,
        delitos: json['delitos'] as String?,
        tribunalId: json['tribunal_id'] as String?,
        tribunalNombre: json['tribunal_nombre'] as String?,
        estadoProcesal: json['estado_procesal'] as String?,
        fechaAudiencia: json['fecha_audiencia'] != null
            ? DateTime.parse(json['fecha_audiencia'] as String).toLocal()
            : null,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
}
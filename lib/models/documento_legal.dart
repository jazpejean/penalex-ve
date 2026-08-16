import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de documentos legales
enum TipoDocumento {
  demanda,
  contestacion,
  recurso,
  escrito,
  memorial,
  solicitud,
  poder,
  contrato,
  sentencia,
  auto,
  providencia,
  acta,
  otro;
  
  String get nombre {
    switch (this) {
      case TipoDocumento.demanda:
        return 'Demanda';
      case TipoDocumento.contestacion:
        return 'Contestación';
      case TipoDocumento.recurso:
        return 'Recurso';
      case TipoDocumento.escrito:
        return 'Escrito';
      case TipoDocumento.memorial:
        return 'Memorial';
      case TipoDocumento.solicitud:
        return 'Solicitud';
      case TipoDocumento.poder:
        return 'Poder';
      case TipoDocumento.contrato:
        return 'Contrato';
      case TipoDocumento.sentencia:
        return 'Sentencia';
      case TipoDocumento.auto:
        return 'Auto';
      case TipoDocumento.providencia:
        return 'Providencia';
      case TipoDocumento.acta:
        return 'Acta';
      case TipoDocumento.otro:
        return 'Otro';
    }
  }
}

/// Estado del documento
enum EstadoDocumento {
  borrador,
  revision,
  finalizado,
  enviado;
  
  String get nombre {
    switch (this) {
      case EstadoDocumento.borrador:
        return 'Borrador';
      case EstadoDocumento.revision:
        return 'En revisión';
      case EstadoDocumento.finalizado:
        return 'Finalizado';
      case EstadoDocumento.enviado:
        return 'Enviado';
    }
  }
}

/// Modelo de documento legal
class DocumentoLegal {
  final String id;
  final String userId;
  final TipoDocumento tipo;
  final String titulo;
  final String contenido;
  final EstadoDocumento estado;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Metadatos
  final String? caso;
  final String? tribunal;
  final String? expediente;
  final List<String> partes;
  final List<String> tags;
  
  // IA
  final String? promptOriginal;
  final String? modeloIA;
  final bool generadoPorIA;
  
  // Imágenes escaneadas
  final List<String> imagenesURL;
  final bool creadoDesdeImagen;
  final String? textoOCR;
  
  // Versiones
  final int version;
  final String? versionAnteriorId;
  
  DocumentoLegal({
    required this.id,
    required this.userId,
    required this.tipo,
    required this.titulo,
    required this.contenido,
    required this.estado,
    required this.createdAt,
    this.updatedAt,
    this.caso,
    this.tribunal,
    this.expediente,
    this.partes = const [],
    this.tags = const [],
    this.promptOriginal,
    this.modeloIA,
    this.generadoPorIA = false,
    this.imagenesURL = const [],
    this.creadoDesdeImagen = false,
    this.textoOCR,
    this.version = 1,
    this.versionAnteriorId,
  });
  
  factory DocumentoLegal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DocumentoLegal(
      id: doc.id,
      userId: data['userId'] as String,
      tipo: TipoDocumento.values.firstWhere(
        (e) => e.name == data['tipo'],
        orElse: () => TipoDocumento.otro,
      ),
      titulo: data['titulo'] as String,
      contenido: data['contenido'] as String,
      estado: EstadoDocumento.values.firstWhere(
        (e) => e.name == data['estado'],
        orElse: () => EstadoDocumento.borrador,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      caso: data['caso'] as String?,
      tribunal: data['tribunal'] as String?,
      expediente: data['expediente'] as String?,
      partes: data['partes'] != null 
          ? List<String>.from(data['partes'] as List)
          : [],
      tags: data['tags'] != null 
          ? List<String>.from(data['tags'] as List)
          : [],
      promptOriginal: data['promptOriginal'] as String?,
      modeloIA: data['modeloIA'] as String?,
      generadoPorIA: data['generadoPorIA'] as bool? ?? false,
      imagenesURL: data['imagenesURL'] != null 
          ? List<String>.from(data['imagenesURL'] as List)
          : [],
      creadoDesdeImagen: data['creadoDesdeImagen'] as bool? ?? false,
      textoOCR: data['textoOCR'] as String?,
      version: data['version'] as int? ?? 1,
      versionAnteriorId: data['versionAnteriorId'] as String?,
    );
  }
  
  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'tipo': tipo.name,
    'titulo': titulo,
    'contenido': contenido,
    'estado': estado.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'caso': caso,
    'tribunal': tribunal,
    'expediente': expediente,
    'partes': partes,
    'tags': tags,
    'promptOriginal': promptOriginal,
    'modeloIA': modeloIA,
    'generadoPorIA': generadoPorIA,
    'imagenesURL': imagenesURL,
    'creadoDesdeImagen': creadoDesdeImagen,
    'textoOCR': textoOCR,
    'version': version,
    'versionAnteriorId': versionAnteriorId,
  };
  
  DocumentoLegal copyWith({
    String? id,
    String? userId,
    TipoDocumento? tipo,
    String? titulo,
    String? contenido,
    EstadoDocumento? estado,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? caso,
    String? tribunal,
    String? expediente,
    List<String>? partes,
    List<String>? tags,
    String? promptOriginal,
    String? modeloIA,
    bool? generadoPorIA,
    List<String>? imagenesURL,
    bool? creadoDesdeImagen,
    String? textoOCR,
    int? version,
    String? versionAnteriorId,
  }) =>
      DocumentoLegal(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        tipo: tipo ?? this.tipo,
        titulo: titulo ?? this.titulo,
        contenido: contenido ?? this.contenido,
        estado: estado ?? this.estado,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        caso: caso ?? this.caso,
        tribunal: tribunal ?? this.tribunal,
        expediente: expediente ?? this.expediente,
        partes: partes ?? this.partes,
        tags: tags ?? this.tags,
        promptOriginal: promptOriginal ?? this.promptOriginal,
        modeloIA: modeloIA ?? this.modeloIA,
        generadoPorIA: generadoPorIA ?? this.generadoPorIA,
        imagenesURL: imagenesURL ?? this.imagenesURL,
        creadoDesdeImagen: creadoDesdeImagen ?? this.creadoDesdeImagen,
        textoOCR: textoOCR ?? this.textoOCR,
        version: version ?? this.version,
        versionAnteriorId: versionAnteriorId ?? this.versionAnteriorId,
      );
}

/// Plantilla de documento
class PlantillaDocumento {
  final String id;
  final TipoDocumento tipo;
  final String nombre;
  final String descripcion;
  final String estructura;
  final List<String> camposRequeridos;
  final String promptBase;
  
  PlantillaDocumento({
    required this.id,
    required this.tipo,
    required this.nombre,
    required this.descripcion,
    required this.estructura,
    required this.camposRequeridos,
    required this.promptBase,
  });
  
  factory PlantillaDocumento.fromMap(Map<String, dynamic> map) =>
      PlantillaDocumento(
        id: map['id'] as String,
        tipo: TipoDocumento.values.firstWhere(
          (e) => e.name == map['tipo'],
          orElse: () => TipoDocumento.otro,
        ),
        nombre: map['nombre'] as String,
        descripcion: map['descripcion'] as String,
        estructura: map['estructura'] as String,
        camposRequeridos: List<String>.from(map['camposRequeridos'] as List),
        promptBase: map['promptBase'] as String,
      );
  
  Map<String, dynamic> toMap() => {
    'id': id,
    'tipo': tipo.name,
    'nombre': nombre,
    'descripcion': descripcion,
    'estructura': estructura,
    'camposRequeridos': camposRequeridos,
    'promptBase': promptBase,
  };
}

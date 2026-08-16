import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de escritos legales
enum TipoEscrito {
  recursoApelacion,
  escritoDefensa,
  solicitudLibertad,
  oposicionMedidas,
  demanda,
  contestacion,
  alegatos,
  solicitudGeneral,
}

extension TipoEscritoExtension on TipoEscrito {
  String get nombre {
    switch (this) {
      case TipoEscrito.recursoApelacion:
        return 'Recurso de Apelación';
      case TipoEscrito.escritoDefensa:
        return 'Escrito de Defensa';
      case TipoEscrito.solicitudLibertad:
        return 'Solicitud de Libertad';
      case TipoEscrito.oposicionMedidas:
        return 'Oposición a Medidas Cautelares';
      case TipoEscrito.demanda:
        return 'Demanda';
      case TipoEscrito.contestacion:
        return 'Contestación';
      case TipoEscrito.alegatos:
        return 'Alegatos';
      case TipoEscrito.solicitudGeneral:
        return 'Solicitud General';
    }
  }

  String get descripcion {
    switch (this) {
      case TipoEscrito.recursoApelacion:
        return 'Impugna una decisión judicial ante instancia superior';
      case TipoEscrito.escritoDefensa:
        return 'Argumenta la defensa del imputado en el proceso';
      case TipoEscrito.solicitudLibertad:
        return 'Solicita libertad o medida cautelar menos gravosa';
      case TipoEscrito.oposicionMedidas:
        return 'Se opone a medidas cautelares solicitadas por fiscal';
      case TipoEscrito.demanda:
        return 'Inicia acción legal contra el imputado';
      case TipoEscrito.contestacion:
        return 'Responde a una demanda presentada';
      case TipoEscrito.alegatos:
        return 'Argumentación final en juicio oral';
      case TipoEscrito.solicitudGeneral:
        return 'Solicitud genérica al tribunal';
    }
  }
}

/// Escrito legal generado
class EscritoLegal {
  EscritoLegal({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.contenido,
    required this.createdAt,
    this.updatedAt,
    this.numeroCaso,
    this.tribunal,
    this.juez,
    this.imputado,
    this.delitos = const [],
    this.fundamentosLegales = const [],
    this.generadoPorIA = false,
    this.modeloIA,
    this.prompt,
  });

  factory EscritoLegal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EscritoLegal(
      id: doc.id,
      tipo: TipoEscrito.values[data['tipo'] as int? ?? 0],
      titulo: data['titulo'] as String? ?? '',
      contenido: data['contenido'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      numeroCaso: data['numeroCaso'] as String?,
      tribunal: data['tribunal'] as String?,
      juez: data['juez'] as String?,
      imputado: data['imputado'] as String?,
      delitos: (data['delitos'] as List<dynamic>?)?.cast<String>() ?? [],
      fundamentosLegales:
          (data['fundamentosLegales'] as List<dynamic>?)?.cast<String>() ?? [],
      generadoPorIA: data['generadoPorIA'] as bool? ?? false,
      modeloIA: data['modeloIA'] as String?,
      prompt: data['prompt'] as String?,
    );
  }

  final String id;
  final TipoEscrito tipo;
  final String titulo;
  final String contenido;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? numeroCaso;
  final String? tribunal;
  final String? juez;
  final String? imputado;
  final List<String> delitos;
  final List<String> fundamentosLegales;
  final bool generadoPorIA;
  final String? modeloIA;
  final String? prompt;

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo.index,
      'titulo': titulo,
      'contenido': contenido,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (numeroCaso != null) 'numeroCaso': numeroCaso,
      if (tribunal != null) 'tribunal': tribunal,
      if (juez != null) 'juez': juez,
      if (imputado != null) 'imputado': imputado,
      'delitos': delitos,
      'fundamentosLegales': fundamentosLegales,
      'generadoPorIA': generadoPorIA,
      if (modeloIA != null) 'modeloIA': modeloIA,
      if (prompt != null) 'prompt': prompt,
    };
  }

  EscritoLegal copyWith({
    String? id,
    TipoEscrito? tipo,
    String? titulo,
    String? contenido,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? numeroCaso,
    String? tribunal,
    String? juez,
    String? imputado,
    List<String>? delitos,
    List<String>? fundamentosLegales,
    bool? generadoPorIA,
    String? modeloIA,
    String? prompt,
  }) {
    return EscritoLegal(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      numeroCaso: numeroCaso ?? this.numeroCaso,
      tribunal: tribunal ?? this.tribunal,
      juez: juez ?? this.juez,
      imputado: imputado ?? this.imputado,
      delitos: delitos ?? this.delitos,
      fundamentosLegales: fundamentosLegales ?? this.fundamentosLegales,
      generadoPorIA: generadoPorIA ?? this.generadoPorIA,
      modeloIA: modeloIA ?? this.modeloIA,
      prompt: prompt ?? this.prompt,
    );
  }
}

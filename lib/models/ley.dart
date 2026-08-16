import 'package:cloud_firestore/cloud_firestore.dart';

class Ley {
  final String id;
  final String titulo;
  final String nombreCorto; // "CP", "COPP", "LOSDMVLV"
  final String gaceta; // "G.O. N° 5.768 Extraordinario"
  final DateTime fechaPublicacion;
  final String descripcion;
  final List<Capitulo> capitulos;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  Ley({
    required this.id,
    required this.titulo,
    required this.nombreCorto,
    required this.gaceta,
    required this.fechaPublicacion,
    required this.descripcion,
    required this.capitulos,
    required this.createdAt,
    this.updatedAt,
  });
  
  factory Ley.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Ley(
      id: doc.id,
      titulo: data['titulo'] as String,
      nombreCorto: data['nombreCorto'] as String,
      gaceta: data['gaceta'] as String,
      fechaPublicacion: (data['fechaPublicacion'] as Timestamp).toDate(),
      descripcion: data['descripcion'] as String,
      capitulos: (data['capitulos'] as List)
          .map((c) => Capitulo.fromMap(c as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
  
  Map<String, dynamic> toFirestore() => {
    'titulo': titulo,
    'nombreCorto': nombreCorto,
    'gaceta': gaceta,
    'fechaPublicacion': Timestamp.fromDate(fechaPublicacion),
    'descripcion': descripcion,
    'capitulos': capitulos.map((c) => c.toMap()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };
}

class Capitulo {
  final String numero; // "I", "II", "III"
  final String titulo;
  final List<Articulo> articulos;
  
  Capitulo({
    required this.numero,
    required this.titulo,
    required this.articulos,
  });
  
  factory Capitulo.fromMap(Map<String, dynamic> map) => Capitulo(
    numero: map['numero'] as String,
    titulo: map['titulo'] as String,
    articulos: (map['articulos'] as List)
        .map((a) => Articulo.fromMap(a as Map<String, dynamic>))
        .toList(),
  );
  
  Map<String, dynamic> toMap() => {
    'numero': numero,
    'titulo': titulo,
    'articulos': articulos.map((a) => a.toMap()).toList(),
  };
}

class Articulo {
  final String numero; // "406", "74", "1"
  final String texto;
  final List<String>? incisos; // Opcionales
  final String? nota; // Nota aclaratoria
  final bool? derogado; // Si fue derogado
  final String? reformadoPor; // Ley que lo reformó
  
  // Campos de usuario
  final bool? esFavorito;
  final String? notasUsuario;
  
  Articulo({
    required this.numero,
    required this.texto,
    this.incisos,
    this.nota,
    this.derogado,
    this.reformadoPor,
    this.esFavorito,
    this.notasUsuario,
  });
  
  factory Articulo.fromMap(Map<String, dynamic> map) => Articulo(
    numero: map['numero'] as String,
    texto: map['texto'] as String,
    incisos: map['incisos'] != null
        ? List<String>.from(map['incisos'] as List)
        : null,
    nota: map['nota'] as String?,
    derogado: map['derogado'] as bool?,
    reformadoPor: map['reformadoPor'] as String?,
    esFavorito: map['esFavorito'] as bool?,
    notasUsuario: map['notasUsuario'] as String?,
  );
  
  Map<String, dynamic> toMap() => {
    'numero': numero,
    'texto': texto,
    'incisos': incisos,
    'nota': nota,
    'derogado': derogado,
    'reformadoPor': reformadoPor,
    'esFavorito': esFavorito,
    'notasUsuario': notasUsuario,
  };
  
  Articulo copyWith({
    String? numero,
    String? texto,
    List<String>? incisos,
    String? nota,
    bool? derogado,
    String? reformadoPor,
    bool? esFavorito,
    String? notasUsuario,
  }) =>
      Articulo(
        numero: numero ?? this.numero,
        texto: texto ?? this.texto,
        incisos: incisos ?? this.incisos,
        nota: nota ?? this.nota,
        derogado: derogado ?? this.derogado,
        reformadoPor: reformadoPor ?? this.reformadoPor,
        esFavorito: esFavorito ?? this.esFavorito,
        notasUsuario: notasUsuario ?? this.notasUsuario,
      );
}

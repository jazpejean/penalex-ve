import 'package:cloud_firestore/cloud_firestore.dart';

class Jurisprudencia {
  final String id;
  final String numero; // TSJ-CP 123/2024
  final DateTime fecha;
  final String tribunal; // TSJ Sala Penal, Corte Apelaciones, etc.
  final String magistradoPonente;
  final String delito; // Delito principal
  final List<String> articulosCitados; // ["Art. 406 CP", "Art. 74 CP"]
  final String resumen; // Resumen breve del caso
  final String doctrina; // Doctrina establecida
  final String? fundamentacion; // Fundamentación completa (opcional)
  final String? urlPDF; // URL del PDF de la sentencia
  final int relevancia; // 1-5 estrellas
  final List<String> tags; // ["homicidio", "premeditación", etc.]
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Campos de interacción del usuario
  final bool? isFavorito; // Si el usuario la marcó como favorita
  final String? notasUsuario; // Notas personales del usuario
  
  Jurisprudencia({
    required this.id,
    required this.numero,
    required this.fecha,
    required this.tribunal,
    required this.magistradoPonente,
    required this.delito,
    required this.articulosCitados,
    required this.resumen,
    required this.doctrina,
    this.fundamentacion,
    this.urlPDF,
    required this.relevancia,
    required this.tags,
    required this.createdAt,
    this.updatedAt,
    this.isFavorito,
    this.notasUsuario,
  });
  
  factory Jurisprudencia.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Jurisprudencia(
      id: doc.id,
      numero: data['numero'] as String,
      fecha: (data['fecha'] as Timestamp).toDate(),
      tribunal: data['tribunal'] as String,
      magistradoPonente: data['magistradoPonente'] as String,
      delito: data['delito'] as String,
      articulosCitados: List<String>.from(data['articulosCitados'] as List),
      resumen: data['resumen'] as String,
      doctrina: data['doctrina'] as String,
      fundamentacion: data['fundamentacion'] as String?,
      urlPDF: data['urlPDF'] as String?,
      relevancia: data['relevancia'] as int,
      tags: List<String>.from(data['tags'] as List),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isFavorito: data['isFavorito'] as bool?,
      notasUsuario: data['notasUsuario'] as String?,
    );
  }
  
  Map<String, dynamic> toFirestore() => {
    'numero': numero,
    'fecha': Timestamp.fromDate(fecha),
    'tribunal': tribunal,
    'magistradoPonente': magistradoPonente,
    'delito': delito,
    'articulosCitados': articulosCitados,
    'resumen': resumen,
    'doctrina': doctrina,
    'fundamentacion': fundamentacion,
    'urlPDF': urlPDF,
    'relevancia': relevancia,
    'tags': tags,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'isFavorito': isFavorito,
    'notasUsuario': notasUsuario,
  };
  
  Jurisprudencia copyWith({
    String? id,
    String? numero,
    DateTime? fecha,
    String? tribunal,
    String? magistradoPonente,
    String? delito,
    List<String>? articulosCitados,
    String? resumen,
    String? doctrina,
    String? fundamentacion,
    String? urlPDF,
    int? relevancia,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorito,
    String? notasUsuario,
  }) =>
      Jurisprudencia(
        id: id ?? this.id,
        numero: numero ?? this.numero,
        fecha: fecha ?? this.fecha,
        tribunal: tribunal ?? this.tribunal,
        magistradoPonente: magistradoPonente ?? this.magistradoPonente,
        delito: delito ?? this.delito,
        articulosCitados: articulosCitados ?? this.articulosCitados,
        resumen: resumen ?? this.resumen,
        doctrina: doctrina ?? this.doctrina,
        fundamentacion: fundamentacion ?? this.fundamentacion,
        urlPDF: urlPDF ?? this.urlPDF,
        relevancia: relevancia ?? this.relevancia,
        tags: tags ?? this.tags,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isFavorito: isFavorito ?? this.isFavorito,
        notasUsuario: notasUsuario ?? this.notasUsuario,
      );
}

class CasoHipotetico {
  final String id;
  final int nivel;
  final int poolId;
  final String delitoBase;
  final String? agravante;
  final String contextoNarrativo;
  final List<String> opciones;
  final int respuestaCorrecta;
  final int dificultad;
  final double? tasaExito;
  final int? intentosTotales;
  final bool activo;
  final DateTime? createdAt;

  CasoHipotetico({
    required this.id,
    required this.nivel,
    required this.poolId,
    required this.delitoBase,
    this.agravante,
    required this.contextoNarrativo,
    required this.opciones,
    required this.respuestaCorrecta,
    this.dificultad = 3,
    this.tasaExito,
    this.intentosTotales,
    this.activo = true,
    this.createdAt,
  });

  factory CasoHipotetico.fromJson(Map<String, dynamic> json) {
    return CasoHipotetico(
      id: json['id'] as String,
      nivel: json['nivel'] as int,
      poolId: json['pool_id'] as int,
      delitoBase: json['delito_base'] as String,
      agravante: json['agravante'] as String?,
      contextoNarrativo: json['contexto_narrativo'] as String,
      opciones: (json['opciones'] as List<dynamic>).cast<String>(),
      respuestaCorrecta: json['respuesta_correcta'] as int,
      dificultad: json['dificultad'] as int? ?? 3,
      tasaExito: json['tasa_exito'] as double?,
      intentosTotales: json['intentos_totales'] as int?,
      activo: json['activo'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nivel': nivel,
      'pool_id': poolId,
      'delito_base': delitoBase,
      'agravante': agravante,
      'contexto_narrativo': contextoNarrativo,
      'opciones': opciones,
      'respuesta_correcta': respuestaCorrecta,
      'dificultad': dificultad,
      'tasa_exito': tasaExito,
      'intentos_totales': intentosTotales,
      'activo': activo,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class Fundamentacion {
  final String id;
  final String casoId;
  final String explicacion;
  final List<ArticuloReferencia> articulos;
  final List<String> sentenciasIds;
  final List<String> jurisprudenciasIds;
  final DateTime? createdAt;

  Fundamentacion({
    required this.id,
    required this.casoId,
    required this.explicacion,
    required this.articulos,
    required this.sentenciasIds,
    required this.jurisprudenciasIds,
    this.createdAt,
  });

  factory Fundamentacion.fromJson(Map<String, dynamic> json) {
    return Fundamentacion(
      id: json['id'] as String,
      casoId: json['caso_id'] as String,
      explicacion: json['explicacion'] as String,
      articulos: (json['articulos'] as List<dynamic>)
          .map((a) => ArticuloReferencia.fromJson(a as Map<String, dynamic>))
          .toList(),
      sentenciasIds: (json['sentencias_ids'] as List<dynamic>).cast<String>(),
      jurisprudenciasIds:
          (json['jurisprudencias_ids'] as List<dynamic>).cast<String>(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caso_id': casoId,
      'explicacion': explicacion,
      'articulos': articulos.map((a) => a.toJson()).toList(),
      'sentencias_ids': sentenciasIds,
      'jurisprudencias_ids': jurisprudenciasIds,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class ArticuloReferencia {
  final String codigo;
  final String articulo;
  final String texto;

  ArticuloReferencia({
    required this.codigo,
    required this.articulo,
    required this.texto,
  });

  factory ArticuloReferencia.fromJson(Map<String, dynamic> json) {
    return ArticuloReferencia(
      codigo: json['codigo'] as String,
      articulo: json['articulo'] as String,
      texto: json['texto'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'articulo': articulo,
      'texto': texto,
    };
  }
}

class Pista {
  final String id;
  final String casoId;
  final int nivelPista;
  final String textoPista;
  final List<String>? articulosSugeridos;
  final String? busquedaSugerida;
  final DateTime? createdAt;

  Pista({
    required this.id,
    required this.casoId,
    required this.nivelPista,
    required this.textoPista,
    this.articulosSugeridos,
    this.busquedaSugerida,
    this.createdAt,
  });

  factory Pista.fromJson(Map<String, dynamic> json) {
    return Pista(
      id: json['id'] as String,
      casoId: json['caso_id'] as String,
      nivelPista: json['nivel_pista'] as int,
      textoPista: json['texto_pista'] as String,
      articulosSugeridos: json['articulos_sugeridos'] != null
          ? (json['articulos_sugeridos'] as List<dynamic>).cast<String>()
          : null,
      busquedaSugerida: json['busqueda_sugerida'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caso_id': casoId,
      'nivel_pista': nivelPista,
      'texto_pista': textoPista,
      'articulos_sugeridos': articulosSugeridos,
      'busqueda_sugerida': busquedaSugerida,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class CasoFallado {
  final String id;
  final String userId;
  final String casoId;
  final int vecesFallado;
  final DateTime ultimaVezFallado;
  final bool bloqueado;
  final bool estudiado;
  final DateTime? createdAt;

  CasoFallado({
    required this.id,
    required this.userId,
    required this.casoId,
    required this.vecesFallado,
    required this.ultimaVezFallado,
    this.bloqueado = false,
    this.estudiado = false,
    this.createdAt,
  });

  factory CasoFallado.fromJson(Map<String, dynamic> json) {
    return CasoFallado(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      casoId: json['caso_id'] as String,
      vecesFallado: json['veces_fallado'] as int,
      ultimaVezFallado: DateTime.parse(json['ultima_vez_fallado'] as String),
      bloqueado: json['bloqueado'] as bool? ?? false,
      estudiado: json['estudiado'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'caso_id': casoId,
      'veces_fallado': vecesFallado,
      'ultima_vez_fallado': ultimaVezFallado.toIso8601String(),
      'bloqueado': bloqueado,
      'estudiado': estudiado,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class ResultadoRespuesta {
  final bool correcto;
  final Fundamentacion? fundamentacion;
  final Pista? pista;
  final bool bloqueoCaso;
  final bool bloqueoNivel;
  final String? mensaje;

  ResultadoRespuesta({
    required this.correcto,
    this.fundamentacion,
    this.pista,
    this.bloqueoCaso = false,
    this.bloqueoNivel = false,
    this.mensaje,
  });
}

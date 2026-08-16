/// Modelo para estrategias legales y su comparación
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipo de estrategia legal
enum TipoEstrategia {
  defensaTecnica,
  negociacion,
  recursoApelacion,
  accionTutela,
  medidasCautelares,
  libertadProvisional,
  nulidad,
  prescripcion,
  atenuantes,
  transaccionPenal,
}

extension TipoEstrategiaExtension on TipoEstrategia {
  String get nombre {
    switch (this) {
      case TipoEstrategia.defensaTecnica:
        return 'Defensa Técnica';
      case TipoEstrategia.negociacion:
        return 'Negociación';
      case TipoEstrategia.recursoApelacion:
        return 'Recurso de Apelación';
      case TipoEstrategia.accionTutela:
        return 'Acción de Amparo';
      case TipoEstrategia.medidasCautelares:
        return 'Medidas Cautelares';
      case TipoEstrategia.libertadProvisional:
        return 'Libertad Provisional';
      case TipoEstrategia.nulidad:
        return 'Nulidad de Actuaciones';
      case TipoEstrategia.prescripcion:
        return 'Prescripción';
      case TipoEstrategia.atenuantes:
        return 'Circunstancias Atenuantes';
      case TipoEstrategia.transaccionPenal:
        return 'Transacción Penal';
    }
  }

  String get descripcion {
    switch (this) {
      case TipoEstrategia.defensaTecnica:
        return 'Estrategia procesal completa durante todo el juicio';
      case TipoEstrategia.negociacion:
        return 'Acuerdo con el Ministerio Público para reducir pena';
      case TipoEstrategia.recursoApelacion:
        return 'Impugnación de sentencia ante tribunal superior';
      case TipoEstrategia.accionTutela:
        return 'Protección constitucional de derechos fundamentales';
      case TipoEstrategia.medidasCautelares:
        return 'Sustitución de privación de libertad';
      case TipoEstrategia.libertadProvisional:
        return 'Solicitud de libertad durante el proceso';
      case TipoEstrategia.nulidad:
        return 'Declarar nulas actuaciones procesales irregulares';
      case TipoEstrategia.prescripcion:
        return 'Extinción de la acción penal por tiempo transcurrido';
      case TipoEstrategia.atenuantes:
        return 'Reducción de pena por circunstancias favorables';
      case TipoEstrategia.transaccionPenal:
        return 'Acuerdo reparatorio para delitos menores';
    }
  }
}

/// Nivel de riesgo de una estrategia
enum NivelRiesgo {
  bajo,
  medio,
  alto,
  muyAlto,
}

extension NivelRiesgoExtension on NivelRiesgo {
  String get nombre {
    switch (this) {
      case NivelRiesgo.bajo:
        return 'Bajo';
      case NivelRiesgo.medio:
        return 'Medio';
      case NivelRiesgo.alto:
        return 'Alto';
      case NivelRiesgo.muyAlto:
        return 'Muy Alto';
    }
  }
}

/// Beneficio o ventaja de una estrategia
class Beneficio {
  final String descripcion;
  final double impacto; // 0.0 a 1.0

  const Beneficio({
    required this.descripcion,
    required this.impacto,
  });

  Map<String, dynamic> toMap() {
    return {
      'descripcion': descripcion,
      'impacto': impacto,
    };
  }

  factory Beneficio.fromMap(Map<String, dynamic> map) {
    return Beneficio(
      descripcion: map['descripcion'] ?? '',
      impacto: (map['impacto'] ?? 0.0).toDouble(),
    );
  }
}

/// Riesgo o desventaja de una estrategia
class Riesgo {
  final String descripcion;
  final NivelRiesgo nivel;
  final double probabilidad; // 0.0 a 1.0

  const Riesgo({
    required this.descripcion,
    required this.nivel,
    required this.probabilidad,
  });

  Map<String, dynamic> toMap() {
    return {
      'descripcion': descripcion,
      'nivel': nivel.name,
      'probabilidad': probabilidad,
    };
  }

  factory Riesgo.fromMap(Map<String, dynamic> map) {
    return Riesgo(
      descripcion: map['descripcion'] ?? '',
      nivel: NivelRiesgo.values.firstWhere(
        (e) => e.name == map['nivel'],
        orElse: () => NivelRiesgo.medio,
      ),
      probabilidad: (map['probabilidad'] ?? 0.0).toDouble(),
    );
  }
}

/// Jurisprudencia que respalda una estrategia
class JurisprudenciaRespaldo {
  final String sentenciaId;
  final String ponente;
  final DateTime fecha;
  final String extracto;
  final double relevancia; // 0.0 a 1.0

  const JurisprudenciaRespaldo({
    required this.sentenciaId,
    required this.ponente,
    required this.fecha,
    required this.extracto,
    required this.relevancia,
  });

  Map<String, dynamic> toMap() {
    return {
      'sentenciaId': sentenciaId,
      'ponente': ponente,
      'fecha': Timestamp.fromDate(fecha),
      'extracto': extracto,
      'relevancia': relevancia,
    };
  }

  factory JurisprudenciaRespaldo.fromMap(Map<String, dynamic> map) {
    return JurisprudenciaRespaldo(
      sentenciaId: map['sentenciaId'] ?? '',
      ponente: map['ponente'] ?? '',
      fecha: (map['fecha'] as Timestamp).toDate(),
      extracto: map['extracto'] ?? '',
      relevancia: (map['relevancia'] ?? 0.0).toDouble(),
    );
  }
}

/// Estrategia legal completa con análisis
class EstrategiaLegal {
  final String id;
  final TipoEstrategia tipo;
  final String titulo;
  final String descripcion;
  final double probabilidadExito; // 0.0 a 1.0
  final List<Beneficio> beneficios;
  final List<Riesgo> riesgos;
  final List<String> requisitos;
  final List<String> pasos;
  final List<JurisprudenciaRespaldo> jurisprudencia;
  final int duracionEstimadaDias;
  final String costoEstimado;
  final DateTime fechaCreacion;
  final bool generadaPorIA;

  const EstrategiaLegal({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.probabilidadExito,
    required this.beneficios,
    required this.riesgos,
    required this.requisitos,
    required this.pasos,
    required this.jurisprudencia,
    required this.duracionEstimadaDias,
    required this.costoEstimado,
    required this.fechaCreacion,
    this.generadaPorIA = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo.name,
      'titulo': titulo,
      'descripcion': descripcion,
      'probabilidadExito': probabilidadExito,
      'beneficios': beneficios.map((b) => b.toMap()).toList(),
      'riesgos': riesgos.map((r) => r.toMap()).toList(),
      'requisitos': requisitos,
      'pasos': pasos,
      'jurisprudencia': jurisprudencia.map((j) => j.toMap()).toList(),
      'duracionEstimadaDias': duracionEstimadaDias,
      'costoEstimado': costoEstimado,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'generadaPorIA': generadaPorIA,
    };
  }

  factory EstrategiaLegal.fromMap(Map<String, dynamic> map) {
    return EstrategiaLegal(
      id: map['id'] ?? '',
      tipo: TipoEstrategia.values.firstWhere(
        (e) => e.name == map['tipo'],
        orElse: () => TipoEstrategia.defensaTecnica,
      ),
      titulo: map['titulo'] ?? '',
      descripcion: map['descripcion'] ?? '',
      probabilidadExito: (map['probabilidadExito'] ?? 0.0).toDouble(),
      beneficios: (map['beneficios'] as List?)
              ?.map((b) => Beneficio.fromMap(b as Map<String, dynamic>))
              .toList() ??
          [],
      riesgos: (map['riesgos'] as List?)
              ?.map((r) => Riesgo.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
      requisitos: List<String>.from(map['requisitos'] ?? []),
      pasos: List<String>.from(map['pasos'] ?? []),
      jurisprudencia: (map['jurisprudencia'] as List?)
              ?.map((j) =>
                  JurisprudenciaRespaldo.fromMap(j as Map<String, dynamic>))
              .toList() ??
          [],
      duracionEstimadaDias: map['duracionEstimadaDias'] ?? 0,
      costoEstimado: map['costoEstimado'] ?? '',
      fechaCreacion: (map['fechaCreacion'] as Timestamp).toDate(),
      generadaPorIA: map['generadaPorIA'] ?? false,
    );
  }

  /// Calcula un score ponderado de la estrategia
  double get scorePonderado {
    // Fórmula: (probabilidadExito * 0.4) + (promedioImpactoBeneficios * 0.3) - (promedioRiesgo * 0.3)
    final impactoBeneficios = beneficios.isEmpty
        ? 0.0
        : beneficios.map((b) => b.impacto).reduce((a, b) => a + b) /
            beneficios.length;

    final promedioRiesgo = riesgos.isEmpty
        ? 0.0
        : riesgos.map((r) => r.probabilidad).reduce((a, b) => a + b) /
            riesgos.length;

    return (probabilidadExito * 0.4) +
        (impactoBeneficios * 0.3) -
        (promedioRiesgo * 0.3);
  }
}

/// Comparación entre múltiples estrategias
class ComparacionEstrategias {
  final String id;
  final String titulo;
  final String casoId;
  final List<EstrategiaLegal> estrategias;
  final DateTime fechaCreacion;
  final String? notas;

  const ComparacionEstrategias({
    required this.id,
    required this.titulo,
    required this.casoId,
    required this.estrategias,
    required this.fechaCreacion,
    this.notas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'casoId': casoId,
      'estrategias': estrategias.map((e) => e.toMap()).toList(),
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'notas': notas,
    };
  }

  factory ComparacionEstrategias.fromMap(Map<String, dynamic> map) {
    return ComparacionEstrategias(
      id: map['id'] ?? '',
      titulo: map['titulo'] ?? '',
      casoId: map['casoId'] ?? '',
      estrategias: (map['estrategias'] as List?)
              ?.map((e) => EstrategiaLegal.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      fechaCreacion: (map['fechaCreacion'] as Timestamp).toDate(),
      notas: map['notas'],
    );
  }

  /// Ordena estrategias por score descendente
  List<EstrategiaLegal> get estrategiasOrdenadas {
    final lista = List<EstrategiaLegal>.from(estrategias);
    lista.sort((a, b) => b.scorePonderado.compareTo(a.scorePonderado));
    return lista;
  }

  /// Retorna la mejor estrategia según score
  EstrategiaLegal? get mejorEstrategia {
    if (estrategias.isEmpty) return null;
    return estrategiasOrdenadas.first;
  }
}

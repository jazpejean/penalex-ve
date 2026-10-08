import '../logic/dosimetria_engine.dart';

enum GradoEjecucion { consumado, frustrado, tentativa }

enum TipoConcurso { real, ideal }

// Tipos de pena según Código Penal Venezolano (Arts. 86-87)
enum TipoPena {
  presidio, // Pena base con trabajos forzados
  prision, // Sin trabajos forzados (1 presidio = 2 prisión)
}

// ==================== AJUSTE ADICIONAL (fracción) ====================
class AjusteAdicional {
  // valor entre 0 y 1 (ej. 0.3333 para 1/3)

  AjusteAdicional({
    required this.nombre,
    required this.esAgravante,
    required this.fraccion,
  });

  factory AjusteAdicional.fromMap(Map<String, dynamic> map) => AjusteAdicional(
        nombre: (map['nombre'] as String?) ?? '',
        esAgravante: (map['esAgravante'] as bool?) ?? false,
        fraccion: (map['fraccion'] as num?)?.toDouble() ?? 0.0,
      );
  String nombre;
  bool esAgravante; // true = agravante (+), false = atenuante (-)
  double fraccion;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'nombre': nombre,
        'esAgravante': esAgravante,
        'fraccion': fraccion,
      };
}

// ==================== DELITO ====================
class Delito {
  Delito({
    required this.id,
    this.nombre = "",
    double penaMin = 0,
    double penaMax = 0,
    this.gradoEjecucion = GradoEjecucion.consumado,
    this.fraccionEjecucion = 0,
    this.participacionEspecifica = "Autor",
    this.delitoContinuado = false,
    this.fraccionContinuidad = 1 / 6,
    this.modificadorManual = 0,
    this.modificadorUnidad = "años",
    this.tipoPena = TipoPena.prision,
    this.montoMulta = 0,
    List<AjusteAdicional>? ajustesAdicionales,
  })  : _penaMin = penaMin,
        _penaMax = penaMax {
    _actualizarCamposDesdePena();
    if (ajustesAdicionales != null) {
      this.ajustesAdicionales = ajustesAdicionales;
    }
  }

  factory Delito.fromMap(Map<String, dynamic> map) {
    final List<AjusteAdicional> ajustesList =
        (map["ajustesAdicionales"] as List<dynamic>?)
                ?.map(
                  (e) => AjusteAdicional.fromMap(e as Map<String, dynamic>),
                )
                .toList() ??
            <AjusteAdicional>[];

    return Delito(
      id: map["id"] as String,
      nombre: (map["nombre"] as String?) ?? "",
      penaMin: (map["penaMin"] as num?)?.toDouble() ?? 0,
      penaMax: (map["penaMax"] as num?)?.toDouble() ?? 0,
      gradoEjecucion:
          GradoEjecucion.values[(map["gradoEjecucion"] as int?) ?? 0],
      fraccionEjecucion: (map["fraccionEjecucion"] as num?)?.toDouble() ?? 0,
      participacionEspecifica:
          (map["participacionEspecifica"] as String?) ?? "Autor",
      delitoContinuado: (map["delitoContinuado"] as bool?) ?? false,
      fraccionContinuidad:
          (map["fraccionContinuidad"] as num?)?.toDouble() ?? 1 / 6,
      modificadorManual: (map["modificadorManual"] as num?)?.toDouble() ?? 0,
      modificadorUnidad:
          _normalizeUnidad((map["modificadorUnidad"] as String?) ?? "años"),
      tipoPena: TipoPena.values[(map["tipoPena"] as int?) ?? 0],
      montoMulta: (map["montoMulta"] as num?)?.toDouble() ?? 0,
      ajustesAdicionales: ajustesList,
    );
  }
  String id;
  String nombre;

  double _penaMin;
  double _penaMax;

  double minValorNumerico = 0;
  String minUnidad = 'años';
  double maxValorNumerico = 0;
  String maxUnidad = 'años';

  GradoEjecucion gradoEjecucion;
  double fraccionEjecucion;
  String participacionEspecifica;
  bool delitoContinuado;
  double fraccionContinuidad;
  double modificadorManual;
  String modificadorUnidad;

  // Nuevos campos para tipos de pena (Arts. 86-87 CP)
  TipoPena tipoPena;
  double montoMulta; // En Unidades Tributarias (solo para multas)

  // NUEVA LISTA DE AJUSTES ADICIONALES
  List<AjusteAdicional> ajustesAdicionales = <AjusteAdicional>[];

  List<Map<String, dynamic>> pasosCalculo = <Map<String, dynamic>>[];

  double get penaMin => _penaMin;
  set penaMin(double value) {
    _penaMin = value;
    _actualizarCamposDesdePena();
  }

  double get penaMax => _penaMax;
  set penaMax(double value) {
    _penaMax = value;
    _actualizarCamposDesdePena();
  }

  static String _normalizeUnidad(String rawUnidad) {
    final String unidad = rawUnidad
        .toLowerCase()
        .replaceAll('í', 'i')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    if (unidad == 'anos' || unidad == 'años') {
      return 'años';
    }
    if (unidad == 'meses') {
      return 'meses';
    }
    if (unidad == 'dias' || unidad == 'días') {
      return 'días';
    }
    return rawUnidad;
  }

  void _actualizarCamposDesdePena() {
    // Convertir el valor en años a una representación YMD y usar años como
    // unidad principal, preservando la fracción de año de forma precisa.
    // Así, 1.5 años se mostrará como 1 año 6 meses, y al guardar/modificar
    // no se pierde precisión porque siempre se usa 'años' como unidad base.
    final double minAnios = _penaMin;
    final double maxAnios = _penaMax;

    // Redondear a 6 decimales para evitar errores de punto flotante
    // Usamos años como unidad universal para máxima precisión
    minValorNumerico = double.parse(minAnios.toStringAsFixed(6));
    minUnidad = 'años';
    maxValorNumerico = double.parse(maxAnios.toStringAsFixed(6));
    maxUnidad = 'años';
  }

  void actualizarPenaDesdeCampos() {
    switch (_normalizeUnidad(minUnidad)) {
      case 'años':
        _penaMin = minValorNumerico;
        break;
      case 'meses':
        _penaMin = minValorNumerico / 12;
        break;
      case 'días':
        _penaMin = minValorNumerico / 360;
        break;
    }
    switch (_normalizeUnidad(maxUnidad)) {
      case 'años':
        _penaMax = maxValorNumerico;
        break;
      case 'meses':
        _penaMax = maxValorNumerico / 12;
        break;
      case 'días':
        _penaMax = maxValorNumerico / 360;
        break;
    }
  }

  double get terminoMedio => (penaMin + penaMax) / 2;

  // Método de conversión según Art. 87 CP
  // Convierte cualquier tipo de pena a su equivalente en presidio
  double convertirAPresidio() {
    final double penaIndividualizada = calcularPenaIndividualizada();

    switch (tipoPena) {
      case TipoPena.presidio:
        // Ya es presidio, retornar tal cual
        return penaIndividualizada;

      case TipoPena.prision:
        // 1 día presidio = 2 días prisión
        // Por tanto: prisión / 2 = presidio
        return penaIndividualizada / 2;
    }
  }

  // Método auxiliar para obtener el nombre del tipo de pena
  String get nombreTipoPena {
    switch (tipoPena) {
      case TipoPena.presidio:
        return 'Presidio';
      case TipoPena.prision:
        return 'Prisión';
    }
  }

  double calcularPenaIndividualizada() {
    pasosCalculo.clear();
    double pena = terminoMedio;
    pasosCalculo.add(<String, dynamic>{
      'descripcion': 'Término medio',
      'resultado': DosimetriaEngine.formatNumero(pena),
      'pena_actual': pena,
    });

    // 1. Atenuantes/agravantes (Arts. 74 y 77 CP): potestativo del juez,
    //    aplicados desde el término medio y limitados a los extremos del tipo
    //    (la única condición es no pasar el límite mínimo ni el máximo).
    if (modificadorManual != 0) {
      final String tipo = modificadorManual > 0 ? 'AGRAVANTE' : 'ATENUANTE';
      double nuevaPena = pena + modificadorManual;
      if (nuevaPena > penaMax) {
        pasosCalculo.add(<String, dynamic>{
          'descripcion':
              'Modificador $tipo (Arts. 74/77 CP) limitado al máximo legal',
          'resultado': '+${DosimetriaEngine.formatNumero(penaMax - pena)} años',
          'pena_actual': penaMax,
        });
        nuevaPena = penaMax;
      } else if (nuevaPena < penaMin) {
        pasosCalculo.add(<String, dynamic>{
          'descripcion':
              'Modificador $tipo (Arts. 74/77 CP) limitado al mínimo legal',
          'resultado': '-${DosimetriaEngine.formatNumero(pena - penaMin)} años',
          'pena_actual': penaMin,
        });
        nuevaPena = penaMin;
      } else {
        pasosCalculo.add(<String, dynamic>{
          'descripcion': 'Modificador $tipo (Arts. 74/77 CP)',
          'resultado':
              '${modificadorManual > 0 ? '+' : '-'}${DosimetriaEngine.formatNumero(modificadorManual.abs())} años',
          'pena_actual': nuevaPena,
        });
      }
      pena = nuevaPena;
    }

    // 2. Ajustes adicionales: aumentos/reducciones fijados por leyes especiales
    //    (ej. "con el aumento de 1/3" en la Ley de Drogas para la ocultación).
    //    Son multiplicativos y PUEDEN superar los límites del tipo penal.
    for (final AjusteAdicional a in ajustesAdicionales) {
      final double cambio = pena * a.fraccion;
      if (a.esAgravante) {
        pena += cambio;
        pasosCalculo.add(<String, dynamic>{
          'descripcion': 'Ajuste legal (ley especial): ${a.nombre}',
          'resultado': '+${DosimetriaEngine.formatNumero(cambio)} años',
          'pena_actual': pena,
        });
      } else {
        pena -= cambio;
        pasosCalculo.add(<String, dynamic>{
          'descripcion': 'Ajuste legal (ley especial): ${a.nombre}',
          'resultado': '-${DosimetriaEngine.formatNumero(cambio)} años',
          'pena_actual': pena,
        });
      }
    }

    // 3. Grado de ejecución (Art. 82 CP): la rebaja puede bajar del mínimo.
    if (gradoEjecucion != GradoEjecucion.consumado) {
      final String tipo = gradoEjecucion == GradoEjecucion.frustrado
          ? 'FRUSTRADO'
          : 'TENTATIVA';
      final double rebaja = pena * fraccionEjecucion;
      pena = pena * (1 - fraccionEjecucion);
      pasosCalculo.add(<String, dynamic>{
        'descripcion': 'Rebaja por $tipo',
        'resultado': '-${DosimetriaEngine.formatNumero(rebaja)} años',
        'pena_actual': pena,
      });
    }

    // 4. Participación (Art. 84 CP, Cómplice No Necesario): puede bajar del mínimo.
    if (participacionEspecifica == 'Cómplice No Necesario') {
      final double rebaja = pena * 0.5;
      pena = pena * 0.5;
      pasosCalculo.add(<String, dynamic>{
        'descripcion': 'Rebaja por complicidad no necesaria (Art. 84 CP)',
        'resultado': '-${DosimetriaEngine.formatNumero(rebaja)} años',
        'pena_actual': pena,
      });
    }

    // 5. Delito continuado (Art. 99 CP): el aumento PUEDE superar el máximo.
    if (delitoContinuado) {
      final double aumento = pena * fraccionContinuidad;
      pena = pena * (1 + fraccionContinuidad);
      pasosCalculo.add(<String, dynamic>{
        'descripcion': 'Aumento por delito continuado',
        'resultado': '+${DosimetriaEngine.formatNumero(aumento)} años',
        'pena_actual': pena,
      });
    }

    pasosCalculo.add(<String, dynamic>{
      'descripcion': 'PENA FINAL',
      'resultado': DosimetriaEngine.formatNumero(pena),
      'pena_actual': pena,
    });
    return pena;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'nombre': nombre,
        'penaMin': penaMin,
        'penaMax': penaMax,
        'gradoEjecucion': gradoEjecucion.index,
        'fraccionEjecucion': fraccionEjecucion,
        'participacionEspecifica': participacionEspecifica,
        'delitoContinuado': delitoContinuado,
        'fraccionContinuidad': fraccionContinuidad,
        'modificadorManual': modificadorManual,
        'modificadorUnidad': modificadorUnidad,
        'tipoPena': tipoPena.index,
        'montoMulta': montoMulta,
        'ajustesAdicionales':
            ajustesAdicionales.map((AjusteAdicional a) => a.toMap()).toList(),
      };
}

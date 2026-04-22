import '../logic/dosimetria_engine.dart';

enum GradoEjecucion { consumado, frustrado, tentativa }
enum TipoConcurso { real, ideal }

// ==================== AJUSTE ADICIONAL (fracción) ====================
class AjusteAdicional {   // valor entre 0 y 1 (ej. 0.3333 para 1/3)

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
            ?.map((e) => 
                AjusteAdicional.fromMap(e as Map<String, dynamic>),)
            .toList() ??
        <AjusteAdicional>[];

    return Delito(
      id: map["id"] as String,
      nombre: (map["nombre"] as String?) ?? "",
      penaMin: (map["penaMin"] as num?)?.toDouble() ?? 0,
      penaMax: (map["penaMax"] as num?)?.toDouble() ?? 0,
      gradoEjecucion: GradoEjecucion.values[
          (map["gradoEjecucion"] as int?) ?? 0],
      fraccionEjecucion: (map["fraccionEjecucion"] as num?)?.toDouble() ?? 0,
      participacionEspecifica: 
          (map["participacionEspecifica"] as String?) ?? "Autor",
      delitoContinuado: (map["delitoContinuado"] as bool?) ?? false,
      fraccionContinuidad: 
          (map["fraccionContinuidad"] as num?)?.toDouble() ?? 1 / 6,
      modificadorManual: (map["modificadorManual"] as num?)?.toDouble() ?? 0,
      modificadorUnidad:
          _normalizeUnidad((map["modificadorUnidad"] as String?) ?? "años"),
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
    final Map<String, int> minYMD = DosimetriaEngine.convertToYMD(_penaMin);
    if (minYMD['anos']! > 0) {
      minValorNumerico = minYMD['anos']!.toDouble();
      minUnidad = 'años';
    } else if (minYMD['meses']! > 0) {
      minValorNumerico = minYMD['meses']!.toDouble();
      minUnidad = 'meses';
    } else {
      minValorNumerico = minYMD['dias']!.toDouble();
      minUnidad = 'días';
    }

    final Map<String, int> maxYMD = DosimetriaEngine.convertToYMD(_penaMax);
    if (maxYMD['anos']! > 0) {
      maxValorNumerico = maxYMD['anos']!.toDouble();
      maxUnidad = 'años';
    } else if (maxYMD['meses']! > 0) {
      maxValorNumerico = maxYMD['meses']!.toDouble();
      maxUnidad = 'meses';
    } else {
      maxValorNumerico = maxYMD['dias']!.toDouble();
      maxUnidad = 'días';
    }
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

  double calcularPenaIndividualizada() {
    pasosCalculo.clear();
    double pena = terminoMedio;
    pasosCalculo.add(<String, dynamic>{
      'descripcion': 'Término medio',
      'resultado': DosimetriaEngine.formatNumero(pena),
      'pena_actual': pena,
    });

    // 1. Ajustes adicionales (fracciones manuales)
    for (final AjusteAdicional a in ajustesAdicionales) {
      final double cambio = pena * a.fraccion;
      if (a.esAgravante) {
        pena += cambio;
        pasosCalculo.add(<String, dynamic>{
          'descripcion': 'Agravante: ${a.nombre}',
          'resultado': '+${DosimetriaEngine.formatNumero(cambio)} años',
          'pena_actual': pena,
        });
      } else {
        pena -= cambio;
        pasosCalculo.add(<String, dynamic>{
          'descripcion': 'Atenuante: ${a.nombre}',
          'resultado': '-${DosimetriaEngine.formatNumero(cambio)} años',
          'pena_actual': pena,
        });
      }
    }

    // 2. Grado de ejecución
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

    // 3. Participación (solo Cómplice No Necesario)
    if (participacionEspecifica == 'Cómplice No Necesario') {
      final double rebaja = pena * 0.5;
      pena = pena * 0.5;
      pasosCalculo.add(<String, dynamic>{
        'descripcion': 'Rebaja por complicidad no necesaria (Art. 84 CP)',
        'resultado': '-${DosimetriaEngine.formatNumero(rebaja)} años',
        'pena_actual': pena,
      });
    }

    // 4. Delito continuado
    if (delitoContinuado) {
      final double aumento = pena * fraccionContinuidad;
      pena = pena * (1 + fraccionContinuidad);
      pasosCalculo.add(<String, dynamic>{
        'descripcion': 'Aumento por delito continuado',
        'resultado': '+${DosimetriaEngine.formatNumero(aumento)} años',
        'pena_actual': pena,
      });
    }

    // 5. Modificador manual (atenuante/agravante numérico)
    if (modificadorManual != 0) {
      final String tipo = modificadorManual > 0 ? 'AGRAVANTE' : 'ATENUANTE';
      final double nuevaPena = pena + modificadorManual;
      pasosCalculo.add(<String, dynamic>{
        'descripcion': 'Modificador $tipo',
                'resultado':
            '${modificadorManual > 0 ? '+' : '-'}${DosimetriaEngine.formatNumero(modificadorManual.abs())} años',
        'pena_actual': nuevaPena,
      });
      pena = nuevaPena;
    }

    // 6. Límites mínimo y máximo
    if (pena < penaMin) {
      pena = penaMin;
      pasosCalculo.add(<String, dynamic>{
        'descripcion': 'Ajuste a pena mínima legal',
        'resultado': DosimetriaEngine.formatNumero(pena),
        'pena_actual': pena,
      });
    }
    if (pena > penaMax) {
      pena = penaMax;
      pasosCalculo.add(<String, dynamic>{
        'descripcion': 'Ajuste a pena máxima legal',
        'resultado': DosimetriaEngine.formatNumero(pena),
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
        'ajustesAdicionales': ajustesAdicionales
            .map((AjusteAdicional a) => a.toMap())
            .toList(),
      };
}
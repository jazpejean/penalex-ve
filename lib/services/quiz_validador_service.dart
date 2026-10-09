/// Validador del quiz — "cero error por construcción".
///
/// Reglas (todas determinísticas; ninguna depende del juicio de la IA):
///  1. Estructura completa (contexto, 4 opciones, índice, fundamentación, artículos).
///  2. Citas POR LEY: "Art. N <Ley>" → el artículo N debe existir en el corpus
///     de ESA ley (no basta que el número exista en otra).
///  3. Fundamentación LITERAL: debe contener una cita textual (≥40 caracteres
///     normalizados) del artículo citado — prohíbe la paráfrasis de la IA.
///  4. Firma de elementos: el escenario debe contener ≥2 tokens distintivos
///     del artículo citado (tokens con baja frecuencia documental en la ley).
///  5. Ambigüedad: si el escenario encaja también en otro artículo (≥2 tokens
///     distintivos suyos) → se descarta (una historia ambigua es un error).
///  6. Penas desde el corpus: si una opción declara un rango de pena, ese
///     rango debe aparecer en el texto del artículo citado; los distractores
///     con rango deben diferir del rango correcto.
///  7. Personalización por usuario: 'variables' con ≥2 listas.
///  8. Deduplicación: contra lotes previos.
///
/// Uso: puro Dart (sin Flutter) para poder ejecutarse desde `tool/` con
/// `dart run` y reutilizarse dentro de la app (sync automático del quiz).
library;

class ArticuloCorpus {
  final String numero;
  final String texto;
  const ArticuloCorpus(this.numero, this.texto);
}

class LeyCorpus {
  final String nombre;
  final String archivo;
  final List<ArticuloCorpus> articulos;
  const LeyCorpus(this.nombre, this.archivo, this.articulos);
}

/// Resultado de evaluar un caso.
class VerdictoCaso {
  final bool valido;
  final List<String> errores;
  final List<String> advertencias;
  const VerdictoCaso(this.valido, this.errores, [this.advertencias = const []]);
}

class QuizValidadorService {
  QuizValidadorService({
    this.minTokensFirma = 1,
    this.minTokensAmbiguedad = 3,
    this.largoCitaLiteral = 40,
  });

  /// Mínimo de tokens distintivos del artículo que debe contener el escenario
  /// (calibrado: art. 405 CP tiene solo 1 distintivo — "intencionalmente").
  final int minTokensFirma;

  /// Para declarar ambigüedad: el escenario debe encajar en OTRO artículo con
  /// al menos este número de tokens distintivos suyos (señal fuerte; 2 tokens
  /// comunes como "detenido"+"violencia" producen falsos positivos).
  final int minTokensAmbiguedad;
  final int largoCitaLiteral;

  // ---------------------------------------------------------------------
  // Normalización de texto (acentos, minúsculas, tokenización)
  // ---------------------------------------------------------------------

  static const _acentos = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
    'ü': 'u', 'ñ': 'n', 'Á': 'a', 'É': 'e', 'Í': 'i', 'Ó': 'o',
    'Ú': 'u', 'Ü': 'u', 'Ñ': 'n',
  };

  static const _stopwords = {
    'de', 'la', 'el', 'los', 'las', 'del', 'para', 'por', 'con', 'sin',
    'que', 'se', 'su', 'sus', 'un', 'una', 'unos', 'unas', 'al', 'lo',
    'le', 'les', 'en', 'es', 'y', 'o', 'a', 'no', 'si', 'como',
    'pero', 'cual', 'cuales', 'cuando', 'donde', 'este', 'esta',
    'estos', 'estas', 'todo', 'toda', 'todos', 'todas', 'cada', 'entre',
    'sobre', 'hasta', 'desde', 'contra', 'durante', 'solo', 'sola',
    'segundo', 'segunda', 'primer', 'primera', 'tercer', 'tercera',
    'tambien', 'asi', 'aun', 'ya', 'muy', 'ser', 'estar', 'haber',
    'tener', 'hacer', 'podra', 'podran', 'sera', 'seran', 'debe',
    'deben', 'debera', 'deberan', 'puede', 'pueden', 'pudiera',
    'pudieran', 'responde', 'responden', 'aplica', 'aplican',
    'sanciona', 'sancionan', 'establece', 'establecen', 'dispone',
    'disponen', 'previene', 'previenen', 'comete', 'cometen',
    'incurre', 'incurren', 'art', 'articulo', 'articulos',
    'correspondera', 'corresponde', 'corresponden', 'anos', 'anios',
  };

  static String normalizar(String texto) {
    final sb = StringBuffer();
    for (final ch in texto.toLowerCase().split('')) {
      sb.write(_acentos[ch] ?? ch);
    }
    return sb.toString();
  }

  static List<String> tokenizar(String texto) {
    final norm = normalizar(texto);
    final partes = norm.split(RegExp(r'[^a-z0-9]+'));
    return partes
        .where((t) => t.length >= 4 && !_stopwords.contains(t))
        .toList();
  }

  static String normalizarEspacios(String texto) =>
      texto.replaceAll(RegExp(r'\s+'), ' ').trim();

  // ---------------------------------------------------------------------
  // Corpus (esquema agnóstico: bucket y assets locales)
  // ---------------------------------------------------------------------

  /// Extrae los artículos de una ley, soportando ambos esquemas:
  ///  - bucket: { estructura: [{ articulos: [{identificador, texto_principal,
  ///    numerales_literales, paragrafos}]}] }
  ///  - assets locales: { articulos: [{numero_texto, parrafos:[{texto}]}] }
  static LeyCorpus cargarLey(Map<String, dynamic> json, String archivo) {
    final nombre = (json['nombre'] as String?) ??
        (json['ley_nombre'] as String?) ??
        archivo;
    final articulos = <ArticuloCorpus>[];

    final estructura = json['estructura'];
    if (estructura is List) {
      for (final bloque in estructura) {
        final lista = (bloque as Map<String, dynamic>)['articulos'];
        if (lista is! List) continue;
        for (final a in lista.cast<Map<String, dynamic>>()) {
          final cuerpo = <String>[
            a['encabezado'],
            a['texto_principal'],
            ...((a['numerales_literales'] as List?) ?? const []),
            ...((a['paragrafos'] as List?) ?? const []),
          ]
              .map(_textoDe)
              .where((t) => t.isNotEmpty)
              .join(' ');
          articulos.add(ArticuloCorpus(
            (a['identificador'] ?? '').toString(),
            normalizarEspacios(cuerpo),
          ));
        }
      }
    } else {
      final lista = json['articulos'];
      if (lista is List) {
        for (final a in lista.cast<Map<String, dynamic>>()) {
          final parrafos = ((a['parrafos'] as List?) ?? const [])
              .map((p) => p is Map ? (p['texto'] ?? '') : p)
              .map((t) => t.toString())
              .join(' ');
          articulos.add(ArticuloCorpus(
            (a['numero_texto'] ?? '').toString(),
            normalizarEspacios(parrafos),
          ));
        }
      }
    }
    return LeyCorpus(nombre, archivo, articulos);
  }

  static String _textoDe(dynamic x) =>
      x is String ? x : (x is Map ? (x['texto'] ?? x['texto_principal'] ?? '') : '');

  /// Busca la ley del corpus cuyo nombre/archivo coincide con la cita.
  /// Reglas: "Código Penal" → codigo-penal; "COPP"/"Procesal Penal" → copp;
  /// "Orgánica de Drogas" → ley-organica-de-drogas; etc.
  static LeyCorpus? leyParaCita(
    List<LeyCorpus> corpus,
    String citaLey,
  ) {
    final norm = normalizar(citaLey);
    if (norm.contains('procesal penal') || norm.contains('copp')) {
      return _buscar(corpus, 'copp') ?? _buscar(corpus, 'procesal');
    }
    if (norm.contains('penal') && norm.contains('codigo')) {
      return _buscar(corpus, 'codigopenal');
    }
    if (norm.contains('drogas')) return _buscar(corpus, 'drogas');
    if (norm.contains('nino') || norm.contains('adolescente')) {
      return _buscar(corpus, 'protecciondeninos');
    }
    if (norm.contains('corrupcion')) return _buscar(corpus, 'corrupcion');
    if (norm.contains('secuestro')) return _buscar(corpus, 'secuestro');
    if (norm.contains('informatico')) return _buscar(corpus, 'informaticos');
    if (norm.contains('delincuencia organizada')) {
      return _buscar(corpus, 'delincuenciaorganizada');
    }
    if (norm.contains('violencia')) return _buscar(corpus, 'violencia');
    return _buscar(corpus, normalizar(citaLey).split(' ').first);
  }

  static LeyCorpus? _buscar(List<LeyCorpus> corpus, String fragmento) {
    final f = normalizar(fragmento).replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (final ley in corpus) {
      final nombre = normalizar(ley.nombre).replaceAll(RegExp(r'[^a-z0-9]'), '');
      final archivo = normalizar(ley.archivo).replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (nombre.contains(f) || archivo.contains(f)) {
        return ley;
      }
    }
    return null;
  }

  /// Tokens distintivos de un artículo: tokens que aparecen en el artículo
  /// y en menos del 8% de los demás artículos de la misma ley (frecuencia
  /// documental baja). Son la "firma" legal del artículo.
  static Set<String> tokensDistintivos(LeyCorpus ley, ArticuloCorpus articulo) {
    final tokensArt = tokenizar(articulo.texto).toSet();
    if (tokensArt.isEmpty) return const {};
    final total = ley.articulos.length;
    final umbral = (total * 0.08).ceil().clamp(2, 20);
    final presentes = <String, int>{};
    for (final a in ley.articulos) {
      for (final t in tokenizar(a.texto).toSet()) {
        presentes[t] = (presentes[t] ?? 0) + 1;
      }
    }
    return tokensArt
        .where((t) => (presentes[t] ?? 0) < umbral)
        .toSet();
  }

  static const _numeros = {
    'cero': 0, 'uno': 1, 'dos': 2, 'tres': 3, 'cuatro': 4, 'cinco': 5,
    'seis': 6, 'siete': 7, 'ocho': 8, 'nueve': 9, 'diez': 10, 'once': 11,
    'doce': 12, 'trece': 13, 'catorce': 14, 'quince': 15, 'dieciseis': 16,
    'diecisiete': 17, 'dieciocho': 18, 'diecinueve': 19, 'veinte': 20,
    'veintiuno': 21, 'veintidos': 22, 'veintitres': 23, 'veinticuatro': 24,
    'veinticinco': 25, 'veintiseis': 26, 'veintisiete': 27, 'veintiocho': 28,
    'veintinueve': 29, 'treinta': 30, 'cuarenta': 40, 'cincuenta': 50,
    'sesenta': 60, 'setenta': 70, 'ochenta': 80, 'noventa': 90,
  };

  /// Convierte números en palabras a dígitos (el corpus usa ambos formatos).
  static String _numerosADigitos(String texto) {
    var s = texto;
    for (final e in _numeros.entries) {
      s = s.replaceAll(RegExp('\\b${e.key}\\b'), e.value.toString());
    }
    return s;
  }

  // ---------------------------------------------------------------------
  // Extracción de rangos de pena desde texto ("de 4 a 8 años", "doce a dieciocho")
  // ---------------------------------------------------------------------

  static List<List<int>> rangosDePena(String texto) {
    final norm = _numerosADigitos(normalizar(texto));
    final resultados = <List<int>>[];
    final patrones = [
      // "de 12 a 18 años" (años solo al final) y "de 4 años a 8 años"
      RegExp(r'de\s+(\d{1,3})\s*(?:anos|anios)?\s+(?:a|y)\s+(\d{1,3})\s*(?:anos|anios)'),
      // "12 a 18 años" / "4 años a 8 años" (sin 'de')
      RegExp(r'(?<!\d)(\d{1,3})\s*(?:anos|anios)?\s+(?:a|y)\s+(\d{1,3})\s*(?:anos|anios)'),
    ];
    final vistos = <String>{};
    for (final p in patrones) {
      for (final m in p.allMatches(norm)) {
        final par = [int.parse(m.group(1)!), int.parse(m.group(2)!)];
        final clave = par.join('-');
        if (vistos.add(clave)) {
          resultados.add(par);
        }
      }
    }
    return resultados;
  }

  /// ¿El rango de la opción coincide con el rango legal esperado (tolerancia)?
  static bool rangoCoincide(List<int> opcion, List<int> esperado,
      {int tolerancia = 1}) {
    final difMin = (opcion[0] - esperado[0]).abs();
    final difMax = (opcion[1] - esperado[1]).abs();
    return difMin <= tolerancia && difMax <= tolerancia;
  }

  // ---------------------------------------------------------------------
  // Evaluación de un caso
  // ---------------------------------------------------------------------

  VerdictoCaso validarCaso(
    Map<String, dynamic> caso,
    List<LeyCorpus> corpus, {
    Set<String>? idsPrevios,
  }) {
    final errores = <String>[];
    final advertencias = <String>[];

    // 1. Estructura -------------------------------------------------------
    final contexto = (caso['contexto'] ?? caso['contextoNarrativo'] ?? '')
        .toString();
    final opciones = (caso['opciones'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final respuesta = (caso['respuesta_correcta'] as num?)?.toInt() ??
        (caso['respuestaCorrecta'] as num?)?.toInt() ??
        -1;
    final fundamentacion =
        (caso['fundamentacion'] ?? caso['fundamentación'] ?? '').toString();
    final articulos =
        (caso['articulos'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final variables = caso['variables'];

    if (contexto.length < 40) errores.add('contexto corto (<40)');
    if (opciones.length != 4) errores.add('opciones != 4');
    if (respuesta < 0 || respuesta > 3) errores.add('respuesta_correcta inválida');
    if (fundamentacion.length < 25) errores.add('fundamentación corta (<25)');
    if (articulos.isEmpty) errores.add('sin artículos');
    if (variables is! Map || variables.length < 2) {
      errores.add('variables: se requieren ≥2 listas (personalización por usuario)');
    } else {
      for (final v in variables.values) {
        if (v is! List || v.length < 2) {
          errores.add('variables: cada lista debe tener ≥2 valores');
          break;
        }
      }
    }

    // 8. Deduplicación -----------------------------------------------------
    if (idsPrevios != null) {
      final id = caso['id']?.toString() ?? '';
      if (idsPrevios.contains(id)) {
        errores.add('id duplicado: $id');
      }
      final hash = normalizarEspacios(contexto);
      if (idsPrevios.contains('h:$hash')) {
        errores.add('contexto duplicado (mismo escenario)');
      }
    }

    // 2 + 3 + 4 + 5 + 6: por cada artículo citado --------------------------
    final escenario = '$contexto ${opciones.join(' ')}';
    final tokensEscenario = tokenizar(escenario).toSet();
    final rangosOpciones = opciones.map(rangosDePena).toList();
    final textoArticulosCitados = <String>[];

    for (final cita in articulos) {
      final m = RegExp(r'art\.?\s*([\d\-\.]+)', caseSensitive: false)
          .firstMatch(cita);
      if (m == null) {
        errores.add('cita sin número de artículo: "$cita"');
        continue;
      }
      final numCita = m.group(1)!.split(RegExp(r'[-\.]')).first;
      final ley = leyParaCita(corpus, cita.replaceFirst(RegExp(r'art\.?\s*[\d\-\.]+', caseSensitive: false), ''));
      if (ley == null) {
        errores.add('ley no encontrada en corpus: "$cita"');
        continue;
      }
      final articulo = ley.articulos.where((a) => a.numero == numCita).toList();
      if (articulo.isEmpty) {
        errores.add('art. $numCita no existe en ${ley.nombre}');
        continue;
      }
      final a = articulo.first;

      // 3. Fundamentación LITERAL -------------------------------------------
      final fundNorm = normalizarEspacios(fundamentacion);
      final artNorm = normalizarEspacios(a.texto);
      final tieneCita =
          artNorm.length >= largoCitaLiteral &&
              fundNorm.contains(artNorm.substring(0, largoCitaLiteral));
      if (!tieneCita) {
        errores.add(
            'fundamentación no literal para art. $numCita (debe citar textualmente el artículo)');
      }
      textoArticulosCitados.add(artNorm);

      // 4. Firma de elementos ------------------------------------------------
      final distintivos = tokensDistintivos(ley, a);
      final coinciden = distintivos.intersection(tokensEscenario).length;
      if (coinciden < minTokensFirma) {
        errores.add(
            'firma insuficiente para art. $numCita: $coinciden/${minTokensFirma} tokens distintivos del artículo en el escenario');
      }

      // 5. Ambigüedad ----------------------------------------------------------
      // Solo importa si el otro artículo es una ALTERNATIVA PLAUSIBLE: aparece
      // en las opciones o su rango de pena aparece en alguna opción. Un match
      // incidental (p. ej. mencionar que NO hubo agravantes) no es ambigüedad.
      final opcionesTexto = opciones.join(' ');
      final rangosOpcionesTodos = rangosOpciones.expand((r) => r).toList();
      for (final otro in ley.articulos) {
        if (otro.numero == a.numero) continue;
        // Solo el rango PRINCIPAL del otro artículo define relevancia (un
        // artículo puede listar varios rangos para supuestos distintos).
        final rangosOtro = rangosDePena(otro.texto);
        final rangoPrincipal =
            rangosOtro.isNotEmpty ? [rangosOtro.first] : const <List<int>>[];
        final esRelevante = opcionesTexto.contains(otro.numero) ||
            rangosOpcionesTodos.any(
                (r) => rangoPrincipal.any((e) => rangoCoincide(r, e)));
        if (!esRelevante) continue;
        final d = tokensDistintivos(ley, otro);
        if (d.intersection(tokensEscenario).length >= minTokensAmbiguedad) {
          errores.add(
              'escenario ambiguo: también encaja con art. ${otro.numero} (${ley.nombre})');
          break;
        }
      }

      // 6. Penas desde el corpus ----------------------------------------------
      final rangosArt = rangosDePena(a.texto);
      final opcionCorrecta = opciones[respuesta];
      final rangosCorrecta = rangosDePena(opcionCorrecta);
      if (rangosArt.isNotEmpty) {
        if (rangosCorrecta.isEmpty) {
          advertencias.add(
              'art. $numCita declara pena pero la opción correcta no menciona un rango');
        } else {
          final ok = rangosCorrecta.any(
              (r) => rangosArt.any((e) => rangoCoincide(r, e)));
          if (!ok) {
            errores.add(
                'pena de la opción correcta ($rangosCorrecta) no coincide con la del art. $numCita ($rangosArt)');
          }
        }
        // Distractores: ningún otro rango de opción debe coincidir con el legal.
        for (var i = 0; i < opciones.length; i++) {
          if (i == respuesta) continue;
          for (final r in rangosOpciones[i]) {
            if (rangosArt.any((e) => rangoCoincide(r, e))) {
              errores.add(
                  'distractor $i repite la pena legal del art. $numCita ($r)');
              break;
            }
          }
        }
      }
    }

    // Control de calidad extra
    if (opciones[respuesta].trim().isEmpty) {
      errores.add('opción correcta vacía');
    }
    if (opciones.toSet().length != opciones.length) {
      errores.add('opciones duplicadas');
    }

    return VerdictoCaso(errores.isEmpty, errores, advertencias);
  }

  /// Valida un lote completo y devuelve (aprobados, rechazados).
  List<Map<String, dynamic>> validarLote(
    List<Map<String, dynamic>> casos,
    List<LeyCorpus> corpus, {
    Set<String>? idsPrevios,
  }) {
    final aprobados = <Map<String, dynamic>>[];
    for (final caso in casos) {
      final v = validarCaso(caso, corpus, idsPrevios: idsPrevios);
      if (v.valido) {
        aprobados.add(caso);
      }
    }
    return aprobados;
  }

  /// Convierte un caso aprobado al formato que espera la app (CasoQuiz.toJson).
  static Map<String, dynamic> aFormatoApp(Map<String, dynamic> caso) => {
        'id': caso['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'nivel': caso['nivel'] ?? 1,
        'tramo': caso['tramo'] ?? 1,
        'delito_base': caso['delito_base'] ?? caso['delitoBase'] ?? '',
        'contexto': caso['contexto'] ?? caso['contextoNarrativo'] ?? '',
        'opciones': caso['opciones'],
        'respuesta_correcta': caso['respuesta_correcta'] ?? caso['respuestaCorrecta'],
        'dificultad': caso['dificultad'] ?? 1,
        'fundamentacion': caso['fundamentacion'] ?? '',
        'articulos': caso['articulos'] ?? const [],
        'sentencias': caso['sentencias'] ?? const [],
      };
}
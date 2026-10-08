import 'dart:convert';

/// Metadatos de una ley provenientes del `manifest.json` alojado en
/// Supabase Storage (bucket público `leyes`).
class LeyMeta {
  final String slug;
  final String archivo;
  final String nombre;
  final int orden; // 1 = más relevante (Constitución) ... n = menos relevante
  final int articulos;
  final String url;

  const LeyMeta({
    required this.slug,
    required this.archivo,
    required this.nombre,
    required this.orden,
    required this.articulos,
    required this.url,
  });

  factory LeyMeta.fromJson(Map<String, dynamic> json) => LeyMeta(
        slug: json['slug'] as String? ?? '',
        archivo: json['archivo'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        orden: json['orden'] as int? ?? 999,
        articulos: json['articulos'] as int? ?? 0,
        url: json['url'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'archivo': archivo,
        'nombre': nombre,
        'orden': orden,
        'articulos': articulos,
        'url': url,
      };
}

/// Ley completa (esquema `{ley_nombre, estructura[]}`) descargada desde Storage.
class LeyEstructurada {
  final String nombre;
  final List<BloqueLey> estructura;

  const LeyEstructurada({required this.nombre, required this.estructura});

  int get totalArticulos => estructura.fold<int>(
      0, (acc, b) => acc + b.articulos.length);

  List<ArticuloLey> get todosLosArticulos =>
      estructura.expand((b) => b.articulos).toList();

  factory LeyEstructurada.fromJson(Map<String, dynamic> json) {
    final est = (json['estructura'] as List? ?? const []);
    return LeyEstructurada(
      nombre: json['ley_nombre'] as String? ?? '',
      estructura: est
          .map((e) => BloqueLey.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Bloque jerárquico: Libro > Título > Capítulo > Sección, con sus artículos.
class BloqueLey {
  final String? libro;
  final String? titulo;
  final String? capitulo;
  final String? seccion;
  final List<ArticuloLey> articulos;

  const BloqueLey({
    this.libro,
    this.titulo,
    this.capitulo,
    this.seccion,
    required this.articulos,
  });

  factory BloqueLey.fromJson(Map<String, dynamic> json) => BloqueLey(
        libro: _nullToEmpty(json['libro']),
        titulo: _nullToEmpty(json['titulo']),
        capitulo: _nullToEmpty(json['capitulo']),
        seccion: _nullToEmpty(json['seccion']),
        articulos: (json['articulos'] as List? ?? const [])
            .map((a) => ArticuloLey.fromJson(a as Map<String, dynamic>))
            .toList(),
      );

  static String? _nullToEmpty(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}

class ArticuloLey {
  final String tipoNorma; // "Artículo", "Preámbulo", "Disposición ..."
  final String identificador;
  final String? encabezado;
  final String textoPrincipal;
  final List<String> numeralesLiterales;
  final List<String> paragrafos;
  final String estado;
  final List<TablaAnexo> tablas;

  const ArticuloLey({
    required this.tipoNorma,
    required this.identificador,
    this.encabezado,
    required this.textoPrincipal,
    required this.numeralesLiterales,
    required this.paragrafos,
    required this.estado,
    this.tablas = const [],
  });

  factory ArticuloLey.fromJson(Map<String, dynamic> json) => ArticuloLey(
        tipoNorma: json['tipo_norma'] as String? ?? 'Artículo',
        identificador: json['identificador'] as String? ?? '',
        encabezado: _nullToEmpty(json['encabezado']),
        textoPrincipal: json['texto_principal'] as String? ?? '',
        numeralesLiterales: List<String>.from(json['numerales_literales'] as List? ?? const []),
        paragrafos: List<String>.from(json['paragrafos'] as List? ?? const []),
        estado: json['estado'] as String? ?? 'vigente',
        tablas: (json['tablas'] as List? ?? const [])
            .map((t) => TablaAnexo.fromJson(t as Map<String, dynamic>))
            .toList(),
      );

  static String? _nullToEmpty(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Texto completo plano del artículo (para búsqueda y visualización).
  String get textoCompleto => [
        if (encabezado != null && encabezado!.isNotEmpty) encabezado!,
        textoPrincipal,
        ...numeralesLiterales,
        ...paragrafos,
      ].join('\n');
}

/// Tabla o anexo asociado a un artículo (campo `tablas` del JSON de la ley).
/// Ejemplo: {"numeral": "26", "titulo": "ANEXO I", "tabla": "...",
///  "columnas": [{"id": "lista_1", "titulo": "LISTA I"}, ...],
///  "filas": [{"lista_1": "...", "lista_2": "..."}, ...]}
class TablaAnexo {
  final String? numeral; // numeral del artículo al que pertenece (ej. "26")
  final String? titulo; // ej. "ANEXO I"
  final String? tabla; // nombre de la tabla
  final List<Map<String, String>> columnas; // [{id, titulo}]
  final List<Map<String, String>> filas; // [{id_columna: valor}]

  const TablaAnexo({
    this.numeral,
    this.titulo,
    this.tabla,
    this.columnas = const [],
    this.filas = const [],
  });

  factory TablaAnexo.fromJson(Map<String, dynamic> json) => TablaAnexo(
        numeral: json['numeral'] as String?,
        titulo: json['titulo'] as String?,
        tabla: json['tabla'] as String?,
        columnas: _mapStrings(json['columnas']),
        filas: _mapStrings(json['filas']),
      );

  Map<String, dynamic> toJson() => {
        'numeral': numeral,
        'titulo': titulo,
        'tabla': tabla,
        'columnas': columnas,
        'filas': filas,
      };

  static List<Map<String, String>> _mapStrings(dynamic v) {
    final raw = v as List? ?? const [];
    return raw.map((e) {
      final m = (e as Map).cast<String, dynamic>();
      return m.map((k, val) => MapEntry(k, val?.toString() ?? ''));
    }).toList();
  }
}

/// Registro plano de un artículo dentro del índice de búsqueda.
/// Se genera a partir de cada [ArticuloLey] para permitir búsqueda
/// semántica/full-text sin tener que descargar y recorrer todo el JSON.
class RegistroArticulo {
  final String slug;
  final String leyNombre;
  final String? libro;
  final String? titulo;
  final String? capitulo;
  final String? seccion;
  final String identificador;
  final String tipoNorma;
  final String? encabezado;
  final String texto;
  final List<String> numeralesLiterales;
  final List<String> paragrafos;
  final String estado;
  final List<TablaAnexo> tablas;

  const RegistroArticulo({
    required this.slug,
    required this.leyNombre,
    this.libro,
    this.titulo,
    this.capitulo,
    this.seccion,
    required this.identificador,
    required this.tipoNorma,
    this.encabezado,
    required this.texto,
    this.numeralesLiterales = const [],
    this.paragrafos = const [],
    this.estado = 'vigente',
    this.tablas = const [],
  });

  /// Texto sobre el que se calcula la relevancia.
  String get textoBusqueda => [
        if (encabezado != null) encabezado!,
        texto,
        ...numeralesLiterales,
        ...paragrafos,
      ].join(' ').toLowerCase();

  /// Texto completo del artículo para visualización.
  String get textoCompleto => [
        if (encabezado != null && encabezado!.isNotEmpty) encabezado!,
        texto,
        ...numeralesLiterales,
        ...paragrafos,
      ].join('\n');

  /// Indica si el artículo está vigente (no derogado/reformado/anulado).
  bool get esVigente {
    final e = estado.toLowerCase().trim();
    if (e.contains('derog') ||
        e.contains('reform') ||
        e.contains('anul') ||
        e.contains('sin vigencia')) {
      return false;
    }
    final txt =
        '$encabezado $texto ${numeralesLiterales.join(' ')} ${paragrafos.join(' ')}'.toLowerCase();
    const marcadores = [
      'artículo derogado',
      'articulo derogado',
      'derogado por',
      'derogada por',
      'sin vigencia',
    ];
    return !marcadores.any(txt.contains);
  }

  factory RegistroArticulo.fromJson(Map<String, dynamic> json) =>
      RegistroArticulo(
        slug: json['slug'] as String? ?? '',
        leyNombre: json['ley_nombre'] as String? ?? '',
        libro: json['libro'] as String?,
        titulo: json['titulo'] as String?,
        capitulo: json['capitulo'] as String?,
        seccion: json['seccion'] as String?,
        identificador: json['identificador'] as String? ?? '',
        tipoNorma: json['tipo_norma'] as String? ?? 'Artículo',
        encabezado: json['encabezado'] as String?,
        texto: json['texto'] as String? ?? '',
        numeralesLiterales:
            List<String>.from(json['numerales_literales'] as List? ?? const []),
        paragrafos: List<String>.from(json['paragrafos'] as List? ?? const []),
        estado: json['estado'] as String? ?? 'vigente',
        tablas: (json['tablas'] as List? ?? const [])
            .map((t) => TablaAnexo.fromJson(t as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'ley_nombre': leyNombre,
        'libro': libro,
        'titulo': titulo,
        'capitulo': capitulo,
        'seccion': seccion,
        'identificador': identificador,
        'tipo_norma': tipoNorma,
        'encabezado': encabezado,
        'texto': texto,
        'numerales_literales': numeralesLiterales,
        'paragrafos': paragrafos,
        'estado': estado,
        'tablas': tablas.map((t) => t.toJson()).toList(),
      };
}

/// Convierte una [LeyEstructurada] en una lista plana de [RegistroArticulo].
List<RegistroArticulo> aplanarLey(LeyEstructurada ley, String slug) {
  final registros = <RegistroArticulo>[];
  for (final bloque in ley.estructura) {
    for (final art in bloque.articulos) {
      registros.add(RegistroArticulo(
        slug: slug,
        leyNombre: ley.nombre,
        libro: bloque.libro,
        titulo: bloque.titulo,
        capitulo: bloque.capitulo,
        seccion: bloque.seccion,
        identificador: art.identificador,
        tipoNorma: art.tipoNorma,
        encabezado: art.encabezado,
        texto: art.textoPrincipal,
        numeralesLiterales: art.numeralesLiterales,
        paragrafos: art.paragrafos,
        estado: art.estado,
        tablas: art.tablas,
      ));
    }
  }
  return registros;
}

/// Codifica/decodifica el índice completo (lista de registros) para caché local.
String codificarIndice(List<RegistroArticulo> registros) =>
    jsonEncode(registros.map((r) => r.toJson()).toList());

List<RegistroArticulo> decodificarIndice(String raw) {
  final list = jsonDecode(raw) as List;
  return list
      .map((e) => RegistroArticulo.fromJson(e as Map<String, dynamic>))
      .toList();
}

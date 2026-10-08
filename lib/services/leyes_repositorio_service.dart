import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ley_estructurada.dart';

/// Servicio del Repositorio de Leyes.
///
/// Las leyes viven en Supabase **Storage** (bucket público `leyes`) —no en la
/// base de datos— y este servicio se encarga de:
///  * descargar el `manifest.json` (lista ordenada por relevancia),
///  * descargar y parsear cada ley (`{ley_nombre, estructura[]}`),
///  * construir un índice plano de artículos para búsqueda rápida,
///  * búsqueda semántica (expansión de consulta con DeepSeek + puntaje local).
class LeyesRepositorioService {
  LeyesRepositorioService._();
  static final LeyesRepositorioService _instance =
      LeyesRepositorioService._();
  factory LeyesRepositorioService() => _instance;

  static const String _bucket = 'leyes';
  static const String _manifestKey = 'leyes_manifest_cache_v1';
  static const String _indiceFile = 'penalex_indice_leyes_v3.json';

  /// Caché en memoria (por sesión).
  List<LeyMeta>? _manifest;
  List<RegistroArticulo>? _indice;
  final Map<String, LeyEstructurada> _leyesCache = {};

  /// Caché de expansiones semánticas (evita llamadas repetidas a DeepSeek).
  final Map<String, List<String>> _cacheExpansiones = {};

  static String get _deepseekApiKey =>
      dotenv.env['DEEPSEEK_API_KEY'] ?? '';

  String _publicUrl(String path) => Supabase.instance.client.storage
      .from(_bucket)
      .getPublicUrl(path);

  // ---------------------------------------------------------------------------
  // Manifest (lista de leyes ordenada por relevancia)
  // ---------------------------------------------------------------------------

  Future<List<LeyMeta>> cargarManifest({bool forzarRed = false}) async {
    if (_manifest != null && !forzarRed) return _manifest!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_manifestKey);
      if (!forzarRed && cached != null && cached.isNotEmpty) {
        _manifest = _parseManifest(cached);
        debugPrint('📚 Manifest de leyes cargado desde caché local');
        return _manifest!;
      }

      final url = _publicUrl('manifest.json');
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final raw = utf8.decode(res.bodyBytes);
        await prefs.setString(_manifestKey, raw);
        _manifest = _parseManifest(raw);
        debugPrint('📚 Manifest de leyes descargado: ${_manifest!.length} leyes');
        return _manifest!;
      }
      debugPrint('⚠️ Error descargando manifest: HTTP ${res.statusCode}');
    } catch (e) {
      debugPrint('❌ Error cargando manifest: $e');
    }

    // Último recurso: caché local aunque sea viejo
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_manifestKey);
    if (cached != null && cached.isNotEmpty) {
      return _parseManifest(cached);
    }
    return [];
  }

  List<LeyMeta> _parseManifest(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final leyes = (data['leyes'] as List? ?? const []);
    final lista = leyes
        .map((e) => LeyMeta.fromJson(e as Map<String, dynamic>))
        .toList();
    lista.sort((a, b) => a.orden.compareTo(b.orden));
    return lista;
  }

  // ---------------------------------------------------------------------------
  // Descarga / parseo de leyes
  // ---------------------------------------------------------------------------

  Future<LeyEstructurada?> cargarLey(String slug) async {
    if (_leyesCache.containsKey(slug)) return _leyesCache[slug];
    try {
      final url = _publicUrl('$slug.json');
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final ley = LeyEstructurada.fromJson(data);
        _leyesCache[slug] = ley;
        return ley;
      }
      debugPrint('⚠️ Error descargando ley $slug: HTTP ${res.statusCode}');
    } catch (e) {
      debugPrint('❌ Error descargando ley $slug: $e');
    }
    return null;
  }

  /// Obtiene artículos específicos de una ley por su identificador numérico
  /// (ej. COPP 236, 237, 238). Devuelve los encontrados, en orden.
  Future<List<RegistroArticulo>> obtenerArticulos(
    String slug,
    List<String> identificadores,
  ) async {
    final ley = await cargarLey(slug);
    if (ley == null) return [];
    final planos = aplanarLey(ley, slug);
    final buscados = identificadores.map(_normalizarIdentificador).toSet();
    final resultado = planos.where((r) {
      return r.esVigente &&
          r.tipoNorma.toLowerCase().contains('art') &&
          buscados.contains(_normalizarIdentificador(r.identificador));
    }).toList();
    // Ordenar según el orden solicitado.
    resultado.sort((a, b) {
      final ia = identificadores.indexOf(a.identificador);
      final ib = identificadores.indexOf(b.identificador);
      final na = ia < 0 ? 999 : ia;
      final nb = ib < 0 ? 999 : ib;
      return na.compareTo(nb);
    });
    return resultado;
  }

  static String _normalizarIdentificador(String id) {
    return id.trim().replaceAll(RegExp(r'^0+'), '').toLowerCase();
  }

  // ---------------------------------------------------------------------------
  // Índice de búsqueda (plano de artículos)
  // ---------------------------------------------------------------------------

  /// Garantiza que el índice esté construido, descargando todas las leyes
  /// (solo la primera vez por instalación; luego se reusa desde caché).
  Future<void> garantizarIndice({
    void Function(int actual, int total)? onProgress,
  }) async {
    if (_indice != null) return;

    // 1) Intentar cargar desde caché en disco.
    final desdeDisco = await _cargarIndiceDisco();
    if (desdeDisco != null && desdeDisco.isNotEmpty) {
      _indice = desdeDisco.where((r) => r.esVigente).toList();
      debugPrint('🧠 Índice de leyes cargado desde disco (${_indice!.length} artículos)');
      return;
    }

    // 2) Construir descargando ley por ley.
    final manifest = await cargarManifest();
    final registros = <RegistroArticulo>[];
    final total = manifest.length;
    for (var i = 0; i < total; i++) {
      final meta = manifest[i];
      onProgress?.call(i + 1, total);
      final ley = await cargarLey(meta.slug);
      if (ley != null) {
        registros.addAll(aplanarLey(ley, meta.slug));
      }
    }
    _indice = registros.where((r) => r.esVigente).toList();
    debugPrint('🧠 Índice de leyes construido: ${_indice!.length} artículos');
    await _guardarIndiceDisco(registros.where((r) => r.esVigente).toList());
  }

  Future<List<RegistroArticulo>?> _cargarIndiceDisco() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_indiceFile');
      if (await file.exists()) {
        return decodificarIndice(await file.readAsString());
      }
    } catch (e) {
      debugPrint('⚠️ No se pudo leer índice en disco: $e');
    }
    return null;
  }

  Future<void> _guardarIndiceDisco(List<RegistroArticulo> registros) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_indiceFile');
      await file.writeAsString(codificarIndice(registros));
    } catch (e) {
      debugPrint('⚠️ No se pudo guardar índice en disco: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Búsqueda semántica
  // ---------------------------------------------------------------------------

  /// Busca artículos relevantes a [consulta] en todas las leyes.
  Future<List<ResultadoLey>> buscar(
    String consulta, {
    int limite = 50,
    void Function(int actual, int total)? onProgresoIndice,
  }) async {
    final q = consulta.trim();
    if (q.isEmpty) return [];

    await garantizarIndice(onProgress: onProgresoIndice);
    if (_indice == null || _indice!.isEmpty) return [];

    // Números de artículo (ej. "406") → coincidencia exacta prioritaria.
    final numeros = RegExp(r'\d+')
        .allMatches(q)
        .map((m) => m.group(0)!)
        .toSet();

    // Palabras clave (sin números) → búsqueda de texto.
    final palabras = q
        .split(RegExp(r'[\s,.;:()\-\u2013\u2014]+'))
        .map(_sinAcentos)
        .where((t) => t.isNotEmpty && !RegExp(r'^\d+$').hasMatch(t))
        .toSet();

    // Expansión semántica SOLO si no hay número (la precisión manda).
    final terminos =
        numeros.isEmpty ? await _expandirConsulta(q) : const <String>[];

    // Detectar la ley especificada en la consulta → FILTRAR a esa ley.
    final leyesUnicas = _indice!.map((r) => r.leyNombre).toSet();
    final leyDetectada = _detectarLey(q, leyesUnicas);

    final resultados = <ResultadoLey>[];
    for (final reg in _indice!) {
      if (leyDetectada != null && reg.leyNombre != leyDetectada) continue;
      final score = _puntuar(reg, terminos, numeros, palabras);
      if (score > 0) {
        resultados.add(ResultadoLey(
          registro: reg,
          puntaje: score,
          extracto: _extracto(reg.textoBusqueda, terminos, q),
        ));
      }
    }

    resultados.sort((a, b) => b.puntaje.compareTo(a.puntaje));
    return resultados.take(limite).toList();
  }

  double _puntuar(
    RegistroArticulo reg,
    List<String> terminos,
    Set<String> numeros,
    Set<String> palabras,
  ) {
    final texto = _sinAcentos(reg.textoBusqueda);
    final encabezado = _sinAcentos(reg.encabezado ?? '');
    final titulo = _sinAcentos(reg.titulo ?? '');
    final leyNombre = _sinAcentos(reg.leyNombre);
    final identificador = _sinAcentos(reg.identificador);

    double score = 0;

    // 1) Coincidencia EXACTA de número de artículo: prioridad máxima.
    for (final n in numeros) {
      if (identificador == n) {
        score += 100;
      } else if (n.length >= 2 && identificador.contains(n)) {
        score += 6;
      }
    }

    // 2) Palabras clave en encabezado/título/nombre de ley/texto.
    for (final p in palabras) {
      if (p.isEmpty) continue;
      score += _contar(encabezado, p) * 4.0;
      score += _contar(titulo, p) * 3.0;
      score += _contar(leyNombre, p) * 3.0;
      score += _contar(texto, p) * 1.0;
    }

    // 3) Términos expandidos (solo consultas sin número).
    for (final t in terminos) {
      final term = _sinAcentos(t);
      if (term.isEmpty) continue;
      score += _contar(encabezado, term) * 3.0;
      score += _contar(titulo, term) * 2.0;
      score += _contar(texto, term) * 1.0;
      if (identificador == term) score += 8;
    }

    return score;
  }

  /// Detecta la ley mencionada en la consulta ("ley de violencia",
  /// "código penal", "copp", "lopnna", "constitución", ...).
  /// Devuelve el nombre exacto de la ley (o null si no se especifica).
  String? _detectarLey(String consulta, Set<String> leyesUnicas) {
    const stopwords = {
      'articulo', 'articulos', 'art', 'del', 'de', 'la', 'el', 'los', 'las',
      'segun', 'conforme',
    };
    const alias = {
      'copp': 'procesal penal',
      'crbv': 'constitucion',
      'constitucion': 'constitucion',
      'lopnna': 'lopnna',
      'violencia': 'violencia',
      'codigo penal': 'codigo penal',
      'cp': 'codigo penal',
    };

    final qnorm = _sinAcentos(consulta.toLowerCase()).trim();

    // Alias primero (acrónimos y nombres comunes).
    for (final e in alias.entries) {
      if (qnorm.contains(e.key)) {
        final frag = _sinAcentos(e.value);
        for (final nombre in leyesUnicas) {
          if (_sinAcentos(nombre).contains(frag)) return nombre;
        }
      }
    }

    // Frase completa (sin números ni stopwords) contenida en el nombre.
    final tokens = qnorm
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) =>
            t.isNotEmpty &&
            !RegExp(r'^\d+$').hasMatch(t) &&
            !stopwords.contains(t))
        .toList();
    if (tokens.isEmpty) return null;

    final frase = tokens.join(' ');
    for (final nombre in leyesUnicas) {
      if (_sinAcentos(nombre).contains(frase)) return nombre;
    }

    // Fallback: palabra significativa (>= 4 letras) en el nombre.
    final palabras = tokens.where((t) => t.length >= 4).toSet();
    if (palabras.isEmpty) return null;
    String? mejor;
    var mejorScore = 0;
    for (final nombre in leyesUnicas) {
      final n = _sinAcentos(nombre);
      var score = 0;
      for (final p in palabras) {
        if (n.contains(p)) score++;
      }
      if (score > mejorScore) {
        mejorScore = score;
        mejor = nombre;
      }
    }
    return mejorScore >= 1 ? mejor : null;
  }

  /// Expande la consulta con sinónimos legales usando DeepSeek.
  Future<List<String>> _expandirConsulta(String consulta) async {
    final key = consulta.toLowerCase().trim();
    if (_cacheExpansiones.containsKey(key)) return _cacheExpansiones[key]!;

    try {
      if (_deepseekApiKey.isEmpty) return [consulta];

      final res = await http.post(
        Uri.parse('https://api.deepseek.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_deepseekApiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Eres un experto en derecho penal venezolano. Expande un término de búsqueda '
                  'legal con sinónimos, conceptos y términos relacionados (sin acentos). '
                  'Responde SOLO con una lista de términos separados por comas, máximo 8, '
                  'incluyendo el término original. Ejemplo: "matar" -> "matar, homicidio, '
                  'asesinato, dar muerte, privar de vida, occiso".',
            },
            {'role': 'user', 'content': consulta},
          ],
          'temperature': 0.3,
          'max_tokens': 100,
          'stream': false,
        }),
      ).timeout(const Duration(seconds: 8), onTimeout: () => http.Response('{}', 408));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final contenido = data['choices']?[0]?['message']?['content'] as String?;
        if (contenido != null) {
          final terminos = contenido
              .split(',')
              .map((t) => t.trim().toLowerCase())
              .where((t) => t.isNotEmpty && t.length > 1)
              .toList();
          if (terminos.isNotEmpty) {
            _cacheExpansiones[key] = terminos;
            return terminos;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error expandiendo consulta: $e');
    }
    return [consulta];
  }

  // ---------------------------------------------------------------------------
  // Utilidades
  // ---------------------------------------------------------------------------

  String _extracto(String texto, List<String> terminos, String consulta) {
    final textoNorm = _sinAcentos(texto);
    int pos = -1;
    for (final t in terminos) {
      pos = textoNorm.indexOf(_sinAcentos(t));
      if (pos != -1) break;
    }
    if (pos == -1) pos = textoNorm.indexOf(_sinAcentos(consulta));
    if (pos == -1) {
      return texto.length > 180 ? '${texto.substring(0, 180)}...' : texto;
    }
    final inicio = (pos - 60).clamp(0, texto.length);
    final fin = (pos + 120).clamp(0, texto.length);
    var ex = texto.substring(inicio, fin);
    if (inicio > 0) ex = '...$ex';
    if (fin < texto.length) ex = '$ex...';
    return ex;
  }

  int _contar(String texto, String termino) {
    if (termino.isEmpty) return 0;
    var count = 0;
    var idx = texto.indexOf(termino);
    while (idx != -1) {
      count++;
      idx = texto.indexOf(termino, idx + termino.length);
    }
    return count;
  }

  String _sinAcentos(String s) {
    const map = {
      'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a',
      'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
      'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
      'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o',
      'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
      'ñ': 'n', 'ç': 'c',
    };
    final buffer = StringBuffer();
    for (final c in s.toLowerCase().split('')) {
      buffer.write(map[c] ?? c);
    }
    return buffer.toString();
  }
}

/// Resultado de búsqueda con su puntaje y extracto resaltable.
class ResultadoLey {
  final RegistroArticulo registro;
  final double puntaje;
  final String extracto;

  const ResultadoLey({
    required this.registro,
    required this.puntaje,
    required this.extracto,
  });

  String get tituloCorto {
    final a = registro.identificador;
    if (registro.tipoNorma == 'Artículo') return 'Art. $a';
    return registro.tipoNorma;
  }
}

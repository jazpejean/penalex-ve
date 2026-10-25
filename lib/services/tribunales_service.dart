import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';

/// Tribunal penal venezolano (catálogo oficial del TSJ).
class Tribunal {
  final String id;
  final String codigo;
  final String nombre;
  final String? sede;
  final String estado;
  final String? municipio;
  final String? parroquia;
  final double? latitud;
  final double? longitud;
  final String instancia;
  final String? funcion;
  final String? seccion;
  final String? tipoSede;
  final String despacho;
  final double? distancia;
  final String? urlFoto;

  const Tribunal({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.sede,
    required this.estado,
    this.municipio,
    this.parroquia,
    this.latitud,
    this.longitud,
    required this.instancia,
    this.funcion,
    this.seccion,
    this.tipoSede,
    this.despacho = 'desconocido',
    this.distancia,
    this.urlFoto,
  });

  LatLng? get latLng {
    if (latitud == null || longitud == null) return null;
    return LatLng(latitud!, longitud!);
  }

  bool get tieneUbicacion => latLng != null;

  String get etiquetaFuncion {
    switch (funcion?.toUpperCase()) {
      case 'CONTROL':
        return 'Control';
      case 'JUICIO':
        return 'Juicio';
      case 'EJECUCIÓN':
        return 'Ejecución';
      case 'APELACIÓN':
        return 'Apelación';
      default:
        return funcion ?? '';
    }
  }

  /// Nombre limpio para mostrar: recorta el sufijo repetitivo del TSJ
  /// ("DEL CIRCUITO JUDICIAL PENAL DE LA CIRCUNSCRIPCIÓN JUDICIAL DEL
  /// ESTADO ...") y capitaliza cada palabra. Ej.:
  /// "TRIBUNAL PRIMERO DE PRIMERA INSTANCIA EN FUNCIONES DE JUICIO DEL
  ///  CIRCUITO JUDICIAL PENAL DE LA CIRCUNSCRIPCIÓN JUDICIAL DEL ESTADO
  ///  PORTUGUESA. EXTENSIÓN ACARIGUA"
  /// → "Tribunal Primero de Primera Instancia en Funciones de Juicio".
  String get nombreLimpio {
    var n = nombre.trim();
    // cortar en el separador de sede/extensión, si existe
    final corte = RegExp(
      r'\s+(DEL|DE LA)\s+(CIRCUITO|CIRCUNSCRIPCIÓN|CORTE|JUZGADO)\b',
      caseSensitive: false,
    ).firstMatch(n);
    if (corte != null) {
      n = n.substring(0, corte.start).trim();
    }
    // limpiar puntuación final y espacios dobles
    n = n.replaceAll(RegExp(r'[\.\s]+$'), '').replaceAll(RegExp(r'\s+'), ' ');
    // capitalizar (Title Case con minúsculas para conectores)
    const menores = {
      'DE', 'DEL', 'LA', 'EL', 'EN', 'A', 'AL', 'Y', 'O', 'POR', 'CON',
      'SEGÚN', 'SOBRE', 'PARA', 'LOS', 'LAS', 'UN', 'UNA',
    };
    final palabras = n.split(' ').map((p) {
      final baja = p.toLowerCase();
      if (menores.contains(baja.toUpperCase())) return baja;
      if (p.isEmpty) return p;
      return p[0].toUpperCase() + p.substring(1).toLowerCase();
    }).join(' ');
    return palabras;
  }

  factory Tribunal.fromMap(Map<String, dynamic> m) => Tribunal(
        id: (m['id'] ?? '').toString(),
        codigo: (m['codigo'] ?? '').toString(),
        nombre: (m['nombre'] ?? '').toString(),
        sede: m['sede']?.toString(),
        estado: (m['estado'] ?? '').toString(),
        municipio: m['municipio']?.toString(),
        parroquia: m['parroquia']?.toString(),
        latitud: (m['latitud'] as num?)?.toDouble(),
        longitud: (m['longitud'] as num?)?.toDouble(),
        instancia: (m['instancia'] ?? '').toString(),
        funcion: m['funcion']?.toString(),
        seccion: m['seccion']?.toString(),
        tipoSede: m['tipo_sede']?.toString(),
        despacho: (m['despacho'] ?? 'desconocido').toString(),
        distancia: (m['distancia'] as num?)?.toDouble(),
        urlFoto: m['url_foto']?.toString(),
      );
}

/// Consulta el catálogo de tribunales penales en Supabase.
class TribunalesService {
  static final _supabase = Supabase.instance.client;

  /// Caché del catálogo completo (el selector y el mapa lo reutilizan
  /// para el filtro por texto local, sin golpear la red en cada tecla).
  static List<Tribunal>? _cache;

  /// Todos los tribunales penales (con ubicación, filtrables).
  static Future<List<Tribunal>> listar() async {
    if (_cache != null) return _cache!;
    final rows = await _supabase
        .from('tribunales')
        .select()
        .order('estado')
        .order('nombre');
    final lista = rows.map(Tribunal.fromMap).toList();
    _cache = lista;
    return lista;
  }

  /// Invalida la caché (p. ej. tras corregir el catálogo en Supabase).
  static void invalidarCache() => _cache = null;

  /// Devuelve el catálogo ya cargado en caché (sin golpear la red), o null
  /// si aún no se ha cargado. Lo usa el selector para mostrar el directorio
  /// completo cuando el buscador está vacío.
  static List<Tribunal>? listarEnCache() => _cache;

  /// Filtro por TEXTO local (substring sin tildes) sobre todos los campos
  /// visibles: nombre, código, sede, municipio, estado, parroquia, sección
  /// y función. Devuelve TODOS los que coinciden (el "palacio completo"):
  /// buscar "Los Teques" lista los ~20 tribunales de esa sede, no uno solo.
  ///
  /// La búsqueda semántica (pgvector) queda como REFUERZO: se usa solo
  /// cuando este filtro local no encuentra nada.
  static List<Tribunal> filtrarPorTexto(String consulta) {
    final q = _normalizar(consulta.trim());
    if (q.isEmpty) return const <Tribunal>[];
    final cache = _cache;
    if (cache == null) return const <Tribunal>[];
    return cache.where((t) {
      final haystack = _normalizar(<String>[
        t.nombre,
        t.codigo,
        t.sede ?? '',
        t.municipio ?? '',
        t.estado,
        t.parroquia ?? '',
        t.seccion ?? '',
        t.funcion ?? '',
      ].join(' '));
      return haystack.contains(q);
    }).toList();
  }

  /// Normaliza para comparar sin tildes ni mayúsculas (Los Teques →
  /// "los teques"; BOLIVARIANO GUAICAIPURO → "bolivariano guaicaipuro").
  static String _normalizar(String s) {
    const acentos = <String, String>{
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
      'Á': 'a', 'É': 'e', 'Í': 'i', 'Ó': 'o', 'Ú': 'u',
      'ñ': 'ñ', 'Ñ': 'ñ',
    };
    final b = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      b.write(acentos[ch] ?? ch);
    }
    return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Tribunales con coordenadas válidas (para el mapa).
  static Future<List<Tribunal>> listarConUbicacion() async {
    final rows = await _supabase
        .from('tribunales')
        .select()
        .not('latitud', 'is', null)
        .not('longitud', 'is', null)
        .order('estado')
        .order('nombre');
    return rows.map(Tribunal.fromMap).toList();
  }

  /// Estados disponibles (para el filtro del mapa).
  static Future<List<String>> listarEstados() async {
    final rows = await _supabase
        .from('tribunales')
        .select('estado')
        .order('estado');
    return rows.map((r) => r['estado'] as String).toSet().toList();
  }

  /// Búsqueda semántica por pgvector (bge-m3, 1024 dims).
  ///
  /// Vectoriza [consulta] en el worker `/embedding` (Workers AI) y llama al
  /// RPC `buscar_tribunales_semanticos` de Supabase. Devuelve `null` si el
  /// worker no responde (no desplegado / sin red) para que la UI use el
  /// filtro por texto tradicional.
  ///
  /// [distancia] es distancia coseno (0 = idéntico, 1 = opuesto); la UI
  /// puede usar un umbral (ej. < 0.35) para decidir coincidencia.
  static Future<List<Tribunal>?> buscarSemantico(
    String consulta, {
    String? estado,
    String? funcion,
    String? instancia,
    String? seccion,
    int limite = 20,
  }) async {
    const workerUrl = String.fromEnvironment(
      'WORKER_URL',
      defaultValue: 'https://penalex-scraper.ignaciojazpe47.workers.dev',
    );
    const token = String.fromEnvironment(
      'INGEST_TOKEN',
      defaultValue: '',
    );
    try {
      final client = http.Client();
      try {
        final res = await client
            .post(
              Uri.parse('$workerUrl/embedding'),
              headers: {'Content-Type': 'application/json', 'x-token': token},
              body: jsonEncode({'texto': consulta}),
            )
            .timeout(const Duration(seconds: 10));
        if (res.statusCode != 200) return null;
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['ok'] != true || data['embedding'] == null) return null;
        final vector = List<double>.from(data['embedding'] as List);

        final rpc = await _supabase.rpc(
          'buscar_tribunales_semanticos',
          params: {
            'query_embedding': vector,
            'limite': limite,
            if (estado != null) 'p_estado': estado,
            if (funcion != null) 'p_funcion': funcion,
            if (instancia != null) 'p_instancia': instancia,
            if (seccion != null) 'p_seccion': seccion,
          },
        );
        return (rpc as List)
            .map((m) => Tribunal.fromMap(m as Map<String, dynamic>))
            .toList();
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('buscarSemantico: $e');
      return null;
    }
  }
}
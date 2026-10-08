import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Entrada de un estilo: [nombre] es el nombre original (mostrado al usuario);
/// [clave] es la ruta en el bucket (sin acentos/paréntesis) o el nombre local.
class EstiloEntrada {
  const EstiloEntrada({required this.nombre, required this.clave});
  final String nombre;
  final String clave;
}

/// Banco de estilos (escritos y sentencias reales).
///
/// Estrategia de carga:
///   1. Supabase Storage (bucket "estilos") — siempre actualizado, la app no
///      necesita una versión nueva para ver estilos recién agregados.
///   2. Assets locales (assets/estilos/) — respaldo sin conexión.
///
/// El manifest remoto tiene la forma { categoria: [ {slug, nombre} ] } y el
/// local { categoria: ["archivo.txt", ...] }; ambos se unifican en
/// [EstiloEntrada].
class EstilosService {
  EstilosService._();
  static final EstilosService _instance = EstilosService._();
  factory EstilosService() => _instance;

  static const String _bucket = 'estilos';
  static const String _assetRoot = 'assets/estilos';

  Map<String, List<EstiloEntrada>>? _manifest;
  bool _remoto = false;

  Future<Map<String, List<EstiloEntrada>>> _cargarManifest() async {
    if (_manifest != null) return _manifest!;

    // 1) Remoto (Supabase Storage).
    try {
      final bytes = await Supabase.instance.client.storage
          .from(_bucket)
          .download('manifest.json');
      final data = json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
      final result = <String, List<EstiloEntrada>>{};
      data.forEach((k, v) {
        result[k] = (v as List)
            .map((e) => e is Map
                ? EstiloEntrada(
                    nombre: e['nombre'] as String,
                    clave: e['slug'] as String,
                  )
                : EstiloEntrada(nombre: e as String, clave: e))
            .toList();
      });
      _manifest = result;
      _remoto = true;
      return result;
    } catch (e) {
      debugPrint('ℹ️ Estilos: Supabase no disponible ($e), usando assets.');
    }

    // 2) Local (assets).
    final raw = await rootBundle.loadString('$_assetRoot/manifest.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final result = <String, List<EstiloEntrada>>{};
    data.forEach((k, v) {
      result[k] = (v as List)
          .cast<String>()
          .map((s) => EstiloEntrada(nombre: s, clave: s))
          .toList();
    });
    _manifest = result;
    return result;
  }

  /// Categorías en orden de presentación (sentencias primero, luego escritos).
  Future<List<String>> obtenerCategorias() async {
    final manifest = await _cargarManifest();
    final categorias = manifest.keys.toList();
    categorias.sort((a, b) {
      final raizA = a == '.';
      final raizB = b == '.';
      if (raizA != raizB) return raizA ? -1 : 1;
      return a.compareTo(b);
    });
    return categorias;
  }

  /// Entradas (nombre + clave) de una categoría, ordenadas por nombre.
  Future<List<EstiloEntrada>> obtenerDocumentos(String categoria) async {
    final manifest = await _cargarManifest();
    final lista = manifest[categoria] ?? <EstiloEntrada>[];
    lista.sort((a, b) => a.nombre.compareTo(b.nombre));
    return lista;
  }

  /// Nombre legible de una categoría (p. ej. "DERECHO PENAL/MEDIDA CAUTELAR
  /// SUSTITUTIVA DE LIBERTAD" → "MEDIDA CAUTELAR SUSTITUTIVA DE LIBERTAD").
  static String nombreLegibleCategoria(String categoria) {
    if (categoria == '.') return 'Sentencias (publicaciones)';
    final partes = categoria.split('/');
    final ultima = partes.last.trim();
    return ultima.isEmpty ? categoria : ultima
        .split(' ')
        .map((p) => p.isEmpty
            ? p
            : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
        .join(' ');
  }

  /// Texto completo del documento. Remoto primero; assets como respaldo.
  Future<String> cargarTexto(String categoria, EstiloEntrada entrada) async {
    if (_remoto) {
      try {
        final bytes = await Supabase.instance.client.storage
            .from(_bucket)
            .download(entrada.clave);
        return utf8.decode(bytes);
      } catch (e) {
        debugPrint('ℹ️ Estilos: descarga remota falló ($e), usando assets.');
      }
    }
    final ruta = categoria == '.'
        ? '$_assetRoot/${entrada.nombre}'
        : '$_assetRoot/$categoria/${entrada.nombre}';
    return rootBundle.loadString(ruta);
  }
}
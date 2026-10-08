import 'dart:convert';

import 'package:flutter/services.dart';

/// Carga el banco de estilos (ejemplos reales de escritos y sentencias)
/// empaquetado en `assets/estilos/` junto a su `manifest.json`.
///
/// La estructura del manifiesto es:
///   { "categoria": ["archivo.txt", ...], ... }
class EstilosService {
  EstilosService._();
  static final EstilosService _instance = EstilosService._();
  factory EstilosService() => _instance;

  static const String _manifestPath = 'assets/estilos/manifest.json';

  Map<String, List<String>>? _manifest;

  Future<Map<String, List<String>>> _obtenerManifest() async {
    if (_manifest != null) return _manifest!;
    final raw = await rootBundle.loadString(_manifestPath);
    final data = json.decode(raw) as Map<String, dynamic>;
    final result = <String, List<String>>{};
    data.forEach((k, v) {
      result[k] = (v as List).cast<String>();
    });
    _manifest = result;
    return result;
  }

  /// Categorías en orden de presentación (sentencias primero, luego escritos).
  Future<List<String>> obtenerCategorias() async {
    final manifest = await _obtenerManifest();
    final categorias = manifest.keys.toList();
    categorias.sort((a, b) {
      final raizA = a == '.';
      final raizB = b == '.';
      if (raizA != raizB) return raizA ? -1 : 1;
      return a.compareTo(b);
    });
    return categorias;
  }

  /// Documentos de una categoría.
  Future<List<String>> obtenerDocumentos(String categoria) async {
    final manifest = await _obtenerManifest();
    return manifest[categoria] ?? [];
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

  /// Texto completo del documento de estilo.
  Future<String> cargarTexto(String categoria, String archivo) async {
    final ruta = categoria == '.'
        ? 'assets/estilos/$archivo'
        : 'assets/estilos/$categoria/$archivo';
    return rootBundle.loadString(ruta);
  }
}
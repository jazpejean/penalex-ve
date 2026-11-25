import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Colección de sentencias de un usuario.
class Coleccion {
  const Coleccion({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.total = 0,
  });

  final String id;
  final String nombre;
  final String? descripcion;
  final int total;
}

/// Agrupa sentencias en colecciones, guardadas en Supabase.
///
/// Requiere la migración docs/migrations/001_colecciones.sql.
class ColeccionService {
  ColeccionService._();

  static SupabaseClient get _db => Supabase.instance.client;

  static String? get _uid => _db.auth.currentUser?.id;

  static Future<List<Coleccion>> listar() async {
    final String? uid = _uid;
    if (uid == null) return <Coleccion>[];
    try {
      final List<dynamic> filas = await _db
          .from('colecciones')
          .select('id, nombre, descripcion')
          .eq('user_id', uid)
          .order('actualizada_en', ascending: false);
      return <Coleccion>[
        for (final dynamic f in filas)
          Coleccion(
            id: f['id'] as String,
            nombre: f['nombre'] as String,
            descripcion: f['descripcion'] as String?,
          ),
      ];
    } catch (e) {
      debugPrint('No se pudieron leer las colecciones: $e');
      return <Coleccion>[];
    }
  }

  static Future<Coleccion?> crear(String nombre, {String? descripcion}) async {
    final String? uid = _uid;
    if (uid == null) return null;
    try {
      final Map<String, dynamic> fila = await _db
          .from('colecciones')
          .insert(<String, dynamic>{
            'user_id': uid,
            'nombre': nombre.trim(),
            'descripcion': descripcion?.trim(),
          })
          .select('id, nombre, descripcion')
          .single();
      return Coleccion(
        id: fila['id'] as String,
        nombre: fila['nombre'] as String,
        descripcion: fila['descripcion'] as String?,
      );
    } catch (e) {
      debugPrint('No se pudo crear la colección: $e');
      return null;
    }
  }

  static Future<bool> agregar(String coleccionId, String sentenciaId) async {
    try {
      await _db.from('coleccion_sentencias').upsert(
        <String, dynamic>{
          'coleccion_id': coleccionId,
          'sentencia_id': sentenciaId,
        },
        onConflict: 'coleccion_id,sentencia_id',
      );
      return true;
    } catch (e) {
      debugPrint('No se pudo agregar a la colección: $e');
      return false;
    }
  }

  static Future<bool> quitar(String coleccionId, String sentenciaId) async {
    try {
      await _db
          .from('coleccion_sentencias')
          .delete()
          .eq('coleccion_id', coleccionId)
          .eq('sentencia_id', sentenciaId);
      return true;
    } catch (e) {
      debugPrint('No se pudo quitar de la colección: $e');
      return false;
    }
  }

  static Future<List<String>> idsEn(String coleccionId) async {
    try {
      final List<dynamic> filas = await _db
          .from('coleccion_sentencias')
          .select('sentencia_id')
          .eq('coleccion_id', coleccionId);
      return <String>[for (final dynamic f in filas) f['sentencia_id'] as String];
    } catch (e) {
      debugPrint('No se pudo leer la colección: $e');
      return <String>[];
    }
  }

  /// Total de sentencias de una colección.
  static Future<int> conteo(String coleccionId) async {
    try {
      final dynamic r = await _db
          .from('coleccion_sentencias')
          .select('sentencia_id')
          .eq('coleccion_id', coleccionId);
      return (r as List<dynamic>).length;
    } catch (e) {
      debugPrint('No se pudo contar la colección: $e');
      return 0;
    }
  }

  /// Sentencias de una colección, con su contenido.
  static Future<List<Map<String, dynamic>>> sentenciasDe(
      String coleccionId) async {
    final List<String> ids = await idsEn(coleccionId);
    if (ids.isEmpty) return <Map<String, dynamic>>[];
    try {
      final List<dynamic> filas = await _db
          .from('sentencias')
          .select(
              'id, tipo, sala, num_sentencia, fecha_sentencia, ponente, '
              'tipo_sentencia, materia, partes, delito, decision, resumen, '
              'extracto, ratio_decidendi, analisis_ia, url_tsj, url_html, '
              'url_txt, url_ficha_penalex, contenido_completo, expediente, '
              'es_jurisprudencia, tiene_pdf')
          .inFilter('id', ids);
      return <Map<String, dynamic>>[
        for (final dynamic f in filas) f as Map<String, dynamic>,
      ];
    } catch (e) {
      debugPrint('No se pudieron leer las sentencias de la colección: $e');
      return <Map<String, dynamic>>[];
    }
  }
}

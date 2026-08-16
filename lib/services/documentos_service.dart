import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/documento_escaneado.dart';

class DocumentosService {
  final _supabase = Supabase.instance.client;
  static const String _tableName = 'documentos_escaneados';
  static const String _bucketName = 'documentos';

  /// Obtiene todos los documentos del usuario actual
  Future<List<DocumentoEscaneado>> obtenerDocumentos() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ Usuario no autenticado');
        return [];
      }

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('fecha_creacion', ascending: false);

      return (response as List)
          .map((json) => DocumentoEscaneado.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo documentos: $e');
      return [];
    }
  }

  /// Guarda un nuevo documento escaneado
  Future<DocumentoEscaneado?> guardarDocumento({
    required String titulo,
    required List<String> rutasImagenesLocales,
    String? textoOcr,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ Usuario no autenticado');
        return null;
      }

      // Generar ID único para el documento
      final docId = DateTime.now().millisecondsSinceEpoch.toString();

      // Subir todas las imágenes a Supabase Storage
      final List<String> urlsSubidas = [];
      for (int i = 0; i < rutasImagenesLocales.length; i++) {
        final imagePath = rutasImagenesLocales[i];
        final fileName = '$userId/$docId/page_$i.jpeg';
        
        debugPrint('📤 Subiendo imagen ${i + 1}/${rutasImagenesLocales.length}...');
        
        final file = File(imagePath);
        final bytes = await file.readAsBytes();
        
        await _supabase.storage
            .from(_bucketName)
            .uploadBinary(fileName, bytes);

        final url = _supabase.storage.from(_bucketName).getPublicUrl(fileName);
        urlsSubidas.add(url);
      }

      // Crear thumbnail (primera página)
      final thumbnailUrl = urlsSubidas.isNotEmpty ? urlsSubidas.first : null;

      // Guardar metadata en la tabla
      final documento = DocumentoEscaneado(
        id: docId,
        userId: userId,
        titulo: titulo,
        paginasUrls: urlsSubidas,
        textoOcr: textoOcr,
        fechaCreacion: DateTime.now(),
        thumbnailUrl: thumbnailUrl,
      );

      await _supabase.from(_tableName).insert(documento.toJson());

      debugPrint('✅ Documento guardado: $docId');
      return documento;
    } catch (e) {
      debugPrint('❌ Error guardando documento: $e');
      return null;
    }
  }

  /// Elimina un documento
  Future<bool> eliminarDocumento(String docId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Obtener URLs de las imágenes antes de eliminar
      final response = await _supabase
          .from(_tableName)
          .select('paginas_urls')
          .eq('id', docId)
          .eq('user_id', userId)
          .single();

      final paginasUrls = (response['paginas_urls'] as List<dynamic>)
          .map((e) => e as String)
          .toList();

      // Eliminar imágenes del storage
      for (final url in paginasUrls) {
        final fileName = url.split('/').last;
        final path = '$userId/$docId/$fileName';
        
        try {
          await _supabase.storage.from(_bucketName).remove([path]);
        } catch (e) {
          debugPrint('⚠️ Error eliminando imagen: $e');
        }
      }

      // Eliminar registro de la tabla
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', docId)
          .eq('user_id', userId);

      debugPrint('✅ Documento eliminado: $docId');
      return true;
    } catch (e) {
      debugPrint('❌ Error eliminando documento: $e');
      return false;
    }
  }

  /// Actualiza el texto OCR de un documento
  Future<bool> actualizarTextoOcr(String docId, String textoOcr) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from(_tableName)
          .update({'texto_ocr': textoOcr})
          .eq('id', docId)
          .eq('user_id', userId);

      debugPrint('✅ Texto OCR actualizado: $docId');
      return true;
    } catch (e) {
      debugPrint('❌ Error actualizando OCR: $e');
      return false;
    }
  }

  /// Verifica si el bucket existe, si no lo crea
  Future<void> inicializarStorage() async {
    try {
      // Intentar listar el bucket
      await _supabase.storage.from(_bucketName).list();
      debugPrint('✅ Bucket "$_bucketName" existe');
    } catch (e) {
      debugPrint('⚠️ Bucket "$_bucketName" no existe, creándolo...');
      try {
        await _supabase.storage.createBucket(
          _bucketName,
          const BucketOptions(public: true),
        );
        debugPrint('✅ Bucket "$_bucketName" creado');
      } catch (createError) {
        debugPrint('❌ Error creando bucket: $createError');
      }
    }
  }
}

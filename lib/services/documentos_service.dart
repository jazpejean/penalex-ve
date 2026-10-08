import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/documento_escaneado.dart';

class DocumentosService {
  final _supabase = Supabase.instance.client;
  static final _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  static String? get _currentUserId => _firebaseAuth.currentUser?.uid;
  static const String _tableName = 'documentos_escaneados';
  static const String _bucketName = 'documents';

  /// Obtiene todos los documentos del usuario actual
  Future<List<DocumentoEscaneado>> obtenerDocumentos() async {
    try {
      final userId = _currentUserId;
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

  /// Guarda un nuevo documento escaneado (comprime antes de subir).
  Future<DocumentoEscaneado?> guardarDocumento({
    required String titulo,
    required List<String> rutasImagenesLocales,
    String? textoOcr,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        debugPrint('❌ Usuario no autenticado');
        return null;
      }

      final docId = DateTime.now().millisecondsSinceEpoch.toString();
      final urlsSubidas = <String>[];

      for (int i = 0; i < rutasImagenesLocales.length; i++) {
        final imagePath = rutasImagenesLocales[i];
        final fileName = '$userId/$docId/page_$i.jpeg';

        debugPrint('📤 Subiendo imagen ${i + 1}/${rutasImagenesLocales.length}...');

        final bytes = await _comprimirYLeer(imagePath);
        if (bytes == null) continue;

        await _supabase.storage.from(_bucketName).uploadBinary(fileName, bytes);

        final url = _supabase.storage.from(_bucketName).getPublicUrl(fileName);
        urlsSubidas.add(url);
      }

      if (urlsSubidas.isEmpty) {
        debugPrint('❌ No se pudo subir ninguna imagen');
        return null;
      }

      final thumbnailUrl = urlsSubidas.first;

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

  /// Comprime una imagen local y devuelve sus bytes (o null si falla).
  Future<Uint8List?> _comprimirYLeer(String imagePath) async {
    try {
      final file = File(imagePath);
      final originalBytes = await file.readAsBytes();

      // Si la imagen ya es pequeña, subirla tal cual.
      if (originalBytes.length < 300 * 1024) return originalBytes;

      final result = await FlutterImageCompress.compressWithList(
        originalBytes,
        quality: 82,
        minWidth: 1600,
        minHeight: 1600,
        format: CompressFormat.jpeg,
      );
      return result.isNotEmpty ? result : originalBytes;
    } catch (e) {
      debugPrint('⚠️ Error comprimiendo imagen: $e');
      try {
        return await File(imagePath).readAsBytes();
      } catch (_) {
        return null;
      }
    }
  }

  /// Elimina un documento
  Future<bool> eliminarDocumento(String docId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return false;

      final response = await _supabase
          .from(_tableName)
          .select('paginas_urls')
          .eq('id', docId)
          .eq('user_id', userId)
          .single();

      final paginasUrls = (response['paginas_urls'] as List<dynamic>)
          .map((e) => e as String)
          .toList();

      for (final url in paginasUrls) {
        final fileName = url.split('/').last;
        final path = '$userId/$docId/$fileName';

        try {
          await _supabase.storage.from(_bucketName).remove([path]);
        } catch (e) {
          debugPrint('⚠️ Error eliminando imagen: $e');
        }
      }

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
      final userId = _currentUserId;
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

  /// Renombra un documento
  Future<bool> renombrarDocumento(String docId, String nuevoTitulo) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return false;

      await _supabase
          .from(_tableName)
          .update({'titulo': nuevoTitulo})
          .eq('id', docId)
          .eq('user_id', userId);

      debugPrint('✅ Documento renombrado: $docId');
      return true;
    } catch (e) {
      debugPrint('❌ Error renombrando documento: $e');
      return false;
    }
  }

  /// Verifica si el bucket existe, si no lo crea
  Future<void> inicializarStorage() async {
    try {
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

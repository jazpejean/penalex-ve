import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class UserProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final ImagePicker _picker = ImagePicker();

  // Lista de emails de administradores
  static const List<String> _adminEmails = [
    // TODO: Agrega tu email aquí
    'admin@penalex.ve',
    'ignaciojazpe47@example.com', // Reemplaza con tu email real
  ];

  /// Verifica si el usuario actual es administrador
  static bool isAdmin() {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return false;
    return _adminEmails.contains(user.email!.toLowerCase());
  }

  static Future<void> ensureUserDocument(User user) async {
    try {
      debugPrint('📝 Asegurando documento de usuario: ${user.uid}');
      await _firestore.collection('users').doc(user.uid).set(<String, dynamic>{
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'nivel_actual': 1,
        'xp_total': 0,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('✅ Documento de usuario creado/actualizado');
    } catch (e, stack) {
      debugPrint('❌ Error creando documento de usuario: $e');
      debugPrint('Stack: $stack');
    }
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream() {
    final User? user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _firestore.collection('users').doc(user.uid).snapshots();
  }

  /// Sube foto de perfil como base64 en Firestore (sin Firebase Storage)
  static Future<String?> uploadProfileImage(ImageSource source) async {
    try {
      debugPrint('📸 Iniciando selección de imagen desde: ${source.name}');
      
      final User? user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ No hay usuario autenticado');
        throw Exception('Usuario no autenticado');
      }

      final XFile? selected = await _picker.pickImage(
        source: source,
        maxWidth: 400,  // Reducido para ahorrar espacio en Firestore
        maxHeight: 400,
        imageQuality: 85,
      );
      
      if (selected == null) {
        debugPrint('⚠️ No se seleccionó ninguna imagen');
        return null;
      }

      debugPrint('📤 Procesando imagen...');
      
      // Leer bytes de la imagen
      final bytes = await selected.readAsBytes();
      debugPrint('   Tamaño original: ${(bytes.length / 1024).toStringAsFixed(2)} KB');
      
      // Comprimir usando package:image
      final img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('No se pudo decodificar la imagen');
      }
      
      // Redimensionar a máximo 400x400
      final img.Image resized = img.copyResize(
        image,
        width: image.width > 400 ? 400 : image.width,
        height: image.height > 400 ? 400 : image.height,
      );
      
      // Convertir a JPEG con buena compresión
      final List<int> compressedBytes = img.encodeJpg(resized, quality: 85);
      debugPrint('   Tamaño comprimido: ${(compressedBytes.length / 1024).toStringAsFixed(2)} KB');
      
      // Verificar que no sea muy grande (Firestore tiene límite de 1MB por campo)
      if (compressedBytes.length > 500 * 1024) { // 500KB límite seguro
        throw Exception('Imagen muy grande incluso después de comprimir. Intenta con otra imagen.');
      }
      
      // Convertir a base64
      final String base64Image = base64Encode(compressedBytes);
      debugPrint('   String base64: ${(base64Image.length / 1024).toStringAsFixed(2)} KB');
      
      // Guardar en Firestore
      debugPrint('💾 Guardando en Firestore...');
      await _firestore.collection('users').doc(user.uid).set(<String, dynamic>{
        'photoBase64': base64Image,
        'photoUrl': null, // Limpiar URL antigua si existía
        'photoUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('✅ Foto guardada en Firestore como base64');

      return base64Image; // Retornar base64 en lugar de URL
    } catch (e, stack) {
      debugPrint('❌ Error al procesar imagen: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  static String rankLabel(int nivel) {
    if (nivel <= 100) return 'Asistente Judicial';
    if (nivel <= 500) return 'Abogado Litigante';
    return 'Magistrado';
  }
}

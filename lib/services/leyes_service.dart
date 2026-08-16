import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/ley.dart';

class LeyesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Obtiene todas las leyes
  static Future<List<Ley>> getAll() async {
    try {
      debugPrint('📚 Cargando leyes...');
      
      final snapshot = await _firestore
          .collection('leyes')
          .orderBy('nombreCorto')
          .get();
      
      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ No hay leyes en Firebase');
        return [];
      }
      
      final List<Ley> leyes = snapshot.docs
          .map((doc) => Ley.fromFirestore(doc))
          .toList();
      
      debugPrint('✅ ${leyes.length} leyes cargadas');
      return leyes;
    } catch (e) {
      debugPrint('❌ Error cargando leyes: $e');
      return [];
    }
  }
  
  /// Obtiene una ley específica por ID
  static Future<Ley?> getById(String id) async {
    try {
      final doc = await _firestore.collection('leyes').doc(id).get();
      
      if (!doc.exists) return null;
      
      return Ley.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ Error obteniendo ley: $e');
      return null;
    }
  }
  
  /// Busca artículo específico en una ley
  static Future<Articulo?> buscarArticulo(String leyId, String numeroArticulo) async {
    try {
      final ley = await getById(leyId);
      if (ley == null) return null;
      
      for (final capitulo in ley.capitulos) {
        for (final articulo in capitulo.articulos) {
          if (articulo.numero == numeroArticulo) {
            return articulo;
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error buscando artículo: $e');
      return null;
    }
  }
  
  /// Busca texto en todas las leyes
  static Future<List<Map<String, dynamic>>> buscarTexto(String termino) async {
    try {
      debugPrint('🔍 Buscando en leyes: $termino');
      
      final leyes = await getAll();
      final List<Map<String, dynamic>> resultados = [];
      
      for (final ley in leyes) {
        for (final capitulo in ley.capitulos) {
          for (final articulo in capitulo.articulos) {
            if (articulo.texto.toLowerCase().contains(termino.toLowerCase()) ||
                articulo.numero.contains(termino)) {
              resultados.add({
                'ley': ley,
                'capitulo': capitulo,
                'articulo': articulo,
              });
            }
          }
        }
      }
      
      debugPrint('✅ ${resultados.length} resultados encontrados');
      return resultados;
    } catch (e) {
      debugPrint('❌ Error buscando texto: $e');
      return [];
    }
  }
  
  /// Marca/desmarca artículo como favorito
  static Future<void> toggleFavoritoArticulo(
    String leyId,
    String articuloNumero,
    bool isFavorito,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      final favoritoRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('articulos_favoritos')
          .doc('${leyId}_$articuloNumero');
      
      if (isFavorito) {
        await favoritoRef.set({
          'leyId': leyId,
          'articuloNumero': articuloNumero,
          'addedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('⭐ Artículo marcado como favorito');
      } else {
        await favoritoRef.delete();
        debugPrint('❌ Artículo desmarcado como favorito');
      }
    } catch (e) {
      debugPrint('❌ Error toggle favorito: $e');
      rethrow;
    }
  }
  
  /// Guarda notas en un artículo
  static Future<void> guardarNotasArticulo(
    String leyId,
    String articuloNumero,
    String notas,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('articulos_notas')
          .doc('${leyId}_$articuloNumero')
          .set({
        'leyId': leyId,
        'articuloNumero': articuloNumero,
        'notas': notas,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('📝 Notas guardadas en artículo');
    } catch (e) {
      debugPrint('❌ Error guardando notas: $e');
      rethrow;
    }
  }
  
  /// Obtiene notas de un artículo
  static Future<String?> getNotasArticulo(String leyId, String articuloNumero) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;
      
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('articulos_notas')
          .doc('${leyId}_$articuloNumero')
          .get();
      
      if (!doc.exists) return null;
      
      return doc.data()?['notas'] as String?;
    } catch (e) {
      debugPrint('❌ Error obteniendo notas: $e');
      return null;
    }
  }
  
  /// Obtiene artículos favoritos del usuario
  static Future<List<Map<String, dynamic>>> getFavoritos() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('articulos_favoritos')
          .get();
      
      final List<Map<String, dynamic>> favoritos = [];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final leyId = data['leyId'] as String;
        final articuloNumero = data['articuloNumero'] as String;
        
        final articulo = await buscarArticulo(leyId, articuloNumero);
        final ley = await getById(leyId);
        
        if (articulo != null && ley != null) {
          favoritos.add({
            'ley': ley,
            'articulo': articulo,
          });
        }
      }
      
      return favoritos;
    } catch (e) {
      debugPrint('❌ Error cargando favoritos: $e');
      return [];
    }
  }
  
  /// Stream de leyes en tiempo real
  static Stream<List<Ley>> streamAll() {
    return _firestore
        .collection('leyes')
        .orderBy('nombreCorto')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Ley.fromFirestore(doc)).toList());
  }
}

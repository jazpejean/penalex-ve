import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/audiencia.dart';

class AgendaService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _userId => _auth.currentUser?.uid;

  static Future<List<Audiencia>> cargarAudiencias(DateTime mes) async {
    final String? userId = _userId;
    final DateTime inicio = DateTime(mes.year, mes.month);
    final DateTime fin = DateTime(mes.year, mes.month + 1);

    try {
      final Query<Map<String, dynamic>> baseQuery = _firestore
          .collection('audiencias')
          .where('fecha', isGreaterThanOrEqualTo: inicio)
          .where('fecha', isLessThan: fin)
          .orderBy('fecha');

      final List<Future<QuerySnapshot<Object?>>> possibleQueries = <Future<QuerySnapshot>>[];
      if (userId != null) {
        possibleQueries.add(baseQuery.where('usuarioId', isEqualTo: userId).get());
        possibleQueries.add(baseQuery.where('userId', isEqualTo: userId).get());
        possibleQueries.add(baseQuery.where('user_id', isEqualTo: userId).get());
      }

      for (final Future<QuerySnapshot<Object?>> queryFuture in possibleQueries) {
        final QuerySnapshot<Object?> query = await queryFuture;
        if (query.docs.isNotEmpty) {
          return _parseAudiencias(query.docs);
        }
      }

      final QuerySnapshot<Map<String, dynamic>> fallbackQuery = await baseQuery.get();
      return _parseAudiencias(fallbackQuery.docs);
    } on FirebaseException catch (e) {
      debugPrint('Error cargando audiencias: $e');
      return <Audiencia>[];
    } on Exception catch (e) {
      debugPrint('Error cargando audiencias: $e');
      return <Audiencia>[];
    }
  }

  static List<Audiencia> _parseAudiencias(List<QueryDocumentSnapshot> docs) => docs.map((QueryDocumentSnapshot<Object?> doc) {
      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return Audiencia(
        id: doc.id,
        expediente: data["expediente"] ?? data["expediente_id"] ?? "",
        tribunal: data["tribunal"],
        imputado: data["imputado"] ?? data["acusado"] ?? "",
        cedula: data["cedula"],
        fiscalia: data["fiscalia"],
        delitos: data["delitos"],
        fecha: (data["fecha"] as Timestamp).toDate(),
        hora: data["hora"] ?? data["hora_audiencia"] ?? "",
        tipo: data["tipo"],
        notas: data["notas"],
      );
    }).toList();

  static Future<bool> crearAudiencia(Audiencia audiencia) async {
    final String? userId = _userId;
    if (userId == null) return false;

    try {
      // Usar solo 'userId' según las reglas de Firestore
      await _firestore.collection('audiencias').add(<String, dynamic>{
        'userId': userId,
        'expediente': audiencia.expediente,
        'tribunal': audiencia.tribunal,
        'imputado': audiencia.imputado,
        'cedula': audiencia.cedula,
        'fiscalia': audiencia.fiscalia,
        'delitos': audiencia.delitos,
        'fecha': Timestamp.fromDate(audiencia.fecha),
        'hora': audiencia.hora,
        'tipo': audiencia.tipo,
        'notas': audiencia.notas,
        'creadoEn': FieldValue.serverTimestamp(),
      });
      return true;
    } on FirebaseException catch (e) {
      debugPrint('Error creando audiencia: $e');
      return false;
    } on Exception catch (e) {
      debugPrint('Error creando audiencia: $e');
      return false;
    }
  }

  static Future<bool> eliminarAudiencia(String documentId) async {
    final String? userId = _userId;
    if (userId == null) return false;

    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _firestore.collection('audiencias').doc(documentId).get();
      // Verificar userId según las reglas de Firestore
      if (doc.exists && doc.data()?['userId'] == userId) {
        await doc.reference.delete();
        return true;
      }
      return false;
    } on FirebaseException catch (e) {
      debugPrint('Error eliminando audiencia: $e');
      return false;
    } on Exception catch (e) {
      debugPrint('Error eliminando audiencia: $e');
      return false;
    }
  }
}
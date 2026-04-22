import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/calculation_model.dart';
import "../models/delito.dart";

class CalculationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _userId => _auth.currentUser?.uid;

  static Future<List<CalculationModel>> getSavedCalculations() async {
    final String? userId = _userId;
    if (userId == null) return <CalculationModel>[];

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('calculations')
        .orderBy('fecha', descending: true)
        .get();

    return snapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final Map<String, dynamic> data = doc.data();
      return CalculationModel.fromMap(<String, dynamic>{
        'id': doc.id,
        ...data,
      });
    }).toList();
  }

  static Future<bool> saveCalculation(CalculationModel calculation) async {
    final String? userId = _userId;
    if (userId == null) return false;

    final DocumentReference<Map<String, dynamic>> docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('calculations')
        .doc(calculation.id);

    try {
      await docRef.set(<String, dynamic>{
        'nombre': calculation.nombre,
        'fecha': Timestamp.fromDate(calculation.fecha),
        'delitos': calculation.delitos.map((Delito d) => d.toMap()).toList(),
        'concurso': calculation.concurso.index,
        'admisionHechos': calculation.admisionHechos,
        'fraccionAdmision': calculation.fraccionAdmision,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } on FirebaseException catch (e) {
      debugPrint('Error guardando cálculo: $e');
      return false;
    } on Exception catch (e) {
      debugPrint('Error guardando cálculo: $e');
      return false;
    }
  }

  static Future<bool> deleteCalculation(String id) async {
    final String? userId = _userId;
    if (userId == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('calculations')
          .doc(id)
          .delete();
      return true;
    } on FirebaseException catch (e) {
      debugPrint('Error eliminando cálculo: $e');
      return false;
    } on Exception catch (e) {
      debugPrint('Error eliminando cálculo: $e');
      return false;
    }
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../utils/non_working_days.dart';

class NonWorkingDayService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _userId => _auth.currentUser?.uid;

  static Future<bool> saveNonWorkingDay(NonWorkingDay nonWorkingDay) async {
    final String? userId = _userId;
    if (userId == null) return false;

    try {
      await _firestore.collection('userNonWorkingDays').add(<String, dynamic>{
        'userId': userId,
        'usuarioId': userId,
        'date': Timestamp.fromDate(nonWorkingDay.date),
        'reason': nonWorkingDay.reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } on FirebaseException catch (e) {
      debugPrint('Error saving non-working day to Firestore: $e');
      return false;
    } on Exception catch (e) {
      debugPrint('Error saving non-working day to Firestore: $e');
      return false;
    }
  }

  static Future<List<NonWorkingDay>> loadUserNonWorkingDays() async {
    final String? userId = _userId;
    if (userId == null) return <NonWorkingDay>[];

    try {
      final Future<QuerySnapshot<Map<String, dynamic>>> queryByUserId = _firestore
          .collection('userNonWorkingDays')
          .where('userId', isEqualTo: userId)
          .orderBy('date')
          .get();
      final Future<QuerySnapshot<Map<String, dynamic>>> queryByUsuarioId = _firestore
          .collection('userNonWorkingDays')
          .where('usuarioId', isEqualTo: userId)
          .orderBy('date')
          .get();

      final List<QuerySnapshot<Map<String, dynamic>>> results = await Future.wait(<Future<QuerySnapshot<Map<String, dynamic>>>>[queryByUserId, queryByUsuarioId]);
      final QuerySnapshot<Map<String, dynamic>> querySnapshot = results.firstWhere((QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs.isNotEmpty,
          orElse: () => results.first);

      return querySnapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        final Map<String, dynamic> data = doc.data();
        return NonWorkingDay(
          date: (data['date'] as Timestamp).toDate(),
          reason: data['reason'] ?? 'Motivo desconocido',
        );
      }).toList();
    } on FirebaseException catch (e) {
      debugPrint('Error loading user non-working days: $e');
      return <NonWorkingDay>[];
    } on Exception catch (e) {
      debugPrint('Error loading user non-working days: $e');
      return <NonWorkingDay>[];
    }
  }
}
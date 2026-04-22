import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/quiz_question.dart';

class QuizService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _uid => _auth.currentUser?.uid;

  static Future<QuizQuestion?> loadQuestionByLevel(int nivel) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('preguntas')
          .where('nivel', isEqualTo: nivel)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return QuizQuestion.fromDocument(snapshot.docs.first);
      }

      final QuerySnapshot<Map<String, dynamic>> fallbackSnapshot = await _firestore
          .collection('preguntas')
          .where('level', isEqualTo: nivel)
          .limit(1)
          .get();
      if (fallbackSnapshot.docs.isNotEmpty) {
        return QuizQuestion.fromDocument(fallbackSnapshot.docs.first);
      }

      return null;
    } on FirebaseException catch (e) {
      debugPrint('Error cargando pregunta nivel $nivel: $e');
      return null;
    } on Exception catch (e) {
      debugPrint('Error cargando pregunta nivel $nivel: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> loadProgress() async {
    final String? userId = _uid;
    if (userId == null) return <String, dynamic>{'nivel_actual': 1, 'xp': 0};

    final DocumentSnapshot<Map<String, dynamic>> doc = await _firestore.collection('users').doc(userId).collection('quizProgress').doc('progress').get();
    if (!doc.exists) return <String, dynamic>{'nivel_actual': 1, 'xp': 0};
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return <String, dynamic>{
      'nivel_actual': (data['nivel_actual'] as num?)?.toInt() ?? 1,
      'xp': (data['xp'] as num?)?.toInt() ?? 0,
    };
  }

  static Future<void> saveProgress({required int nivelActual, required int xp}) async {
    final String? userId = _uid;
    if (userId == null) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('quizProgress')
        .doc('progress')
        .set(<String, dynamic>{
      'nivel_actual': nivelActual,
      'xp': xp,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _firestore.collection('users').doc(userId).set(<String, dynamic>{
      'nivel_actual': nivelActual,
      'xp_total': xp,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _firestore.collection('quizRanking').doc(userId).set(<String, dynamic>{
      'userId': userId,
      'nivel': nivelActual,
      'xp': xp,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<List<Map<String, dynamic>>> loadGlobalRanking() async {
    final QuerySnapshot<Map<String, dynamic>> query = await _firestore
        .collection('quizRanking')
        .orderBy('xp', descending: true)
        .limit(50)
        .get();
    return query.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => doc.data()).toList();
  }
}
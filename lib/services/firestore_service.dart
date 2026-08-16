import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/question.dart';
import '../models/user.dart';
import '../models/user_progress.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _userId => _auth.currentUser?.uid;

  // ==================== USER ====================
  static Future<UserModel?> loadUser() async {
    final String? userId = _userId;
    if (userId == null) return null;
    final DocumentSnapshot<Map<String, dynamic>> doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    final Map<String, dynamic>? data = doc.data();
    if (data == null) return null;
    return UserModel.fromMap(data);
  }

  static Future<void> saveUser(UserModel user) async {
    final String? userId = _userId;
    if (userId == null) return;
    await _db.collection('users').doc(userId).set(user.toMap(), SetOptions(merge: true));
  }

  // ==================== USER PROGRESS ====================
  static Future<UserProgress?> loadUserProgress() async {
    final String? userId = _userId;
    if (userId == null) return null;
    final DocumentSnapshot<Map<String, dynamic>> doc = await _db.collection('users').doc(userId).collection('progress').doc('game').get();
    if (!doc.exists) return null;
    final Map<String, dynamic>? data = doc.data();
    if (data == null) return null;
    return UserProgress.fromMap(data);
  }

  static Future<void> saveUserProgress(UserProgress progress) async {
    final String? userId = _userId;
    if (userId == null) return;
    await _db.collection('users').doc(userId).collection('progress').doc('game').set(progress.toMap());
  }

  // ==================== QUIZ QUESTIONS ====================
  static Future<Question?> loadQuestionByLevel(int level) async {
    if (level <= 1600) {
      // Primero intentar buscar por documento directo nivel_X
      final DocumentSnapshot<Map<String, dynamic>> doc = await _db.collection('preguntas').doc('nivel_$level').get();
      if (doc.exists) {
        final Map<String, dynamic>? data = doc.data();
        if (data != null) {
          return Question.fromDocument(data, doc.id);
        }
      }
      
      // Si no existe, buscar por campo nivel (formato nivel_X_pregunta_Y)
      final QuerySnapshot<Map<String, dynamic>> querySnapshot = await _db
          .collection('preguntas')
          .where('nivel', isEqualTo: level)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final Map<String, dynamic> data = querySnapshot.docs.first.data();
        return Question.fromDocument(data, querySnapshot.docs.first.id);
      }
      
      return null;
    } else {
      final Random random = Random();
      final int baseLevel = 1000 + random.nextInt(601);
      final DocumentSnapshot<Map<String, dynamic>> baseDoc = await _db.collection('preguntas').doc('nivel_$baseLevel').get();
      if (!baseDoc.exists) {
        final QuerySnapshot<Map<String, dynamic>> fallback = await _db.collection('preguntas').limit(1).get();
        if (fallback.docs.isNotEmpty) {
          final Map<String, dynamic> fallbackData = fallback.docs.first.data();
          return Question.fromDocument(fallbackData, fallback.docs.first.id);
                }
        return null;
      }
      final Map<String, dynamic>? baseData = baseDoc.data();
      if (baseData == null) return null;
      final Question baseQuestion = Question.fromDocument(baseData, baseDoc.id);
      final List<String> shuffledOptions = List<String>.from(baseQuestion.opciones);
      shuffledOptions.shuffle(random);
      final String correctText = baseQuestion.opciones[baseQuestion.respuestaCorrecta];
      final int newCorrectIndex = shuffledOptions.indexOf(correctText);
      return Question(
        id: 'infinite_${level}_from_$baseLevel',
        nivel: level,
        pregunta: baseQuestion.pregunta,
        opciones: shuffledOptions,
        respuestaCorrecta: newCorrectIndex,
        fundamentacion: baseQuestion.fundamentacion,
      );
    }
  }
}
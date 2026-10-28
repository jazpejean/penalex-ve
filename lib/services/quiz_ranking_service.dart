import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'quiz_rules.dart';

/// Ranking global del quiz (única tabla diminuta en Postgres; el resto de los
/// datos vive en Storage). Sin materias ni niveles numéricos: el "nivel" del
/// ranking es el índice dentro de la carrera judicial (derivado del XP).
class QuizRankingService {
  static final _supabase = Supabase.instance.client;
  static final _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  static String? get _uid => _firebaseAuth.currentUser?.uid;

  static Future<void> actualizar({
    required int xp,
    required String rango,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final nombre =
        _firebaseAuth.currentUser?.displayName?.trim().isNotEmpty == true
            ? _firebaseAuth.currentUser!.displayName!
            : 'Usuario';
    try {
      await _supabase.from('quiz_ranking').upsert({
        'user_id': uid,
        'nombre': nombre,
        'xp': xp,
        'nivel_actual': QuizRules.indiceRango(xp) + 1,
        'rango_actual': rango,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Error actualizando ranking: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> top({int limit = 100}) async {
    try {
      final response = await _supabase
          .from('quiz_ranking')
          .select()
          .order('xp', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error obteniendo ranking: $e');
      return [];
    }
  }
}

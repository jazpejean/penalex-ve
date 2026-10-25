import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/non_working_days.dart';

/// Días sin despacho del usuario — respaldo en Supabase.
///
/// Tabla: `dias_no_despacho` (user_id = UID de Firebase, RLS por usuario).
/// Reemplaza la estructura anterior en Firestore (`userNonWorkingDays`).
class NonWorkingDayService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static String? get _userId {
    try {
      return fb.FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> saveNonWorkingDay(NonWorkingDay nonWorkingDay) async {
    final String? userId = _userId;
    if (userId == null) return false;

    try {
      // ON CONFLICT (user_id, fecha): ya existe → se ignora (idempotente).
      await _supabase.from('dias_no_despacho').upsert(<String, dynamic>{
        'user_id': userId,
        'fecha': nonWorkingDay.date.toUtc().toIso8601String(),
        'motivo': nonWorkingDay.reason,
        if (nonWorkingDay.tribunalId != null)
          'tribunal_id': nonWorkingDay.tribunalId,
        if (nonWorkingDay.tribunalNombre != null)
          'tribunal_nombre': nonWorkingDay.tribunalNombre,
      }, onConflict: 'user_id,fecha');
      return true;
    } on Exception catch (e) {
      debugPrint('Error guardando día sin despacho: $e');
      return false;
    }
  }

  static Future<List<NonWorkingDay>> loadUserNonWorkingDays() async {
    final String? userId = _userId;
    if (userId == null) return <NonWorkingDay>[];

    try {
      final resp = await _supabase
          .from('dias_no_despacho')
          .select('fecha,motivo,tribunal_id,tribunal_nombre')
          .eq('user_id', userId)
          .order('fecha');
      return (resp as List<dynamic>)
          .map((e) => NonWorkingDay(
                date: DateTime.tryParse(
                        (e as Map<String, dynamic>)['fecha']?.toString() ??
                            '') ??
                    DateTime.now(),
                reason:
                    (e['motivo']?.toString() ?? 'Motivo desconocido'),
                tribunalId: e['tribunal_id']?.toString(),
                tribunalNombre: e['tribunal_nombre']?.toString(),
              ))
          .toList();
    } on Exception catch (e) {
      debugPrint('Error cargando días sin despacho: $e');
      return <NonWorkingDay>[];
    }
  }

  static Future<bool> deleteNonWorkingDay(DateTime fecha) async {
    final String? userId = _userId;
    if (userId == null) return false;

    try {
      final resp = await _supabase
          .from('dias_no_despacho')
          .delete()
          .eq('user_id', userId)
          .eq('fecha', fecha.toUtc().toIso8601String());
      return resp.error == null;
    } on Exception catch (e) {
      debugPrint('Error eliminando día sin despacho: $e');
      return false;
    }
  }
}
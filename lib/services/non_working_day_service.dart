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

  /// true cuando la tabla ya tiene las columnas tribunal_id/tribunal_nombre
  /// (migración 20261025070309 aplicada). Se detecta una vez y se cachea
  /// para no fallar mientras la migración esté pendiente.
  static bool? _soportaTribunal;

  static Future<bool> _verificarSoporteTribunal() async {
    if (_soportaTribunal != null) return _soportaTribunal!;
    try {
      await _supabase
          .from('dias_no_despacho')
          .select('tribunal_id')
          .limit(1);
      _soportaTribunal = true;
    } on Exception {
      _soportaTribunal = false;
    }
    return _soportaTribunal!;
  }

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
      final Map<String, dynamic> datos = <String, dynamic>{
        'user_id': userId,
        'fecha': nonWorkingDay.date.toUtc().toIso8601String(),
        'motivo': nonWorkingDay.reason,
      };
      if (await _verificarSoporteTribunal()) {
        if (nonWorkingDay.tribunalId != null) {
          datos['tribunal_id'] = nonWorkingDay.tribunalId;
        }
        if (nonWorkingDay.tribunalNombre != null) {
          datos['tribunal_nombre'] = nonWorkingDay.tribunalNombre;
        }
      }
      await _supabase.from('dias_no_despacho').upsert(datos,
          onConflict: 'user_id,fecha');
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
      final bool soporta = await _verificarSoporteTribunal();
      final resp = soporta
          ? await _supabase
              .from('dias_no_despacho')
              .select('fecha,motivo,tribunal_id,tribunal_nombre')
              .eq('user_id', userId)
              .order('fecha')
          : await _supabase
              .from('dias_no_despacho')
              .select('fecha,motivo')
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
                tribunalId: soporta ? e['tribunal_id']?.toString() : null,
                tribunalNombre:
                    soporta ? e['tribunal_nombre']?.toString() : null,
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
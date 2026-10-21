import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/audiencia.dart';

/// Servicio de la agenda judicial — respaldo en Supabase.
///
/// Tabla: `agenda_eventos` (user_id = UID de Firebase, RLS por usuario).
/// Reemplaza por completo el almacén anterior en Firestore.
class AgendaService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static String? get _userId {
    try {
      return fb.FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// Audiencias del mes [mes] (desde el día 1 hasta el día 1 del siguiente).
  static Future<List<Audiencia>> cargarAudiencias(DateTime mes) async {
    final String? userId = _userId;
    if (userId == null) return <Audiencia>[];
    final DateTime inicio = DateTime(mes.year, mes.month);
    final DateTime fin = DateTime(mes.year, mes.month + 1);

    try {
      final resp = await _supabase
          .from('agenda_eventos')
          .select('*')
          .eq('user_id', userId)
          .gte('fecha', inicio.toIso8601String())
          .lt('fecha', fin.toIso8601String())
          .order('fecha');
      return (resp as List<dynamic>)
          .map((e) => Audiencia.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Exception catch (e) {
      debugPrint('Error cargando audiencias: $e');
      return <Audiencia>[];
    }
  }

  /// Crea una audiencia nueva (id lo genera Supabase).
  static Future<bool> crearAudiencia(Audiencia audiencia) async {
    final String? userId = _userId;
    if (userId == null) return false;

    try {
      await _supabase.from('agenda_eventos').insert(<String, dynamic>{
        'user_id': userId,
        'expediente': audiencia.expediente,
        'tribunal': audiencia.tribunal,
        'tribunal_id': audiencia.tribunalId,
        'imputado': audiencia.imputado,
        'cedula': audiencia.cedula,
        'fiscalia': audiencia.fiscalia,
        'delitos': audiencia.delitos,
        'fecha': audiencia.fecha.toUtc().toIso8601String(),
        'hora': audiencia.hora,
        'tipo': audiencia.tipo,
        'notas': audiencia.notas,
        'recordatorio_minutos': audiencia.recordatorioMinutos,
      });
      return true;
    } on Exception catch (e) {
      debugPrint('Error creando audiencia: $e');
      return false;
    }
  }

  /// Actualiza una audiencia existente.
  static Future<bool> actualizarAudiencia(Audiencia audiencia) async {
    final String? userId = _userId;
    if (userId == null) return false;

    try {
      final resp = await _supabase
          .from('agenda_eventos')
          .update(<String, dynamic>{
            'expediente': audiencia.expediente,
            'tribunal': audiencia.tribunal,
            'tribunal_id': audiencia.tribunalId,
            'imputado': audiencia.imputado,
            'cedula': audiencia.cedula,
            'fiscalia': audiencia.fiscalia,
            'delitos': audiencia.delitos,
            'fecha': audiencia.fecha.toUtc().toIso8601String(),
            'hora': audiencia.hora,
            'tipo': audiencia.tipo,
            'notas': audiencia.notas,
            'recordatorio_minutos': audiencia.recordatorioMinutos,
          })
          .eq('id', audiencia.id)
          .eq('user_id', userId);
      return resp.error == null;
    } on Exception catch (e) {
      debugPrint('Error actualizando audiencia: $e');
      return false;
    }
  }

  /// Elimina una audiencia (solo la propia; RLS lo garantiza).
  static Future<bool> eliminarAudiencia(String id) async {
    final String? userId = _userId;
    if (userId == null) return false;

    try {
      final resp = await _supabase
          .from('agenda_eventos')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
      return resp.error == null;
    } on Exception catch (e) {
      debugPrint('Error eliminando audiencia: $e');
      return false;
    }
  }
}
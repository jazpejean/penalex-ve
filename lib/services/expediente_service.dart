import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/expediente.dart';

/// Servicio del portafolio de expedientes — respaldo en Supabase.
///
/// Tabla: `expedientes` (user_id = UID de Firebase, RLS por usuario).
/// Un expediente se crea/actualiza automáticamente al agendar una
/// audiencia con número de expediente; los documentos del caso se
/// vinculan por `documentos_escaneados.expediente_id`.
class ExpedienteService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static String? get _userId {
    try {
      return fb.FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// Busca el expediente por su número (el número identifica la causa).
  static Future<Expediente?> buscarPorNumero(String numero) async {
    final String? userId = _userId;
    if (userId == null || numero.trim().isEmpty) return null;
    try {
      final resp = await _supabase
          .from('expedientes')
          .select('*')
          .eq('user_id', userId)
          .eq('numero_expediente', numero.trim())
          .limit(1)
          .maybeSingle();
      if (resp == null) return null;
      return Expediente.fromJson(resp);
    } on Exception catch (e) {
      debugPrint('Error buscando expediente: $e');
      return null;
    }
  }

  /// Crea un expediente nuevo (id lo genera Supabase).
  static Future<Expediente?> crear({
    required String numeroExpediente,
    required String imputado,
    String? cedula,
    String? delitos,
    String? tribunalId,
    String? tribunalNombre,
    DateTime? fechaAudiencia,
  }) async {
    final String? userId = _userId;
    if (userId == null) return null;
    try {
      final resp = await _supabase
          .from('expedientes')
          .insert(<String, dynamic>{
            'user_id': userId,
            'numero_expediente': numeroExpediente.trim(),
            'imputado': imputado,
            'cedula': cedula,
            'delitos': delitos,
            'tribunal_id': tribunalId,
            'tribunal_nombre': tribunalNombre,
            'estado_procesal': null,
            'fecha_audiencia':
                fechaAudiencia?.toUtc().toIso8601String(),
          })
          .select()
          .single();
      return Expediente.fromJson(resp);
    } on Exception catch (e) {
      debugPrint('Error creando expediente: $e');
      return null;
    }
  }

  /// Obtiene o crea el expediente de una causa (upsert por número).
  /// Se llama al agendar una audiencia para asegurar el portafolio.
  static Future<Expediente?> asegurarExpediente({
    required String numeroExpediente,
    required String imputado,
    String? cedula,
    String? delitos,
    String? tribunalId,
    String? tribunalNombre,
    DateTime? fechaAudiencia,
  }) async {
    if (numeroExpediente.trim().isEmpty) return null;
    final Expediente? existente = await buscarPorNumero(numeroExpediente);
    if (existente != null) {
      // Actualiza datos que hayan cambiado en la agenda.
      await _supabase
          .from('expedientes')
          .update(<String, dynamic>{
            if (imputado.isNotEmpty) 'imputado': imputado,
            if (delitos != null && delitos.isNotEmpty) 'delitos': delitos,
            'tribunal_id': tribunalId,
            'tribunal_nombre': tribunalNombre,
            'fecha_audiencia': fechaAudiencia?.toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', existente.id);
      return buscarPorNumero(numeroExpediente);
    }
    return crear(
      numeroExpediente: numeroExpediente,
      imputado: imputado,
      cedula: cedula,
      delitos: delitos,
      tribunalId: tribunalId,
      tribunalNombre: tribunalNombre,
      fechaAudiencia: fechaAudiencia,
    );
  }

  /// Lista los expedientes del usuario (más recientes primero).
  static Future<List<Expediente>> listarExpedientes() async {
    final String? userId = _userId;
    if (userId == null) return <Expediente>[];
    try {
      final resp = await _supabase
          .from('expedientes')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (resp as List<dynamic>)
          .map((e) => Expediente.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Exception catch (e) {
      debugPrint('Error listando expedientes: $e');
      return <Expediente>[];
    }
  }
}
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/caso_hipotetico_model.dart';
import 'dart:math';

/// Servicio para gestionar el quiz con Supabase
class SupabaseQuizService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Random _random = Random();

  String? get _userId => _supabase.auth.currentUser?.id;

  // ==================== CASOS HIPOTÉTICOS ====================

  /// Obtener caso aleatorio para un nivel específico
  Future<CasoHipotetico?> getCasoParaNivel(int nivel) async {
    try {
      // Obtener todos los casos para este nivel
      final response = await _supabase
          .from('casos_hipoteticos')
          .select()
          .eq('nivel', nivel)
          .eq('activo', true);

      if (response.isEmpty) {
        // Si no hay casos para este nivel exacto, buscar uno cercano
        final fallback = await _supabase
            .from('casos_hipoteticos')
            .select()
            .eq('activo', true)
            .order('nivel')
            .limit(10);

        if (fallback.isEmpty) return null;

        final randomCase = fallback[_random.nextInt(fallback.length)];
        return CasoHipotetico.fromJson(randomCase);
      }

      // Seleccionar caso aleatorio del pool
      final randomCase = response[_random.nextInt(response.length)];
      return CasoHipotetico.fromJson(randomCase);
    } catch (e) {
      debugPrint('❌ Error obteniendo caso: $e');
      return null;
    }
  }

  /// Obtener múltiples casos para un rango de niveles
  Future<List<CasoHipotetico>> getCasosPorRango(
    int nivelInicio,
    int nivelFin,
  ) async {
    try {
      final response = await _supabase
          .from('casos_hipoteticos')
          .select()
          .gte('nivel', nivelInicio)
          .lte('nivel', nivelFin)
          .eq('activo', true)
          .order('nivel');

      return response
          .map((json) => CasoHipotetico.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo casos por rango: $e');
      return [];
    }
  }

  // ==================== VERIFICACIÓN DE RESPUESTAS ====================

  /// Verificar respuesta y registrar en historial
  Future<ResultadoRespuesta> verificarRespuesta({
    required CasoHipotetico caso,
    required int respuestaUsuario,
    required int tiempoRespuesta, // En segundos
  }) async {
    final userId = _userId;
    if (userId == null) {
      return ResultadoRespuesta(
        correcto: false,
        mensaje: 'Usuario no autenticado',
      );
    }

    final correcto = respuestaUsuario == caso.respuestaCorrecta;

    try {
      // Obtener progreso actual
      final progress = await getProgresoUsuario();
      final vecesIntentadas = await _getVecesIntentadas(caso.id);

      // Registrar respuesta en historial
      await _supabase.from('user_respuestas').insert({
        'user_id': userId,
        'caso_id': caso.id,
        'nivel': caso.nivel,
        'respuesta_seleccionada': respuestaUsuario,
        'correcta': correcto,
        'tiempo_respuesta': tiempoRespuesta,
        'racha_actual': progress?.rachaActual ?? 0,
        'puntos_ganados': correcto ? 100 : 0,
      });

      if (correcto) {
        // Obtener fundamentación
        final fundamentacion = await _getFundamentacion(caso.id);
        return ResultadoRespuesta(
          correcto: true,
          fundamentacion: fundamentacion,
          mensaje: _getMensajeExito(vecesIntentadas + 1),
        );
      } else {
        // Registrar caso fallado
        await _registrarCasoFallado(caso.id);

        // Obtener pista
        final pista = await _getPista(caso.id, vecesIntentadas + 1);
        final bloqueado = vecesIntentadas >= 2; // Bloquear después de 3 intentos

        return ResultadoRespuesta(
          correcto: false,
          pista: pista,
          bloqueoCaso: bloqueado,
          mensaje: _getMensajeError(vecesIntentadas + 1),
        );
      }
    } catch (e) {
      debugPrint('❌ Error verificando respuesta: $e');
      return ResultadoRespuesta(
        correcto: false,
        mensaje: 'Error verificando respuesta: $e',
      );
    }
  }

  Future<int> _getVecesIntentadas(String casoId) async {
    try {
      final response = await _supabase
          .from('user_casos_fallados')
          .select('veces_fallado')
          .eq('user_id', _userId!)
          .eq('caso_id', casoId)
          .maybeSingle();

      return response?['veces_fallado'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _registrarCasoFallado(String casoId) async {
    try {
      await _supabase.rpc('upsert_caso_fallado', params: {
        'p_user_id': _userId,
        'p_caso_id': casoId,
      });
    } catch (e) {
      // Si la función no existe, usar upsert manual
      final existing = await _supabase
          .from('user_casos_fallados')
          .select('veces_fallado')
          .eq('user_id', _userId!)
          .eq('caso_id', casoId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('user_casos_fallados')
            .update({
              'veces_fallado': existing['veces_fallado'] + 1,
              'ultima_vez_fallado': DateTime.now().toIso8601String(),
              'bloqueado': existing['veces_fallado'] >= 2,
            })
            .eq('user_id', _userId!)
            .eq('caso_id', casoId);
      } else {
        await _supabase.from('user_casos_fallados').insert({
          'user_id': _userId,
          'caso_id': casoId,
          'veces_fallado': 1,
          'bloqueado': false,
        });
      }
    }
  }

  // ==================== FUNDAMENTACIONES Y PISTAS ====================

  Future<Fundamentacion?> _getFundamentacion(String casoId) async {
    try {
      final response = await _supabase
          .from('fundamentaciones')
          .select()
          .eq('caso_id', casoId)
          .maybeSingle();

      if (response == null) return null;

      final articulos = (response['articulos'] as List)
          .map((a) => ArticuloReferencia.fromJson(a))
          .toList();

      return Fundamentacion(
        id: response['id'],
        casoId: response['caso_id'],
        explicacion: response['explicacion'],
        articulos: articulos,
        sentenciasIds: List<String>.from(response['sentencias_ids'] ?? []),
        jurisprudenciasIds:
            List<String>.from(response['jurisprudencias_ids'] ?? []),
      );
    } catch (e) {
      debugPrint('❌ Error obteniendo fundamentación: $e');
      return null;
    }
  }

  Future<Pista?> _getPista(String casoId, int nivel) async {
    try {
      final response = await _supabase
          .from('pistas_casos')
          .select()
          .eq('caso_id', casoId)
          .eq('nivel_pista', nivel.clamp(1, 3))
          .maybeSingle();

      if (response == null) return null;

      return Pista(
        id: response['id'],
        casoId: response['caso_id'],
        nivelPista: response['nivel_pista'],
        textoPista: response['texto_pista'],
        articulosSugeridos:
            response['articulos_sugeridos'] != null
                ? List<String>.from(response['articulos_sugeridos'])
                : null,
        busquedaSugerida: response['busqueda_sugerida'],
      );
    } catch (e) {
      debugPrint('❌ Error obteniendo pista: $e');
      return null;
    }
  }

  // ==================== PROGRESO DEL USUARIO ====================

  /// Obtener progreso del usuario
  Future<UserQuizProgress?> getProgresoUsuario() async {
    final userId = _userId;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('user_quiz_progress')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Crear progreso inicial
        await _crearProgresoInicial();
        return UserQuizProgress.inicial(userId);
      }

      return UserQuizProgress.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error obteniendo progreso: $e');
      return null;
    }
  }

  Future<void> _crearProgresoInicial() async {
    try {
      await _supabase.from('user_quiz_progress').insert({
        'user_id': _userId,
        'nivel_actual': 1,
        'puntos_totales': 0,
        'apelaciones': 5,
      });
    } catch (e) {
      debugPrint('❌ Error creando progreso inicial: $e');
    }
  }

  /// Actualizar progreso del usuario
  Future<void> actualizarProgreso({
    int? nivelActual,
    int? puntosTotales,
    int? rachaActual,
    int? apelaciones,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final updates = <String, dynamic>{};
      if (nivelActual != null) updates['nivel_actual'] = nivelActual;
      if (puntosTotales != null) updates['puntos_totales'] = puntosTotales;
      if (rachaActual != null) {
        updates['racha_actual'] = rachaActual;
        // Actualizar racha máxima si supera el récord
        final current = await getProgresoUsuario();
        if (current != null && rachaActual > current.rachaMaxima) {
          updates['racha_maxima'] = rachaActual;
        }
      }
      if (apelaciones != null) {
        updates['apelaciones'] = apelaciones;
        if (apelaciones < 5) {
          updates['ultima_regeneracion_apelaciones'] =
              DateTime.now().toIso8601String();
        }
      }

      await _supabase
          .from('user_quiz_progress')
          .update(updates)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('❌ Error actualizando progreso: $e');
    }
  }

  // ==================== RANKING GLOBAL ====================

  /// Obtener ranking global top 100
  Future<List<Map<String, dynamic>>> getRankingGlobal({int limit = 100}) async {
    try {
      final response = await _supabase
          .from('ranking_global')
          .select()
          .order('puntuacion_maxima', ascending: false)
          .order('nivel_actual', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error obteniendo ranking: $e');
      return [];
    }
  }

  /// Actualizar entrada en ranking global
  Future<void> actualizarRanking() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final progress = await getProgresoUsuario();
      if (progress == null) return;

      final user = _supabase.auth.currentUser;
      final nombre = user?.userMetadata?['name'] ?? 'Usuario';

      await _supabase.from('ranking_global').upsert({
        'user_id': userId,
        'nombre': nombre,
        'nivel_actual': progress.nivelActual,
        'puntos_totales': progress.puntosTotales,
        'puntuacion_maxima': progress.puntuacionMaxima,
        'racha_maxima': progress.rachaMaxima,
        'rango_actual': progress.rangoActual,
        'preguntas_respondidas': progress.preguntasRespondidas,
        'preguntas_correctas': progress.preguntasCorrectas,
        'tiempo_promedio_respuesta': progress.tiempoPromedioRespuesta,
      });
    } catch (e) {
      debugPrint('❌ Error actualizando ranking: $e');
    }
  }

  // ==================== UTILIDADES ====================

  String _getMensajeExito(int intentos) {
    if (intentos == 1) return '¡Perfecto! Respuesta correcta al primer intento 🎯';
    if (intentos == 2) return '¡Correcto! Segunda oportunidad aprovechada ✓';
    return '¡Correcto! Has demostrado persistencia ⚖️';
  }

  String _getMensajeError(int intentos) {
    if (intentos == 1) return 'Respuesta incorrecta. Analiza los elementos del caso.';
    if (intentos == 2) return 'Incorrecto nuevamente. Última oportunidad.';
    return 'Caso bloqueado. Usa una apelación para desbloquearlo.';
  }
}

/// Modelo de progreso del usuario
class UserQuizProgress {
  final String userId;
  final int nivelActual;
  final int puntosTotales;
  final int puntuacionMaxima;
  final int rachaActual;
  final int rachaMaxima;
  final int apelaciones;
  final DateTime? ultimaRegeneracionApelaciones;
  final int preguntasRespondidas;
  final int preguntasCorrectas;
  final double tiempoPromedioRespuesta;
  final int xp;
  final String rangoActual;
  final String? regionActual;

  UserQuizProgress({
    required this.userId,
    required this.nivelActual,
    required this.puntosTotales,
    required this.puntuacionMaxima,
    required this.rachaActual,
    required this.rachaMaxima,
    required this.apelaciones,
    this.ultimaRegeneracionApelaciones,
    required this.preguntasRespondidas,
    required this.preguntasCorrectas,
    required this.tiempoPromedioRespuesta,
    required this.xp,
    required this.rangoActual,
    this.regionActual,
  });

  factory UserQuizProgress.fromJson(Map<String, dynamic> json) {
    return UserQuizProgress(
      userId: json['user_id'],
      nivelActual: json['nivel_actual'] ?? 1,
      puntosTotales: json['puntos_totales'] ?? 0,
      puntuacionMaxima: json['puntuacion_maxima'] ?? 0,
      rachaActual: json['racha_actual'] ?? 0,
      rachaMaxima: json['racha_maxima'] ?? 0,
      apelaciones: json['apelaciones'] ?? 5,
      ultimaRegeneracionApelaciones:
          json['ultima_regeneracion_apelaciones'] != null
              ? DateTime.parse(json['ultima_regeneracion_apelaciones'])
              : null,
      preguntasRespondidas: json['preguntas_respondidas'] ?? 0,
      preguntasCorrectas: json['preguntas_correctas'] ?? 0,
      tiempoPromedioRespuesta:
          (json['tiempo_promedio_respuesta'] ?? 0).toDouble(),
      xp: json['xp'] ?? 0,
      rangoActual: json['rango_actual'] ?? 'Alguacil',
      regionActual: json['region_actual'],
    );
  }

  factory UserQuizProgress.inicial(String userId) {
    return UserQuizProgress(
      userId: userId,
      nivelActual: 1,
      puntosTotales: 0,
      puntuacionMaxima: 0,
      rachaActual: 0,
      rachaMaxima: 0,
      apelaciones: 5,
      preguntasRespondidas: 0,
      preguntasCorrectas: 0,
      tiempoPromedioRespuesta: 0,
      xp: 0,
      rangoActual: 'Alguacil',
    );
  }
}

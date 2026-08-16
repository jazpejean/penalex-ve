import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para tracking y analytics de uso de herramientas IA
class AIAnalyticsService {
  static final _supabase = Supabase.instance.client;

  // ============================================================================
  // TRACKING DE USO
  // ============================================================================

  /// Registra el uso de una herramienta IA
  static Future<void> trackUsage({
    required AIToolName toolName,
    required AIActionType actionType,
    required double responseTimeSeconds,
    bool success = true,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('⚠️ No se puede trackear: usuario no autenticado');
        return;
      }

      await _supabase.from('ai_tool_usage').insert({
        'user_id': userId,
        'tool_name': toolName.value,
        'action_type': actionType.value,
        'response_time_seconds': responseTimeSeconds,
        'success': success,
        'metadata': metadata ?? {},
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Uso trackeado: ${toolName.value} - ${actionType.value}');
    } catch (e) {
      debugPrint('❌ Error trackeando uso: $e');
      // No lanzar error para no interrumpir la UX
    }
  }

  /// Wrapper para trackear con cronómetro automático
  static Future<T> trackOperation<T>({
    required AIToolName toolName,
    required AIActionType actionType,
    required Future<T> Function() operation,
    Map<String, dynamic>? metadata,
  }) async {
    final stopwatch = Stopwatch()..start();
    bool success = true;
    
    try {
      final result = await operation();
      return result;
    } catch (e) {
      success = false;
      rethrow;
    } finally {
      stopwatch.stop();
      await trackUsage(
        toolName: toolName,
        actionType: actionType,
        responseTimeSeconds: stopwatch.elapsedMilliseconds / 1000.0,
        success: success,
        metadata: metadata,
      );
    }
  }

  // ============================================================================
  // CONSULTAS DE ESTADÍSTICAS
  // ============================================================================

  /// Obtiene estadísticas de una herramienta específica
  static Future<AIToolStats?> getToolStats({
    required AIToolName toolName,
    int daysAgo = 30,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase.rpc('get_tool_stats', params: {
        'p_user_id': userId,
        'p_tool_name': toolName.value,
        'p_days_ago': daysAgo,
      });

      if (response == null || (response as List).isEmpty) {
        return AIToolStats(
          toolName: toolName,
          totalUses: 0,
          successfulUses: 0,
          failedUses: 0,
          avgResponseTime: 0,
          successRate: 0,
        );
      }

      final data = (response as List).first as Map<String, dynamic>;
      return AIToolStats.fromMap(data);
    } catch (e) {
      debugPrint('❌ Error obteniendo stats: $e');
      return null;
    }
  }

  /// Obtiene estadísticas de todas las herramientas
  static Future<Map<AIToolName, AIToolStats>> getAllToolsStats({
    int daysAgo = 30,
  }) async {
    final Map<AIToolName, AIToolStats> stats = {};

    for (final tool in AIToolName.values) {
      final toolStats = await getToolStats(
        toolName: tool,
        daysAgo: daysAgo,
      );
      if (toolStats != null) {
        stats[tool] = toolStats;
      }
    }

    return stats;
  }

  /// Obtiene estadísticas globales del usuario
  static Future<GlobalStats?> getGlobalStats({int daysAgo = 30}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase.rpc('get_tool_stats', params: {
        'p_user_id': userId,
        'p_tool_name': null, // Todas las herramientas
        'p_days_ago': daysAgo,
      });

      if (response == null || (response as List).isEmpty) {
        return GlobalStats(
          totalUses: 0,
          successfulUses: 0,
          failedUses: 0,
          avgResponseTime: 0,
          successRate: 0,
          toolsStats: {},
        );
      }

      final List<Map<String, dynamic>> data =
          (response as List).cast<Map<String, dynamic>>();

      int totalUses = 0;
      int successfulUses = 0;
      int failedUses = 0;
      double totalResponseTime = 0;
      final Map<AIToolName, AIToolStats> toolsStats = {};

      for (final item in data) {
        final stats = AIToolStats.fromMap(item);
        totalUses += stats.totalUses;
        successfulUses += stats.successfulUses;
        failedUses += stats.failedUses;
        totalResponseTime += stats.avgResponseTime * stats.totalUses;
        toolsStats[stats.toolName] = stats;
      }

      return GlobalStats(
        totalUses: totalUses,
        successfulUses: successfulUses,
        failedUses: failedUses,
        avgResponseTime: totalUses > 0 ? totalResponseTime / totalUses : 0,
        successRate: totalUses > 0 ? (successfulUses / totalUses) * 100 : 0,
        toolsStats: toolsStats,
      );
    } catch (e) {
      debugPrint('❌ Error obteniendo stats globales: $e');
      return null;
    }
  }

  // ============================================================================
  // TENDENCIAS Y ANÁLISIS
  // ============================================================================

  /// Obtiene la herramienta más usada
  static Future<MostUsedTool?> getMostUsedTool({int daysAgo = 30}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase.rpc('get_most_used_tool', params: {
        'p_user_id': userId,
        'p_days_ago': daysAgo,
      });

      if (response == null || (response as List).isEmpty) return null;

      final data = (response as List).first as Map<String, dynamic>;
      return MostUsedTool.fromMap(data);
    } catch (e) {
      debugPrint('❌ Error obteniendo herramienta más usada: $e');
      return null;
    }
  }

  /// Obtiene tendencia de uso por hora del día
  static Future<List<HourlyUsage>> getHourlyUsageTrend({
    int daysAgo = 7,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase.rpc('get_hourly_usage_trend', params: {
        'p_user_id': userId,
        'p_days_ago': daysAgo,
      });

      if (response == null || (response as List).isEmpty) return [];

      return (response as List)
          .map((item) => HourlyUsage.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo tendencia horaria: $e');
      return [];
    }
  }

  /// Obtiene tendencia semanal de uso
  static Future<List<WeeklyUsage>> getWeeklyUsageTrend({
    int weeks = 12,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase.rpc('get_weekly_usage_trend', params: {
        'p_user_id': userId,
        'p_weeks': weeks,
      });

      if (response == null || (response as List).isEmpty) return [];

      return (response as List)
          .map((item) => WeeklyUsage.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo tendencia semanal: $e');
      return [];
    }
  }

  /// Obtiene horario pico de uso (hora con más actividad)
  static Future<int?> getPeakHour({int daysAgo = 7}) async {
    final hourlyTrend = await getHourlyUsageTrend(daysAgo: daysAgo);
    if (hourlyTrend.isEmpty) return null;

    hourlyTrend.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return hourlyTrend.first.hour;
  }

  // ============================================================================
  // CONSULTAS DIRECTAS (sin funciones SQL)
  // ============================================================================

  /// Obtiene registros de uso recientes
  static Future<List<UsageRecord>> getRecentUsage({
    int limit = 50,
    AIToolName? toolFilter,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      PostgrestFilterBuilder query = _supabase
          .from('ai_tool_usage')
          .select()
          .eq('user_id', userId);

      if (toolFilter != null) {
        query = query.eq('tool_name', toolFilter.value);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((item) => UsageRecord.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo uso reciente: $e');
      return [];
    }
  }

  /// Limpia registros antiguos (opcional, para mantenimiento)
  static Future<void> cleanOldRecords({int daysToKeep = 365}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final cutoffDate =
          DateTime.now().subtract(Duration(days: daysToKeep)).toIso8601String();

      await _supabase
          .from('ai_tool_usage')
          .delete()
          .eq('user_id', userId)
          .lt('created_at', cutoffDate);

      debugPrint('✅ Registros antiguos eliminados');
    } catch (e) {
      debugPrint('❌ Error limpiando registros: $e');
    }
  }
}

// ============================================================================
// ENUMS
// ============================================================================

enum AIToolName {
  chatLegal('chat_legal', 'Chat Legal'),
  redactorDocumentos('redactor_documentos', 'Redactor de Documentos'),
  escanerDocumentos('escaner_documentos', 'Escáner de Documentos'),
  comparadorEstrategias('comparador_estrategias', 'Comparador de Estrategias');

  final String value;
  final String displayName;
  const AIToolName(this.value, this.displayName);

  static AIToolName fromValue(String value) {
    return AIToolName.values.firstWhere((e) => e.value == value);
  }
}

enum AIActionType {
  query('query', 'Consulta'),
  generation('generation', 'Generación'),
  analysis('analysis', 'Análisis'),
  comparison('comparison', 'Comparación'),
  scan('scan', 'Escaneo'),
  export('export', 'Exportación');

  final String value;
  final String displayName;
  const AIActionType(this.value, this.displayName);

  static AIActionType fromValue(String value) {
    return AIActionType.values.firstWhere((e) => e.value == value);
  }
}

// ============================================================================
// MODELOS
// ============================================================================

class AIToolStats {
  final AIToolName toolName;
  final int totalUses;
  final int successfulUses;
  final int failedUses;
  final double avgResponseTime;
  final double successRate;

  AIToolStats({
    required this.toolName,
    required this.totalUses,
    required this.successfulUses,
    required this.failedUses,
    required this.avgResponseTime,
    required this.successRate,
  });

  factory AIToolStats.fromMap(Map<String, dynamic> map) {
    return AIToolStats(
      toolName: AIToolName.fromValue(map['tool_name'] as String),
      totalUses: (map['total_uses'] as num).toInt(),
      successfulUses: (map['successful_uses'] as num).toInt(),
      failedUses: (map['failed_uses'] as num).toInt(),
      avgResponseTime: (map['avg_response_time'] as num).toDouble(),
      successRate: (map['success_rate'] as num).toDouble(),
    );
  }
}

class GlobalStats {
  final int totalUses;
  final int successfulUses;
  final int failedUses;
  final double avgResponseTime;
  final double successRate;
  final Map<AIToolName, AIToolStats> toolsStats;

  GlobalStats({
    required this.totalUses,
    required this.successfulUses,
    required this.failedUses,
    required this.avgResponseTime,
    required this.successRate,
    required this.toolsStats,
  });
}

class MostUsedTool {
  final AIToolName toolName;
  final int usageCount;
  final double percentage;

  MostUsedTool({
    required this.toolName,
    required this.usageCount,
    required this.percentage,
  });

  factory MostUsedTool.fromMap(Map<String, dynamic> map) {
    return MostUsedTool(
      toolName: AIToolName.fromValue(map['tool_name'] as String),
      usageCount: (map['usage_count'] as num).toInt(),
      percentage: (map['percentage'] as num).toDouble(),
    );
  }
}

class HourlyUsage {
  final int hour; // Nombre consistente con analytics_metrics_widgets
  final int usageCount;

  // Compatibilidad con ambos nombres
  int get hourOfDay => hour;

  HourlyUsage({
    required this.hour,
    required this.usageCount,
  });

  factory HourlyUsage.fromMap(Map<String, dynamic> map) {
    return HourlyUsage(
      hour: (map['hour_of_day'] as num?)?.toInt() ?? (map['hour'] as num).toInt(),
      usageCount: (map['usage_count'] as num).toInt(),
    );
  }
}

class WeeklyUsage {
  final int weekNumber;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int usageCount;

  WeeklyUsage({
    required this.weekNumber,
    required this.weekStart,
    required this.weekEnd,
    required this.usageCount,
  });

  factory WeeklyUsage.fromMap(Map<String, dynamic> map) {
    return WeeklyUsage(
      weekNumber: (map['week_number'] as num).toInt(),
      weekStart: DateTime.parse(map['week_start'] as String),
      weekEnd: DateTime.parse(map['week_end'] as String),
      usageCount: (map['usage_count'] as num).toInt(),
    );
  }
}

class UsageRecord {
  final String id;
  final AIToolName toolName;
  final AIActionType actionType;
  final double responseTimeSeconds;
  final bool success;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  UsageRecord({
    required this.id,
    required this.toolName,
    required this.actionType,
    required this.responseTimeSeconds,
    required this.success,
    required this.metadata,
    required this.createdAt,
  });

  factory UsageRecord.fromMap(Map<String, dynamic> map) {
    return UsageRecord(
      id: map['id'] as String,
      toolName: AIToolName.fromValue(map['tool_name'] as String),
      actionType: AIActionType.fromValue(map['action_type'] as String),
      responseTimeSeconds: (map['response_time_seconds'] as num).toDouble(),
      success: map['success'] as bool,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/ai_analytics_service.dart';

/// Widget reutilizable para mostrar estadísticas de uso de herramientas IA
class AIToolStatsWidget extends StatelessWidget {
  final String toolName;
  final int totalUses;
  final double averageResponseTime; // en segundos
  final double successRate; // 0.0 a 1.0
  final Color accentColor;

  const AIToolStatsWidget({
    super.key,
    required this.toolName,
    required this.totalUses,
    required this.averageResponseTime,
    required this.successRate,
    this.accentColor = const Color(0xFFC5A059),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Estadísticas - $toolName',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Métricas
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  icon: Icons.bar_chart,
                  label: 'Usos',
                  value: _formatNumber(totalUses),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetric(
                  icon: Icons.speed,
                  label: 'Tiempo',
                  value: _formatTime(averageResponseTime),
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetric(
                  icon: Icons.check_circle,
                  label: 'Éxito',
                  value: '${(successRate * 100).toStringAsFixed(0)}%',
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatTime(double seconds) {
    if (seconds < 1) {
      return '<1s';
    } else if (seconds < 60) {
      return '${seconds.toStringAsFixed(0)}s';
    } else {
      final minutes = (seconds / 60).floor();
      return '${minutes}m';
    }
  }
}

/// Widget compacto para mostrar estadísticas en una línea
class AIToolStatsCompact extends StatelessWidget {
  final int totalUses;
  final double averageResponseTime;
  final Color accentColor;

  const AIToolStatsCompact({
    super.key,
    required this.totalUses,
    required this.averageResponseTime,
    this.accentColor = const Color(0xFFC5A059),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up,
            color: accentColor,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            '$totalUses usos',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.speed,
            color: accentColor.withValues(alpha: 0.7),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            _formatTime(averageResponseTime),
            style: TextStyle(
              fontSize: 12,
              color: accentColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(double seconds) {
    if (seconds < 1) {
      return '<1s';
    } else if (seconds < 60) {
      return '${seconds.toStringAsFixed(0)}s';
    } else {
      final minutes = (seconds / 60).floor();
      return '${minutes}m';
    }
  }
}

/// Widget de badge con contador
class AIToolBadge extends StatelessWidget {
  final String label;
  final int? count;
  final Color color;

  const AIToolBadge({
    super.key,
    required this.label,
    this.count,
    this.color = const Color(0xFFFBBF24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: 0.5,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Servicio para obtener estadísticas (usa AIAnalyticsService)
class AIToolStatsService {
  /// Obtiene estadísticas de una herramienta específica
  static Future<AIToolStats> getToolStats(String toolName) async {
    final tool = AIToolName.values.firstWhere(
      (t) => t.displayName == toolName || t.value == toolName,
      orElse: () => AIToolName.chatLegal,
    );
    
    final stats = await AIAnalyticsService.getToolStats(
      toolName: tool,
      daysAgo: 30,
    );
    
    return AIToolStats(
      toolName: toolName,
      totalUses: stats?.totalUses ?? 0,
      averageResponseTime: stats?.avgResponseTime ?? 0,
      successRate: stats != null ? stats.successRate / 100 : 0,
      lastUsed: DateTime.now(),
    );
  }

  /// Obtiene estadísticas de todas las herramientas
  static Future<Map<String, AIToolStats>> getAllStats() async {
    final globalStats = await AIAnalyticsService.getGlobalStats(daysAgo: 30);
    final Map<String, AIToolStats> stats = {};
    
    if (globalStats != null) {
      for (final entry in globalStats.toolsStats.entries) {
        stats[entry.key.displayName] = AIToolStats(
          toolName: entry.key.displayName,
          totalUses: entry.value.totalUses,
          averageResponseTime: entry.value.avgResponseTime,
          successRate: entry.value.successRate / 100,
          lastUsed: DateTime.now(),
        );
      }
    }
    
    return stats;
  }
}

/// Modelo de estadísticas
class AIToolStats {
  final String toolName;
  final int totalUses;
  final double averageResponseTime;
  final double successRate;
  final DateTime lastUsed;

  AIToolStats({
    required this.toolName,
    required this.totalUses,
    required this.averageResponseTime,
    required this.successRate,
    required this.lastUsed,
  });

  Map<String, dynamic> toMap() => {
    'toolName': toolName,
    'totalUses': totalUses,
    'averageResponseTime': averageResponseTime,
    'successRate': successRate,
    'lastUsed': lastUsed.toIso8601String(),
  };

  factory AIToolStats.fromMap(Map<String, dynamic> map) => AIToolStats(
    toolName: map['toolName'] as String,
    totalUses: map['totalUses'] as int,
    averageResponseTime: (map['averageResponseTime'] as num).toDouble(),
    successRate: (map['successRate'] as num).toDouble(),
    lastUsed: DateTime.parse(map['lastUsed'] as String),
  );
}

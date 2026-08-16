import 'package:flutter/material.dart';
import '../services/ai_analytics_service.dart';

/// Widget para mostrar la herramienta más usada
class MostUsedToolWidget extends StatelessWidget {
  final MostUsedTool? mostUsedTool;
  final bool isLoading;

  const MostUsedToolWidget({
    super.key,
    this.mostUsedTool,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingCard();
    }

    if (mostUsedTool == null) {
      return _buildEmptyCard();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withValues(alpha: 0.2),
            const Color(0xFF6366F1).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFFBBF24),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Herramienta Más Usada',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mostUsedTool!.toolName.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFBBF24),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${mostUsedTool!.usageCount} usos',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${mostUsedTool!.percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFBBF24),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFC5A059),
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          'Sin datos disponibles',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

/// Widget para mostrar horario pico de uso
class PeakHourWidget extends StatelessWidget {
  final List<HourlyUsage> hourlyTrend;
  final bool isLoading;

  const PeakHourWidget({
    super.key,
    required this.hourlyTrend,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingCard();
    }

    if (hourlyTrend.isEmpty) {
      return _buildEmptyCard();
    }

    // Encontrar hora pico
    final sortedTrend = List<HourlyUsage>.from(hourlyTrend);
    sortedTrend.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    final peakHour = sortedTrend.first;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEC4899).withValues(alpha: 0.2),
            const Color(0xFFF59E0B).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEC4899).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Color(0xFFEC4899),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Horario Pico',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatHour(peakHour.hourOfDay),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEC4899),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${peakHour.usageCount} usos',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.trending_up,
                color: Color(0xFFEC4899),
                size: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour < 12) return '$hour:00 AM';
    if (hour == 12) return '12:00 PM';
    return '${hour - 12}:00 PM';
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFC5A059),
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          'Sin datos disponibles',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

/// Widget para mostrar gráfico de barras horizontal de uso por herramienta
class ToolUsageBarChart extends StatelessWidget {
  final Map<AIToolName, AIToolStats> toolsStats;
  final bool isLoading;

  const ToolUsageBarChart({
    super.key,
    required this.toolsStats,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFC5A059),
        ),
      );
    }

    if (toolsStats.isEmpty) {
      return Center(
        child: Text(
          'Sin datos disponibles',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final sortedStats = toolsStats.entries.toList()
      ..sort((a, b) => b.value.totalUses.compareTo(a.value.totalUses));

    final maxUses = sortedStats.first.value.totalUses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Uso por Herramienta',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        ...sortedStats.map((entry) => _buildBar(
              entry.key.displayName,
              entry.value.totalUses,
              maxUses,
              _getColorForTool(entry.key),
            )),
      ],
    );
  }

  Widget _buildBar(String label, int uses, int maxUses, Color color) {
    final percentage = maxUses > 0 ? (uses / maxUses) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                uses.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColorForTool(AIToolName tool) {
    switch (tool) {
      case AIToolName.chatLegal:
        return const Color(0xFF10B981);
      case AIToolName.redactorDocumentos:
        return const Color(0xFF3B82F6);
      case AIToolName.comparadorEstrategias:
        return const Color(0xFFFBBF24);
      case AIToolName.escanerDocumentos:
        return const Color(0xFF8B5CF6);
    }
  }
}

/// Widget para mostrar gráfico circular de distribución horaria
class HourlyDistributionChart extends StatelessWidget {
  final List<HourlyUsage> hourlyTrend;
  final bool isLoading;

  const HourlyDistributionChart({
    super.key,
    required this.hourlyTrend,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFC5A059),
        ),
      );
    }

    if (hourlyTrend.isEmpty) {
      return Center(
        child: Text(
          'Sin datos disponibles',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final maxUsage = hourlyTrend.map((h) => h.usageCount).reduce(
      (a, b) => a > b ? a : b,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distribución Horaria',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: hourlyTrend.map((hourData) {
              final height = maxUsage > 0
                  ? (hourData.usageCount / maxUsage) * 180
                  : 0.0;
              
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (hourData.usageCount > 0)
                        Text(
                          hourData.usageCount.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFC5A059),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        height: height,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFC5A059),
                              const Color(0xFFC5A059).withValues(alpha: 0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${hourData.hourOfDay}h',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Widget para mostrar tendencia semanal
class WeeklyTrendWidget extends StatelessWidget {
  final List<WeeklyUsage> weeklyTrend;
  final bool isLoading;

  const WeeklyTrendWidget({
    super.key,
    required this.weeklyTrend,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFC5A059),
        ),
      );
    }

    if (weeklyTrend.isEmpty) {
      return Center(
        child: Text(
          'Sin datos disponibles',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    // Preparar datos para gráfico
    final Map<DateTime, int> weeklyData = {};
    for (final usage in weeklyTrend) {
      weeklyData[usage.weekStart] = usage.usageCount;
    }

    final sortedWeeks = weeklyData.keys.toList()..sort();
    final recentWeeks = sortedWeeks.length > 8
        ? sortedWeeks.sublist(sortedWeeks.length - 8)
        : sortedWeeks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tendencia Semanal',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        ...recentWeeks.map((week) {
          final usageCount = weeklyData[week]!;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatWeek(week),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      '$usageCount usos',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC5A059),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: usageCount / (recentWeeks.map((w) => weeklyData[w]!).reduce((a, b) => a > b ? a : b)),
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC5A059)),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /* MÉTODOS ANTIGUOS - Ya no se usan con la estructura simplificada
  List<Widget> _buildWeekSegments(Map<AIToolName, int> data, int total) {
    if (total == 0) return [];

    return data.entries.map((entry) {
      final percentage = entry.value / total;
      return Flexible(
        flex: (percentage * 100).round(),
        child: Container(
          height: 6,
          decoration: BoxDecoration(
            color: _getColorForTool(entry.key),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );
    }).toList();
  }

  Color _getColorForTool(AIToolName tool) {
    switch (tool) {
      case AIToolName.chatLegal:
        return const Color(0xFF10B981);
      case AIToolName.redactorDocumentos:
        return const Color(0xFF3B82F6);
      case AIToolName.comparadorEstrategias:
        return const Color(0xFFFBBF24);
      case AIToolName.escanerDocumentos:
        return const Color(0xFF8B5CF6);
    }
  }
  */

  String _formatWeek(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'ai_analytics_service.dart';

/// Servicio para generar reportes PDF de analytics
class AIReportService {
  static const _dorado = PdfColor.fromInt(0xFFC5A059);
  static const _azulMarino = PdfColor.fromInt(0xFF0F172A);
  static const _grisOscuro = PdfColor.fromInt(0xFF1E293B);
  static const _blanco = PdfColors.white;

  /// Genera un reporte PDF completo de analytics
  /// 
  /// Parámetros:
  /// - [daysAgo]: período de análisis (7, 30, 90, 365 días)
  /// - [includeSections]: secciones a incluir (global, tools, trends, hours)
  /// 
  /// Retorna la ruta del archivo PDF generado
  static Future<String> generatePDFReport({
    int daysAgo = 30,
    Map<String, bool>? includeSections,
  }) async {
    final sections = includeSections ?? {
      'global': true,
      'tools': true,
      'trends': true,
      'hours': true,
    };

    // Crear documento PDF
    final pdf = pw.Document();

    // Cargar datos
    final globalStats = await AIAnalyticsService.getGlobalStats(daysAgo: daysAgo);
    final mostUsedTool = await AIAnalyticsService.getMostUsedTool(daysAgo: daysAgo);
    final hourlyTrend = await AIAnalyticsService.getHourlyUsageTrend(daysAgo: 7);
    final weeklyTrend = await AIAnalyticsService.getWeeklyUsageTrend(weeks: 12);

    // Página 1: Portada y resumen ejecutivo
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => _buildCoverPage(daysAgo),
      ),
    );

    // Página 2: Estadísticas globales
    if (sections['global'] == true && globalStats != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => _buildGlobalStatsPage(
            globalStats,
            mostUsedTool,
            daysAgo,
          ),
        ),
      );
    }

    // Página 3: Detalles por herramienta
    if (sections['tools'] == true && globalStats != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => _buildToolsDetailsPage(globalStats),
        ),
      );
    }

    // Página 4: Tendencias semanales
    if (sections['trends'] == true && weeklyTrend.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => _buildTrendsPage(weeklyTrend),
        ),
      );
    }

    // Página 5: Distribución horaria
    if (sections['hours'] == true && hourlyTrend.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => _buildHoursPage(hourlyTrend),
        ),
      );
    }

    // Guardar PDF
    final output = await _getOutputFile();
    final file = File(output);
    await file.writeAsBytes(await pdf.save());

    return output;
  }

  // ==========================================================================
  // PÁGINAS DEL PDF
  // ==========================================================================

  static pw.Widget _buildCoverPage(int daysAgo) {
    final now = DateTime.now();
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    return pw.Container(
      decoration: const pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [_azulMarino, _grisOscuro],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
      ),
      child: pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: _dorado,
                borderRadius: pw.BorderRadius.circular(20),
              ),
              child: pw.Icon(
                pw.IconData(0xe1b8), // analytics icon
                size: 80,
                color: _azulMarino,
              ),
            ),
            pw.SizedBox(height: 40),
            pw.Text(
              'REPORTE DE ANALYTICS',
              style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: _dorado,
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Asistente Legal - PENALEX VE',
              style: const pw.TextStyle(
                fontSize: 20,
                color: _blanco,
              ),
            ),
            pw.SizedBox(height: 60),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 20,
              ),
              decoration: pw.BoxDecoration(
                color: _blanco.shade(0.1),
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(
                  color: _dorado.shade(0.3),
                  width: 1,
                ),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'Período de Análisis',
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: _blanco.shade(0.7),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Últimos $daysAgo días',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: _dorado,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 80),
            pw.Text(
              'Generado: ${dateFormatter.format(now)}',
              style: pw.TextStyle(
                fontSize: 12,
                color: _blanco.shade(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildGlobalStatsPage(
    GlobalStats stats,
    MostUsedTool? mostUsed,
    int daysAgo,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildPageHeader('Estadísticas Globales'),
          pw.SizedBox(height: 20),
          pw.Text(
            'Resumen de los últimos $daysAgo días',
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 30),

          // Tarjetas de métricas principales
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildMetricCard(
                  'Total de Usos',
                  stats.totalUses.toString(),
                  PdfColors.blue,
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _buildMetricCard(
                  'Usos Exitosos',
                  stats.successfulUses.toString(),
                  PdfColors.green,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildMetricCard(
                  'Tiempo Promedio',
                  '${stats.avgResponseTime.toStringAsFixed(1)}s',
                  PdfColors.orange,
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _buildMetricCard(
                  'Tasa de Éxito',
                  '${stats.successRate.toStringAsFixed(0)}%',
                  PdfColors.purple,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 40),

          // Herramienta más usada
          if (mostUsed != null) ...[
            pw.Text(
              'Herramienta Más Utilizada',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: _azulMarino,
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: _dorado.shade(0.1),
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: _dorado, width: 2),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: _dorado,
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.Icon(
                      pw.IconData(0xe0e0), // trophy icon
                      size: 40,
                      color: _blanco,
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          mostUsed.toolName.displayName,
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: _azulMarino,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          '${mostUsed.usageCount} usos · ${mostUsed.percentage.toStringAsFixed(1)}% del total',
                          style: const pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          pw.SizedBox(height: 40),

          // Resumen por herramienta (tabla)
          pw.Text(
            'Distribución por Herramienta',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: _azulMarino,
            ),
          ),
          pw.SizedBox(height: 16),
          _buildToolsTable(stats.toolsStats),
        ],
      ),
    );
  }

  static pw.Widget _buildToolsDetailsPage(GlobalStats stats) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildPageHeader('Detalles por Herramienta'),
          pw.SizedBox(height: 30),

          // Lista de herramientas con detalles
          ...stats.toolsStats.entries.map((entry) {
            final tool = entry.key;
            final toolStats = entry.value;

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Título
                  pw.Row(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: _getColorForTool(tool).shade(0.2),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Icon(
                          pw.IconData(0xe0e0),
                          size: 24,
                          color: _getColorForTool(tool),
                        ),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Expanded(
                        child: pw.Text(
                          tool.displayName,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: _azulMarino,
                          ),
                        ),
                      ),
                      pw.Text(
                        '${toolStats.totalUses} usos',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: _getColorForTool(tool),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16),

                  // Métricas en grid
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _buildDetailRow(
                          'Exitosos',
                          '${toolStats.successfulUses}',
                          PdfColors.green,
                        ),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Expanded(
                        child: _buildDetailRow(
                          'Fallidos',
                          '${toolStats.failedUses}',
                          PdfColors.red,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _buildDetailRow(
                          'Tiempo Avg',
                          '${toolStats.avgResponseTime.toStringAsFixed(1)}s',
                          PdfColors.orange,
                        ),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Expanded(
                        child: _buildDetailRow(
                          'Tasa Éxito',
                          '${toolStats.successRate.toStringAsFixed(1)}%',
                          PdfColors.purple,
                        ),
                      ),
                    ],
                  ),

                  // Barra de progreso visual
                  pw.SizedBox(height: 16),
                  pw.Container(
                    height: 8,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: (toolStats.successRate / 100) * 200, // Ancho máximo 200
                          decoration: pw.BoxDecoration(
                            color: _getColorForTool(tool),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildTrendsPage(List<WeeklyUsage> weeklyTrend) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildPageHeader('Tendencias Semanales'),
          pw.SizedBox(height: 20),
          pw.Text(
            'Últimas ${weeklyTrend.length} semanas',
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 30),

          // Gráfico de barras vertical
          _buildWeeklyChart(weeklyTrend),
          pw.SizedBox(height: 30),

          // Tabla de datos
          _buildWeeklyTable(weeklyTrend),
        ],
      ),
    );
  }

  static pw.Widget _buildHoursPage(List<HourlyUsage> hourlyTrend) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildPageHeader('Distribución Horaria'),
          pw.SizedBox(height: 20),
          pw.Text(
            'Uso por hora del día (últimos 7 días)',
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 30),

          // Gráfico de barras
          _buildHourlyChart(hourlyTrend),
          pw.SizedBox(height: 30),

          // Horarios pico
          _buildPeakHoursSection(hourlyTrend),
        ],
      ),
    );
  }

  // ==========================================================================
  // COMPONENTES REUTILIZABLES
  // ==========================================================================

  static pw.Widget _buildPageHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _dorado, width: 2),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 6,
            height: 30,
            decoration: pw.BoxDecoration(
              color: _dorado,
              borderRadius: pw.BorderRadius.circular(3),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: _azulMarino,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetricCard(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: color.shade(0.3), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailRow(String label, String value, PdfColor color) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildToolsTable(Map<AIToolName, AIToolStats> toolsStats) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _azulMarino),
          children: [
            _buildTableCell('Herramienta', isHeader: true),
            _buildTableCell('Usos', isHeader: true),
            _buildTableCell('Exitosos', isHeader: true),
            _buildTableCell('Fallidos', isHeader: true),
            _buildTableCell('Tasa Éxito', isHeader: true),
          ],
        ),
        // Filas de datos
        ...toolsStats.entries.map((entry) {
          final tool = entry.key;
          final stats = entry.value;
          return pw.TableRow(
            children: [
              _buildTableCell(tool.displayName),
              _buildTableCell(stats.totalUses.toString()),
              _buildTableCell(stats.successfulUses.toString()),
              _buildTableCell(stats.failedUses.toString()),
              _buildTableCell('${stats.successRate.toStringAsFixed(0)}%'),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? _blanco : _azulMarino,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildWeeklyChart(List<WeeklyUsage> weeklyTrend) {
    final maxCount = weeklyTrend.fold<int>(0, (max, w) => w.usageCount > max ? w.usageCount : max);
    
    return pw.Container(
      height: 200,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: weeklyTrend.map((week) {
          final height = maxCount > 0 ? (week.usageCount / maxCount) * 180 : 0.0;
          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 30,
                height: height,
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue,
                  borderRadius: const pw.BorderRadius.vertical(
                    top: pw.Radius.circular(4),
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'S${week.weekNumber}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  static pw.Widget _buildWeeklyTable(List<WeeklyUsage> weeklyTrend) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _azulMarino),
          children: [
            _buildTableCell('Semana', isHeader: true),
            _buildTableCell('Usos', isHeader: true),
            _buildTableCell('Fecha Inicio', isHeader: true),
          ],
        ),
        ...weeklyTrend.take(10).map((week) {
          return pw.TableRow(
            children: [
              _buildTableCell('Semana ${week.weekNumber}'),
              _buildTableCell(week.usageCount.toString()),
              _buildTableCell(DateFormat('dd/MM/yyyy').format(week.weekStart)),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildHourlyChart(List<HourlyUsage> hourlyTrend) {
    final maxCount = hourlyTrend.fold<int>(0, (max, h) => h.usageCount > max ? h.usageCount : max);
    
    return pw.Container(
      height: 200,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: hourlyTrend.map((hour) {
          final height = maxCount > 0 ? (hour.usageCount / maxCount) * 180 : 0.0;
          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 20,
                height: height,
                decoration: pw.BoxDecoration(
                  color: PdfColors.purple,
                  borderRadius: const pw.BorderRadius.vertical(
                    top: pw.Radius.circular(4),
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${hour.hour}h',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  static pw.Widget _buildPeakHoursSection(List<HourlyUsage> hourlyTrend) {
    // Encontrar top 3 horarios
    final sortedHours = List<HourlyUsage>.from(hourlyTrend)
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
    
    final top3 = sortedHours.take(3).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Horarios de Mayor Uso',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: _azulMarino,
          ),
        ),
        pw.SizedBox(height: 16),
        ...top3.asMap().entries.map((entry) {
          final index = entry.key;
          final hourData = entry.value;
          final medals = ['🥇', '🥈', '🥉'];
          
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  medals[index],
                  style: const pw.TextStyle(fontSize: 24),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Text(
                    _formatHour(hourData.hour),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Text(
                  '${hourData.usageCount} usos',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  static PdfColor _getColorForTool(AIToolName tool) {
    switch (tool) {
      case AIToolName.chatLegal:
        return PdfColors.green;
      case AIToolName.redactorDocumentos:
        return PdfColors.blue;
      case AIToolName.comparadorEstrategias:
        return PdfColors.amber;
      case AIToolName.escanerDocumentos:
        return PdfColors.purple;
    }
  }

  static String _formatHour(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:00 $period';
  }

  static Future<String> _getOutputFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'analytics_report_$timestamp.pdf';
    return '${directory.path}/$filename';
  }
}

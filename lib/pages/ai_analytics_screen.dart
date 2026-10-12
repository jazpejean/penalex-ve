import 'package:flutter/material.dart';
import '../pages/main_screen.dart';
import '../utils/main_tab_controller.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import '../services/ai_analytics_service.dart';
import '../services/ai_report_service.dart';
import '../config/app_theme.dart';
import '../widgets/analytics_metrics_widgets.dart';

/// Pantalla de Analytics detallada del Asistente Legal
class AIAnalyticsScreen extends StatefulWidget {
  const AIAnalyticsScreen({super.key});

  @override
  State<AIAnalyticsScreen> createState() => _AIAnalyticsScreenState();
}

class _AIAnalyticsScreenState extends State<AIAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Datos
  GlobalStats? _globalStats;
  MostUsedTool? _mostUsedTool;
  List<HourlyUsage> _hourlyTrend = [];
  List<WeeklyUsage> _weeklyTrend = [];
  
  // Estado
  bool _isLoading = true;
  int _selectedDays = 30;
  
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        AIAnalyticsService.getGlobalStats(daysAgo: _selectedDays),
        AIAnalyticsService.getMostUsedTool(daysAgo: _selectedDays),
        AIAnalyticsService.getHourlyUsageTrend(daysAgo: 7),
        AIAnalyticsService.getWeeklyUsageTrend(weeks: 12),
      ]);

      setState(() {
        _globalStats = results[0] as GlobalStats?;
        _mostUsedTool = results[1] as MostUsedTool?;
        _hourlyTrend = results[2] as List<HourlyUsage>;
        _weeklyTrend = results[3] as List<WeeklyUsage>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: dorado, size: 24),
            SizedBox(width: 12),
            Text(
              'Analytics IA',
              style: TextStyle(
                color: dorado,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: azulMarino,
        elevation: 0,
        iconTheme: const IconThemeData(color: dorado),
        actions: [
          // Selector de período
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today, color: dorado),
            onSelected: (days) {
              setState(() => _selectedDays = days);
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Últimos 7 días')),
              const PopupMenuItem(value: 30, child: Text('Últimos 30 días')),
              const PopupMenuItem(value: 90, child: Text('Últimos 90 días')),
              const PopupMenuItem(value: 365, child: Text('Último año')),
            ],
          ),
          // Botón de compartir reporte
          IconButton(
            icon: const Icon(Icons.share, color: dorado),
            onPressed: _shareReport,
            tooltip: 'Compartir reporte',
          ),
          // Botón de exportar PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: dorado),
            onPressed: _exportPDF,
            tooltip: 'Exportar PDF',
          ),
            IconButton(
              icon: const Icon(Icons.home_outlined, color: Color(0xFFC5A059)),
              tooltip: 'Ir al inicio',
              onPressed: () {
                mainTabIndex.value = 0;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                  (r) => false,
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: dorado,
          labelColor: dorado,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Resumen'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Por Herramienta'),
            Tab(icon: Icon(Icons.trending_up), text: 'Tendencias'),
            Tab(icon: Icon(Icons.schedule), text: 'Horarios'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: dorado),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: dorado,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildResumenTab(),
                  _buildPorHerramientaTab(),
                  _buildTendenciasTab(),
                  _buildHorariosTab(),
                ],
              ),
            ),
    );
  }

  // ============================================================================
  // TAB 1: RESUMEN
  // ============================================================================

  Widget _buildResumenTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con período
          _buildPeriodHeader(),
          const SizedBox(height: 24),

          // Estadísticas globales
          if (_globalStats != null) _buildGlobalStatsCards(),
          const SizedBox(height: 24),

          // Herramienta más usada
          MostUsedToolWidget(
            mostUsedTool: _mostUsedTool,
            isLoading: false,
          ),
          const SizedBox(height: 20),

          // Horario pico
          PeakHourWidget(
            hourlyTrend: _hourlyTrend,
            isLoading: false,
          ),
          SizedBox(height: 24),

          // Resumen rápido por herramienta
          if (_globalStats != null) ...[
            Text(
              'Resumen por Herramienta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: TemaGlobal.texto,
              ),
            ),
            const SizedBox(height: 16),
            ..._globalStats!.toolsStats.entries.map(
              (entry) => _buildQuickToolCard(entry.key, entry.value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            dorado.withValues(alpha: 0.2),
            dorado.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dorado.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: dorado, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mostrando datos de los últimos $_selectedDays días',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalStatsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.bar_chart,
                label: 'Total Usos',
                value: _globalStats!.totalUses.toString(),
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.check_circle,
                label: 'Exitosos',
                value: _globalStats!.successfulUses.toString(),
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.speed,
                label: 'Tiempo Avg',
                value: '${_globalStats!.avgResponseTime.toStringAsFixed(1)}s',
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.percent,
                label: 'Tasa Éxito',
                value: '${_globalStats!.successRate.toStringAsFixed(0)}%',
                color: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaGlobal.tarjeta,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickToolCard(AIToolName tool, AIToolStats stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaGlobal.tarjeta,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getColorForTool(tool).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIconForTool(tool),
              color: _getColorForTool(tool),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: TemaGlobal.texto,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.totalUses} usos · ${stats.avgResponseTime.toStringAsFixed(1)}s avg',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${stats.successRate.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getColorForTool(tool),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 2: POR HERRAMIENTA
  // ============================================================================

  Widget _buildPorHerramientaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_globalStats != null)
            ToolUsageBarChart(
              toolsStats: _globalStats!.toolsStats,
              isLoading: false,
            ),
          SizedBox(height: 32),
          
          // Detalles por herramienta
          if (_globalStats != null) ...[
            Text(
              'Detalles por Herramienta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: TemaGlobal.texto,
              ),
            ),
            const SizedBox(height: 16),
            ..._globalStats!.toolsStats.entries.map(
              (entry) => _buildDetailedToolCard(entry.key, entry.value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedToolCard(AIToolName tool, AIToolStats stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: TemaGlobal.tarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getColorForTool(tool).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getColorForTool(tool).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getIconForTool(tool),
            color: _getColorForTool(tool),
            size: 24,
          ),
        ),
        title: Text(
          tool.displayName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: TemaGlobal.texto,
          ),
        ),
        subtitle: Text(
          '${stats.totalUses} usos totales',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildDetailRow(
                  'Usos Exitosos',
                  '${stats.successfulUses}',
                  const Color(0xFF10B981),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Usos Fallidos',
                  '${stats.failedUses}',
                  const Color(0xFFEF4444),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Tiempo Promedio',
                  '${stats.avgResponseTime.toStringAsFixed(1)}s',
                  const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Tasa de Éxito',
                  '${stats.successRate.toStringAsFixed(1)}%',
                  const Color(0xFF8B5CF6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 3: TENDENCIAS
  // ============================================================================

  Widget _buildTendenciasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WeeklyTrendWidget(
            weeklyTrend: _weeklyTrend,
            isLoading: false,
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 4: HORARIOS
  // ============================================================================

  Widget _buildHorariosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HourlyDistributionChart(
            hourlyTrend: _hourlyTrend,
            isLoading: false,
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  Color _getColorForTool(AIToolName tool) {
    switch (tool) {
      case AIToolName.chatLegal:
        return const Color(0xFF10B981);
      case AIToolName.redactorDocumentos:
        return const Color(0xFF3B82F6);
      case AIToolName.comparadorEstrategias:
        return const Color(0xFFC5A059);
      case AIToolName.escanerDocumentos:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _getIconForTool(AIToolName tool) {
    switch (tool) {
      case AIToolName.chatLegal:
        return Icons.chat_bubble;
      case AIToolName.redactorDocumentos:
        return Icons.edit_document;
      case AIToolName.comparadorEstrategias:
        return Icons.compare_arrows;
      case AIToolName.escanerDocumentos:
        return Icons.document_scanner;
    }
  }

  void _shareReport() {
    if (_globalStats == null) return;

    final text = '''
📊 Reporte de Analytics - Asistente Legal PENALEX

📅 Período: Últimos $_selectedDays días

📈 Estadísticas Globales:
• Total de usos: ${_globalStats!.totalUses}
• Usos exitosos: ${_globalStats!.successfulUses}
• Tiempo promedio: ${_globalStats!.avgResponseTime.toStringAsFixed(1)}s
• Tasa de éxito: ${_globalStats!.successRate.toStringAsFixed(0)}%

${_mostUsedTool != null ? '''
🏆 Herramienta más usada:
${_mostUsedTool!.toolName.displayName} (${_mostUsedTool!.percentage.toStringAsFixed(1)}%)
''' : ''}

Generado por PENALEX VE
''';

    Share.share(text, subject: 'Reporte Analytics - Asistente Legal');
  }

  Future<void> _exportPDF() async {
    // Mostrar diálogo de opciones
    final selectedSections = await showDialog<Map<String, bool>>(
      context: context,
      builder: (context) => _buildExportDialog(),
    );

    if (selectedSections == null) return; // Usuario canceló

    // Mostrar loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: dorado),
                SizedBox(height: 16),
                Text(
                  'Generando reporte PDF...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Generar PDF
      final pdfPath = await AIReportService.generatePDFReport(
        daysAgo: _selectedDays,
        includeSections: selectedSections,
      );

      // Cerrar loading
      if (!mounted) return;
      Navigator.pop(context);

      // Mostrar opciones de compartir o abrir
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF10B981)),
              SizedBox(width: 12),
              Text('PDF Generado'),
            ],
          ),
          content: const Text(
            'El reporte PDF ha sido generado exitosamente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Share.shareXFiles(
                  [XFile(pdfPath)],
                  subject: 'Reporte Analytics - Asistente Legal PENALEX',
                );
              },
              child: const Text('Compartir'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await OpenFile.open(pdfPath);
              },
              child: const Text('Abrir'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Cerrar loading si está abierto
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Mostrar error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Widget _buildExportDialog() {
    final sections = {
      'global': true,
      'tools': true,
      'trends': true,
      'hours': true,
    };

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.settings, color: dorado),
              SizedBox(width: 12),
              Text('Opciones de Exportación'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona las secciones a incluir en el PDF:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Estadísticas Globales'),
                  subtitle: const Text('Resumen ejecutivo y métricas principales'),
                  value: sections['global'],
                  onChanged: (value) {
                    setState(() => sections['global'] = value ?? true);
                  },
                  activeColor: dorado,
                ),
                CheckboxListTile(
                  title: const Text('Detalles por Herramienta'),
                  subtitle: const Text('Métricas individuales de cada herramienta'),
                  value: sections['tools'],
                  onChanged: (value) {
                    setState(() => sections['tools'] = value ?? true);
                  },
                  activeColor: dorado,
                ),
                CheckboxListTile(
                  title: const Text('Tendencias Semanales'),
                  subtitle: const Text('Gráfico y tabla de uso semanal'),
                  value: sections['trends'],
                  onChanged: (value) {
                    setState(() => sections['trends'] = value ?? true);
                  },
                  activeColor: dorado,
                ),
                CheckboxListTile(
                  title: const Text('Distribución Horaria'),
                  subtitle: const Text('Horarios pico y uso por hora'),
                  value: sections['hours'],
                  onChanged: (value) {
                    setState(() => sections['hours'] = value ?? true);
                  },
                  activeColor: dorado,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, sections),
              style: FilledButton.styleFrom(
                backgroundColor: dorado,
              ),
              child: const Text('Generar PDF'),
            ),
          ],
        );
      },
    );
  }
}

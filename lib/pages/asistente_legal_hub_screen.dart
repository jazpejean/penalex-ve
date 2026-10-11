import 'package:flutter/material.dart';
import '../widgets/ai_tool_stats_widget.dart';
import '../widgets/app_drawer.dart';
import 'chat_legal_screen.dart';
import 'redactor_documentos_screen.dart';
import 'escanear_documento_screen.dart';
import 'calculadora_prescripcion_screen.dart';

/// Hub principal del Asistente Legal con IA
/// Agrupa las 4 herramientas principales potenciadas por IA
class AsistenteLegalHubScreen extends StatefulWidget {
  const AsistenteLegalHubScreen({super.key});

  @override
  State<AsistenteLegalHubScreen> createState() => _AsistenteLegalHubScreenState();
}

class _AsistenteLegalHubScreenState extends State<AsistenteLegalHubScreen> {
  Map<String, AIToolStats>? _stats;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await AIToolStatsService.getAllStats();
      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    } catch (e) {
      setState(() => _loadingStats = false);
      debugPrint('Error cargando estadísticas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: "/asistente_legal"),
      backgroundColor: const Color(0xFF0F172A), // Azul marino
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFC5A059), size: 28),
            SizedBox(width: 12),
            Text(
              'Ulpiano',
              style: TextStyle(
                color: Color(0xFFC5A059),
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFC5A059)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header descriptivo
            _buildHeader(),
            const SizedBox(height: 24),

            // Estadísticas globales
            if (_loadingStats)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Color(0xFFC5A059),
                  ),
                ),
              )
            else if (_stats != null)
              _buildGlobalStats(),
            const SizedBox(height: 32),

            // ULPIANO - El asistente (feature estrella)
            _buildStarFeatureCard(
              context,
              icon: Icons.auto_awesome,
              title: 'Ulpiano — Asistente Legal',
              badge: '⭐ EL ASISTENTE',
              description:
                  'Pregúntale a Ulpiano: detecta si quieres consultar, redactar, '
                  'analizar, calcular o citar, y responde siempre con fuentes '
                  'verificables (artículos y sentencias del TSJ).',
              highlights: [
                '🔍 Consulta con citas verificables',
                '✍️ Redacta escritos con estilo forense',
                '📄 Analiza documentos adjuntos',
                '⚖️ Calcula dosimetría y lapsos',
              ],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatLegalScreen(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Título de herramientas complementarias
            const Text(
              'Herramientas Complementarias',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC5A059),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),

            // REDACTOR DE DOCUMENTOS
            _buildToolCard(
              context,
              icon: Icons.edit_document,
              iconColor: const Color(0xFF3B82F6),
              title: 'Redactor de Documentos',
              badge: '⚡ Ahorra tiempo',
              description:
                  'Genera escritos legales profesionales: demandas, recursos, '
                  'solicitudes y más con asistencia guiada de IA.',
              stats: '2-3 horas → 15 min',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RedactorDocumentosScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ESCÁNER DE DOCUMENTOS
            _buildToolCard(
              context,
              icon: Icons.document_scanner,
              iconColor: const Color(0xFF8B5CF6),
              title: 'Escáner de Documentos',
              badge: null,
              description:
                  'Digitaliza expedientes físicos con OCR avanzado. '
                  'Extrae texto de documentos legales al instante.',
              stats: 'OCR preciso',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EscanearDocumentoScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // CALCULADORA DE PRESCRIPCIÓN
            _buildToolCard(
              context,
              icon: Icons.hourglass_bottom,
              iconColor: const Color(0xFFEF4444),
              title: 'Calculadora de Prescripción',
              badge: '⚖️ Art. 108 y 112 CP',
              description:
                  'Calcula el término de prescripción de la acción penal o '
                  'de la pena con el texto exacto del Código Penal y la fecha '
                  'exacta. Cálculo determinístico, sin IA.',
              stats: 'Término + fecha + días',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CalculadoraPrescripcionScreen(),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Botón de Analytics
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, '/ai_analytics'),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.analytics,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ver Analytics Completo',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Métricas detalladas, tendencias y reportes',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Footer informativo
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalStats() {
    if (_stats == null) return const SizedBox.shrink();

    final totalUses = _stats!.values.fold<int>(
      0,
      (sum, stat) => sum + stat.totalUses,
    );

    final avgResponseTime = _stats!.values.fold<double>(
      0,
      (sum, stat) => sum + stat.averageResponseTime,
    ) / _stats!.length;

    final avgSuccessRate = _stats!.values.fold<double>(
      0,
      (sum, stat) => sum + stat.successRate,
    ) / _stats!.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B).withValues(alpha: 0.8),
            const Color(0xFF0F172A).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFC5A059).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics,
                color: Color(0xFFC5A059),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Estadísticas Globales',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.bar_chart,
                  label: 'Total Usos',
                  value: totalUses.toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.speed,
                  label: 'Tiempo Promedio',
                  value: '${avgResponseTime.toStringAsFixed(1)}s',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle,
                  label: 'Tasa de Éxito',
                  value: '${(avgSuccessRate * 100).toStringAsFixed(0)}%',
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
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
            size: 18,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFC5A059).withValues(alpha: 0.15),
            const Color(0xFFC5A059).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFC5A059).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.psychology,
                color: Color(0xFFC5A059),
                size: 32,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Inteligencia Artificial Legal',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ulpiano, tu asistente jurídico de IA: consulta la ley y la '
            'jurisprudencia con fuentes verificables, redacta escritos con '
            'estilo forense, analiza documentos y calcula penas con precisión '
            'profesional.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String badge,
    required String description,
    required List<String> highlights,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC5A059),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC5A059).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con icono y badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC5A059).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFC5A059).withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFFC5A059),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFFC5A059),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Descripción
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),

                // Highlights
                ...highlights.map((highlight) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            highlight.substring(0, 2),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              highlight.substring(3),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),

                // Botón de acción
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5A059),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC5A059).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF0F172A),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Analizar mi caso',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? badge,
    required String description,
    required String stats,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título con badge opcional
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              badge,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Descripción
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Stats
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: iconColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.speed,
                              color: iconColor,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              stats,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: iconColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Flecha
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFFC5A059).withValues(alpha: 0.8),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Impulsado por Ulpiano',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Todas las herramientas utilizan modelos de IA avanzados especializados '
            'en derecho penal venezolano para garantizar precisión y confiabilidad.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

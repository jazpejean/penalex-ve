import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/estrategia_legal.dart';
import '../services/comparador_service.dart';
import 'redactor_documentos_screen.dart';
import '../services/chat_legal_export_service.dart';
import '../services/membrete_service.dart';

class ComparadorEstrategiasScreen extends StatefulWidget {
  final String? casoId;

  const ComparadorEstrategiasScreen({super.key, this.casoId});

  @override
  State<ComparadorEstrategiasScreen> createState() =>
      _ComparadorEstrategiasScreenState();
}

class _ComparadorEstrategiasScreenState
    extends State<ComparadorEstrategiasScreen> {
  final ComparadorService _comparadorService = ComparadorService();

  String? _casoId;
  List<EstrategiaLegal>? _estrategias;
  bool _cargando = false;
  String? _error;

  // Contexto del caso (para pasar al redactor al redactar un escrito)
  String _descripcionCaso = '';
  List<String> _delitos = [];
  String _etapaProcesal = '';

  @override
  void initState() {
    super.initState();
    if (widget.casoId != null) {
      _casoId = widget.casoId;
    }
  }

  Future<void> _generarEstrategias() async {
    if (_casoId == null) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final estrategias =
          await _comparadorService.generarEstrategiasParaCaso(
        casoId: _casoId!,
        descripcionCaso: 'Caso legal para análisis',
        delitos: ['Delito a analizar'],
        etapaProcesal: 'investigacion',
        cantidadEstrategias: 3,
      );

      setState(() => _estrategias = estrategias);
    } catch (e) {
      setState(() => _error = 'Error generando estrategias: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _guardarComparacion() async {
    if (_estrategias == null || _estrategias!.isEmpty) return;

    try {
      await _comparadorService.crearComparacion(
        titulo: 'Estrategias para caso ${_casoId ?? ""}',
        casoId: _casoId ?? '',
        estrategias: _estrategias!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comparación guardada exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparador de Estrategias'),
        actions: [
          if (_estrategias != null && _estrategias!.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.download),
              tooltip: 'Exportar comparación',
              onSelected: _exportarComparacion,
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'pdf', child: Text('Exportar PDF')),
                PopupMenuItem(value: 'word', child: Text('Exportar Word')),
              ],
            ),
          if (_estrategias != null && _estrategias!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _guardarComparacion,
              tooltip: 'Guardar comparación',
            ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _mostrarHistorial(),
            tooltip: 'Ver historial',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generando estrategias con IA...'),
            SizedBox(height: 8),
            Text(
              'Esto puede tomar 10-30 segundos',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _error = null);
                if (_casoId != null) _generarEstrategias();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_casoId == null) {
      return _buildSeleccionarCaso();
    }

    if (_estrategias == null) {
      return _buildVistaInicial();
    }

    return _buildComparacion();
  }

  Widget _buildSeleccionarCaso() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Icon(Icons.psychology, size: 80, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Comparador de Estrategias Legales',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Análisis estratégico con IA para tomar mejores decisiones',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Opción principal: Crear caso nuevo
            Card(
              elevation: 4,
              child: InkWell(
                onTap: _crearCasoNuevo,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_circle,
                          size: 48,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nuevo Análisis',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Describe tu caso y comparte documentos para generar estrategias legales con IA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            const Text('o', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            
            // Opción secundaria: Cargar caso existente
            OutlinedButton.icon(
              onPressed: _cargarCasoExistente,
              icon: const Icon(Icons.folder_open),
              label: const Text('Cargar Caso Existente'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                side: const BorderSide(color: Colors.purple, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVistaInicial() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCasoCard(),
          const SizedBox(height: 24),
          const Text(
            '¿Qué es el Comparador de Estrategias?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.psychology,
            title: 'Análisis Inteligente',
            description:
                'Genera múltiples estrategias legales usando IA avanzada, '
                'cada una con enfoque y tácticas diferentes.',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.compare_arrows,
            title: 'Comparación Detallada',
            description:
                'Compara lado a lado probabilidades de éxito, beneficios, '
                'riesgos y jurisprudencia de respaldo.',
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.trending_up,
            title: 'Decisión Informada',
            description:
                'Toma decisiones estratégicas basadas en análisis objetivo '
                'con scores ponderados y métricas clave.',
          ),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton.icon(
              onPressed: _generarEstrategias,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generar Estrategias con IA'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCasoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder, color: Colors.purple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Caso $_casoId',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _seleccionarCaso,
                  child: const Text('Cambiar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.purple, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparacion() {
    final estrategiasOrdenadas = List<EstrategiaLegal>.from(_estrategias!);
    estrategiasOrdenadas
        .sort((a, b) => b.scorePonderado.compareTo(a.scorePonderado));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.purple.shade50,
          child: Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mejor estrategia: ${estrategiasOrdenadas.first.titulo}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                'Score: ${(estrategiasOrdenadas.first.scorePonderado * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: estrategiasOrdenadas.length,
            itemBuilder: (context, index) {
              final estrategia = estrategiasOrdenadas[index];
              return _buildEstrategiaCard(estrategia, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEstrategiaCard(EstrategiaLegal estrategia, int ranking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor:
              ranking == 1 ? Colors.amber : Colors.purple.shade100,
          child: Text(
            '#$ranking',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: ranking == 1 ? Colors.black : Colors.purple,
            ),
          ),
        ),
        title: Text(
          estrategia.titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(estrategia.tipo.nombre),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Métricas principales
                Row(
                  children: [
                    _buildMetrica(
                      'Éxito',
                      '${(estrategia.probabilidadExito * 100).toStringAsFixed(0)}%',
                      Colors.green,
                    ),
                    const SizedBox(width: 16),
                    _buildMetrica(
                      'Score',
                      '${(estrategia.scorePonderado * 100).toStringAsFixed(0)}%',
                      Colors.purple,
                    ),
                    const SizedBox(width: 16),
                    _buildMetrica(
                      'Duración',
                      '${estrategia.duracionEstimadaDias}d',
                      Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    _buildMetrica(
                      'Costo',
                      estrategia.costoMaximoUSD > 0
                          ? '\$${(estrategia.costoMaximoUSD / 1000).toStringAsFixed(1)}k'
                          : '-',
                      Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),

                // Descripción
                const SizedBox(height: 16),
                const Text(
                  'Descripción',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(estrategia.descripcion),

                // Beneficios
                const SizedBox(height: 16),
                const Text(
                  'Beneficios',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                ...estrategia.beneficios.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(b.descripcion)),
                          Text(
                            '${(b.impacto * 100).toInt()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    )),

                // Riesgos
                const SizedBox(height: 16),
                const Text(
                  'Riesgos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                ...estrategia.riesgos.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.warning,
                              color: _getColorRiesgo(r.nivel), size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(r.descripcion)),
                          Text(
                            '${(r.probabilidad * 100).toInt()}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getColorRiesgo(r.nivel),
                            ),
                          ),
                        ],
                      ),
                    )),

                // Requisitos
                if (estrategia.requisitos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Requisitos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...estrategia.requisitos.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_right, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(r)),
                          ],
                        ),
                      )),
                ],

                // Jurisprudencia
                if (estrategia.jurisprudencia.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Jurisprudencia de Respaldo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...estrategia.jurisprudencia.map((j) => Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                j.sentenciaId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${j.ponente} - ${j.fecha.day}/${j.fecha.month}/${j.fecha.year}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(j.extracto),
                            ],
                          ),
                        ),
                      )),
                ],

                // Costo
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Costo estimado: ${estrategia.costoEstimado}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                // Acción: redactar el escrito correspondiente
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _abrirRedactor(estrategia),
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('Redactar escrito'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: const Color(0xFFC5A059),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _construirMarkdownComparacion() {
    final estrategias = _estrategias ?? [];
    final buffer = StringBuffer();
    buffer.writeln('# Comparación de Estrategias');
    if (_descripcionCaso.isNotEmpty) buffer.writeln('**Caso:** $_descripcionCaso');
    if (_delitos.isNotEmpty) buffer.writeln('**Delitos:** ${_delitos.join(', ')}');
    if (_etapaProcesal.isNotEmpty) buffer.writeln('**Etapa:** $_etapaProcesal');
    buffer.writeln();

    final ordenadas = List<EstrategiaLegal>.from(estrategias)
      ..sort((a, b) => b.scorePonderado.compareTo(a.scorePonderado));

    for (var i = 0; i < ordenadas.length; i++) {
      final e = ordenadas[i];
      buffer.writeln('## ${i + 1}. ${e.titulo}');
      buffer.writeln('**Tipo:** ${e.tipo.nombre} · '
          '**Éxito:** ${(e.probabilidadExito * 100).toStringAsFixed(0)}% · '
          '**Score:** ${(e.scorePonderado * 100).toStringAsFixed(0)}%');
      buffer.writeln('**Duración:** ${e.duracionEstimadaDias} días · '
          '**Costo:** ${e.costoEstimado}');
      buffer.writeln();
      buffer.writeln(e.descripcion);
      buffer.writeln();
      if (e.beneficios.isNotEmpty) {
        buffer.writeln('**Beneficios:**');
        for (final b in e.beneficios) {
          buffer.writeln('- ${b.descripcion} (${(b.impacto * 100).toStringAsFixed(0)}%)');
        }
        buffer.writeln();
      }
      if (e.riesgos.isNotEmpty) {
        buffer.writeln('**Riesgos:**');
        for (final r in e.riesgos) {
          buffer.writeln('- ${r.descripcion} (${r.nivel.nombre}, ${(r.probabilidad * 100).toStringAsFixed(0)}%)');
        }
        buffer.writeln();
      }
      if (e.requisitos.isNotEmpty) {
        buffer.writeln('**Requisitos:**');
        for (final r in e.requisitos) buffer.writeln('- $r');
        buffer.writeln();
      }
      if (e.pasos.isNotEmpty) {
        buffer.writeln('**Pasos:**');
        for (final p in e.pasos) buffer.writeln('- $p');
        buffer.writeln();
      }
      if (e.jurisprudencia.isNotEmpty) {
        buffer.writeln('**Jurisprudencia de respaldo:**');
        for (final j in e.jurisprudencia) {
          buffer.writeln('- ${j.sentenciaId} · ${j.ponente} · '
              '${j.fecha.day}/${j.fecha.month}/${j.fecha.year}: ${j.extracto}');
        }
        buffer.writeln();
      }
    }
    return buffer.toString().trim();
  }

  Future<void> _exportarComparacion(String formato) async {
    final markdown = _construirMarkdownComparacion();
    if (markdown.isEmpty) return;

    final config = await MembreteService.obtenerConfig();
    String? ruta;
    if (formato == 'pdf') {
      ruta = await ChatLegalExportService.exportarTextoAPDF(
        markdown,
        titulo: 'Comparación de Estrategias',
        membreteUrl: config.url,
        alineacion: config.alineacion,
        tamano: config.tamano,
      );
    } else {
      ruta = await ChatLegalExportService.exportarTextoAWord(
        markdown,
        titulo: 'Comparación de Estrategias',
        membreteUrl: config.url,
        alineacion: config.alineacion,
        tamano: config.tamano,
      );
    }

    if (ruta != null) {
      await Share.shareXFiles([XFile(ruta)], text: 'Comparación de Estrategias');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Comparación exportada')),
        );
      }
    }
  }

  String _instruccionConContexto(EstrategiaLegal estrategia) {
    final buffer = StringBuffer(estrategia.tipo.instruccionRedaccion);
    if (_descripcionCaso.trim().isNotEmpty) {
      buffer.write('\n\nContexto del caso: ${_descripcionCaso.trim()}');
    }
    if (_delitos.isNotEmpty) {
      buffer.write('\nDelitos: ${_delitos.join(', ')}');
    }
    if (_etapaProcesal.trim().isNotEmpty) {
      buffer.write('\nEtapa procesal: ${_etapaProcesal.trim()}');
    }
    return buffer.toString();
  }

  void _abrirRedactor(EstrategiaLegal estrategia) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RedactorDocumentosScreen(
          initialPrompt: _instruccionConContexto(estrategia),
        ),
      ),
    );
  }

  Widget _buildMetrica(String label, String valor, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorRiesgo(NivelRiesgo nivel) {
    switch (nivel) {
      case NivelRiesgo.bajo:
        return Colors.yellow.shade700;
      case NivelRiesgo.medio:
        return Colors.orange;
      case NivelRiesgo.alto:
        return Colors.red;
      case NivelRiesgo.muyAlto:
        return Colors.red.shade900;
    }
  }

  Future<void> _seleccionarCaso() async {
    // Método antiguo - mantener para compatibilidad
    await _cargarCasoExistente();
  }

  Future<void> _crearCasoNuevo() async {
    // Mostrar diálogo para crear caso nuevo con descripción y documentos
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _DialogoCasoNuevo(),
    );

    if (resultado != null) {
      final String descripcion = resultado['descripcion'] ?? '';
      final List<String> delitos = resultado['delitos'] ?? [];
      final String etapa = resultado['etapa'] ?? 'investigacion';
      
      // Generar ID único para el caso
      final casoId = 'CASO_${DateTime.now().millisecondsSinceEpoch}';
      
      setState(() {
        _casoId = casoId;
        _estrategias = null;
      });

      // Auto-iniciar generación de estrategias
      await _generarEstrategiasConDatos(
        descripcion: descripcion,
        delitos: delitos,
        etapa: etapa,
      );
    }
  }

  Future<void> _cargarCasoExistente() async {
    // Mostrar lista de casos guardados o permitir ingresar ID
    final TextEditingController controller = TextEditingController();
    
    final casoId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cargar Caso Existente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ingresa el ID de un caso previamente guardado:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'ID del caso',
                hintText: 'Ej: CASO-2024-001',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Cargar'),
          ),
        ],
      ),
    );

    if (casoId != null && casoId.isNotEmpty) {
      setState(() {
        _casoId = casoId;
        _estrategias = null;
      });
    }
  }

  Future<void> _generarEstrategiasConDatos({
    required String descripcion,
    required List<String> delitos,
    required String etapa,
  }) async {
    if (_casoId == null) return;

    setState(() {
      _cargando = true;
      _error = null;
      _descripcionCaso = descripcion;
      _delitos = delitos;
      _etapaProcesal = etapa;
    });

    try {
      final estrategias = await _comparadorService.generarEstrategiasParaCaso(
        casoId: _casoId!,
        descripcionCaso: descripcion,
        delitos: delitos,
        etapaProcesal: etapa,
        cantidadEstrategias: 3,
      );

      setState(() => _estrategias = estrategias);
    } catch (e) {
      setState(() => _error = 'Error generando estrategias: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _mostrarHistorial() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HistorialComparacionesScreen(),
      ),
    );
  }
}

/// Pantalla de historial de comparaciones
class HistorialComparacionesScreen extends StatefulWidget {
  const HistorialComparacionesScreen({super.key});

  @override
  State<HistorialComparacionesScreen> createState() =>
      _HistorialComparacionesScreenState();
}

class _HistorialComparacionesScreenState
    extends State<HistorialComparacionesScreen> {
  final ComparadorService _comparadorService = ComparadorService();
  late Future<List<ComparacionEstrategias>> _future;

  @override
  void initState() {
    super.initState();
    _future = _comparadorService.obtenerComparaciones();
  }

  void _recargar() {
    setState(() => _future = _comparadorService.obtenerComparaciones());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Comparaciones'),
      ),
      body: FutureBuilder<List<ComparacionEstrategias>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final comparaciones = snapshot.data ?? [];

          if (comparaciones.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay comparaciones guardadas'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: comparaciones.length,
            itemBuilder: (context, index) {
              final comparacion = comparaciones[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.compare_arrows),
                  title: Text(comparacion.titulo),
                  subtitle: Text(
                    '${comparacion.estrategias.length} estrategias - ${comparacion.fechaCreacion.day}/${comparacion.fechaCreacion.month}/${comparacion.fechaCreacion.year}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirmar'),
                          content: const Text('¿Eliminar esta comparación?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await _comparadorService
                            .eliminarComparacion(comparacion.id);
                        _recargar();
                      }
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetalleComparacionScreen(
                          comparacion: comparacion,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Pantalla de detalles de una comparación guardada
class DetalleComparacionScreen extends StatelessWidget {
  final ComparacionEstrategias comparacion;

  const DetalleComparacionScreen({super.key, required this.comparacion});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(comparacion.titulo),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comparación guardada el ${comparacion.fechaCreacion.day}/${comparacion.fechaCreacion.month}/${comparacion.fechaCreacion.year}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (comparacion.notas != null) ...[
                    const SizedBox(height: 8),
                    Text(comparacion.notas!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...comparacion.estrategiasOrdenadas.asMap().entries.map((entry) {
            final index = entry.key;
            final estrategia = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: index == 0
                              ? Colors.amber
                              : Colors.purple.shade100,
                          child: Text('#${index + 1}'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                estrategia.titulo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                estrategia.tipo.nombre,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${(estrategia.scorePonderado * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(estrategia.descripcion),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Diálogo para crear un caso nuevo
class _DialogoCasoNuevo extends StatefulWidget {
  const _DialogoCasoNuevo();

  @override
  State<_DialogoCasoNuevo> createState() => _DialogoCasoNuevoState();
}

class _DialogoCasoNuevoState extends State<_DialogoCasoNuevo> {
  final _descripcionController = TextEditingController();
  final _delitosController = TextEditingController();
  String _etapaSeleccionada = 'investigacion';

  @override
  void dispose() {
    _descripcionController.dispose();
    _delitosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear Nuevo Análisis'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Describe el caso que deseas analizar:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descripcionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Descripción del caso',
                hintText: 'Ej: Cliente acusado de hurto calificado. Se alega que sustrajo mercancía de un comercio...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Delitos imputados:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _delitosController,
              decoration: const InputDecoration(
                labelText: 'Delitos (separados por comas)',
                hintText: 'Ej: Hurto calificado, Asociación ilícita',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Etapa procesal:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _etapaSeleccionada,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'investigacion',
                  child: Text('Investigación'),
                ),
                DropdownMenuItem(
                  value: 'control',
                  child: Text('Control'),
                ),
                DropdownMenuItem(
                  value: 'juicio',
                  child: Text('Juicio'),
                ),
                DropdownMenuItem(
                  value: 'ejecucion',
                  child: Text('Ejecución'),
                ),
                DropdownMenuItem(
                  value: 'recursos',
                  child: Text('Recursos'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _etapaSeleccionada = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (_descripcionController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Por favor, describe el caso'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            final delitos = _delitosController.text
                .split(',')
                .map((d) => d.trim())
                .where((d) => d.isNotEmpty)
                .toList();

            if (delitos.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Por favor, indica al menos un delito'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            Navigator.pop(context, {
              'descripcion': _descripcionController.text.trim(),
              'delitos': delitos,
              'etapa': _etapaSeleccionada,
            });
          },
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Generar Estrategias'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

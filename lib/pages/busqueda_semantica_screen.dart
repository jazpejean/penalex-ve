import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../pages/main_screen.dart';
import '../utils/main_tab_controller.dart';
import '../services/busqueda_semantica_service.dart';
import '../models/sentencia.dart';
import '../models/ley.dart';

class BusquedaSemanticaScreen extends StatefulWidget {
  const BusquedaSemanticaScreen({super.key});

  @override
  State<BusquedaSemanticaScreen> createState() =>
      _BusquedaSemanticaScreenState();
}

class _BusquedaSemanticaScreenState extends State<BusquedaSemanticaScreen> {
  final BusquedaSemanticaService _busquedaService =
      BusquedaSemanticaService();
  final TextEditingController _searchController = TextEditingController();

  ResultadosBusquedaUnificados? _resultados;
  List<String> _sugerencias = [];
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final consulta = _searchController.text.trim();
    if (consulta.isEmpty) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultados = await _busquedaService.buscarUnificado(
        consulta: consulta,
        limitePorFuente: 10,
        umbralSimilitud: 0.2,
      );

      await _busquedaService.guardarEnHistorial(
        consulta: consulta,
        resultados: resultados,
      );

      setState(() => _resultados = resultados);
    } catch (e) {
      setState(() => _error = 'Error en búsqueda: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _buscarSugerencias(String texto) async {
    if (texto.length < 3) {
      setState(() => _sugerencias = []);
      return;
    }

    try {
      final sugerencias =
          await _busquedaService.sugerirConsultas(texto);
      setState(() => _sugerencias = sugerencias);
    } catch (e) {
      setState(() => _sugerencias = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
      appBar: AppBar(
        title: Text('Búsqueda Semántica', style: TextStyle(color: TemaGlobal.dorado, fontWeight: FontWeight.bold)),
        backgroundColor: TemaGlobal.azulMarino,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFC5A059)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _mostrarHistorial(),
            tooltip: 'Historial',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _mostrarAyuda(),
            tooltip: 'Ayuda',
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
      ),
      body: Column(
        children: [
          _buildBarraBusqueda(),
          if (_sugerencias.isNotEmpty) _buildSugerencias(),
          Expanded(child: _buildContenido()),
        ],
      ),
    );
  }

  Widget _buildBarraBusqueda() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaGlobal.capa,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar en leyes y jurisprudencia...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _resultados = null;
                            _sugerencias = [];
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: TemaGlobal.campoTexto,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _buscarSugerencias,
              onSubmitted: (_) => _buscar(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _cargando ? null : _buscar,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _cargando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
          ),
        ],
      ),
    );
  }

  Widget _buildSugerencias() {
    return Container(
      color: TemaGlobal.superficie,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Búsquedas recientes',
              style: TextStyle(
                fontSize: 12,
                color: TemaGlobal.textoSecundario,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ..._sugerencias.map((sugerencia) => ListTile(
                dense: true,
                leading: const Icon(Icons.history, size: 20),
                title: Text(sugerencia),
                onTap: () {
                  _searchController.text = sugerencia;
                  setState(() => _sugerencias = []);
                  _buscar();
                },
              )),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    if (_cargando) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Buscando con IA semántica...'),
            const SizedBox(height: 8),
            Text(
              'Esto puede tomar unos segundos',
              style: TextStyle(fontSize: 12, color: TemaGlobal.textoTenue),
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
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _buscar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_resultados == null) {
      return _buildVistaInicial();
    }

    if (!_resultados!.hayResultados) {
      return _buildSinResultados();
    }

    return _buildResultados();
  }

  Widget _buildVistaInicial() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.manage_search,
                size: 100, color: TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino),
            const SizedBox(height: 24),
            const Text(
              'Búsqueda Semántica Inteligente',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Busca usando lenguaje natural. La IA encuentra contenido relevante '
              'aunque no uses las palabras exactas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: TemaGlobal.textoSecundario, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildEjemploChip('¿Qué es la prisión preventiva?'),
                _buildEjemploChip('Casos de legítima defensa'),
                _buildEjemploChip('Derechos del imputado'),
                _buildEjemploChip('Recursos de apelación'),
                _buildEjemploChip('Circunstancias atenuantes'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEjemploChip(String texto) {
    return ActionChip(
      label: Text(texto),
      onPressed: () {
        _searchController.text = texto;
        _buscar();
      },
    );
  }

  Widget _buildSinResultados() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: TemaGlobal.textoTenue),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron resultados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'para "${_resultados!.consulta}"',
              textAlign: TextAlign.center,
              style: TextStyle(color: TemaGlobal.textoSecundario),
            ),
            const SizedBox(height: 24),
            const Text(
              'Intenta con:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text('• Palabras más generales'),
            const Text('• Diferentes términos legales'),
            const Text('• Frases más cortas'),
          ],
        ),
      ),
    );
  }

  Widget _buildResultados() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Resumen
        Card(
          color: TemaGlobal.tarjeta,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.analytics, color: Color(0xFFC5A059)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_resultados!.totalResultados} resultados encontrados',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${_resultados!.sentencias.length} sentencias • ${_resultados!.leyes.length} artículos',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Sentencias
        if (_resultados!.sentencias.isNotEmpty) ...[
          const Text(
            'Jurisprudencia',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._resultados!.sentencias.map((resultado) =>
              _buildSentenciaCard(resultado)),
          const SizedBox(height: 24),
        ],

        // Leyes
        if (_resultados!.leyes.isNotEmpty) ...[
          const Text(
            'Legislación',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._resultados!.leyes.map((resultado) => _buildLeyCard(resultado)),
        ],
      ],
    );
  }

  Widget _buildSentenciaCard(ResultadoBusqueda<Sentencia> resultado) {
    final sentencia = resultado.item;
    final similitud = (resultado.similitud * 100).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navegar a detalle de sentencia cuando exista la pantalla
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sentencia: ${sentencia.numero}')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getColorSimilitud(resultado.similitud),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$similitud% relevante',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.gavel, size: 16, color: Color(0xFFC5A059)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      sentencia.numero,
                      style: TextStyle(
                        fontSize: 12,
                        color: TemaGlobal.textoSecundario,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                sentencia.sala,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                resultado.extractoRelevante,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: TemaGlobal.textoTenue),
                  const SizedBox(width: 4),
                  Text(
                    '${sentencia.fecha.day}/${sentencia.fecha.month}/${sentencia.fecha.year}',
                    style: TextStyle(fontSize: 12, color: TemaGlobal.textoTenue),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeyCard(ResultadoBusqueda<Ley> resultado) {
    final ley = resultado.item;
    final similitud = (resultado.similitud * 100).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navegar a detalle de ley cuando exista la pantalla
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ley: ${ley.titulo}')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getColorSimilitud(resultado.similitud),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$similitud% relevante',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.article, size: 16, color: Color(0xFFC5A059)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ley.nombreCorto,
                      style: TextStyle(
                        fontSize: 12,
                        color: TemaGlobal.textoSecundario,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ley.titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                resultado.extractoRelevante,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (ley.capitulos.isNotEmpty)
                    Text(
                      'Cap. ${ley.capitulos.first.numero}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: TemaGlobal.textoSecundario,
                      ),
                    ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorSimilitud(double similitud) {
    if (similitud >= 0.7) {
      return TemaGlobal.isDark
          ? const Color(0xFF4ADE80)
          : const Color(0xFF15803D);
    }
    if (similitud >= 0.5) {
      return TemaGlobal.isDark
          ? const Color(0xFFFBBF24)
          : const Color(0xFFC2410C);
    }
    return TemaGlobal.textoTenue;
  }

  void _mostrarHistorial() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historial de Búsquedas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<HistorialBusqueda>>(
                stream: _busquedaService.obtenerHistorial(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final historial = snapshot.data ?? [];

                  if (historial.isEmpty) {
                    return const Center(
                      child: Text('No hay búsquedas recientes'),
                    );
                  }

                  return ListView.builder(
                    itemCount: historial.length,
                    itemBuilder: (context, index) {
                      final item = historial[index];
                      return ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(item.consulta),
                        subtitle: Text(
                          '${item.cantidadSentencias + item.cantidadLeyes} resultados',
                        ),
                        trailing: Text(
                          '${item.timestamp.day}/${item.timestamp.month}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _searchController.text = item.consulta;
                          _buscar();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarAyuda() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cómo funciona?'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Búsqueda Semántica con IA',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Esta herramienta usa inteligencia artificial para entender '
                'el significado de tu búsqueda, no solo las palabras exactas.',
              ),
              SizedBox(height: 16),
              Text(
                '✓ Escribe en lenguaje natural',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'Ej: "¿Cuándo procede la legítima defensa?"',
              ),
              SizedBox(height: 12),
              Text(
                '✓ Usa conceptos, no solo palabras clave',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'La IA encuentra contenido relacionado aunque uses términos diferentes.',
              ),
              SizedBox(height: 12),
              Text(
                '✓ Porcentaje de relevancia',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'Los resultados muestran qué tan relevantes son para tu búsqueda.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

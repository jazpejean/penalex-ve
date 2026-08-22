import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/sentencia_model.dart';
import '../services/jurisprudencia_service.dart';
import '../services/ai_service.dart';
import '../widgets/app_drawer.dart';

class RepositorioJurisprudenciaScreen extends StatefulWidget {
  const RepositorioJurisprudenciaScreen({super.key});

  @override
  State<RepositorioJurisprudenciaScreen> createState() =>
      _RepositorioJurisprudenciaScreenState();
}

class _RepositorioJurisprudenciaScreenState
    extends State<RepositorioJurisprudenciaScreen> with SingleTickerProviderStateMixin {
  final JurisprudenciaService _service = JurisprudenciaService();
  final TextEditingController _searchController = TextEditingController();

  List<SentenciaModel> _resultados = [];
  List<SentenciaModel> _todosResultados = [];

  bool _cargando = false;
  
  // ✅ Filtros nuevos
  String _tipoSeleccionado = 'Sentencias';
  String? _salaSeleccionada;
  int? _anioSeleccionado;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Colores de la app
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color fondoGris = Color(0xFFF1F5F9);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _buscar(); // ✅ Cargar sentencias al inicio
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    setState(() => _cargando = true);
    _animationController.forward();

    String tipoParam = 'sentencia';
    if (_tipoSeleccionado == 'Jurisprudencias') {
      tipoParam = 'jurisprudencia';
    } else if (_tipoSeleccionado == 'Resoluciones') {
      tipoParam = 'resoluciones';
    }

    // ✅ Búsqueda con filtros
    final resultados = await _service.buscarDocumentos(
      textoBusqueda: _searchController.text.trim(),
      tipo: tipoParam,
      sala: _salaSeleccionada,
      anio: _anioSeleccionado,
      limit: 50,
    );

    if (mounted) {
      setState(() {
        _todosResultados = resultados;
        _resultados = resultados; // Ya vienen ordenados por relevancia
        
        // ✅ Si Firebase está vacío, mostrar datos de ejemplo
        if (_resultados.isEmpty && _searchController.text.isEmpty) {
          _resultados = _obtenerSentenciasEjemplo();
          _todosResultados = _resultados;
        }
        
        _cargando = false;
      });
    }
  }
  
  // Datos de ejemplo cuando Firebase está vacío
  List<SentenciaModel> _obtenerSentenciasEjemplo() {
    return [
      SentenciaModel(
        id: 'ejemplo_1',
        tipo: 'sentencia',
        numeroSentencia: '234-2023',
        sala: 'Sala Penal',
        fechaSentencia: '15/08/2023',
        delito: 'Homicidio Calificado',
        ponente: 'Magistrado Juan Pérez',
        partes: 'Ministerio Público vs. Acusado',
        resumen: 'Recurso de apelación contra sentencia condenatoria por homicidio calificado. Se reduce pena de 25 a 18 años por falta de pruebas de premeditación.',
        extracto: 'Extracto de ejemplo de la sentencia...',
        decision: 'REVOCA PARCIALMENTE',
        contenidoCompleto: 'Sentencia de ejemplo...',
        tipoSentencia: 'Definitiva',
        materia: 'Penal',
        urlFichaPenalex: 'https://www.tsj.gob.ve',
        urlTSJ: 'https://www.tsj.gob.ve',
        urlHTML: '',
        urlTXT: '',
        esJurisprudencia: false,
        tienePDF: false,
        timestamp: DateTime.now(),
      ),
      SentenciaModel(
        id: 'ejemplo_2',
        tipo: 'sentencia',
        numeroSentencia: '156-2023',
        sala: 'Sala Penal',
        fechaSentencia: '22/07/2023',
        delito: 'Hurto Agravado',
        ponente: 'Magistrada María González',
        partes: 'Ministerio Público vs. Imputado',
        resumen: 'Recurso de casación por violación de garantías constitucionales. Tribunal anula proceso por violación del derecho a la defensa.',
        extracto: 'Extracto de ejemplo de la sentencia...',
        decision: 'DECLARA CON LUGAR',
        contenidoCompleto: 'Sentencia de ejemplo...',
        tipoSentencia: 'Definitiva',
        materia: 'Penal',
        urlFichaPenalex: 'https://www.tsj.gob.ve',
        urlTSJ: 'https://www.tsj.gob.ve',
        urlHTML: '',
        urlTXT: '',
        esJurisprudencia: true,
        tienePDF: false,
        timestamp: DateTime.now(),
      ),
      SentenciaModel(
        id: 'ejemplo_3',
        tipo: 'sentencia',
        numeroSentencia: '089-2023',
        sala: 'Sala de Casación Penal',
        fechaSentencia: '10/06/2023',
        delito: 'Violencia de Género',
        ponente: 'Magistrado Carlos Ramírez',
        partes: 'Víctima vs. Agresor',
        resumen: 'Medida de protección a víctima de violencia de género. Se ordena alejamiento del agresor y custodia de menores.',
        extracto: 'Extracto de ejemplo de la sentencia...',
        decision: 'DECLARA CON LUGAR',
        contenidoCompleto: 'Sentencia de ejemplo...',
        tipoSentencia: 'Medida Cautelar',
        materia: 'Penal',
        urlFichaPenalex: 'https://www.tsj.gob.ve',
        urlTSJ: 'https://www.tsj.gob.ve',
        urlHTML: '',
        urlTXT: '',
        esJurisprudencia: false,
        tienePDF: false,
        timestamp: DateTime.now(),
      ),
      SentenciaModel(
        id: 'ejemplo_4',
        tipo: 'sentencia',
        numeroSentencia: '312-2023',
        sala: 'Sala Penal',
        fechaSentencia: '03/09/2023',
        delito: 'Estafa Calificada',
        ponente: 'Magistrado Luis Fernández',
        partes: 'Víctima vs. Estafador',
        resumen: 'Condena por estafa calificada mediante engaño digital. Víctima perdió 50.000 USD en esquema piramidal. Pena de 8 años de prisión.',
        extracto: 'Extracto de ejemplo de la sentencia...',
        decision: 'CONDENA',
        contenidoCompleto: 'Sentencia de ejemplo...',
        tipoSentencia: 'Definitiva',
        materia: 'Penal',
        urlFichaPenalex: 'https://www.tsj.gob.ve',
        urlTSJ: 'https://www.tsj.gob.ve',
        urlHTML: '',
        urlTXT: '',
        esJurisprudencia: false,
        tienePDF: false,
        timestamp: DateTime.now(),
      ),
      SentenciaModel(
        id: 'ejemplo_5',
        tipo: 'sentencia',
        numeroSentencia: '445-2023',
        sala: 'Sala de Casación Penal',
        fechaSentencia: '18/10/2023',
        delito: 'Lesiones Graves',
        ponente: 'Magistrada Ana López',
        partes: 'Ministerio Público vs. Acusado',
        resumen: 'Apelación por lesiones graves en riña callejera. Se confirma sentencia de 5 años por uso de arma blanca.',
        extracto: 'Extracto de ejemplo de la sentencia...',
        decision: 'CONFIRMA',
        contenidoCompleto: 'Sentencia de ejemplo...',
        tipoSentencia: 'Definitiva',
        materia: 'Penal',
        urlFichaPenalex: 'https://www.tsj.gob.ve',
        urlTSJ: 'https://www.tsj.gob.ve',
        urlHTML: '',
        urlTXT: '',
        esJurisprudencia: false,
        tienePDF: false,
        timestamp: DateTime.now(),
      ),
    ];
  }

  // Búsqueda ultra precisa con scoring
  List<SentenciaModel> _busquedaPrecisa(List<SentenciaModel> sentencias, String query) {
    if (query.isEmpty) return sentencias;

    final queryLower = query.toLowerCase();
    final palabras = queryLower.split(' ').where((p) => p.length > 2).toList();

    // Calcular score para cada sentencia
    final sentenciasConScore = sentencias.map((s) {
      double score = 0.0;

      // Coincidencia exacta en número (peso 100)
      if (s.numeroSentencia.toLowerCase().contains(queryLower)) {
        score += 100;
      }

      // Coincidencia exacta en delito (peso 80)
      if (s.delito.toLowerCase().contains(queryLower)) {
        score += 80;
      }

      // Coincidencia en resumen (peso 50)
      if (s.resumen.toLowerCase().contains(queryLower)) {
        score += 50;
      }

      // Coincidencia por palabras individuales
      for (final palabra in palabras) {
        if (s.numeroSentencia.toLowerCase().contains(palabra)) score += 20;
        if (s.delito.toLowerCase().contains(palabra)) score += 15;
        if (s.resumen.toLowerCase().contains(palabra)) score += 10;
        if (s.contenidoCompleto.toLowerCase().contains(palabra)) score += 5;
        if (s.partes.toLowerCase().contains(palabra)) score += 8;
        if (s.decision.toLowerCase().contains(palabra)) score += 8;
      }

      return {'sentencia': s, 'score': score};
    }).where((item) => (item['score'] as double) > 0).toList();

    // Ordenar por score
    sentenciasConScore.sort((a, b) => 
      (b['score'] as double).compareTo(a['score'] as double));

    return sentenciasConScore
        .map((item) => item['sentencia'] as SentenciaModel)
        .toList();
  }

  void _limpiarBusqueda() {
    setState(() {
      _searchController.clear();
      _tipoSeleccionado = 'Sentencias';
      _salaSeleccionada = null;
      _anioSeleccionado = null;
    });
    _buscar();
  }

  Widget _buildFiltros() {
    final int currentYear = DateTime.now().year;
    final List<int> years = List.generate(currentYear - 2000 + 1, (index) => currentYear - index);
    final List<String> salas = ['Todas', 'Sala de Casación Penal', 'Sala Constitucional'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Tipo
          ...['Sentencias', 'Jurisprudencias', 'Resoluciones'].map((tipo) {
            final isSelected = _tipoSeleccionado == tipo;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(tipo),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _tipoSeleccionado = tipo;
                      if (tipo != 'Sentencias' && tipo != 'Jurisprudencias') {
                        _salaSeleccionada = null;
                      }
                    });
                    _buscar();
                  }
                },
                selectedColor: dorado,
                backgroundColor: Colors.transparent,
                labelStyle: TextStyle(
                  color: isSelected ? azulMarino : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? dorado : Colors.white,
                  ),
                ),
                visualDensity: VisualDensity.compact,
                showCheckmark: false,
              ),
            );
          }),
          const SizedBox(width: 8),
          
          // Sala
          if (_tipoSeleccionado == 'Sentencias' || _tipoSeleccionado == 'Jurisprudencias')
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: PopupMenuButton<String>(
                initialValue: _salaSeleccionada ?? 'Todas',
                onSelected: (String value) {
                  setState(() {
                    _salaSeleccionada = value == 'Todas' ? null : value;
                  });
                  _buscar();
                },
                itemBuilder: (BuildContext context) {
                  return salas.map((String sala) {
                    return PopupMenuItem<String>(
                      value: sala,
                      child: Text(sala),
                    );
                  }).toList();
                },
                child: Chip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_salaSeleccionada ?? 'Sala (Todas)'),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
                    ],
                  ),
                  backgroundColor: Colors.transparent,
                  labelStyle: const TextStyle(color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.white),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            
          // Año
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: PopupMenuButton<int?>(
              initialValue: _anioSeleccionado,
              onSelected: (int? value) {
                setState(() {
                  _anioSeleccionado = value;
                });
                _buscar();
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem<int?>(
                    value: null,
                    child: Text('Todos los años'),
                  ),
                  ...years.map((int year) {
                    return PopupMenuItem<int?>(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }),
                ];
              },
              child: Chip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_anioSeleccionado?.toString() ?? 'Año (Todos)'),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
                  ],
                ),
                backgroundColor: Colors.transparent,
                labelStyle: const TextStyle(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.white),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/repositorio_jurisprudencia'),
      appBar: AppBar(
        title: const Text(
          'Jurisprudencia TSJ',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: azulMarino,
        foregroundColor: dorado,
        elevation: 0,
        actions: [
          // ✅ Contador de resultados simple
          if (!_cargando && _resultados.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_resultados.length} ${_resultados.length == 1 ? "resultado" : "resultados"}',
                  style: const TextStyle(
                    color: dorado,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      backgroundColor: fondoGris,
      body: Column(
        children: [
          // ✅ Barra de búsqueda SIMPLE y clara
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: azulMarino,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Buscar por número, delito, partes...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 15,
                    ),
                    prefixIcon: const Icon(Icons.search, color: dorado, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: dorado, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                              _buscar();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: dorado, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) => _buscar(),
                  onChanged: (value) {
                    setState(() {});
                    if (value.isEmpty) {
                      _buscar();
                    }
                  },
                ),
                const SizedBox(height: 8),
                // ✅ Ayuda sutil con indicador de búsqueda semántica
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: dorado.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(
                      'Búsqueda inteligente: prueba "matar", "robar", "drogas"...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFiltros(),
              ],
            ),
          ),

          // ✅ Lista de resultados limpia
          Expanded(
            child: _cargando
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: dorado,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Buscando sentencias...',
                          style: TextStyle(
                            color: azulMarino.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : _resultados.isEmpty
                    ? _buildEmptyState()
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _resultados.length,
                          itemBuilder: (context, index) {
                            return _buildSentenciaCard(_resultados[index], index);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: azulMarino.withOpacity(0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'No se encontraron resultados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: azulMarino.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Intenta con otros términos de búsqueda',
              style: TextStyle(
                fontSize: 14,
                color: azulMarino.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _limpiarBusqueda,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Limpiar búsqueda'),
              style: ElevatedButton.styleFrom(
                backgroundColor: azulMarino,
                foregroundColor: dorado,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentenciaCard(SentenciaModel sentencia, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 200 + (index * 30)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shadowColor: azulMarino.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _verSentencia(sentencia),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Header simplificado
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: azulMarino,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sentencia.sala,
                        style: const TextStyle(
                          color: dorado,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ✅ Badge Vinculante
                    if (_tipoSeleccionado == 'Sentencias' && sentencia.esJurisprudencia) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD4A843), Color(0xFFE8C547)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: dorado.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: const Text(
                          '⚖️ Vinculante',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        'Nº ${sentencia.numeroSentencia}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: azulMarino,
                        ),
                      ),
                    ),
                    Text(
                      sentencia.fechaSentencia,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ✅ Delito (si existe)
                if (sentencia.delito.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.gavel, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          sentencia.delito,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // ✅ Resumen limpio
                if (sentencia.resumen.isNotEmpty)
                  Text(
                    sentencia.resumen,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.grey[700],
                    ),
                  ),

                // ✅ Acción simple
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Ver detalles →',
                    style: TextStyle(
                      color: azulMarino,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _verSentencia(SentenciaModel sentencia) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleSentenciaScreen(sentencia: sentencia),
      ),
    );
  }
}

// ============================================
// PANTALLA DE DETALLE CON BOTÓN IA FLOTANTE
// ============================================

class DetalleSentenciaScreen extends StatefulWidget {
  final SentenciaModel sentencia;

  const DetalleSentenciaScreen({super.key, required this.sentencia});

  @override
  State<DetalleSentenciaScreen> createState() => _DetalleSentenciaScreenState();
}

class _DetalleSentenciaScreenState extends State<DetalleSentenciaScreen> {
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  
  bool _mostrandoAnalisisIA = false;
  bool _analizando = false;
  AnalisisProfundoSentencia? _analisisProfundo;

  Future<void> _analizarConIA() async {
    setState(() {
      _mostrandoAnalisisIA = true;
      _analizando = true;
    });

    try {
      await AIService.inicializar();
      
      final analisis = await AIService.analizarSentenciaProfundo(
        numeroSentencia: widget.sentencia.numeroSentencia,
        sala: widget.sentencia.sala,
        delito: widget.sentencia.delito,
        ponente: widget.sentencia.ponente,
        resumen: widget.sentencia.resumen,
        decision: widget.sentencia.decision,
        partes: widget.sentencia.partes,
        contenidoCompleto: widget.sentencia.contenidoCompleto,
      );

      if (mounted) {
        setState(() {
          _analisisProfundo = analisis;
          _analizando = false;
        });
      }
    } catch (e) {
      debugPrint('Error en análisis IA: $e');
      if (mounted) {
        setState(() => _analizando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al analizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sentencia ${widget.sentencia.numeroSentencia}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: azulMarino,
        foregroundColor: dorado,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de compartir próximamente'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            tooltip: 'Compartir',
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView con la sentencia
          WebViewWidget(
            controller: WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..setBackgroundColor(Colors.white)
              ..loadRequest(Uri.parse(widget.sentencia.urlFichaPenalex)),
          ),

          // Botón flotante de IA (esquina inferior derecha)
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Panel de análisis IA
                if (_mostrandoAnalisisIA)
                  Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: dorado.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: dorado,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Análisis con IA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: azulMarino,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                setState(() => _mostrandoAnalisisIA = false);
                              },
                              color: Colors.grey[600],
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_analizando)
                          const Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(color: dorado),
                                SizedBox(height: 12),
                                Text(
                                  'Analizando sentencia con IA...',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        else if (_analisisProfundo != null)
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSeccionAnalisis(
                                  '📋 RESUMEN EJECUTIVO',
                                  _analisisProfundo!.resumenEjecutivo,
                                ),
                                const Divider(height: 24),
                                _buildSeccionAnalisis(
                                  '⚖️ RATIO DECIDENDI',
                                  _analisisProfundo!.ratioDecidendi,
                                ),
                                const Divider(height: 24),
                                _buildSeccionAnalisis(
                                  '🔑 PRECEDENTES Y CITAS CLAVE',
                                  _analisisProfundo!.precedentesClave,
                                ),
                                const Divider(height: 24),
                                _buildSeccionAnalisis(
                                  '💡 ARGUMENTOS LEGALES PRINCIPALES',
                                  _analisisProfundo!.argumentosPrincipales,
                                ),
                                const Divider(height: 24),
                                _buildSeccionAnalisis(
                                  '📊 IMPACTO Y APLICABILIDAD',
                                  _analisisProfundo!.impactoAplicabilidad,
                                ),
                                const Divider(height: 24),
                                _buildSeccionAnalisis(
                                  '⚠️ PUNTOS CRÍTICOS',
                                  _analisisProfundo!.puntosCriticos,
                                ),
                                const Divider(height: 24),
                                _buildSeccionAnalisis(
                                  '🎯 RECOMENDACIONES PRÁCTICAS',
                                  _analisisProfundo!.recomendacionesPracticas,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // TODO: Exportar análisis a PDF
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Exportar análisis próximamente'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                                  label: const Text('Exportar Análisis'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: azulMarino,
                                    foregroundColor: dorado,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAnalisisItem(
                                Icons.check_circle_outline,
                                'Tipo de Sentencia',
                                widget.sentencia.tipoSentencia,
                              ),
                              _buildAnalisisItem(
                                Icons.balance,
                                'Decisión',
                                widget.sentencia.decision,
                              ),
                              _buildAnalisisItem(
                                Icons.lightbulb_outline,
                                'Relevancia',
                                'Sentencia relacionada con ${widget.sentencia.delito}',
                              ),
                              const Divider(height: 24),
                              const Text(
                                '💡 Resumen:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: azulMarino,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.sentencia.resumen,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _analizarConIA,
                                icon: const Icon(Icons.psychology, size: 18),
                                label: const Text('Análisis Profundo con IA'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: azulMarino,
                                  foregroundColor: dorado,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                // Botón flotante de IA
                FloatingActionButton.extended(
                  onPressed: _analizarConIA,
                  backgroundColor: azulMarino,
                  foregroundColor: dorado,
                  elevation: 8,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text(
                    'Analizar con IA',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalisisItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: dorado),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: azulMarino,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionAnalisis(String titulo, String contenido) {
    if (contenido.isEmpty || contenido == 'No disponible') {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: azulMarino,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          contenido,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

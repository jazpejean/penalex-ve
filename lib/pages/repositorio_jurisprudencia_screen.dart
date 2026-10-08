import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import '../models/sentencia_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/jurisprudencia_service.dart';
import '../services/ai_service.dart';
import '../services/sentencia_pdf_service.dart';
import '../services/favoritos_service.dart';
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

  // ⭐ Favoritas / Importantes
  final FavoritosService _favoritosService = FavoritosService();
  Set<String> _idsFavoritos = {};
  bool _soloFavoritas = false;
  
  // ✅ Filtros nuevos
  String _tipoSeleccionado = 'Sentencias';
  String? _salaSeleccionada;
  int? _anioSeleccionado;
  final Set<String> _resumenGenerado = {};
  int? _mesSeleccionado;
  int? _diaSeleccionado;
  List<int> _mesesDisponibles = [];
  List<int> _diasDisponibles = [];
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Colores de la app
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFEAB308);
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
    _cargarFavoritos(); // ⭐ Cargar favoritas guardadas
    _buscar(); // ✅ Cargar sentencias al inicio
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _cargarMeses(int anio) async {
    final meses = await _service.obtenerMesesDisponibles(anio);
    if (mounted) setState(() => _mesesDisponibles = meses);
  }

  Future<void> _cargarDias(int anio, int mes) async {
    final dias = await _service.obtenerDiasDisponibles(anio, mes);
    if (mounted) setState(() => _diasDisponibles = dias);
  }

  String _nombreMes(int m) {
    const nombres = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return (m >= 1 && m <= 12) ? nombres[m - 1] : '$m';
  }

  Future<void> _rellenarResumenes() async {
    if (_resultados.isEmpty) return;
    for (final s in _resultados.take(5)) {
      if (_resumenGenerado.contains(s.id)) continue;
      if (s.resumen.isNotEmpty && s.resumen != 'null') continue;
      final texto = s.ratioDecidendi.isNotEmpty
          ? s.ratioDecidendi
          : (s.extracto.isNotEmpty ? s.extracto : s.decision);
      if (texto.isEmpty || texto == 'null') continue;
      _resumenGenerado.add(s.id);
      try {
        final resumen = await AIService.generarTesisJurisprudencial(texto);
        if (resumen.isNotEmpty) {
          await Supabase.instance.client
              .from('documentos')
              .update({'resumen_ia': resumen})
              .eq('id', s.id);
          debugPrint('✅ Resumen generado y guardado: ${s.id}');
        }
      } catch (e) {
        debugPrint('⚠️ Error generando resumen: $e');
      }
    }
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
      mes: _mesSeleccionado,
      dia: _diaSeleccionado,
      limit: 50,
    );

    if (mounted) {
      setState(() {
        _todosResultados = resultados;
        _resultados = resultados; // Ya vienen ordenados por relevancia
        
        // ✅ Si Supabase está vacío, mostrar datos de ejemplo
        if (_resultados.isEmpty && _searchController.text.isEmpty) {
          _resultados = _obtenerSentenciasEjemplo();
          _todosResultados = _resultados;
        }

        // ⭐ Aplicar filtro de favoritas si está activo
        _aplicarFiltroFavoritas();
        
        _cargando = false;
        _rellenarResumenes();
      });
    }
  }

  // ⭐ Favoritas / Importantes
  Future<void> _cargarFavoritos() async {
    // Sincronizar desde la nube (si hay sesión) y luego leer locales
    await _favoritosService.sincronizarDesdeNube();
    final ids = await _favoritosService.obtenerIdsFavoritas();
    if (mounted) {
      setState(() => _idsFavoritos = ids);
    }
  }

  void _aplicarFiltroFavoritas() {
    if (_soloFavoritas) {
      _resultados = _todosResultados
          .where((s) => _idsFavoritos.contains(s.id))
          .toList();
    } else {
      _resultados = _todosResultados;
    }
  }

  Future<void> _toggleFavorita(SentenciaModel sentencia) async {
    await _favoritosService.toggleFavorita(sentencia.id);
    if (!mounted) return;

    setState(() {
      if (_idsFavoritos.contains(sentencia.id)) {
        _idsFavoritos.remove(sentencia.id);
      } else {
        _idsFavoritos.add(sentencia.id);
      }
      if (_soloFavoritas) _aplicarFiltroFavoritas();
    });

    final esFavorita = _idsFavoritos.contains(sentencia.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          esFavorita
              ? '⭐ Agregada a Favoritas'
              : 'Eliminada de Favoritas',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
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
          // ⭐ Filtro solo favoritas
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              avatar: Icon(
                Icons.star,
                size: 16,
                color: _soloFavoritas ? azulMarino : Colors.amber,
              ),
              label: const Text('Favoritas'),
              selected: _soloFavoritas,
              onSelected: (selected) {
                setState(() => _soloFavoritas = selected);
                _aplicarFiltroFavoritas();
              },
              selectedColor: dorado,
              backgroundColor: Colors.transparent,
              labelStyle: TextStyle(
                color: _soloFavoritas ? azulMarino : Colors.white,
                fontWeight: _soloFavoritas ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: _soloFavoritas ? dorado : Colors.white,
                ),
              ),
              visualDensity: VisualDensity.compact,
              showCheckmark: false,
            ),
          ),
          const SizedBox(width: 8),

          // Tipo (dropdown)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: PopupMenuButton<String>(
              initialValue: _tipoSeleccionado,
              onSelected: (tipo) {
                setState(() {
                  _tipoSeleccionado = tipo;
                  if (tipo != 'Sentencias' && tipo != 'Jurisprudencias') {
                    _salaSeleccionada = null;
                  }
                });
                _buscar();
              },
              itemBuilder: (context) => [
                'Sentencias',
                'Jurisprudencias',
                'Resoluciones',
              ].map((tipo) => PopupMenuItem<String>(value: tipo, child: Text(tipo))).toList(),
              child: Chip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_tipoSeleccionado),
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
                  _mesSeleccionado = null;
                  _diaSeleccionado = null;
                  _mesesDisponibles = [];
                  _diasDisponibles = [];
                });
                _buscar();
                if (value != null) _cargarMeses(value);
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

          // Mes (solo meses con sentencias)
          if (_anioSeleccionado != null && _mesesDisponibles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: PopupMenuButton<int?>(
                initialValue: _mesSeleccionado,
                onSelected: (int? value) {
                  setState(() {
                    _mesSeleccionado = value;
                    _diaSeleccionado = null;
                    _diasDisponibles = [];
                  });
                  _buscar();
                  if (value != null && _anioSeleccionado != null) {
                    _cargarDias(_anioSeleccionado!, value);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<int?>(
                      value: null, child: Text('Mes (Todos)')),
                  ..._mesesDisponibles.map((m) => PopupMenuItem<int?>(
                        value: m,
                        child: Text(_nombreMes(m)),
                      )),
                ],
                child: Chip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_mesSeleccionado != null
                          ? _nombreMes(_mesSeleccionado!)
                          : 'Mes'),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down,
                          size: 16, color: Colors.white),
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

          // Día (solo días con sentencias)
          if (_mesSeleccionado != null && _diasDisponibles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: PopupMenuButton<int?>(
                initialValue: _diaSeleccionado,
                onSelected: (int? value) {
                  setState(() => _diaSeleccionado = value);
                  _buscar();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<int?>(
                      value: null, child: Text('Día (Todos)')),
                  ..._diasDisponibles.map((d) => PopupMenuItem<int?>(
                        value: d,
                        child: Text(d.toString()),
                      )),
                ],
                child: Chip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_diaSeleccionado?.toString() ?? 'Día'),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down,
                          size: 16, color: Colors.white),
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
          'Sala de Sentencias',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: dorado,
          ),
        ),
        backgroundColor: azulMarino,
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

  String _etiquetaDelito(SentenciaModel s) {
    if (s.delito.isNotEmpty && s.delito != 'null') return s.delito;
    if (s.materia.isNotEmpty && s.materia != 'null') return s.materia;
    return 'Jurisprudencia Penal';
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
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: dorado.withValues(alpha: 0.4), width: 1.2),
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
                        _etiquetaDelito(sentencia),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                      '${sentencia.sala} • ${sentencia.fechaSentencia}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _mostrarMetadata(sentencia),
                      icon: Icon(Icons.info_outline,
                          size: 20,
                          color: azulMarino.withValues(alpha: 0.55)),
                      tooltip: 'Ver metadata',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                    // ⭐ Botón para marcar como favorita/importante
                    IconButton(
                      onPressed: () => _toggleFavorita(sentencia),
                      icon: Icon(
                        _idsFavoritos.contains(sentencia.id)
                            ? Icons.star
                            : Icons.star_border,
                        size: 22,
                        color: _idsFavoritos.contains(sentencia.id)
                            ? Colors.amber
                            : Colors.grey[500],
                      ),
                      tooltip: _idsFavoritos.contains(sentencia.id)
                          ? 'Quitar de favoritas'
                          : 'Agregar a favoritas',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
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
                if (sentencia.resumen.isNotEmpty || sentencia.extracto.isNotEmpty)
                  Text(
                    sentencia.resumen.isNotEmpty ? sentencia.resumen : sentencia.extracto,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Colors.grey[800],
                    ),
                  ),

                // ✅ Pie: ver sentencia completa
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _verSentencia(sentencia),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: azulMarino,
                      side: const BorderSide(color: dorado),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined, size: 16),
                        SizedBox(width: 6),
                        Text('Ver sentencia completa'),
                      ],
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

  void _mostrarMetadata(SentenciaModel s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sentencia Nº ${s.numeroSentencia}',
                style: const TextStyle(
                  color: dorado,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 14),
              _filaMeta('Sala', s.sala),
              _filaMeta('Ponente', s.ponente),
              _filaMeta('Fecha', s.fechaSentencia),
              _filaMeta('Delito', s.delito),
              _filaMeta('Materia', s.materia),
              _filaMeta('Partes', s.partes),
              _filaMeta('Tipo', s.tipoSentencia),
            ],
          ),
        );
      },
    );
  }

  Widget _filaMeta(String etiqueta, String valor) {
    if (valor.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              etiqueta,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verSentencia(SentenciaModel sentencia) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleSentenciaScreen(sentencia: sentencia),
      ),
    );
    // ⭐ Refrescar favoritas por si cambiaron desde la pantalla de detalle
    if (mounted) {
      final ids = await _favoritosService.obtenerIdsFavoritas();
      if (mounted) {
        setState(() {
          _idsFavoritos = ids;
          if (_soloFavoritas) _aplicarFiltroFavoritas();
        });
      }
    }
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
  static const Color dorado = Color(0xFFEAB308);

  // ⭐ Favoritas / Importantes
  final FavoritosService _favoritosService = FavoritosService();
  bool _esFavorita = false;
  
  bool _mostrandoAnalisisIA = false;
  bool _analizando = false;
  AnalisisProfundoSentencia? _analisisProfundo;

  @override
  void initState() {
    super.initState();
    _cargarEstadoFavorito();
  }

  Future<void> _cargarEstadoFavorito() async {
    final favorita = await _favoritosService.estaFavorita(widget.sentencia.id);
    if (mounted) setState(() => _esFavorita = favorita);
  }

  Future<void> _toggleFavorita() async {
    await _favoritosService.toggleFavorita(widget.sentencia.id);
    if (!mounted) return;
    setState(() => _esFavorita = !_esFavorita);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _esFavorita ? '⭐ Agregada a Favoritas' : 'Eliminada de Favoritas',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Compartir la sentencia (resumen + enlace oficial).
  /// Funciona en Android, iOS y Web (Web Share API).
  Future<void> _compartirSentencia() async {
    final s = widget.sentencia;
    // Al compartir se cita la fuente oficial (TSJ) para no exponer el
    // almacenamiento interno; solo se usa la copia propia como respaldo.
    final fuente = (s.urlTSJ.isNotEmpty && s.urlTSJ != 'null')
        ? s.urlTSJ
        : (s.urlParaVer.isNotEmpty ? s.urlParaVer : 'No disponible');

    final texto = '⚖️ Sentencia Nº ${s.numeroSentencia}\n'
        'Sala: ${s.sala}\n'
        'Fecha: ${s.fechaSentencia}\n'
        'Delito: ${s.delito}\n\n'
        '${s.resumen}\n\n'
        'Fuente: $fuente';

    try {
      await Share.share(texto, subject: 'Sentencia Nº ${s.numeroSentencia}');
    } catch (e) {
      _mostrarSnack('No se pudo compartir: $e');
    }
  }

  /// Descargar la sentencia como PDF estructurado.
  ///
  /// Se genera a partir de la copia HTML en R2 (copia fiel del TSJ):
  /// párrafos continuos y justificados, sin los saltos de línea del TXT.
  /// En Web (sin `dart:io`) se abre la copia HTML en el navegador.
  Future<void> _descargarSentencia() async {
    final s = widget.sentencia;

    // Web: no hay `dart:io` para generar el PDF; abrir la copia en R2.
    if (kIsWeb) {
      if (_esUrlValida(s.urlHTML)) {
        await _abrirUrl(s.urlHTML);
      } else if (_esUrlValida(s.urlTSJ)) {
        await _abrirUrl(s.urlTSJ);
      } else {
        _mostrarSnack('No hay documento disponible');
      }
      return;
    }

    // Prioridad: PDF estructurado desde la copia HTML de R2.
    if (_esUrlValida(s.urlHTML)) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text('Generando PDF estructurado...'),
              ),
            ],
          ),
        ),
      );
      try {
        final exito = await SentenciaPdfService.exportarYAbrir(s);
        if (!mounted) return;
        _mostrarSnack(
          exito ? 'PDF generado correctamente' : 'No se pudo generar el PDF',
        );
      } finally {
        if (mounted) Navigator.of(context).pop();
      }
      return;
    }

    // Sin copia HTML en R2: abrir la página original del TSJ.
    if (_esUrlValida(s.urlTSJ)) {
      await _abrirUrl(s.urlTSJ);
      return;
    }

    _mostrarSnack('No hay documento disponible para descargar');
  }

  bool _esUrlValida(String url) =>
      url.isNotEmpty && url != 'null' && Uri.tryParse(url)?.hasScheme == true;

  Future<void> _abrirUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final abierto =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!abierto) _mostrarSnack('No se pudo abrir el documento');
    } catch (e) {
      _mostrarSnack('Error al abrir documento: $e');
    }
  }

  void _mostrarSnack(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _analizarConIA() async {
    // 1) Si ya existe análisis guardado, mostrarlo sin gastar tokens.
    final guardado = widget.sentencia.analisisIa;
    if (guardado.isNotEmpty && guardado != 'null') {
      _mostrarAnalisisBottomSheet(guardado);
      return;
    }

    setState(() => _analizando = true);
    try {
      await AIService.inicializar();

      // 2) Texto plano desde url_txt (Cloudflare) como contexto adicional.
      String textoCompleto = '';
      final urlTxt = widget.sentencia.urlTXT;
      if (urlTxt.isNotEmpty && urlTxt != 'null') {
        try {
          final resp = await http
              .get(Uri.parse(urlTxt))
              .timeout(const Duration(seconds: 15));
          if (resp.statusCode == 200) {
            textoCompleto = utf8.decode(resp.bodyBytes);
          }
        } catch (e) {
          debugPrint('⚠️ No se pudo descargar url_txt: $e');
        }
      }

      // 3) Generar el análisis estructurado con ratio_decidendi + texto.
      final analisis = await AIService.generarAnalisisJurisprudencial(
        widget.sentencia.ratioDecidendi,
        textoCompleto.isNotEmpty
            ? textoCompleto
            : widget.sentencia.contenidoCompleto,
      );

      if (analisis.isEmpty) {
        if (mounted) setState(() => _analizando = false);
        return;
      }

      // 4) Persistir en Supabase (costo cero de tokens en futuras consultas).
      try {
        await Supabase.instance.client
            .from('documentos')
            .update({'analisis_ia': analisis})
            .eq('id', widget.sentencia.id);
      } catch (e) {
        debugPrint('⚠️ No se pudo guardar analisis_ia: $e');
      }

      if (mounted) {
        setState(() => _analizando = false);
        _mostrarAnalisisBottomSheet(analisis);
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

  void _mostrarAnalisisBottomSheet(String analisis) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.35,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: dorado, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Análisis con IA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: MarkdownBody(
                    data: analisis,
                    styleSheet: MarkdownStyleSheet(
                      h2: const TextStyle(
                        color: dorado,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      p: const TextStyle(
                        color: Colors.white,
                        height: 1.55,
                        fontSize: 14,
                      ),
                      strong: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        elevation: 0,
        actions: [
          // ⭐ Marcar como favorita/importante
          IconButton(
            icon: Icon(
              _esFavorita ? Icons.star : Icons.star_border,
              color: _esFavorita ? Colors.amber : null,
            ),
            onPressed: _toggleFavorita,
            tooltip: _esFavorita ? 'Quitar de favoritas' : 'Agregar a favoritas',
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: _compartirSentencia,
            tooltip: 'Compartir sentencia',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _descargarSentencia,
            tooltip: 'Descargar PDF estructurado',
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView con la sentencia (móvil) / vista simple (Web: no existe
          // webview_flutter para web, así que mostramos los datos + enlace).
          if (kIsWeb)
            _buildContenidoWeb()
          else
            WebViewWidget(
              controller: WebViewController()
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                ..setBackgroundColor(Colors.white)
                // Abrir la copia en R2 cuando exista (más estable que el TSJ).
                ..loadRequest(Uri.parse(widget.sentencia.urlParaVer)),
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

  /// Vista alternativa para Web (webview_flutter no soporta navegadores):
  /// muestra los datos de la sentencia y permite abrir el documento oficial.
  Widget _buildContenidoWeb() {
    final s = widget.sentencia;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWebDato('Sala', s.sala),
          _buildWebDato('Nº de sentencia', s.numeroSentencia),
          _buildWebDato('Fecha', s.fechaSentencia),
          _buildWebDato('Ponente', s.ponente),
          _buildWebDato('Delito', s.delito),
          _buildWebDato('Decisión', s.decision),
          _buildWebDato('Tipo', s.tipoSentencia),
          const Divider(height: 32),
          const Text(
            '📋 Resumen',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: azulMarino,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(s.resumen, style: const TextStyle(fontSize: 14, height: 1.5)),
          const SizedBox(height: 24),
          if (s.urlParaVer.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _descargarSentencia,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir documento completo en el navegador'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulMarino,
                  foregroundColor: dorado,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWebDato(String etiqueta, String valor) {
    if (valor.isEmpty || valor == 'null') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              etiqueta,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 14,
                color: azulMarino,
                fontWeight: FontWeight.w500,
              ),
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

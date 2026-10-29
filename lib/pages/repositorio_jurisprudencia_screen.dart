import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import '../models/sentencia_model.dart';
import '../models/doctrina_academica_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../services/jurisprudencia_service.dart';
import '../services/super_buscador_service.dart';
import '../services/ai_service.dart';
import '../services/sentencia_pdf_service.dart';
import '../services/favoritos_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/main_bottom_bar.dart';
import '../widgets/app_bar_institucional.dart';
import '../widgets/app_snackbar.dart';

class RepositorioJurisprudenciaScreen extends StatefulWidget {
  const RepositorioJurisprudenciaScreen({super.key});

  @override
  State<RepositorioJurisprudenciaScreen> createState() =>
      _RepositorioJurisprudenciaScreenState();
}

class _RepositorioJurisprudenciaScreenState
    extends State<RepositorioJurisprudenciaScreen>
    with SingleTickerProviderStateMixin {
  final JurisprudenciaService _service = JurisprudenciaService();
  final SuperBuscadorService _superService = SuperBuscadorService();
  final TextEditingController _searchController = TextEditingController();

  List<SentenciaModel> _resultados = [];
  List<SentenciaModel> _todosResultados = [];

  // 📚 Resultados de la categoría Doctrinas Académicas
  List<DoctrinaAcademicaModel> _doctrinas = [];

  bool _cargando = false;

  // ⭐ Favoritas / Importantes
  final FavoritosService _favoritosService = FavoritosService();
  Set<String> _idsFavoritos = {};
  bool _soloFavoritas = false;

  // ✅ Filtros (Super Buscador: 4 categorías)
  String _categoriaSeleccionada = 'Sentencias';
  String? _salaSeleccionada;
  int? _anioSeleccionado;
  // 📅 Orden cronológico: false = más reciente primero (desc), true = más
  // antiguo primero (asc).
  bool _ordenAscendente = false;

  // ♾️ Lazy load (scroll infinito con paginación)
  int _offset = 0;
  static const int _limitePagina = 20;
  bool _tieneMas = false;
  bool _cargandoMas = false;

  // 🔎 Fallback semántico: etiqueta "Resultados por búsqueda semántica"
  bool _usoSemantica = false;

  /// Total visible (sentencias + doctrinas según la categoría activa).
  int get _totalResultados => _categoriaSeleccionada == 'Doctrinas'
      ? _doctrinas.length
      : _resultados.length;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ♾️ Detector de scroll para el lazy load (cargar siguiente página)
  final ScrollController _scrollController = ScrollController();

  // Colores de la app
  
  
  /// Acento de marca: azul marino en modo claro, AppColors.dorado en modo oscuro.
  
  static Color get fondoGris => TemaGlobal.superficie;

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
    // Lazy load: al acercarse al final de la lista, pedir la siguiente página.
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 400) {
        _buscarMas();
      }
    });
    _cargarFavoritos(); // ⭐ Cargar favoritas guardadas
    _buscar(); // ✅ Cargar sentencias al inicio
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    setState(() {
      _cargando = true;
      _offset = 0;
      _tieneMas = false;
      _usoSemantica = false;
    });
    _animationController.forward();

    // Super Buscador: búsqueda híbrida (FTS Supabase + semántica Qdrant
    // vía worker, fusionadas con RRF) sobre las 4 categorías.
    final resultado = await _superService.buscar(
      texto: _searchController.text.trim(),
      categoria: _categoriaSeleccionada,
      sala: _salaSeleccionada,
      anio: _anioSeleccionado,
      offset: 0,
      limit: _limitePagina,
      ordenAscendente: _ordenAscendente,
    );

    if (mounted) {
      setState(() {
        _todosResultados = resultado.sentencias;
        _doctrinas = resultado.doctrinas;
        _resultados = resultado.sentencias; // Ya ordenadas por relevancia
        _tieneMas = resultado.tieneMas;
        _usoSemantica = resultado.usoSemantica;

        // ⭐ Aplicar filtro de favoritas si está activo
        _aplicarFiltroFavoritas();

        _cargando = false;
        _offset = _limitePagina;
      });
    }
  }

  /// Siguiente página del lazy load (scroll infinito).
  Future<void> _buscarMas() async {
    if (_cargando || _cargandoMas || !_tieneMas) return;
    setState(() => _cargandoMas = true);

    final resultado = await _superService.buscar(
      texto: _searchController.text.trim(),
      categoria: _categoriaSeleccionada,
      sala: _salaSeleccionada,
      anio: _anioSeleccionado,
      offset: _offset,
      limit: _limitePagina,
      ordenAscendente: _ordenAscendente,
    );

    if (mounted) {
      setState(() {
        if (_categoriaSeleccionada == 'Doctrinas') {
          _doctrinas.addAll(resultado.doctrinas);
        } else {
          _todosResultados.addAll(resultado.sentencias);
          if (_soloFavoritas) {
            // Re-aplicar el filtro de favoritas para que las favoritas
            // de las páginas nuevas aparezcan en la lista visible.
            _aplicarFiltroFavoritas();
          } else {
            _resultados.addAll(resultado.sentencias);
          }
        }
        _tieneMas = resultado.tieneMas;
        _usoSemantica = _usoSemantica || resultado.usoSemantica;
        _offset += _limitePagina;
        _cargandoMas = false;
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
      _resultados =
          _todosResultados.where((s) => _idsFavoritos.contains(s.id)).toList();
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
    // Guía 3.4: AppSnackBar siempre.
    AppSnackBar.success(
      context,
      esFavorita ? '⭐ Agregada a Favoritas' : 'Eliminada de Favoritas',
    );
  }

  void _limpiarBusqueda() {
    setState(() {
      _searchController.clear();
      _categoriaSeleccionada = 'Sentencias';
      _salaSeleccionada = null;
      _anioSeleccionado = null;
    });
    _buscar();
  }

  /// Panel lateral de filtros (Año y Sala).
  ///
  /// REGLA ESTRICTA: el filtro de Sala se oculta automáticamente en las
  /// categorías Resoluciones y Doctrinas (no aplica a esos contenidos).
  void _abrirPanelFiltros() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TemaGlobal.tarjeta,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final int currentYear = DateTime.now().year;
          final List<int> years =
              List.generate(currentYear - 1999, (index) => currentYear - index);
          final bool mostrarSala = _categoriaSeleccionada != 'Resoluciones' &&
              _categoriaSeleccionada != 'Doctrinas';

          Widget chip(String label,
              {required bool activo, required VoidCallback onTap}) {
            return Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 4),
              child: ChoiceChip(
                label: Text(label),
                selected: activo,
                onSelected: (_) => onTap(),
                selectedColor: AppColors.dorado,
                backgroundColor: Colors.transparent,
                labelStyle: TextStyle(
                  // Guía 3.3: texto sobre dorado = onDorado.
                  color: activo ? AppColors.onDorado : TemaGlobal.texto,
                  fontWeight: activo ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                      color: activo ? AppColors.dorado : TemaGlobal.capa),
                ),
                visualDensity: VisualDensity.compact,
                showCheckmark: false,
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Filtros',
                      style: TextStyle(
                        color: TemaGlobal.texto,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: TemaGlobal.textoSecundario, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Año
                Text(
                  'Año',
                  style: TextStyle(
                    color: TemaGlobal.textoSecundario,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      chip('Todos', activo: _anioSeleccionado == null, onTap: () {
                        setSheetState(() => _anioSeleccionado = null);
                      }),
                      ...years.map((y) => chip('$y',
                          activo: _anioSeleccionado == y,
                          onTap: () => setSheetState(() => _anioSeleccionado = y))),
                    ],
                  ),
                ),
                // Sala (solo Sentencias y Jurisprudencias)
                if (mostrarSala) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Sala',
                    style: TextStyle(
                      color: TemaGlobal.textoSecundario,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        chip('Todas', activo: _salaSeleccionada == null, onTap: () {
                          setSheetState(() => _salaSeleccionada = null);
                        }),
                        // Penalex solo indexa 2 salas del TSJ: Casación Penal
                        // (scp) y Constitucional (scon). Verificado en la BD.
                        chip('Casación Penal', activo: _salaSeleccionada == 'scp',
                            onTap: () =>
                                setSheetState(() => _salaSeleccionada = 'scp')),
                        chip('Constitucional', activo: _salaSeleccionada == 'scon',
                            onTap: () =>
                                setSheetState(() => _salaSeleccionada = 'scon')),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _buscar();
                    },
                    style: ElevatedButton.styleFrom(
                      // Guía 3.2: primario = acento dinámico.
                      backgroundColor: AppColors.acento,
                      foregroundColor: AppColors.acento == AppColors.dorado
                          ? AppColors.onDorado
                          : AppColors.onAzulMarino,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Aplicar filtros',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Fila superior del Super Buscador: dropdown de categorías + Favoritas
  /// + botón Filtros.
  Widget _buildFiltros() {
    const categorias = ['Sentencias', 'Jurisprudencias', 'Resoluciones', 'Doctrinas'];

    Widget chip(String label, {required bool activo, required VoidCallback onTap}) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: activo,
          onSelected: (_) => onTap(),
          selectedColor: AppColors.dorado,
          backgroundColor: Colors.transparent,
          labelStyle: TextStyle(
            // Guía 3.3: texto sobre dorado = onDorado.
            color: activo ? AppColors.onDorado : TemaGlobal.texto,
            fontWeight: activo ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: activo ? AppColors.dorado : TemaGlobal.capa),
          ),
          visualDensity: VisualDensity.compact,
          showCheckmark: false,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Dropdown de categorías (guía 3.3: acento dinámico).
            Expanded(
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: TemaGlobal.campoTexto,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.acento.withValues(alpha: 0.35)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _categoriaSeleccionada,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down,
                        color: AppColors.acento, size: 22),
                    borderRadius: BorderRadius.circular(12),
                    dropdownColor: TemaGlobal.tarjeta,
                    style: TextStyle(
                      color: TemaGlobal.texto,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    items: [
                      for (final categoria in categorias)
                        DropdownMenuItem(
                          value: categoria,
                          child: Text(categoria),
                        ),
                    ],
                    onChanged: (categoria) {
                      if (categoria == null || categoria == _categoriaSeleccionada) {
                        return;
                      }
                      setState(() {
                        _categoriaSeleccionada = categoria;
                        // Al cambiar a Resoluciones/Doctrinas se oculta Sala
                        // (regla estricta): limpiar el filtro de sala.
                        if (categoria == 'Resoluciones' ||
                            categoria == 'Doctrinas') {
                          _salaSeleccionada = null;
                        }
                      });
                      _buscar();
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // ⭐ Favoritas: solo aplica a sentencias/jurisprudencias/
            // resoluciones (las doctrinas no se marcan como favoritas).
            if (_categoriaSeleccionada != 'Doctrinas')
              chip('⭐ Favoritas', activo: _soloFavoritas, onTap: () {
                setState(() => _soloFavoritas = !_soloFavoritas);
                _aplicarFiltroFavoritas();
              }),
            // 📅 Orden cronológico (asc/desc)
            IconButton(
              onPressed: () {
                setState(() => _ordenAscendente = !_ordenAscendente);
                _buscar();
              },
              icon: Icon(
                _ordenAscendente
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 18,
                color: AppColors.acento,
              ),
              tooltip: _ordenAscendente
                  ? 'Ordenar por fecha: más antiguas primero'
                  : 'Ordenar por fecha: más recientes primero',
              visualDensity: VisualDensity.compact,
            ),
            // Botón Filtros
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: OutlinedButton.icon(
                onPressed: _abrirPanelFiltros,
                icon: Icon(Icons.tune, size: 16, color: AppColors.acento),
                label: Text(
                  'Filtros',
                  style: TextStyle(
                      color: AppColors.acento,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: AppColors.acento.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Resumen de filtros activos
        if (_salaSeleccionada != null ||
            _anioSeleccionado != null) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (_salaSeleccionada != null)
                  chip(_nombreSalaCorto(_salaSeleccionada!),
                      activo: true, onTap: () {
                    setState(() => _salaSeleccionada = null);
                    _buscar();
                  }),
                if (_anioSeleccionado != null)
                  chip('Año ${_anioSeleccionado}', activo: true, onTap: () {
                    setState(() => _anioSeleccionado = null);
                    _buscar();
                  }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Nombre corto para mostrar una sala activa (código BD → etiqueta).
  String _nombreSalaCorto(String codigo) {
    const nombres = {
      'scp': 'Casación Penal',
      'scon': 'Constitucional',
    };
    return nombres[codigo] ?? codigo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/repositorio_jurisprudencia'),
            appBar: AppBarInstitucional(
        title: 'Super Buscador',
        mostrarBack: true,

        actions: [
          // ✅ Contador de resultados
          if (!_cargando &&
              (_resultados.isNotEmpty || _doctrinas.isNotEmpty))
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_totalResultados} ${_totalResultados == 1 ? "resultado" : "resultados"}',
                  style: const TextStyle(
                    color: AppColors.dorado,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const MainBottomBar(),
      backgroundColor: fondoGris,
      body: Column(
        children: [
          // ✅ Barra de búsqueda SIMPLE y clara
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TemaGlobal.superficie,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: AppColors.a12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Barra de búsqueda premium: input + botón dorado
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: TemaGlobal.texto, fontSize: 14),
                        decoration: InputDecoration(
                          // Placeholder premium (especificación del Super Buscador).
                          hintText: 'Busca por número, delito, partes o tema...',
                          hintStyle: TextStyle(
                            color: TemaGlobal.textoTenue,
                            fontSize: 14,
                          ),
                          prefixIcon:
                              Icon(Icons.search, color: AppColors.acento, size: 22),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear,
                                      color: AppColors.acento, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                    _buscar();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: TemaGlobal.campoTexto,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: AppColors.acento, width: 2),
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
                    ),
                    const SizedBox(width: 8),
                    // Botón de búsqueda dorado (guía 3.2: primario acento).
                    Material(
                      color: AppColors.dorado,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: _buscar,
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Icon(Icons.search,
                              color: AppColors.onDorado, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // ✅ Ayuda sutil con indicador de búsqueda semántica
                Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 12, color: AppColors.acento.withValues(alpha: AppColors.a48)),
                    const SizedBox(width: 4),
                    Text(
                      'Búsqueda inteligente: prueba "matar", "robar", "drogas"...',
                      style: TextStyle(
                        color: TemaGlobal.textoSecundario,
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

          // ✅ Lista de resultados con skeletons + lazy load
          Expanded(
            child: _cargando
                ? _buildSkeletons()
                : _listaVacia
                    ? _buildEmptyState()
                    : Column(
                        children: [
                          // Etiqueta cuando el FTS no dio nada y se usó la
                          // semántica de Qdrant (fallback automático).
                          if (_usoSemantica)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.dorado
                                    .withValues(alpha: AppColors.a12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.auto_awesome,
                                      size: 14, color: AppColors.dorado),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Resultados por búsqueda semántica',
                                    style: TextStyle(
                                      color: AppColors.dorado,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _categoriaSeleccionada == 'Doctrinas'
                                  ? _buildListaDoctrinas()
                                  : _buildListaSentencias(),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  /// ¿No hay nada que mostrar en la lista?
  bool get _listaVacia =>
      _resultados.isEmpty && _doctrinas.isEmpty;

  /// Lista de sentencias con lazy load (scroll infinito).
  Widget _buildListaSentencias() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _resultados.length + (_tieneMas ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _resultados.length) {
          // Pie de carga para la siguiente página
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.acento,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          );
        }
        return _buildSentenciaCard(_resultados[index], index);
      },
    );
  }

  /// Lista de doctrinas académicas con lazy load.
  Widget _buildListaDoctrinas() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _doctrinas.length + (_tieneMas ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _doctrinas.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.acento,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          );
        }
        return _buildDoctrinaCard(_doctrinas[index], index);
      },
    );
  }

  /// Esqueletos de carga mientras se busca (guía 3.1: tarjetas r16).
  Widget _buildSkeletons() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TemaGlobal.tarjeta,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TemaGlobal.capa, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge esqueleto
              Container(
                width: 90,
                height: 18,
                decoration: BoxDecoration(
                  color: TemaGlobal.capa,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              // Título esqueleto
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: TemaGlobal.capa,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 10),
              // Líneas esqueleto
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: TemaGlobal.capa.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 200,
                height: 12,
                decoration: BoxDecoration(
                  color: TemaGlobal.capa.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Tarjeta de DOCTRINA ACADÉMICA (autor/obra/párrafo de evidencia).
  Widget _buildDoctrinaCard(DoctrinaAcademicaModel doctrina, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: AppColors.azulMarino.withValues(alpha: 0.08),
      // Guía 3.1: r16 para tarjetas de lista.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: TemaGlobal.capa, width: 1),
      ),
      child: InkWell(
        onTap: () => _verDoctrina(doctrina),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.dorado.withValues(alpha: AppColors.a12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'DOCTRINA',
                      style: TextStyle(
                        color: AppColors.dorado,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.auto_stories,
                      size: 16, color: AppColors.acento.withValues(alpha: 0.6)),
                ],
              ),
              const SizedBox(height: 10),
              // Autor — Obra (título de la tarjeta)
              Text(
                doctrina.titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: TemaGlobal.texto,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              // Párrafo de evidencia (cita textual)
              Text(
                doctrina.parrafoEvidencia,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: TemaGlobal.textoSecundario,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Abrir una doctrina: si referencia una sentencia, la abre; si no,
  /// muestra la cita completa en un panel.
  Future<void> _verDoctrina(DoctrinaAcademicaModel doctrina) async {
    final sentenciaId = doctrina.sentenciaId;
    if (sentenciaId.isNotEmpty) {
      // Buscar la sentencia vinculada (referencia exacta por id).
      final encontradas = await _service.buscarDocumentos(
        textoBusqueda: sentenciaId,
        tipo: 'sentencia',
        limit: 1,
      );
      if (encontradas.isNotEmpty && mounted) {
        await _verSentencia(encontradas.first);
        return;
      }
    }
    if (!mounted) return;
    // Sin sentencia vinculada: mostrar la cita doctrinal completa.
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TemaGlobal.tarjeta,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              doctrina.titulo,
              style: TextStyle(
                color: AppColors.acento,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              doctrina.parrafoEvidencia,
              style: TextStyle(
                color: TemaGlobal.texto,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.acento,
                  foregroundColor: AppColors.acento == AppColors.dorado
                      ? AppColors.onDorado
                      : AppColors.onAzulMarino,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
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
              color: TemaGlobal.textoTenue,
            ),
            const SizedBox(height: 24),
            Text(
              'No se encontraron resultados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: TemaGlobal.texto.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Intenta con otros términos de búsqueda',
              style: TextStyle(
                fontSize: 14,
                color: TemaGlobal.texto.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _limpiarBusqueda,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Limpiar búsqueda'),
              style: ElevatedButton.styleFrom(
                // Guía 3.2: primario = acento dinámico (navy en claro /
                // dorado en oscuro).
                backgroundColor: AppColors.acento,
                foregroundColor: AppColors.acento == AppColors.dorado
                    ? AppColors.onDorado
                    : AppColors.onAzulMarino,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shadowColor: AppColors.azulMarino.withValues(alpha: 0.08),
      // Guía 3.1: r16 para tarjetas de lista.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: TemaGlobal.capa, width: 1),
      ),
      child: InkWell(
        // Al tocar la ficha se abre la ventana flotante con toda la
        // metadata y el botón "Leer sentencia completa".
        onTap: () => _mostrarMetadata(sentencia),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: delito + vinculante + favorita
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.azulMarino,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _etiquetaDelito(sentencia),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.onAzulMarino,
                        // Guía 3.6: badge 10px.
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (sentencia.esJurisprudencia) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.dorado,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Vinculante',
                        style: TextStyle(
                          color: AppColors.onDorado,
                          // Guía 3.6: badge 10px.
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    onPressed: () => _toggleFavorita(sentencia),
                    icon: Icon(
                      _idsFavoritos.contains(sentencia.id)
                          ? Icons.star
                          : Icons.star_border,
                      size: 20,
                      color: _idsFavoritos.contains(sentencia.id)
                          // Guía 3.5: favorita = dorado (igual que el detalle).
                          ? AppColors.dorado
                          : TemaGlobal.textoTenue,
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
              const SizedBox(height: 10),
              // Número + sala · fecha
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      'Nº ${sentencia.numeroSentencia}',
                      style: TextStyle(color: TemaGlobal.texto,
                      ),
                    ),
                  ),
                  Text(
                    '${_nombreSala(sentencia.sala)} · ${sentencia.fechaSentencia}',
                    style: TextStyle(color: TemaGlobal.textoSecundario, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Resumen / extracto / ratio
              if (_textoResumen(sentencia).isNotEmpty)
                Text(
                  _textoResumen(sentencia),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: TemaGlobal.texto,
                  ),
                ),
              const SizedBox(height: 12),
              // Pie: decisión (con truncado) + acciones
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // La decisión puede ser larga: Flexible + ellipsis evita
                  // que se salga de la pantalla (hasta 2 líneas).
                  if (sentencia.decision.isNotEmpty &&
                      sentencia.decision != 'null')
                    Flexible(child: _chipDecision(sentencia.decision)),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _verSentencia(sentencia),
                    style: TextButton.styleFrom(
                      foregroundColor: TemaGlobal.texto,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Ver',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Texto de vista previa: prioriza ratio decidendi, luego resumen IA,
  /// luego extracto.
  String _textoResumen(SentenciaModel s) {
    final texto = s.ratioDecidendi.isNotEmpty
        ? s.ratioDecidendi
        : (s.resumen.isNotEmpty ? s.resumen : s.extracto);
    return (texto == 'null') ? '' : texto;
  }

  /// Chip de decisión con color según el sentido del fallo.
  /// Fondo translúcido (alpha) sobre la superficie actual y texto con tono
  /// adaptado al modo claro/oscuro: legible sin destellar en modo oscuro.
  Widget _chipDecision(String decision) {
    final d = decision.toUpperCase();
    final oscuro = TemaGlobal.isDark;
    Color bg;
    Color fg;
    if (d.contains('CON LUGAR')) {
      bg = AppColors.success.withValues(alpha: oscuro ? 0.22 : 0.14);
      fg = oscuro ? AppColors.success : AppColors.success;
    } else if (d.contains('SIN LUGAR') ||
        d.contains('IMPROCEDENTE') ||
        d.contains('INADMISIBLE')) {
      bg = AppColors.error.withValues(alpha: oscuro ? 0.22 : 0.14);
      fg = oscuro ? AppColors.error : AppColors.error;
    } else if (d.contains('REVOCA') ||
        d.contains('ANULA') ||
        d.contains('NULIDAD')) {
      bg = AppColors.warning.withValues(alpha: oscuro ? 0.22 : 0.14);
      fg = oscuro ? AppColors.warning : AppColors.warning;
    } else {
      bg = TemaGlobal.capa;
      fg = TemaGlobal.textoSecundario;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        decision,
        // Decisiones largas: máximo 2 líneas con puntos suspensivos (el
        // Flexible del Row ya limita el ancho disponible).
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
      ),
    );
  }

  void _mostrarMetadata(SentenciaModel s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TemaGlobal.tarjeta,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: TemaGlobal.capa,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sentencia Nº ${s.numeroSentencia}',
                  style: TextStyle(
                    color: AppColors.acento,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 14),
                _filaMeta('Sala', _nombreSala(s.sala)),
                _filaMeta('Ponente', s.ponente),
                _filaMeta('Fecha', s.fechaSentencia),
                _filaMeta('Delito', s.delito),
                _filaMeta('Materia', s.materia),
                _filaMeta('Partes', s.partes),
                _filaMeta('Tipo', s.tipoSentencia),
                // ⚖️ Criterios jurisprudenciales de la sentencia
                if (_criterios.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Divider(color: TemaGlobal.capa, height: 1),
                  const SizedBox(height: 12),
                  Text(
                    '⚖️ Criterios jurisprudenciales (${_criterios.length})',
                    style: TextStyle(
                      color: AppColors.acento,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final c in _criterios)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: TemaGlobal.capa,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (c['tipo'] ?? '') == 'jurisprudencia'
                                  ? '★ Criterio oficial de la Sala'
                                  : 'Criterio de la Sala',
                              style: TextStyle(
                                color: AppColors.acento,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _textoCriterio(c),
                              style: TextStyle(
                                color: TemaGlobal.texto,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                            if (_citaCriterio(c).isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                '«${_citaCriterio(c)}»',
                                style: TextStyle(
                                  color: TemaGlobal.textoSecundario,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
                // 📖 Leer sentencia completa
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _verSentencia(s);
                    },
                    // Guía 3.2: primario = AppColors.acento con su fg.
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.acento,
                      foregroundColor:
                          AppColors.acento == AppColors.dorado
                              ? AppColors.onDorado
                              : AppColors.onAzulMarino,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.menu_book_outlined, size: 20),
                    label: Text(
                      'Leer sentencia completa',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
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
                color: TemaGlobal.textoSecundario,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(color: TemaGlobal.texto, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Criterios de la sentencia para la ficha técnica del listado
  // (se mantienen vacíos aquí; el detalle es quien los carga).
  List<Map<String, dynamic>> _criterios = [];

  String _textoCriterio(Map<String, dynamic> c) {
    final texto = (c['texto_ratio'] ?? '').toString().trim();
    if (texto.isNotEmpty && texto != 'null') return texto;
    return (c['resumen'] ?? '').toString().trim();
  }

  String _citaCriterio(Map<String, dynamic> c) {
    final ev = (c['parrafo_evidencia'] ?? '').toString().trim();
    if (ev.isEmpty || ev == 'null') return '';
    final texto = _textoCriterio(c);
    // Si la cita es casi el mismo texto que el criterio, no duplicar.
    if (texto.isNotEmpty && ev == texto) return '';
    if (ev.length > 600) return '${ev.substring(0, 600)}…';
    return ev;
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
  
  
  /// Acento de marca: azul marino en modo claro, AppColors.dorado en modo oscuro.
  

  // ⭐ Favoritas / Importantes
  final FavoritosService _favoritosService = FavoritosService();
  bool _esFavorita = false;

  // ⚖️ Criterios jurisprudenciales (ficha técnica)
  final JurisprudenciaService _jurisService = JurisprudenciaService();
  List<Map<String, dynamic>> _criterios = [];
  bool _cargandoCriterios = false;

  // 📚 Citas a doctrina académica (autor/obra) citadas por la sentencia
  List<Map<String, dynamic>> _citasDoctrinales = [];
  bool _cargandoCitasDoctrinales = false;

  bool _mostrandoAnalisisIA = false;
  bool _analizando = false;
  AnalisisProfundoSentencia? _analisisProfundo;

  @override
  void initState() {
    super.initState();
    _cargarEstadoFavorito();
    _cargarCriterios();
    _cargarCitasDoctrinales();
  }

  Future<void> _cargarCriterios() async {
    if (_cargandoCriterios) return;
    setState(() => _cargandoCriterios = true);
    final criterios = await _jurisService
        .doctrinasDeSentencia(widget.sentencia.id);
    if (!mounted) return;
    setState(() {
      _criterios = criterios;
      _cargandoCriterios = false;
    });
  }

  Future<void> _cargarCitasDoctrinales() async {
    if (_cargandoCitasDoctrinales) return;
    setState(() => _cargandoCitasDoctrinales = true);
    final citas = await _jurisService
        .citasDoctrinalesDeSentencia(widget.sentencia.id);
    if (!mounted) return;
    setState(() {
      _citasDoctrinales = citas;
      _cargandoCitasDoctrinales = false;
    });
  }

  Future<void> _cargarEstadoFavorito() async {
    final favorita = await _favoritosService.estaFavorita(widget.sentencia.id);
    if (mounted) setState(() => _esFavorita = favorita);
  }

  Future<void> _toggleFavorita() async {
    await _favoritosService.toggleFavorita(widget.sentencia.id);
    if (!mounted) return;
    setState(() => _esFavorita = !_esFavorita);
    // Guía 3.4: AppSnackBar siempre.
    AppSnackBar.success(
      context,
      _esFavorita ? '⭐ Agregada a Favoritas' : 'Eliminada de Favoritas',
    );
  }

  /// Compartir la sentencia (resumen + enlace).
  /// Funciona en Android, iOS y Web (Web Share API).
  Future<void> _compartirSentencia() async {
    final s = widget.sentencia;
    // La fuente compartida es la copia HTML de R2 (urlParaVer): al citarla
    // se apunta al repositorio propio de Penalex (posicionamiento), no al
    // servidor del TSJ. Solo si no existe copia se cita la URL del TSJ.
    final fuente = (s.urlParaVer.isNotEmpty && s.urlParaVer != 'null')
        ? s.urlParaVer
        : (s.urlTSJ.isNotEmpty && s.urlTSJ != 'null' ? s.urlTSJ : 'No disponible');

    final texto = '⚖️ Sentencia Nº ${s.numeroSentencia}\n'
        'Sala: ${_nombreSala(s.sala)}\n'
        'Fecha: ${s.fechaSentencia}\n'
        'Delito: ${s.delito}\n\n'
        '${_textoResumen(s)}\n\n'
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
      } else {
        _mostrarSnack('La copia en el repositorio no está disponible');
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

    // Sin copia HTML en R2: avisar (nunca abrir el servidor del TSJ).
    _mostrarSnack('La copia en el repositorio no está disponible');
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
    // Guía 3.4: AppSnackBar siempre (todos los usos son fallos/avisos).
    AppSnackBar.error(context, mensaje);
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
            .from('sentencias')
            .update({'analyzed_at': DateTime.now().toIso8601String()})
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
        // Guía 3.4: AppSnackBar siempre.
        AppSnackBar.error(context, 'Error al analizar: $e');
      }
    }
  }

  void _mostrarAnalisisBottomSheet(String analisis) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TemaGlobal.tarjeta,
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
                    color: TemaGlobal.capa,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.acento, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Análisis con IA',
                      style: TextStyle(
                        color: TemaGlobal.texto,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: TemaGlobal.textoSecundario),
                  ),
                ],
              ),
              Divider(color: TemaGlobal.capa, height: 1),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: MarkdownBody(
                    data: analisis,
                    styleSheet: MarkdownStyleSheet(
                      h2: TextStyle(
                        color: AppColors.acento,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      p: TextStyle(
                        color: TemaGlobal.texto,
                        height: 1.55,
                        fontSize: 14,
                      ),
                      strong: TextStyle(
                        color: TemaGlobal.texto,
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
            appBar: AppBarInstitucional(
        title: 'Sentencia ${widget.sentencia.numeroSentencia}',
        mostrarBack: true,

        actions: [
          // ⭐ Marcar como favorita/importante
          IconButton(
            icon: Icon(
              _esFavorita ? Icons.star : Icons.star_border,
              color: AppColors.dorado,
            ),
            onPressed: _toggleFavorita,
            tooltip:
                _esFavorita ? 'Quitar de favoritas' : 'Agregar a favoritas',
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            color: AppColors.dorado,
            onPressed: _compartirSentencia,
            tooltip: 'Compartir sentencia',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            color: AppColors.dorado,
            onPressed: _descargarSentencia,
            tooltip: 'Descargar PDF estructurado',
          ),
          // 📋 Ficha técnica (metadatos + criterios jurisprudenciales)
          IconButton(
            icon: const Icon(Icons.info_outline),
            color: AppColors.dorado,
            onPressed: () => _mostrarMetadata(widget.sentencia),
            tooltip: 'Ficha técnica',
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView con la SENTENCIA DE R2 (copia fiel del TSJ alojada en
          // nuestro R2 — estable). Si no existe copia, se muestra un aviso;
          // NUNCA se carga la URL del TSJ (servidor inestable y fuera de
          // nuestro control).
          if (kIsWeb)
            _buildContenidoWeb()
          else if (widget.sentencia.urlParaVer.isNotEmpty)
            WebViewWidget(
              controller: WebViewController()
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                ..setBackgroundColor(TemaGlobal.superficie)
                // Copia fiel en R2 (guía: la sentencia siempre se muestra
                // desde nuestro repositorio, no desde el TSJ).
                ..loadRequest(Uri.parse(widget.sentencia.urlParaVer)),
            )
          else
            _buildCopiaNoDisponible(),

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
                      color: TemaGlobal.tarjeta,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: AppColors.a18),
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
                                color: AppColors.acento.withValues(alpha: AppColors.a12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                color: AppColors.acento,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Análisis con IA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: TemaGlobal.texto,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                setState(() => _mostrandoAnalisisIA = false);
                              },
                              color: TemaGlobal.textoSecundario,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_analizando)
                          Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(color: AppColors.acento),
                                SizedBox(height: 12),
                                Text(
                                  'Analizando sentencia con IA...',
                                  style: TextStyle(color: TemaGlobal.textoTenue),
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
                                  'RESUMEN EJECUTIVO',
                                  _analisisProfundo!.resumenEjecutivo,
                                ),
                                const Divider(height: 24),
                                _buildSeccionAnalisis(
                                  'RATIO DECIDENDI',
                                  _analisisProfundo!.ratioDecidendi,
                                ),
                                const Divider(height: 24),
                                _buildSeccionAnalisis(
                                  'PRECEDENTES Y CITAS CLAVE',
                                  _analisisProfundo!.precedentesClave,
                                ),
                                const Divider(height: 24),
                                _buildSeccionAnalisis(
                                  'ARGUMENTOS LEGALES PRINCIPALES',
                                  _analisisProfundo!.argumentosPrincipales,
                                ),
                                const Divider(height: 24),
                                _buildSeccionAnalisis(
                                  'IMPACTO Y APLICABILIDAD',
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
                                    // Guía 3.4: AppSnackBar siempre.
                                    AppSnackBar.success(
                                        context, 'Exportar análisis próximamente');
                                  },
                                  icon: const Icon(Icons.picture_as_pdf,
                                      size: 18),
                                  label: const Text('Exportar Análisis'),
                                  style: ElevatedButton.styleFrom(
                                    // Guía 3.2: primario = acento dinámico.
                                    backgroundColor: AppColors.acento,
                                    foregroundColor: AppColors.acento ==
                                            AppColors.dorado
                                        ? AppColors.onDorado
                                        : AppColors.onAzulMarino,
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
                              Text(
                                '💡 Resumen:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: TemaGlobal.texto,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.sentencia.resumen,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: TemaGlobal.texto,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _analizarConIA,
                                icon: const Icon(Icons.psychology, size: 18),
                                label: const Text('Análisis Profundo con IA'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.acento,
                                  foregroundColor: AppColors.acento ==
                                          AppColors.dorado
                                      ? AppColors.onDorado
                                      : AppColors.onAzulMarino,
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
                  // Guía 3.2: primario = acento dinámico (navy en claro /
                  // dorado en oscuro). El navy fijo se funde en modo oscuro.
                  backgroundColor: AppColors.acento,
                  foregroundColor: AppColors.acento == AppColors.dorado
                      ? AppColors.onDorado
                      : AppColors.onAzulMarino,
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

  /// Aviso cuando la sentencia NO tiene copia HTML en R2: se muestran los
  /// datos de la ficha y se informa que la copia aún no está disponible
  /// (nunca se abre el servidor del TSJ).
  Widget _buildCopiaNoDisponible() {
    final s = widget.sentencia;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.cloud_off_outlined,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'La copia de esta sentencia aún no está disponible en '
                    'el repositorio. Se muestra la ficha con sus datos.',
                    style: TextStyle(
                      fontSize: 13,
                      color: TemaGlobal.textoSecundario,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildWebDato('Sala', _nombreSala(s.sala)),
          _buildWebDato('Nº de sentencia', s.numeroSentencia),
          _buildWebDato('Fecha', s.fechaSentencia),
          _buildWebDato('Ponente', s.ponente),
          _buildWebDato('Delito', s.delito),
          _buildWebDato('Decisión', s.decision),
          _buildWebDato('Tipo', s.tipoSentencia),
          const Divider(height: 32),
          Text(
            '📋 Resumen',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: TemaGlobal.texto,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(_textoResumen(s),
              style: const TextStyle(fontSize: 14, height: 1.5)),
          const SizedBox(height: 24),
          _buildSeccionCriterios(),
          const SizedBox(height: 24),
          _buildSeccionCitasDoctrinales(),
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
          _buildWebDato('Sala', _nombreSala(s.sala)),
          _buildWebDato('Nº de sentencia', s.numeroSentencia),
          _buildWebDato('Fecha', s.fechaSentencia),
          _buildWebDato('Ponente', s.ponente),
          _buildWebDato('Delito', s.delito),
          _buildWebDato('Decisión', s.decision),
          _buildWebDato('Tipo', s.tipoSentencia),
          const Divider(height: 32),
          Text(
            '📋 Resumen',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: TemaGlobal.texto,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          // ratio decidendi > resumen IA > extracto (nunca vacío si hay datos)
          Text(_textoResumen(s),
              style: const TextStyle(fontSize: 14, height: 1.5)),
          const SizedBox(height: 24),
          _buildSeccionCriterios(),
          const SizedBox(height: 24),
          _buildSeccionCitasDoctrinales(),
          const SizedBox(height: 24),
          if (s.urlParaVer.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _descargarSentencia,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir documento completo en el navegador'),
                style: ElevatedButton.styleFrom(
                  // Guía 3.2: primario = acento dinámico (navy en claro /
                  // dorado en oscuro).
                  backgroundColor: AppColors.acento,
                  foregroundColor: AppColors.acento == AppColors.dorado
                      ? AppColors.onDorado
                      : AppColors.onAzulMarino,
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
                color: TemaGlobal.textoSecundario,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(color: TemaGlobal.texto,
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
          Icon(icon, size: 18, color: AppColors.acento),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: TemaGlobal.textoSecundario,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: TemaGlobal.texto,
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
          style: TextStyle(color: TemaGlobal.texto,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          contenido,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: TemaGlobal.texto,
          ),
        ),
      ],
    );
  }

  /// Sección "⚖️ Criterios jurisprudenciales" de la ficha técnica.
  ///
  /// Muestra los criterios de la Sala para esta sentencia: extractos OFICIALES
  /// de la página de jurisprudencias del TSJ (tipo 'jurisprudencia') y, si no
  /// los hay, los extraídos por IA. Cada criterio con su cita textual.
  Widget _buildSeccionCriterios() {
    if (_cargandoCriterios) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (_criterios.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚖️ Criterios jurisprudenciales (${_criterios.length})',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: TemaGlobal.texto,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        for (final c in _criterios) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TemaGlobal.capa.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.acento.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.gavel, size: 16, color: AppColors.acento),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        (c['tipo'] ?? '') == 'jurisprudencia'
                            ? 'Criterio oficial de la Sala'
                            : 'Criterio de la Sala',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: TemaGlobal.texto,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _textoCriterio(c),
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
                if (_citaCriterio(c).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: TemaGlobal.tarjeta,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '«${_citaCriterio(c)}»',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: TemaGlobal.textoSecundario,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  /// Sección "📚 Doctrina académica citada" de la ficha técnica.
  ///
  /// Muestra las citas a autores/obras académicos que la sentencia invoca
  /// (extraídas por IA con cita textual literal verificada). Si la tabla aún
  /// no existe en la BD (migración pendiente) o no hay citas, no se muestra.
  Widget _buildSeccionCitasDoctrinales() {
    if (_cargandoCitasDoctrinales) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (_citasDoctrinales.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📚 Doctrina académica citada (${_citasDoctrinales.length})',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: TemaGlobal.texto,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        for (final c in _citasDoctrinales) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TemaGlobal.capa.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.acento.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_book, size: 16, color: AppColors.acento),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _nombreCitaDoctrinal(c),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: TemaGlobal.texto,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  (c['parrafo_evidencia'] ?? '').toString().trim(),
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  /// "AUTOR — Obra, p. X" de una cita doctrinal (o solo autor / solo obra).
  String _nombreCitaDoctrinal(Map<String, dynamic> c) {
    final autor = (c['autor'] ?? '').toString().trim();
    final obra = (c['obra'] ?? '').toString().trim();
    final pagina = (c['pagina'] ?? '').toString().trim();
    String base;
    if (autor.isNotEmpty && obra.isNotEmpty) {
      base = '$autor — $obra';
    } else if (autor.isNotEmpty) {
      base = autor;
    } else if (obra.isNotEmpty) {
      base = obra;
    } else {
      base = 'Cita doctrinal';
    }
    if (pagina.isNotEmpty && pagina != 'null') {
      return '$base, $pagina';
    }
    return base;
  }

  String _textoCriterio(Map<String, dynamic> c) {
    final texto = (c['texto_ratio'] ?? '').toString().trim();
    if (texto.isNotEmpty && texto != 'null') return texto;
    return (c['resumen'] ?? '').toString().trim();
  }

  String _citaCriterio(Map<String, dynamic> c) {
    final ev = (c['parrafo_evidencia'] ?? '').toString().trim();
    if (ev.isEmpty || ev == 'null') return '';
    final texto = _textoCriterio(c);
    // Si la cita es casi el mismo texto que el criterio, no duplicar.
    if (texto.isNotEmpty && ev == texto) return '';
    if (ev.length > 600) return '${ev.substring(0, 600)}…';
    return ev;
  }

  /// Texto de vista previa: prioriza ratio decidendi, luego resumen IA,
  /// luego extracto (mismo criterio que la pantalla de listado).
  String _textoResumen(SentenciaModel s) {
    final texto = s.ratioDecidendi.isNotEmpty
        ? s.ratioDecidendi
        : (s.resumen.isNotEmpty ? s.resumen : s.extracto);
    return (texto == 'null') ? '' : texto;
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
                color: TemaGlobal.textoSecundario,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(color: TemaGlobal.texto, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Ficha técnica: bottom sheet con metadatos y criterios jurisprudenciales
  /// (incluida la doctrina académica citada) de la sentencia.
  void _mostrarMetadata(SentenciaModel s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TemaGlobal.tarjeta,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: TemaGlobal.capa,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sentencia Nº ${s.numeroSentencia}',
                  style: TextStyle(
                    color: AppColors.acento,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 14),
                _filaMeta('Sala', _nombreSala(s.sala)),
                _filaMeta('Ponente', s.ponente),
                _filaMeta('Fecha', s.fechaSentencia),
                _filaMeta('Delito', s.delito),
                _filaMeta('Materia', s.materia),
                _filaMeta('Partes', s.partes),
                _filaMeta('Tipo', s.tipoSentencia),
                // ⚖️ Criterios jurisprudenciales de la sentencia
                if (_criterios.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Divider(color: TemaGlobal.capa, height: 1),
                  const SizedBox(height: 12),
                  Text(
                    '⚖️ Criterios jurisprudenciales (${_criterios.length})',
                    style: TextStyle(
                      color: AppColors.acento,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final c in _criterios)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: TemaGlobal.capa,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (c['tipo'] ?? '') == 'jurisprudencia'
                                  ? '★ Criterio oficial de la Sala'
                                  : 'Criterio de la Sala',
                              style: TextStyle(
                                color: AppColors.acento,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _textoCriterio(c),
                              style: TextStyle(
                                color: TemaGlobal.texto,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                            if (_citaCriterio(c).isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                '«${_citaCriterio(c)}»',
                                style: TextStyle(
                                  color: TemaGlobal.textoSecundario,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
                // 📚 Doctrina académica citada
                if (_citasDoctrinales.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Divider(color: TemaGlobal.capa, height: 1),
                  const SizedBox(height: 12),
                  Text(
                    '📚 Doctrina académica citada (${_citasDoctrinales.length})',
                    style: TextStyle(
                      color: AppColors.acento,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final c in _citasDoctrinales)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: TemaGlobal.capa,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nombreCitaDoctrinal(c),
                              style: TextStyle(
                                color: AppColors.acento,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (c['parrafo_evidencia'] ?? '').toString().trim(),
                              style: TextStyle(
                                color: TemaGlobal.texto,
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Nombre legible de la sala para tarjetas y fichas (código BD → etiqueta).
/// Penalex solo indexa 2 salas del TSJ: Casación Penal y Constitucional.
String _nombreSala(String codigo) {
  switch (codigo.toLowerCase()) {
    case 'scp':
      return 'Sala de Casación Penal';
    case 'scon':
      return 'Sala Constitucional';
    default:
      return codigo.isEmpty ? 'Sala' : codigo;
  }
}

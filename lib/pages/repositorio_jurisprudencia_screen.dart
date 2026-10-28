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

import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../services/jurisprudencia_service.dart';
import '../services/ai_service.dart';
import '../services/sentencia_pdf_service.dart';
import '../services/favoritos_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/main_bottom_bar.dart';
import '../widgets/app_bar_institucional.dart';

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
  final TextEditingController _searchController = TextEditingController();

  List<SentenciaModel> _resultados = [];
  List<SentenciaModel> _todosResultados = [];

  bool _cargando = false;

  // ⭐ Favoritas / Importantes
  final FavoritosService _favoritosService = FavoritosService();
  Set<String> _idsFavoritos = {};
  bool _soloFavoritas = false;

  // ✅ Filtros
  String _tipoSeleccionado = 'Sentencias';
  String? _salaSeleccionada;
  int? _anioSeleccionado;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _cargarFavoritos(); // ⭐ Cargar favoritas guardadas
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

        // ⭐ Aplicar filtro de favoritas si está activo
        _aplicarFiltroFavoritas();

        _cargando = false;
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          esFavorita ? '⭐ Agregada a Favoritas' : 'Eliminada de Favoritas',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
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
    final List<int> years =
        List.generate(currentYear - 1999, (index) => currentYear - index);

    Widget chip(String label,
        {required bool activo, required VoidCallback onTap}) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: activo,
          onSelected: (_) => onTap(),
          selectedColor: AppColors.dorado,
          backgroundColor: Colors.transparent,
          labelStyle: TextStyle(
            color: activo ? AppColors.azulMarino : TemaGlobal.texto,
            fontWeight: activo ? FontWeight.bold : FontWeight.normal,
            fontSize: 12.5,
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
        // Fila 1: favoritas + tipo
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              chip('⭐ Favoritas', activo: _soloFavoritas, onTap: () {
                setState(() => _soloFavoritas = !_soloFavoritas);
                _aplicarFiltroFavoritas();
              }),
              chip('Sentencias', activo: _tipoSeleccionado == 'Sentencias',
                  onTap: () {
                setState(() => _tipoSeleccionado = 'Sentencias');
                _buscar();
              }),
              chip('Jurisprudencias',
                  activo: _tipoSeleccionado == 'Jurisprudencias', onTap: () {
                setState(() {
                  _tipoSeleccionado = 'Jurisprudencias';
                  _salaSeleccionada = null;
                });
                _buscar();
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Fila 2: sala + año
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              chip('Sala: Todas', activo: _salaSeleccionada == null, onTap: () {
                setState(() => _salaSeleccionada = null);
                _buscar();
              }),
              chip('Penal',
                  activo: _salaSeleccionada == 'scp',
                  onTap: () {
                setState(() => _salaSeleccionada = 'Sala de Casación Penal');
                _buscar();
              }),
              chip('Constitucional',
                  activo: _salaSeleccionada == 'scon',
                  onTap: () {
                setState(() => _salaSeleccionada = 'Sala Constitucional');
                _buscar();
              }),
              // Año
              PopupMenuButton<int?>(
                initialValue: _anioSeleccionado,
                onSelected: (value) {
                  setState(() => _anioSeleccionado = value);
                  _buscar();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<int?>(
                      value: null, child: Text('Todos los años')),
                  ...years.map(
                      (y) => PopupMenuItem<int?>(value: y, child: Text('$y'))),
                ],
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    avatar: Icon(Icons.calendar_month,
                        size: 15, color: AppColors.acento.withValues(alpha: 0.8)),
                    label: Text(_anioSeleccionado?.toString() ?? 'Año'),
                    backgroundColor: Colors.transparent,
                    labelStyle:
                        TextStyle(color: TemaGlobal.texto, fontSize: 12.5),
                    side:
                        BorderSide(color: TemaGlobal.capa),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/repositorio_jurisprudencia'),
            appBar: AppBarInstitucional(
        title: 'Jurisprudencia',
        mostrarBack: true,
        mostrarHome: true,
        actions: [
          // ✅ Contador de resultados simple
          if (!_cargando && _resultados.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_resultados.length} ${_resultados.length == 1 ? "resultado" : "resultados"}',
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
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: TemaGlobal.texto, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Buscar por número, delito, partes...',
                    hintStyle: TextStyle(
                      color: TemaGlobal.textoTenue,
                      fontSize: 15,
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
                      borderSide: BorderSide(color: AppColors.acento, width: 2),
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

          // ✅ Lista de resultados limpia
          Expanded(
            child: _cargando
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.acento,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Buscando sentencias...',
                          style: TextStyle(
                            color: TemaGlobal.texto.withValues(alpha: 0.6),
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
                            return _buildSentenciaCard(
                                _resultados[index], index);
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
                backgroundColor: AppColors.azulMarino,
                foregroundColor: AppColors.dorado,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: TemaGlobal.capa, width: 1),
      ),
      child: InkWell(
        onTap: () => _verSentencia(sentencia),
        borderRadius: BorderRadius.circular(14),
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
                        fontSize: 10.5,
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
                          color: AppColors.azulMarino,
                          fontSize: 9.5,
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
                          ? Colors.amber
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
                    '${sentencia.sala} · ${sentencia.fechaSentencia}',
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
              // Pie: decisión + acciones
              Row(
                children: [
                  if (sentencia.decision.isNotEmpty &&
                      sentencia.decision != 'null')
                    _chipDecision(sentencia.decision),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _mostrarMetadata(sentencia),
                    icon: Icon(Icons.info_outline,
                        size: 18, color: TemaGlobal.textoSecundario),
                    tooltip: 'Ver metadata',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
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
                _filaMeta('Sala', s.sala),
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
                                fontSize: 11.5,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al analizar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
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
        mostrarHome: true,
        actions: [
          // ⭐ Marcar como favorita/importante
          IconButton(
            icon: Icon(
              _esFavorita ? Icons.star : Icons.star_border,
              color: _esFavorita ? Colors.amber : null,
            ),
            onPressed: _toggleFavorita,
            tooltip:
                _esFavorita ? 'Quitar de favoritas' : 'Agregar a favoritas',
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
          // 📋 Ficha técnica (metadatos + criterios jurisprudenciales)
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _mostrarMetadata(widget.sentencia),
            tooltip: 'Ficha técnica',
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Exportar análisis próximamente'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.picture_as_pdf,
                                      size: 18),
                                  label: const Text('Exportar Análisis'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.azulMarino,
                                    foregroundColor: AppColors.dorado,
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
                                  backgroundColor: AppColors.azulMarino,
                                  foregroundColor: AppColors.dorado,
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
                  backgroundColor: AppColors.azulMarino,
                  foregroundColor: AppColors.dorado,
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
                  backgroundColor: AppColors.azulMarino,
                  foregroundColor: AppColors.dorado,
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
                          fontSize: 12.5,
                          color: TemaGlobal.texto,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _textoCriterio(c),
                  style: const TextStyle(fontSize: 13.5, height: 1.5),
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
                          fontSize: 12.5,
                          color: TemaGlobal.texto,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  (c['parrafo_evidencia'] ?? '').toString().trim(),
                  style: const TextStyle(fontSize: 13.5, height: 1.5),
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
                _filaMeta('Sala', s.sala),
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
                                fontSize: 11.5,
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
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (c['parrafo_evidencia'] ?? '').toString().trim(),
                              style: TextStyle(
                                color: TemaGlobal.texto,
                                fontSize: 12.5,
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

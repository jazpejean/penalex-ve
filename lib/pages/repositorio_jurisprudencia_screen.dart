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

import '../config/app_theme.dart';
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
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
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
          selectedColor: dorado,
          backgroundColor: Colors.transparent,
          labelStyle: TextStyle(
            color: activo ? azulMarino : Colors.white,
            fontWeight: activo ? FontWeight.bold : FontWeight.normal,
            fontSize: 12.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: activo ? dorado : Colors.white.withValues(alpha: 0.5)),
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
                        size: 15, color: dorado.withValues(alpha: 0.8)),
                    label: Text(_anioSeleccionado?.toString() ?? 'Año'),
                    backgroundColor: Colors.transparent,
                    labelStyle:
                        const TextStyle(color: Colors.white, fontSize: 12.5),
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.5)),
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
      appBar: AppBar(
        title: const Text(
          'Jurisprudencia',
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
                    prefixIcon:
                        const Icon(Icons.search, color: dorado, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: dorado, size: 20),
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
                    Icon(Icons.auto_awesome,
                        size: 12, color: dorado.withOpacity(0.6)),
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
              color: azulMarino.withOpacity(0.2),
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
                backgroundColor: azulMarino,
                foregroundColor: dorado,
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
      shadowColor: azulMarino.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: azulMarino.withValues(alpha: 0.08), width: 1),
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
                      color: azulMarino,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _etiquetaDelito(sentencia),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
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
                        color: dorado,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Vinculante',
                        style: TextStyle(
                          color: TemaGlobal.texto,
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
                        size: 18, color: azulMarino.withValues(alpha: 0.45)),
                    tooltip: 'Ver metadata',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                  TextButton(
                    onPressed: () => _verSentencia(sentencia),
                    style: TextButton.styleFrom(
                      foregroundColor: azulMarino,
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
  Widget _chipDecision(String decision) {
    final d = decision.toUpperCase();
    Color bg;
    Color fg;
    if (d.contains('CON LUGAR')) {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
    } else if (d.contains('SIN LUGAR') ||
        d.contains('IMPROCEDENTE') ||
        d.contains('INADMISIBLE')) {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFB91C1C);
    } else if (d.contains('REVOCA') ||
        d.contains('ANULA') ||
        d.contains('NULIDAD')) {
      bg = const Color(0xFFFFEDD5);
      fg = const Color(0xFFC2410C);
    } else {
      bg = const Color(0xFFE2E8F0);
      fg = const Color(0xFF334155);
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
  static const Color dorado = Color(0xFFC5A059);

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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: dorado,
          ),
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
                                CircularProgressIndicator(color: dorado),
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
          Text(
            '📋 Resumen',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: TemaGlobal.texto,
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

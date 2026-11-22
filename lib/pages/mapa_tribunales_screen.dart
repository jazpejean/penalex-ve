import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../services/tribunales_service.dart';
import '../widgets/main_bottom_bar.dart';
import 'tribunal_detail_screen.dart';
import '../widgets/app_bar_institucional.dart';
import '../config/app_tokens.dart';

/// Mapa de tribunales penales de Venezuela (catálogo oficial TSJ).
class MapaTribunalesScreen extends StatefulWidget {
  const MapaTribunalesScreen({super.key});

  @override
  State<MapaTribunalesScreen> createState() => _MapaTribunalesScreenState();
}

class _MapaTribunalesScreenState extends State<MapaTribunalesScreen> {
  final MapController _mapController = MapController();
  bool _modoCircuitos = true; // Vista por defecto: circuitos judiciales
  String? _circuitoSeleccionado;
  List<Tribunal> _tribunales = [];
  List<Tribunal> _visibles = [];
  bool _cargando = true;
  String? _error;
  String? _filtroEstado;
  String? _filtroFuncion;
  String? _filtroInstancia;
  String? _filtroSeccion;
  String _busqueda = '';
  String _busquedaInput = '';
  Timer? _debounce;
  Tribunal? _seleccionado;
  bool _filtrosAvanzados = false;

  final _busquedaController = TextEditingController();

  static const _centroVzla = LatLng(9.3, -66.2);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final tribs = await TribunalesService.listarConUbicacion();
      setState(() {
        _tribunales = tribs;
        _visibles = tribs;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _cargando = false;
        _error = 'No se pudo cargar el catálogo de tribunales. $e';
      });
    }
  }

  /// Búsqueda con debounce (300 ms) para no reconstruir el mapa en cada tecla.
  void _onBusquedaCambio(String valor) {
    _busquedaInput = valor;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _busqueda = _busquedaInput.trim().toLowerCase());
      _aplicarFiltros();
    });
  }

  void _aplicarFiltros() {
    // Filtro por TEXTO local primero: lista TODOS los tribunales que
    // coinciden (buscar "Los Teques" muestra los ~20 de esa sede).
    // La semántica solo se usa como refuerzo si el texto no da resultados.
    final q = _busqueda.trim();
    if (q.isNotEmpty) {
      _buscarLocal(q);
      return;
    }
    setState(() {
      _visibles = _tribunales.where((t) {
        final okEstado =
            _filtroEstado == null || t.estado == _filtroEstado;
        final okFuncion =
            _filtroFuncion == null || t.funcion == _filtroFuncion;
        final okInstancia =
            _filtroInstancia == null || t.instancia == _filtroInstancia;
        final okSeccion = _filtroSeccion == null || t.seccion == _filtroSeccion;
        return okEstado && okFuncion && okInstancia && okSeccion;
      }).toList();
      _seleccionado = null;
    });
  }

  /// Filtro local por texto sobre el catálogo ya cargado; semántica solo
  /// si el texto no coincidió con nada.
  Future<void> _buscarLocal(String q) async {
    // Asegura la caché del catálogo (para filtrarPorTexto).
    await TribunalesService.listar();
    if (!mounted) return;
    final locales = TribunalesService.filtrarPorTexto(q);
    if (locales.isNotEmpty) {
      setState(() {
        _visibles = locales.where((t) {
          final okEstado =
              _filtroEstado == null || t.estado == _filtroEstado;
          final okFuncion =
              _filtroFuncion == null || t.funcion == _filtroFuncion;
          final okInstancia =
              _filtroInstancia == null || t.instancia == _filtroInstancia;
          final okSeccion =
              _filtroSeccion == null || t.seccion == _filtroSeccion;
          return okEstado && okFuncion && okInstancia && okSeccion;
        }).toList();
        _seleccionado = null;
      });
      return;
    }
    await _buscarSemantico(q);
  }

  Future<void> _buscarSemantico(String q) async {
    final resultados = await TribunalesService.buscarSemantico(
      q,
      estado: _filtroEstado,
      funcion: _filtroFuncion,
      instancia: _filtroInstancia,
      seccion: _filtroSeccion,
      limite: 30,
    );
    if (!mounted) return;
    // Umbral de distancia coseno: las coincidencias reales de bge-m3
    // quedan < 0.52; lo más lejano es ruido y cae al filtro tradicional.
    const umbral = 0.52;
    if (resultados != null && resultados.isNotEmpty) {
      final relevantes = resultados
          .where((t) => t.distancia != null && t.distancia! < umbral)
          .toList();
      if (relevantes.isNotEmpty) {
        setState(() {
          _visibles = relevantes;
          _seleccionado = null;
        });
        return;
      }
    }
    // Sin coincidencias semánticas relevantes o worker caído:
    // filtro tradicional (substring + filtros).
    setState(() {
      _visibles = _tribunales.where((t) {
        final haystack = [
          t.nombre,
          t.codigo,
          t.sede ?? '',
          t.municipio ?? '',
          t.estado,
          t.parroquia ?? '',
          t.seccion ?? '',
        ].join(' ').toLowerCase();
        if (!haystack.contains(q.toLowerCase())) return false;
        final okEstado =
            _filtroEstado == null || t.estado == _filtroEstado;
        final okFuncion =
            _filtroFuncion == null || t.funcion == _filtroFuncion;
        final okInstancia =
            _filtroInstancia == null || t.instancia == _filtroInstancia;
        final okSeccion = _filtroSeccion == null || t.seccion == _filtroSeccion;
        return okEstado && okFuncion && okInstancia && okSeccion;
      }).toList();
      _seleccionado = null;
    });
  }

  void _limpiarFiltros() {
    _busquedaController.clear();
    _busquedaInput = '';
    _busqueda = '';
    _debounce?.cancel();
    setState(() {
      _filtroEstado = null;
      _filtroFuncion = null;
      _filtroInstancia = null;
      _filtroSeccion = null;
    });
    _aplicarFiltros();
  }

  bool get _hayFiltrosActivos =>
      _busqueda.isNotEmpty ||
      _filtroEstado != null ||
      _filtroFuncion != null ||
      _filtroInstancia != null ||
      _filtroSeccion != null;

  List<String> get _funcionesUnicas {
    final set = <String>{};
    for (final t in _tribunales) {
      if (t.funcion != null && t.funcion!.isNotEmpty) set.add(t.funcion!);
    }
    return set.toList()..sort();
  }

  List<String> get _estadosUnicos {
    final set = <String>{};
    for (final t in _tribunales) {
      set.add(t.estado);
    }
    return set.toList()..sort();
  }

  List<String> get _instanciasUnicas {
    final set = <String>{};
    for (final t in _tribunales) {
      if (t.instancia.isNotEmpty) set.add(t.instancia);
    }
    return set.toList()..sort();
  }

  List<String> get _seccionesUnicas {
    final set = <String>{};
    for (final t in _tribunales) {
      if (t.seccion != null && t.seccion!.isNotEmpty) set.add(t.seccion!);
    }
    return set.toList()..sort();
  }

  Color _colorPorFuncion(String? funcion) {
    switch (funcion?.toUpperCase()) {
      case 'CONTROL':
        return Colors.blue.shade700;
      case 'JUICIO':
        return Colors.deepPurple.shade600;
      case 'EJECUCIÓN':
        return Colors.orange.shade800;
      case 'APELACIÓN':
        return Colors.teal.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            appBar: AppBarInstitucional(
        title: 'Mapa de Tribunales Penales',
        mostrarBack: true,

      ),
      bottomNavigationBar: const MainBottomBar(),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorVista(mensaje: _error!, onRetry: _cargar)
              : Column(
                  children: [
                    _buscadorBar(),
                    _toggleModo(),
                    _filtrosBar(),
                    _contadorBar(),
                    Expanded(
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _centroVzla,
                              initialZoom: 5.6,
                              minZoom: 4.5,
                              maxZoom: 16,
                              onTap: (_, __) =>
                                  setState(() => _seleccionado = null),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.penalex.ve',
                              ),
                              MarkerLayer(
                                markers: _markersSeparados(),
                              ),
                            ],
                          ),
                          if (_modoCircuitos && _circuitoSeleccionado != null)
                            _fichaCircuito(
                                _circuitoSeleccionado!,
                                _porCircuito[_circuitoSeleccionado!] ?? const []),
                          if (!_modoCircuitos && _seleccionado != null)
                            _fichaTribunal(_seleccionado!),
                          if (_visibles.isEmpty)
                            const Center(
                              child: Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                      'Sin tribunales con esos criterios'),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _leyenda(),
                  ],
                ),
    );
  }

  Widget _buscadorBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _busquedaController,
              onChanged: _onBusquedaCambio,
              decoration: InputDecoration(
                hintText:
                    'Buscar por nombre, código, sede, municipio, estado…',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radioControl),
                ),
                suffixIcon: _busquedaInput.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _busquedaController.clear();
                          _onBusquedaCambio('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            icon: const Icon(Icons.tune),
            tooltip: 'Filtros avanzados',
            onPressed: () =>
                setState(() => _filtrosAvanzados = !_filtrosAvanzados),
          ),
          if (_hayFiltrosActivos)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Limpiar filtros',
              onPressed: _limpiarFiltros,
            ),
        ],
      ),
    );
  }

  Widget _filtrosBar() {
    final avanzados = _filtrosAvanzados;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _filtroEstado,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ..._estadosUnicos.map((e) => DropdownMenuItem<String?>(
                        value: e, child: Text(e, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) {
                    _filtroEstado = v;
                    _aplicarFiltros();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _filtroFuncion,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Función',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    ..._funcionesUnicas.map((f) => DropdownMenuItem<String?>(
                        value: f,
                        child: Text(f, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) {
                    _filtroFuncion = v;
                    _aplicarFiltros();
                  },
                ),
              ),
            ],
          ),
          if (avanzados) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _filtroInstancia,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Instancia',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      ..._instanciasUnicas.map((i) =>
                          DropdownMenuItem<String?>(value: i, child: Text(i))),
                    ],
                    onChanged: (v) {
                      _filtroInstancia = v;
                      _aplicarFiltros();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _filtroSeccion,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Sección',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      ..._seccionesUnicas.map((s) => DropdownMenuItem<String?>(
                          value: s,
                          child: Text(s, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) {
                      _filtroSeccion = v;
                      _aplicarFiltros();
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _toggleModo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment<bool>(
            value: true,
            label: Text('Circuitos', style: TextStyle(fontSize: 12)),
            icon: Icon(Icons.account_balance, size: 16),
          ),
          ButtonSegment<bool>(
            value: false,
            label: Text('Tribunales', style: TextStyle(fontSize: 12)),
            icon: Icon(Icons.gavel, size: 16),
          ),
        ],
        selected: {_modoCircuitos},
        onSelectionChanged: (v) {
          setState(() {
            _modoCircuitos = v.first;
            _circuitoSeleccionado = null;
            _seleccionado = null;
          });
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  Widget _contadorBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Row(
        children: [
          Text(
            '${_visibles.length} de ${_tribunales.length} tribunales',
            style: TextStyle(
              fontSize: 12,
              color: TemaGlobal.textoTenue,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (_hayFiltrosActivos)
            InkWell(
              onTap: _limpiarFiltros,
              child: Text(
                'Limpiar filtros',
                style: TextStyle(
                  fontSize: 12,
                  color: TemaGlobal.isDark
                      ? TemaGlobal.dorado
                      : TemaGlobal.azulMarino,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _marcadorIcon(Tribunal t) {
    return Container(
      decoration: BoxDecoration(
        color: _colorPorFuncion(t.funcion),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Icon(
        _iconoPorFuncion(t.funcion),
        color: Colors.white,
        size: 20,
      ),
    );
  }

  /// Construye los markers separando los tribunales que comparten la MISMA
  /// coordenada (varios tribunales en un mismo palacio de justicia). Sin
  /// esta separación, los 16 de "Los Teques" se apilan en un solo punto y
  /// solo se ve el último dibujado; con el desplazamiento en espiral se
  /// ven todos y cada uno es tocable.
  List<Marker> _markersSeparados() {
    if (_modoCircuitos) return _markersCircuitos();
    const radio = 0.0016; // ~170 m: separación visible en el zoom urbano.
    final conUbicacion =
        _visibles.where((t) => t.latLng != null).toList();
    // Agrupa por coordenada redondeada (≈ 8 m) para detectar apilados.
    final grupos = <String, List<Tribunal>>{};
    for (final t in conUbicacion) {
      final p = t.latLng!;
      final clave =
          '${p.latitude.toStringAsFixed(4)},${p.longitude.toStringAsFixed(4)}';
      grupos.putIfAbsent(clave, () => []).add(t);
    }
    final markers = <Marker>[];
    for (final grupo in grupos.values) {
      if (grupo.length == 1) {
        final t = grupo.single;
        markers.add(_markerEn(t.latLng!, t));
        continue;
      }
      // Espiral de ángulo AppColors.dorado: reparte los N del mismo punto.
      for (var i = 0; i < grupo.length; i++) {
        final t = grupo[i];
        final angulo = i * 2.399963; // ángulo AppColors.dorado (rad)
        final d = radio * (0.4 + i * 0.22);
        final punto = LatLng(
          t.latLng!.latitude + d * math.cos(angulo),
          t.latLng!.longitude + d * math.sin(angulo),
        );
        markers.add(_markerEn(punto, t));
      }
    }
    return markers;
  }

  Marker _markerEn(LatLng punto, Tribunal t) {
    return Marker(
      point: punto,
      width: 36,
      height: 36,
      child: GestureDetector(
        onTap: () => setState(() => _seleccionado = t),
        child: _marcadorIcon(t),
      ),
    );
  }

  IconData _iconoPorFuncion(String? funcion) {
    switch (funcion?.toUpperCase()) {
      case 'CONTROL':
        return Icons.security;
      case 'JUICIO':
        return Icons.gavel;
      case 'EJECUCIÓN':
        return Icons.lock_outline;
      case 'APELACIÓN':
        return Icons.account_balance;
      default:
        return Icons.location_on;
    }
  }

  // ============ MODO CIRCUITOS JUDICIALES ============

  /// Agrupa los tribunales visibles por circunscripción judicial.
  Map<String, List<Tribunal>> get _porCircuito {
    final mapa = <String, List<Tribunal>>{};
    for (final t in _visibles) {
      mapa.putIfAbsent(t.circunscripcionJudicial, () => []).add(t);
    }
    // ordena alfabéticamente
    final claves = mapa.keys.toList()..sort();
    return {for (final k in claves) k: mapa[k]!};
  }

  /// Centroide de un grupo de tribunales con coordenadas.
  LatLng? _centroide(List<Tribunal> grupo) {
    final conGeo = grupo.where((t) => t.latLng != null).toList();
    if (conGeo.isEmpty) return null;
    var lat = 0.0;
    var lng = 0.0;
    for (final t in conGeo) {
      lat += t.latLng!.latitude;
      lng += t.latLng!.longitude;
    }
    return LatLng(lat / conGeo.length, lng / conGeo.length);
  }

  /// Marcadores de CIRCUITOS: uno por circunscripción, con el conteo.
  List<Marker> _markersCircuitos() {
    final markers = <Marker>[];
    _porCircuito.forEach((circuito, grupo) {
      final centro = _centroide(grupo);
      if (centro == null) return;
      final seleccionado = _circuitoSeleccionado == circuito;
      markers.add(Marker(
        point: centro,
        width: 64,
        height: 64,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _circuitoSeleccionado = circuito;
              _seleccionado = null;
            });
            _mapController.move(centro, 8.2);
          },
          child: _marcadorCircuito(grupo.length, seleccionado),
        ),
      ));
    });
    return markers;
  }

  Widget _marcadorCircuito(int cantidad, bool seleccionado) {
    final color =
        TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: seleccionado ? color : color.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: const Icon(Icons.account_balance,
              color: Colors.white, size: 21),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTokens.radioControl),
            border: Border.all(color: color, width: 1),
          ),
          child: Text(
            '$cantidad',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// Ficha de un circuito judicial con su lista de tribunales.
  Widget _fichaCircuito(String circuito, List<Tribunal> grupo) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 16,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radioTarjeta)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            circuito,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14.5),
                          ),
                          Text(
                            '${grupo.length} tribunal(es) · ${grupo.map((t) => t.estado).toSet().join(', ')}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: TemaGlobal.textoSecundario,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          setState(() => _circuitoSeleccionado = null),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: grupo.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final t = grupo[i];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        _iconoPorFuncion(t.funcion),
                        size: 20,
                        color: _colorPorFuncion(t.funcion),
                      ),
                      title: Text(
                        t.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      subtitle: Text(
                        [t.municipio, t.estado]
                            .where((e) => e != null && e.isNotEmpty)
                            .join(' · '),
                        style: const TextStyle(fontSize: 10.5),
                      ),
                      trailing: t.latLng != null
                          ? const Icon(Icons.my_location, size: 16)
                          : null,
                      onTap: () {
                        setState(() {
                          _seleccionado = t;
                          _circuitoSeleccionado = null;
                        });
                        if (t.latLng != null) {
                          _mapController.move(t.latLng!, 13.5);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fichaTribunal(Tribunal t) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 16,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radioTarjeta)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Foto del tribunal en contenedor FIJO: todas las imágenes se
            // muestran del mismo tamaño (220x110, cover), sin importar la
            // resolución original de la foto en R2.
            SizedBox(
              width: double.infinity,
              height: 110,
              child: t.urlFoto == null || t.urlFoto!.isEmpty
                  ? _fichaFotoPlaceholder()
                  : CachedNetworkImage(
                      imageUrl: t.urlFoto!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _fichaFotoPlaceholder(),
                      errorWidget: (_, __, ___) => _fichaFotoPlaceholder(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.nombre,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _seleccionado = null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _filaInfo(Icons.map, '${t.sede ?? ''} — ${t.estado}'),
                  if (t.municipio != null)
                    _filaInfo(Icons.location_city, t.municipio!),
                  _filaInfo(Icons.account_balance, t.circunscripcionJudicial),
                  _filaInfo(Icons.badge, '${t.etiquetaFuncion}'),
                  _filaInfo(Icons.verified, t.instancia),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          'Despacho: ${t.despacho}',
                          style: TextStyle(
                            color: t.despacho == 'con despacho'
                                ? (TemaGlobal.isDark
                                    ? AppColors.success
                                    : AppColors.success)
                                : (TemaGlobal.isDark
                                    ? AppColors.warning
                                    : AppColors.warning),
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: t.despacho == 'con despacho'
                            ? AppColors.success.withValues(
                                alpha: TemaGlobal.isDark ? 0.22 : 0.14)
                            : AppColors.warning.withValues(
                                alpha: TemaGlobal.isDark ? 0.22 : 0.14),
                        visualDensity: VisualDensity.compact,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TribunalDetailScreen(tribunal: t),
                          ),
                        ),
                        icon: const Icon(Icons.open_in_full, size: 18),
                        label: const Text('Ver ficha'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fichaFotoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 110,
      color: AppColors.capa,
      alignment: Alignment.center,
      child: Icon(
        Icons.account_balance,
        size: 40,
        color: AppColors.textoSecundario,
      ),
    );
  }

  Widget _filaInfo(IconData icon, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: TemaGlobal.textoTenue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(fontSize: 13, color: TemaGlobal.texto),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leyenda() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppColors.azulMarino,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _leyendaItem(Colors.blue.shade700, 'Control'),
          _leyendaItem(Colors.deepPurple.shade600, 'Juicio'),
          _leyendaItem(Colors.orange.shade800, 'Ejecución'),
          _leyendaItem(Colors.teal.shade700, 'Apelación'),
        ],
      ),
    );
  }

  Widget _leyendaItem(Color color, String texto) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(texto,
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

class _ErrorVista extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;
  const _ErrorVista({required this.mensaje, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
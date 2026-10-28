// Buscador Jurídico unificado — "nivel Venley".
// Un solo buscador con alcance segmentado: Sentencias / Leyes / Glosario.
// El segmentado cambia el corpus EN LA MISMA PANTALLA (como Venley).
import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../models/ley_estructurada.dart';
import '../models/sentencia_model.dart';
import '../services/jurisprudencia_service.dart';
import '../services/leyes_repositorio_service.dart';
import '../utils/main_tab_controller.dart';
import 'asistente_legal_screen.dart';
import 'glosario_screen.dart';
import 'ley_estructura_screen.dart';
import 'repositorio_jurisprudencia_screen.dart' show DetalleSentenciaScreen;

enum AlcanceBusqueda { sentencias, leyes, glosario }

class BuscadorJuridicoScreen extends StatefulWidget {
  const BuscadorJuridicoScreen({super.key, this.alcanceInicial});

  final AlcanceBusqueda? alcanceInicial;

  @override
  State<BuscadorJuridicoScreen> createState() => _BuscadorJuridicoScreenState();
}

class _BuscadorJuridicoScreenState extends State<BuscadorJuridicoScreen> {
  
  final JurisprudenciaService _serviceSentencias = JurisprudenciaService();
  final LeyesRepositorioService _serviceLeyes = LeyesRepositorioService();
  final TextEditingController _searchController = TextEditingController();

  late AlcanceBusqueda _alcance = widget.alcanceInicial ?? AlcanceBusqueda.sentencias;
  bool _cargando = false;
  String? _error;
  int _secuenciaBusqueda = 0;
  Timer? _debounce;
  int? _conteoSentencias;

  // Sentencias
  List<SentenciaModel> _sentencias = [];
  String _tipoSeleccionado = 'Sentencias';
  String? _salaSeleccionada;
  int? _anioSeleccionado;

  // Leyes
  List<ResultadoLey> _leyes = [];
  String _progresoIndice = '';

  // Glosario
  List<Map<String, String>> _glosario = [];

  @override
  void initState() {
    super.initState();
    _cargarConteo();
    if (_alcance == AlcanceBusqueda.sentencias) _buscar();
    // Alcance pedido desde fuera (dashboard → pestaña Buscar con corpus).
    consultaAlcance.addListener(_onConsultaExterna);
  }

  @override
  void dispose() {
    consultaAlcance.removeListener(_onConsultaExterna);
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onConsultaExterna() {
    final String? alcance = consultaAlcance.value;
    if (alcance == null || !mounted) return;
    final AlcanceBusqueda nuevo = switch (alcance) {
      'leyes' => AlcanceBusqueda.leyes,
      'glosario' => AlcanceBusqueda.glosario,
      _ => AlcanceBusqueda.sentencias,
    };
    if (nuevo == _alcance) return;
    setState(() {
      _alcance = nuevo;
      _searchController.clear();
    });
    _buscar();
  }

  Future<void> _cargarConteo() async {
    final n = await _serviceSentencias.contarSentencias();
    if (mounted) setState(() => _conteoSentencias = n);
  }

  String _formatear(int n) {
    final s = n.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      buffer.write(s[i]);
      final restantes = s.length - i - 1;
      if (restantes > 0 && restantes % 3 == 0) buffer.write('.');
    }
    return buffer.toString();
  }

  // ====================================================================
  // Búsqueda por alcance
  // ====================================================================
  Future<void> _buscar() async {
    final q = _searchController.text.trim();
    switch (_alcance) {
      case AlcanceBusqueda.sentencias:
        await _buscarSentencias(q);
      case AlcanceBusqueda.leyes:
        await _buscarLeyes(q);
      case AlcanceBusqueda.glosario:
        _buscarGlosario(q);
    }
  }

  Future<void> _buscarSentencias(String q) async {
    final int miSecuencia = ++_secuenciaBusqueda;
    setState(() {
      _cargando = true;
      _error = null;
    });
    final tipoParam = _tipoSeleccionado == 'Jurisprudencias'
        ? 'jurisprudencia'
        : _tipoSeleccionado == 'Resoluciones'
            ? 'resoluciones'
            : 'sentencia';
    final resultados = await _serviceSentencias.buscarDocumentos(
      textoBusqueda: q,
      tipo: tipoParam,
      sala: _salaSeleccionada,
      anio: _anioSeleccionado,
      limit: 50,
      onError: (mensaje) {
        if (mounted && miSecuencia == _secuenciaBusqueda) {
          setState(() => _error = mensaje);
        }
      },
    );
    // Respuesta vieja (otra búsqueda la pisó): descartar.
    if (!mounted || miSecuencia != _secuenciaBusqueda) return;
    setState(() {
      _sentencias = resultados;
      _cargando = false;
    });
  }

  Future<void> _buscarLeyes(String q) async {
    if (q.isEmpty) {
      setState(() {
        _leyes = [];
        _progresoIndice = '';
      });
      return;
    }
    setState(() {
      _cargando = true;
      _progresoIndice = '';
    });
    final resultados = await _serviceLeyes.buscar(
      q,
      limite: 50,
      onProgresoIndice: (actual, total) {
        if (mounted && actual % 5 == 0) {
          setState(() => _progresoIndice = 'Indexando leyes $actual/$total...');
        }
      },
    );
    if (!mounted) return;
    setState(() {
      _leyes = resultados;
      _cargando = false;
    });
  }

  void _buscarGlosario(String q) {
    final terminos = GlosarioScreen.terminos;
    if (q.isEmpty) {
      setState(() {
        _glosario = [];
        _cargando = false;
      });
      return;
    }
    final lower = q.toLowerCase();
    setState(() {
      _glosario = terminos
          .where((t) =>
              (t['term'] ?? '').toLowerCase().contains(lower) ||
              (t['definition'] ?? '').toLowerCase().contains(lower))
          .toList()
        ..sort((a, b) => (a['term'] ?? '').compareTo(b['term'] ?? ''));
      _cargando = false;
    });
  }

  void _cambiarAlcance(AlcanceBusqueda nuevo) {
    if (_alcance == nuevo) return;
    _debounce?.cancel();
    setState(() {
      _alcance = nuevo;
      _sentencias = [];
      _leyes = [];
      _glosario = [];
      _progresoIndice = '';
      _error = null;
    });
    _buscar();
  }

  void _limpiar() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _sentencias = [];
      _leyes = [];
      _glosario = [];
      _progresoIndice = '';
      _error = null;
    });
    _buscar();
  }

  // ====================================================================
  // UI
  // ====================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 14),
            _buildPills(),
            const SizedBox(height: 12),
            _buildBarraBusqueda(),
            const SizedBox(height: 14),
            _buildAlcance(),
            const SizedBox(height: 10),
            _buildAyuda(),
            const SizedBox(height: 14),
            Expanded(child: _buildResultados()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titulo = _alcance == AlcanceBusqueda.sentencias
        ? 'Jurisprudencia'
        : _alcance == AlcanceBusqueda.leyes
            ? 'Leyes de Venezuela'
            : 'Glosario Jurídico';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TemaGlobal.dorado.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _alcance == AlcanceBusqueda.sentencias
                  ? Icons.gavel
                  : _alcance == AlcanceBusqueda.leyes
                      ? Icons.menu_book
                      : Icons.menu_book_outlined,
              color: TemaGlobal.isDark
                  ? TemaGlobal.dorado
                  : TemaGlobal.azulMarino,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: TemaGlobal.texto,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Repositorio jurídico de Venezuela',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: TemaGlobal.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          if (_alcance == AlcanceBusqueda.sentencias &&
              _conteoSentencias != null &&
              _conteoSentencias! > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: TemaGlobal.dorado,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_formatear(_conteoSentencias!)} documentos',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onDorado,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill(String texto,
      {required bool activo, required IconData icon, VoidCallback? onTap}) {
    final habilitado = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? TemaGlobal.azulMarino : TemaGlobal.tarjeta,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: activo ? TemaGlobal.azulMarino : TemaGlobal.capa,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: activo
                  ? TemaGlobal.dorado
                  : habilitado
                      ? TemaGlobal.textoSecundario
                      : TemaGlobal.textoTenue,
            ),
            const SizedBox(width: 6),
            Text(
              texto,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: activo
                    ? Colors.white
                    : habilitado
                        ? TemaGlobal.textoSecundario
                        : TemaGlobal.textoTenue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPills() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _pill('Buscar', activo: true, icon: Icons.search),
          const SizedBox(width: 8),
          _pill(
            'Filtros',
            activo: false,
            icon: Icons.tune,
            onTap: _alcance == AlcanceBusqueda.sentencias ? _mostrarFiltros : null,
          ),
          const SizedBox(width: 8),
          _pill(
            'Preguntar a Ulpiano',
            activo: false,
            icon: Icons.auto_awesome,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AsistenteLegalScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBarraBusqueda() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: TemaGlobal.tarjeta,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TemaGlobal.capa, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: TemaGlobal.azulMarino.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search, color: TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  fontSize: 14.5,
                  color: TemaGlobal.texto,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Escribe aquí para empezar a buscar...',
                  hintStyle: TextStyle(
                    fontSize: 14.5,
                    color: TemaGlobal.textoTenue,
                  ),
                ),
                onSubmitted: (_) => _buscar(),
                onChanged: (v) {
                  setState(() {});
                  _debounce?.cancel();
                  if (v.isEmpty) {
                    _buscar();
                  } else {
                    // Debounce 350 ms: no llamar a DeepSeek/Supabase en cada tecla.
                    _debounce = Timer(const Duration(milliseconds: 350), _buscar);
                  }
                },
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.close, size: 18, color: TemaGlobal.textoTenue),
                onPressed: _limpiar,
              ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _buscar,
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: TemaGlobal.dorado,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: TemaGlobal.dorado.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: AppColors.onDorado,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlcance() {
    Widget segmento(String texto, AlcanceBusqueda valor) {
      final activo = _alcance == valor;
      return Expanded(
        child: InkWell(
          onTap: () => _cambiarAlcance(valor),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: activo ? TemaGlobal.azulMarino : TemaGlobal.tarjeta,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: activo ? TemaGlobal.azulMarino : TemaGlobal.capa,
              ),
            ),
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
                color: activo ? Colors.white : TemaGlobal.textoSecundario,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona dónde buscar:',
            style: TextStyle(
              fontSize: 13,
              color: TemaGlobal.textoSecundario,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              segmento('Sentencias', AlcanceBusqueda.sentencias),
              const SizedBox(width: 8),
              segmento('Leyes', AlcanceBusqueda.leyes),
              const SizedBox(width: 8),
              segmento('Glosario', AlcanceBusqueda.glosario),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAyuda() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 12, color: TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              _alcance == AlcanceBusqueda.sentencias
                  ? 'Busca por número, delito, partes o palabras clave'
                  : _alcance == AlcanceBusqueda.leyes
                      ? 'Busca artículos por delito, palabra o número de artículo'
                      : 'Busca términos jurídicos por nombre o definición',
              style: TextStyle(
                fontSize: 12.5,
                color: TemaGlobal.textoTenue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // Resultados
  // ====================================================================
  Widget _buildResultados() {
    if (_cargando) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.dorado),
              ),
            ),
            if (_progresoIndice.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                _progresoIndice,
                style: TextStyle(
                  fontSize: 12,
                  color: TemaGlobal.textoTenue,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 48, color: AppColors.error),
              const SizedBox(height: 14),
              Text(
                'No se pudo buscar',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: TemaGlobal.texto,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: TemaGlobal.textoSecundario,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  setState(() => _error = null);
                  _buscar();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TemaGlobal.dorado,
                  foregroundColor: TemaGlobal.azulMarino,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                child: const Text('Reintentar',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    final vacio = _alcance == AlcanceBusqueda.sentencias
        ? _sentencias.isEmpty
        : _alcance == AlcanceBusqueda.leyes
            ? _leyes.isEmpty
            : _glosario.isEmpty;

    if (vacio && _searchController.text.isEmpty) {
      return _buildInicio();
    }
    if (vacio) {
      return _buildEmptyState();
    }

    final items = _alcance == AlcanceBusqueda.sentencias
        ? _sentencias.length
        : _alcance == AlcanceBusqueda.leyes
            ? _leyes.length
            : _glosario.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(
            items == 1 ? '1 resultado' : '$items resultados',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TemaGlobal.isDark
                  ? TemaGlobal.dorado
                  : TemaGlobal.azulMarino,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: items,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              switch (_alcance) {
                case AlcanceBusqueda.sentencias:
                  return _cardSentencia(_sentencias[i]);
                case AlcanceBusqueda.leyes:
                  return _cardLey(_leyes[i]);
                case AlcanceBusqueda.glosario:
                  return _cardGlosario(_glosario[i]);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInicio() {
    if (_alcance == AlcanceBusqueda.leyes) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book, size: 52, color: TemaGlobal.textoTenue),
              const SizedBox(height: 14),
              Text(
                'Busca por el nombre de la ley',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: TemaGlobal.texto,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ej: "Código Penal", "Ley Orgánica contra la Delincuencia..."',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: TemaGlobal.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_alcance == AlcanceBusqueda.glosario) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          _enlaceRapido(
            titulo: 'Ver todos los términos del glosario',
            contador: null,
            onTap: () {
              setState(() {
                _glosario = List<Map<String, String>>.from(
                    GlosarioScreen.terminos)
                  ..sort(
                      (a, b) => (a['term'] ?? '').compareTo(b['term'] ?? ''));
              });
            },
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        _enlaceRapido(
          titulo: 'Ver todas las sentencias',
          contador: _conteoSentencias != null ? _formatear(_conteoSentencias!) : null,
          onTap: () {
            _tipoSeleccionado = 'Sentencias';
            _searchController.clear();
            _buscar();
          },
        ),
        const SizedBox(height: 12),
        _enlaceRapido(
          titulo: 'Ver decisiones vinculantes',
          contador: null,
          onTap: () {
            setState(() {
              _tipoSeleccionado = 'Jurisprudencias';
              _salaSeleccionada = null;
            });
            _searchController.clear();
            _buscar();
          },
        ),
        const SizedBox(height: 12),
        _enlaceRapido(
          titulo: 'Ver sentencias más recientes',
          contador: null,
          onTap: () {
            setState(() {
              _anioSeleccionado = DateTime.now().year;
              _tipoSeleccionado = 'Sentencias';
            });
            _searchController.clear();
            _buscar();
          },
        ),
        const SizedBox(height: 12),
        _enlaceRapido(
          titulo: 'Ver resoluciones recientes',
          contador: null,
          onTap: () {
            setState(() {
              _tipoSeleccionado = 'Resoluciones';
              _salaSeleccionada = null;
            });
            _searchController.clear();
            _buscar();
          },
        ),
      ],
    );
  }

  Widget _enlaceRapido({
    required String titulo,
    required String? contador,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: TemaGlobal.tarjeta,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TemaGlobal.capa, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: TemaGlobal.texto,
                ),
              ),
            ),
            if (contador != null)
              Text(
                contador,
                style: TextStyle(
                  fontSize: 12.5,
                  color: TemaGlobal.textoTenue,
                ),
              ),
            if (contador != null) const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 13, color: TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _alcance == AlcanceBusqueda.sentencias
                  ? Icons.search_off
                  : _alcance == AlcanceBusqueda.leyes
                      ? Icons.menu_book
                      : Icons.bookmark_border,
              size: 52,
              color: TemaGlobal.textoTenue,
            ),
            const SizedBox(height: 14),
            Text(
              'Sin resultados',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: TemaGlobal.texto,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Prueba con otra palabra clave o quita los filtros',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: TemaGlobal.textoSecundario,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // Tarjetas por alcance
  // ====================================================================
  Widget _cardSentencia(SentenciaModel s) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetalleSentenciaScreen(sentencia: s),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TemaGlobal.tarjeta,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TemaGlobal.capa, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.delito.isNotEmpty ? s.delito : 'Sentencia N° ${s.numeroSentencia}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: TemaGlobal.texto,
                    ),
                  ),
                ),
                if (s.esJurisprudencia)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: TemaGlobal.dorado,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'VINCULANTE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onDorado,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'Sentencia N° ${s.numeroSentencia} · ${s.sala}',
              style: TextStyle(
                fontSize: 12,
                color: TemaGlobal.textoSecundario,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.resumen.isNotEmpty ? s.resumen : s.decision,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: TemaGlobal.textoSecundario,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 11, color: TemaGlobal.textoTenue),
                const SizedBox(width: 4),
                Text(
                  s.fechaSentencia,
                  style: TextStyle(
                    fontSize: 11,
                    color: TemaGlobal.textoTenue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardLey(ResultadoLey r) {
    final reg = r.registro;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LeyEstructuraScreen(
              ley: LeyMeta(
                slug: reg.slug,
                archivo: '${reg.slug}.json',
                nombre: reg.leyNombre,
                orden: 999,
                articulos: 0,
                url: '',
              ),
              articuloInicial: reg.identificador,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TemaGlobal.tarjeta,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TemaGlobal.capa, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: TemaGlobal.azulMarino,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${reg.leyNombre} · ${reg.identificador}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.menu_book, size: 15, color: TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino),
              ],
            ),
            if (reg.encabezado != null && reg.encabezado!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                reg.encabezado!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: TemaGlobal.texto,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              r.extracto.isNotEmpty ? r.extracto : reg.texto,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: TemaGlobal.textoSecundario,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardGlosario(Map<String, String> t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TemaGlobal.tarjeta,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TemaGlobal.capa, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t['term'] ?? '',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: TemaGlobal.texto,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t['definition'] ?? '',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: TemaGlobal.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // Filtros (sentencias)
  // ====================================================================
  void _mostrarFiltros() {
    final currentYear = DateTime.now().year;
    final years = List.generate(currentYear - 1999, (i) => currentYear - i);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: TemaGlobal.tarjeta,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          Widget chip(String label,
              {required bool activo, required VoidCallback onTap}) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: activo,
                onSelected: (_) => onTap(),
                selectedColor: TemaGlobal.isDark
                    ? TemaGlobal.dorado
                    : TemaGlobal.azulMarino,
                backgroundColor: TemaGlobal.capa,
                labelStyle: TextStyle(
                  color: activo
                      ? (TemaGlobal.isDark
                          ? TemaGlobal.azulMarino
                          : Colors.white)
                      : TemaGlobal.textoSecundario,
                  fontWeight: activo ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: activo
                        ? (TemaGlobal.isDark
                            ? TemaGlobal.dorado
                            : TemaGlobal.azulMarino)
                        : TemaGlobal.capa,
                  ),
                ),
                visualDensity: VisualDensity.compact,
                showCheckmark: false,
              ),
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: TemaGlobal.texto,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tipo',
                    style: TextStyle(
                      fontSize: 13,
                      color: TemaGlobal.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      chip('Sentencias',
                          activo: _tipoSeleccionado == 'Sentencias', onTap: () {
                        setSheetState(() => _tipoSeleccionado = 'Sentencias');
                      }),
                      chip('Jurisprudencias',
                          activo: _tipoSeleccionado == 'Jurisprudencias',
                          onTap: () {
                        setSheetState(() {
                          _tipoSeleccionado = 'Jurisprudencias';
                          _salaSeleccionada = null;
                        });
                      }),
                      chip('Resoluciones',
                          activo: _tipoSeleccionado == 'Resoluciones',
                          onTap: () {
                        setSheetState(() {
                          _tipoSeleccionado = 'Resoluciones';
                          _salaSeleccionada = null;
                        });
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sala',
                    style: TextStyle(
                      fontSize: 13,
                      color: TemaGlobal.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        chip('Todas',
                            activo: _salaSeleccionada == null, onTap: () {
                          setSheetState(() => _salaSeleccionada = null);
                        }),
                        chip('Penal',
                            activo: _salaSeleccionada == 'scp',
                            onTap: () {
                          setSheetState(() => _salaSeleccionada = 'scp');
                        }),
                        chip('Constitucional',
                            activo: _salaSeleccionada == 'scon',
                            onTap: () {
                          setSheetState(() =>
                              _salaSeleccionada = 'scon');
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Año',
                    style: TextStyle(
                      fontSize: 13,
                      color: TemaGlobal.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      chip('Todos', activo: _anioSeleccionado == null, onTap: () {
                        setSheetState(() => _anioSeleccionado = null);
                      }),
                      ...years.take(8).map((y) => chip('$y',
                          activo: _anioSeleccionado == y, onTap: () {
                        setSheetState(() => _anioSeleccionado = y);
                      })),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _tipoSeleccionado = 'Sentencias';
                              _salaSeleccionada = null;
                              _anioSeleccionado = null;
                            });
                            _buscar();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: TemaGlobal.texto,
                            side: BorderSide(color: TemaGlobal.capa),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Limpiar filtros'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _buscar();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TemaGlobal.dorado,
                            foregroundColor: TemaGlobal.azulMarino,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Aplicar',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
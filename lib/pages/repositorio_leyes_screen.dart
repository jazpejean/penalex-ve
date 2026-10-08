import 'package:flutter/material.dart';

import '../models/ley_estructurada.dart';
import '../services/leyes_repositorio_service.dart';
import '../widgets/app_drawer.dart';
import 'ley_estructura_screen.dart';

/// Repositorio de Leyes (apariencia similar al repositorio de jurisprudencias).
///
/// Muestra las leyes ordenadas por relevancia (Constitución → COPP → Código
/// Penal → ...) y ofrece búsqueda semántica sobre todos los artículos.
class RepositorioLeyesScreen extends StatefulWidget {
  const RepositorioLeyesScreen({super.key});

  @override
  State<RepositorioLeyesScreen> createState() => _RepositorioLeyesScreenState();
}

class _RepositorioLeyesScreenState extends State<RepositorioLeyesScreen> {
  final LeyesRepositorioService _service = LeyesRepositorioService();
  final TextEditingController _searchController = TextEditingController();

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color fondoGris = Color(0xFFF1F5F9);

  List<LeyMeta> _leyes = [];
  List<ResultadoLey> _resultados = [];

  bool _cargando = true;
  bool _buscando = false;
  String _progresoIndice = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _cargarLeyes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarLeyes() async {
    setState(() {
      _cargando = true;
      _error = '';
    });
    final leyes = await _service.cargarManifest();
    if (mounted) {
      setState(() {
        _leyes = leyes;
        _cargando = false;
        if (leyes.isEmpty) {
          _error = 'No se pudieron cargar las leyes. Revisa tu conexión.';
        }
      });
    }
  }

  Future<void> _buscar() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _resultados = [];
        _buscando = false;
      });
      return;
    }

    setState(() {
      _buscando = true;
      _progresoIndice = '';
    });

    final resultados = await _service.buscar(
      query,
      limite: 50,
      onProgresoIndice: (actual, total) {
        if (mounted && actual % 5 == 0) {
          setState(() => _progresoIndice = 'Indexando leyes $actual/$total...');
        }
      },
    );

    if (mounted) {
      setState(() {
        _resultados = resultados;
        _buscando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/repositorio_leyes'),
      appBar: AppBar(
        title: const Text(
          'Biblioteca Jurídica',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: dorado,
          ),
        ),
        backgroundColor: azulMarino,
        foregroundColor: dorado,
        elevation: 0,
        actions: [
          if (!_cargando && _resultados.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_resultados.length} resultado${_resultados.length == 1 ? '' : 's'}',
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
          _buildBarraBusqueda(),
          Expanded(child: _buildCuerpo()),
        ],
      ),
    );
  }

  Widget _buildBarraBusqueda() {
    return Container(
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
              hintText: 'Busca una ley o un artículo (ej. "250", "homicidio", "COPP")...',
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
              if (value.isEmpty) _buscar();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 12, color: dorado.withOpacity(0.6)),
              const SizedBox(width: 4),
              Text(
                'Escribe el número de un artículo (ej. "250") o un tema (ej. "homicidio", "drogas")...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCuerpo() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: dorado, strokeWidth: 3),
      );
    }
    if (_error.isNotEmpty && _leyes.isEmpty) {
      return _buildError();
    }
    if (_buscando) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: dorado, strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              _progresoIndice.isEmpty
                  ? 'Buscando en las leyes...'
                  : _progresoIndice,
              style: TextStyle(color: azulMarino.withOpacity(0.6), fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Buscando resultados de artículos.
    if (_searchController.text.trim().isNotEmpty) {
      if (_resultados.isEmpty) {
        return _buildEmpty();
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _resultados.length,
        itemBuilder: (context, index) =>
            _buildResultadoCard(_resultados[index], index),
      );
    }

    // Lista de leyes ordenadas por relevancia.
    if (_leyes.isEmpty) {
      return _buildEmpty();
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _leyes.length,
      itemBuilder: (context, index) => _buildLeyCard(_leyes[index], index),
    );
  }

  Widget _buildLeyCard(LeyMeta ley, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: azulMarino.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: dorado.withOpacity(0.45), width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _abrirLey(ley),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: azulMarino,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.menu_book_rounded, color: dorado, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ley.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: azulMarino,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ley.articulos} artículos',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFC5A059)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultadoCard(ResultadoLey r, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirArticulo(r.registro),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: azulMarino,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      r.registro.leyNombre,
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
                  Expanded(
                    child: Text(
                      r.tituloCorto,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: azulMarino,
                      ),
                    ),
                  ),
                  if (r.registro.encabezado != null &&
                      r.registro.encabezado!.isNotEmpty)
                    Expanded(
                      child: Text(
                        r.registro.encabezado!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                r.extracto,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Ver artículo →',
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
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: azulMarino.withOpacity(0.2)),
            const SizedBox(height: 24),
            Text(
              'No se encontraron resultados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: azulMarino.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Intenta con otros términos de búsqueda',
              style: TextStyle(fontSize: 14, color: azulMarino.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 80, color: azulMarino.withOpacity(0.2)),
            const SizedBox(height: 24),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: azulMarino.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarLeyes,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: azulMarino,
                foregroundColor: dorado,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirLey(LeyMeta ley) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeyEstructuraScreen(ley: ley),
      ),
    );
  }

  Future<void> _abrirArticulo(RegistroArticulo reg) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeyEstructuraScreen(
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
  }
}

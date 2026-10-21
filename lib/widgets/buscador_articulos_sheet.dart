import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../services/leyes_repositorio_service.dart';
import 'articulo_ley_sheet.dart';

/// Abre un buscador flotante de artículos de ley. El usuario busca, ve
/// resultados y al tocar uno se abre el artículo completo en otra ventana
/// flotante, sin salir de la pantalla actual.
Future<void> mostrarBuscadorArticulos(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _BuscadorArticulosSheet(),
  );
}

class _BuscadorArticulosSheet extends StatefulWidget {
  const _BuscadorArticulosSheet();

  @override
  State<_BuscadorArticulosSheet> createState() =>
      _BuscadorArticulosSheetState();
}

class _BuscadorArticulosSheetState extends State<_BuscadorArticulosSheet> {
  static const Color dorado = Color(0xFFC5A059);
  static Color get grisOscuro => TemaGlobal.tarjeta;

  final LeyesRepositorioService _service = LeyesRepositorioService();
  final TextEditingController _controller = TextEditingController();

  List<ResultadoLey> _resultados = [];
  bool _buscando = false;
  bool _consultado = false;
  String _progreso = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _buscando = true;
      _consultado = true;
      _progreso = '';
    });

    final resultados = await _service.buscar(
      query,
      limite: 40,
      onProgresoIndice: (actual, total) {
        if (mounted && actual % 5 == 0) {
          setState(() => _progreso = 'Indexando leyes $actual/$total...');
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: grisOscuro,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: TemaGlobal.capa,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Consultar artículos',
                    style: TextStyle(
                      color: TemaGlobal.texto,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: TemaGlobal.textoSecundario),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: TextStyle(color: TemaGlobal.texto, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Buscar por artículo, delito o tema (ej. 406, homicidio)',
                hintStyle: TextStyle(color: TemaGlobal.textoTenue),
                prefixIcon: const Icon(Icons.search, color: dorado, size: 22),
                filled: true,
                fillColor: TemaGlobal.campoTexto,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: dorado, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _buscar(),
            ),
          ),
          Expanded(child: _buildCuerpo()),
        ],
      ),
    );
  }

  Widget _buildCuerpo() {
    if (_buscando) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: dorado, strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              _progreso.isEmpty ? 'Buscando...' : _progreso,
              style: TextStyle(color: TemaGlobal.textoSecundario),
            ),
          ],
        ),
      );
    }

    if (!_consultado) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book, size: 56, color: dorado),
              const SizedBox(height: 16),
              Text(
                'Escribe un término legal o el número de un artículo\ny toca "Buscar" en el teclado.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TemaGlobal.textoSecundario,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_resultados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 56, color: TemaGlobal.textoTenue),
              const SizedBox(height: 16),
              Text(
                'Sin resultados',
                style: TextStyle(color: TemaGlobal.textoSecundario),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      itemCount: _resultados.length,
      itemBuilder: (context, index) =>
          _buildResultado(_resultados[index]),
    );
  }

  Widget _buildResultado(ResultadoLey r) {
    final reg = r.registro;
    final esArticulo = reg.tipoNorma == 'Artículo';
    final titulo = esArticulo ? 'Art. ${reg.identificador}' : reg.tipoNorma;

    return InkWell(
      onTap: () => mostrarArticuloLey(context, r),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TemaGlobal.tarjeta,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TemaGlobal.capa),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: TemaGlobal.capa,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      reg.leyNombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: dorado,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(
                      color: TemaGlobal.texto,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: dorado, size: 20),
              ],
            ),
            if (reg.encabezado != null && reg.encabezado!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  reg.encabezado!,
                  style: TextStyle(
                    color: TemaGlobal.textoSecundario,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Text(
              r.extracto,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: TemaGlobal.textoSecundario,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

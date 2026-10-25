import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../config/app_theme.dart';
import '../models/ley_estructurada.dart';
import '../services/leyes_rag_service.dart';
import '../services/leyes_repositorio_service.dart';
import '../widgets/tabla_anexo.dart';

/// Navegación jerárquica de una ley: Libro → Título → Capítulo → Sección →
/// Artículo. Al tocar un artículo se muestra su contenido y se puede preguntar
/// a la IA (RAG) sobre él.
class LeyEstructuraScreen extends StatefulWidget {
  final LeyMeta ley;
  final String? articuloInicial;

  const LeyEstructuraScreen({super.key, required this.ley, this.articuloInicial});

  @override
  State<LeyEstructuraScreen> createState() => _LeyEstructuraScreenState();
}

class _LeyEstructuraScreenState extends State<LeyEstructuraScreen> {
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  /// Acento de marca: azul marino en modo claro, dorado en modo oscuro.
  static Color get acento => TemaGlobal.isDark ? dorado : azulMarino;

  final LeyesRepositorioService _service = LeyesRepositorioService();

  LeyEstructurada? _ley;
  List<NodoArbol> _arbol = [];
  bool _cargando = true;
  String? _error;
  final TextEditingController _filtroController = TextEditingController();
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    _cargarLey();
  }

  Future<void> _cargarLey() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final ley = await _service.cargarLey(widget.ley.slug);
    if (!mounted) return;
    if (ley == null) {
      setState(() {
        _cargando = false;
        _error = 'No se pudo descargar la ley. Revisa tu conexión.';
      });
      return;
    }
    final arbol = _construirArbol(ley.estructura);
    setState(() {
      _ley = ley;
      _arbol = arbol;
      _cargando = false;
    });

    // Si venimos de una búsqueda, abrir el artículo automáticamente.
    if (widget.articuloInicial != null) {
      final art = ley.todosLosArticulos
          .where((a) => a.identificador == widget.articuloInicial)
          .toList();
      if (art.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mostrarArticulo(art.first);
        });
      }
    }
  }

  @override
  void dispose() {
    _filtroController.dispose();
    super.dispose();
  }

  String _sinAcentos(String v) {
    const con = 'áéíóúüñÁÉÍÓÚÜÑ';
    const sin = 'aeiouunAEIOUUN';
    final b = StringBuffer();
    for (final c in v.split('')) {
      final i = con.indexOf(c);
      b.write(i >= 0 ? sin[i] : c);
    }
    return b.toString();
  }

  List<({String path, ArticuloLey art})> _buscarEnLey(String query) {
    final q = _sinAcentos(query.trim().toLowerCase());
    final resultados = <({String path, ArticuloLey art})>[];
    for (final bloque in _ley?.estructura ?? const <BloqueLey>[]) {
      final path = [
        bloque.libro,
        bloque.titulo,
        bloque.capitulo,
        bloque.seccion,
      ].where((s) => s != null && s.isNotEmpty).map((s) => s!).join(' → ');
      for (final art in bloque.articulos) {
        final id = _sinAcentos(art.identificador.toLowerCase());
        final texto = _sinAcentos(
          '${art.encabezado ?? ''} ${art.textoPrincipal}'.toLowerCase(),
        );
        if (q.isEmpty || id.contains(q) || texto.contains(q)) {
          resultados.add((path: path, art: art));
        }
      }
    }
    return resultados;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
      appBar: AppBar(
        title: Text(
          widget.ley.nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, color: dorado),
        ),
        backgroundColor: azulMarino,
        elevation: 0,
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator(color: acento))
          : _error != null
              ? _buildError()
              : _buildContenido(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 80, color: acento.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: TemaGlobal.texto, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarLey,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: dorado,
                foregroundColor: azulMarino,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenido() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _filtro.trim().isNotEmpty
              ? _buildResultadosFiltro()
              : _arbol.isEmpty
                  ? _buildSoloArticulos()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      children: _arbol.map(_buildNodo).toList(),
                    ),
        ),
      ],
    );
  }

  Widget _buildResultadosFiltro() {
    final resultados = _buscarEnLey(_filtro);
    if (resultados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No se encontró ningún artículo con "$_filtro"',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: TemaGlobal.textoSecundario,
              fontSize: 14,
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: resultados.length,
      itemBuilder: (context, i) {
        final r = resultados[i];
        return _buildResultadoFiltro(r.path, r.art);
      },
    );
  }

  Widget _buildResultadoFiltro(String path, ArticuloLey art) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: TemaGlobal.tarjeta,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: acento.withOpacity(0.35)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _mostrarArticulo(art),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${art.tipoNorma} ${art.identificador}',
                      style: TextStyle(
                        color: acento,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: acento, size: 18),
                ],
              ),
              if (path.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  path,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: TemaGlobal.textoSecundario,
                    fontSize: 11,
                  ),
                ),
              ],
              if (art.encabezado != null && art.encabezado!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  art.encabezado!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: TemaGlobal.texto,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        border: Border(bottom: BorderSide(color: dorado.withOpacity(0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: dorado,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_ley!.totalArticulos} artículos',
                  style: const TextStyle(
                    color: azulMarino,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Busca por número de artículo (ej. "400") o tema',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _filtroController,
            style: TextStyle(color: TemaGlobal.texto, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ej. "400", "homicidio", "medidas"...',
              hintStyle: TextStyle(
                color: TemaGlobal.textoTenue,
                fontSize: 14,
              ),
              prefixIcon: Icon(Icons.search, color: acento, size: 20),
              suffixIcon: _filtro.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: acento, size: 18),
                      onPressed: () {
                        _filtroController.clear();
                        setState(() => _filtro = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: TemaGlobal.campoTexto,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: acento, width: 1.5),
              ),
            ),
            onChanged: (v) => setState(() => _filtro = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSoloArticulos() {
    final arts = _ley!.todosLosArticulos;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: arts.length,
      itemBuilder: (context, i) => _buildArticuloItem(arts[i]),
    );
  }

  // ---------------------------------------------------------------------------
  // Construcción del árbol
  // ---------------------------------------------------------------------------

  List<NodoArbol> _construirArbol(List<BloqueLey> bloques) {
    final raices = <NodoArbol>[];

    NodoArbol findOrAdd(List<NodoArbol> hermanos, String nivel, String etiqueta) {
      for (final h in hermanos) {
        if (h.nivel == nivel && h.etiqueta == etiqueta) return h;
      }
      final n = NodoArbol(nivel: nivel, etiqueta: etiqueta);
      hermanos.add(n);
      return n;
    }

    for (final b in bloques) {
      final path = <(String, String)>[
        if (b.libro != null) ('libro', b.libro!),
        if (b.titulo != null) ('titulo', b.titulo!),
        if (b.capitulo != null) ('capitulo', b.capitulo!),
        if (b.seccion != null) ('seccion', b.seccion!),
      ];

      if (path.isEmpty) {
        raices.add(NodoArbol(nivel: 'articulos', etiqueta: '', articulos: b.articulos));
        continue;
      }

      var hermanos = raices;
      NodoArbol? actual;
      for (final (nivel, etiqueta) in path) {
        actual = findOrAdd(hermanos, nivel, etiqueta);
        hermanos = actual.hijos;
      }
      actual!.articulos.addAll(b.articulos);
    }
    return raices;
  }

  // ---------------------------------------------------------------------------
  // Render del árbol
  // ---------------------------------------------------------------------------

  String _rangoArticulos(NodoArbol nodo) {
    final nums = <int>[];
    void recoger(NodoArbol n) {
      for (final a in n.articulos) {
        final num = int.tryParse(a.identificador.trim());
        if (num != null) nums.add(num);
      }
      for (final h in n.hijos) {
        recoger(h);
      }
    }

    recoger(nodo);
    if (nums.isEmpty) return '';
    nums.sort();
    if (nums.length == 1) return 'Art. ${nums.first}';
    return 'Arts. ${nums.first}-${nums.last}';
  }

  Widget _buildNodo(NodoArbol nodo) {
    final profundidad = _profundidadNodo(nodo.nivel);
    final colorTitulo = profundidad == 0 ? dorado : TemaGlobal.texto;
    final tamano = profundidad == 0 ? 15.0 : 14.0;

    if (nodo.nivel == 'articulos') {
      return Column(children: nodo.articulos.map(_buildArticuloItem).toList());
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: TemaGlobal.tarjeta.withOpacity(profundidad == 0 ? 1.0 : 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: acento.withOpacity(profundidad == 0 ? 0.35 : 0.15)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: profundidad == 0,
          tilePadding: EdgeInsets.only(left: 8.0 + profundidad * 8, right: 12),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          iconColor: acento,
          collapsedIconColor: TemaGlobal.textoTenue,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  nodo.etiqueta,
                  style: TextStyle(
                    color: colorTitulo,
                    fontWeight:
                        profundidad == 0 ? FontWeight.bold : FontWeight.w600,
                    fontSize: tamano,
                  ),
                ),
              ),
              if (_rangoArticulos(nodo).isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: acento.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _rangoArticulos(nodo),
                    style: TextStyle(
                      color: acento,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          children: [
            ...nodo.hijos.map(_buildNodo),
            ...nodo.articulos.map(_buildArticuloItem),
          ],
        ),
      ),
    );
  }

  int _profundidadNodo(String nivel) {
    switch (nivel) {
      case 'libro':
        return 0;
      case 'titulo':
        return 1;
      case 'capitulo':
        return 2;
      case 'seccion':
        return 3;
      default:
        return 0;
    }
  }

  Widget _buildArticuloItem(ArticuloLey art) {
    final esArticulo = art.tipoNorma == 'Artículo';
    final titulo = esArticulo ? 'Art. ${art.identificador}' : art.tipoNorma;

    return InkWell(
      onTap: () => _mostrarArticulo(art),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TemaGlobal.tarjeta,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: TemaGlobal.capa),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: dorado,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                titulo,
                style: const TextStyle(
                  color: azulMarino,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (art.encabezado != null && art.encabezado!.isNotEmpty)
                    Text(
                      art.encabezado!,
                      style: TextStyle(
                        color: TemaGlobal.texto,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    art.textoPrincipal,
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
            Icon(Icons.chevron_right, color: acento, size: 18),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Detalle de artículo (bottom sheet) + IA
  // ---------------------------------------------------------------------------

  void _mostrarArticulo(ArticuloLey art) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ArticuloSheet(
        leyNombre: _ley!.nombre,
        articulo: art,
      ),
    );
  }
}

/// Árbol en memoria para renderizar la jerarquía.
class NodoArbol {
  final String nivel; // 'libro' | 'titulo' | 'capitulo' | 'seccion' | 'articulos'
  final String etiqueta;
  final List<ArticuloLey> articulos;
  final List<NodoArbol> hijos;

  NodoArbol({
    required this.nivel,
    required this.etiqueta,
    List<ArticuloLey>? articulos,
    List<NodoArbol>? hijos,
  })  : articulos = articulos ?? [],
        hijos = hijos ?? [];
}

/// Bottom sheet con el contenido completo de un artículo + botón de IA.
class _ArticuloSheet extends StatelessWidget {
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  /// Acento de marca: azul marino en modo claro, dorado en modo oscuro.
  static Color get acento => TemaGlobal.isDark ? dorado : azulMarino;

  final String leyNombre;
  final ArticuloLey articulo;

  const _ArticuloSheet({required this.leyNombre, required this.articulo});

  @override
  Widget build(BuildContext context) {
    final esArticulo = articulo.tipoNorma == 'Artículo';
    final titulo = esArticulo ? 'Artículo ${articulo.identificador}' : articulo.tipoNorma;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: TemaGlobal.tarjeta,
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: dorado,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      color: azulMarino,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    leyNombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: TemaGlobal.textoSecundario,
                      fontSize: 13,
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
          Divider(color: TemaGlobal.capa, height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (articulo.encabezado != null && articulo.encabezado!.isNotEmpty)
                    Text(
                      articulo.encabezado!,
                      style: TextStyle(
                        color: TemaGlobal.texto,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    articulo.textoPrincipal,
                    style: TextStyle(
                      color: TemaGlobal.texto,
                      fontSize: 15,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  if (articulo.numeralesLiterales.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _subtitulo('Numerales'),
                    ...articulo.numeralesLiterales.map((n) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            n,
                            style: TextStyle(
                              color: TemaGlobal.textoSecundario,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        )),
                  ],
                  if (articulo.tablas.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ...articulo.tablas.map((t) => TablaAnexoView(tabla: t)),
                  ],
                  if (articulo.paragrafos.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _subtitulo('Parágrafos'),
                    ...articulo.paragrafos.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            p,
                            style: TextStyle(
                              color: TemaGlobal.textoSecundario,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        )),
                  ],
                  if (articulo.estado != 'vigente')
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Estado: ${articulo.estado.toUpperCase()}',
                        style: TextStyle(
                          color: TemaGlobal.isDark
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFFC2410C),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LeyChatIAPage(
                        leyNombre: leyNombre,
                        contextoInicial:
                            '${titulo}${articulo.encabezado != null ? ' · ${articulo.encabezado}' : ''}\n\n${articulo.textoCompleto}',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.psychology),
                label: const Text('Preguntar a la IA sobre este artículo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: dorado,
                  foregroundColor: azulMarino,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subtitulo(String texto) => Text(
        texto,
        style: const TextStyle(
          color: Color(0xFFC5A059),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
}

/// Chat con IA (RAG) para el Repositorio de Leyes.
class LeyChatIAPage extends StatefulWidget {
  final String leyNombre;
  final String contextoInicial;

  const LeyChatIAPage({
    super.key,
    required this.leyNombre,
    required this.contextoInicial,
  });

  @override
  State<LeyChatIAPage> createState() => _LeyChatIAPageState();
}

class _LeyChatIAPageState extends State<LeyChatIAPage> {
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  /// Acento de marca: azul marino en modo claro, dorado en modo oscuro.
  static Color get acento => TemaGlobal.isDark ? dorado : azulMarino;

  final LeyesRAGService _rag = LeyesRAGService();
  final TextEditingController _controller = TextEditingController();
  final List<_MensajeChat> _mensajes = [];
  bool _pensando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _pensando) return;

    setState(() {
      _mensajes.add(_MensajeChat(rol: 'user', contenido: texto));
      _controller.clear();
      _pensando = true;
    });

    // Usar el contexto del artículo seleccionado + consulta del usuario.
    final respuesta = await _rag.responder(
      texto,
      contextoAdicional: widget.contextoInicial,
    );

    if (!mounted) return;
    setState(() {
      _mensajes.add(_MensajeChat(
        rol: 'assistant',
        contenido: respuesta.respuesta,
        fuentes: respuesta.fuentes,
      ));
      _pensando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
      appBar: AppBar(
        title: const Text('Asistente Legal IA'),
        backgroundColor: azulMarino,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF1E293B),
            child: Text(
              'Contexto: ${widget.leyNombre}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_mensajes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Text(
                      'Pregúntame sobre este artículo: interpretación, ejemplos, '
                      'penas, jurisprudencia relacionada, etc.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: TemaGlobal.textoTenue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ..._mensajes.map(_buildBurbuja),
                if (_pensando) _buildPensando(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              border: Border(top: BorderSide(color: dorado.withOpacity(0.3))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: TemaGlobal.texto),
                    decoration: InputDecoration(
                      hintText: 'Escribe tu pregunta...',
                      hintStyle: TextStyle(color: TemaGlobal.textoTenue),
                      filled: true,
                      fillColor: TemaGlobal.campoTexto,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _enviar(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _enviar,
                  icon: Icon(Icons.send, color: acento),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBurbuja(_MensajeChat msg) {
    final esUsuario = msg.rol == 'user';
    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: esUsuario
              ? dorado.withOpacity(0.25)
              : TemaGlobal.tarjeta,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: esUsuario ? dorado.withOpacity(0.5) : TemaGlobal.capa,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (esUsuario)
              Text(
                msg.contenido,
                style: TextStyle(color: TemaGlobal.texto, fontSize: 14, height: 1.5),
              )
            else
              MarkdownBody(
                data: msg.contenido,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: TemaGlobal.texto, fontSize: 14, height: 1.5),
                  h1: TextStyle(color: acento, fontWeight: FontWeight.bold, fontSize: 18),
                  h2: TextStyle(color: acento, fontWeight: FontWeight.bold, fontSize: 16),
                  h3: TextStyle(color: acento, fontWeight: FontWeight.bold, fontSize: 15),
                  strong: TextStyle(color: TemaGlobal.texto, fontWeight: FontWeight.bold),
                  listBullet: TextStyle(color: TemaGlobal.texto, fontSize: 14),
                  a: TextStyle(color: acento),
                ),
              ),
            if (msg.fuentes != null && msg.fuentes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Divider(color: TemaGlobal.capa, height: 1),
              const SizedBox(height: 6),
              Text(
                'Fuentes normativas:',
                style: TextStyle(
                  color: acento.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ...msg.fuentes!.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '• ${referenciaCorta(f.registro)}',
                      style: TextStyle(
                        color: TemaGlobal.textoSecundario,
                        fontSize: 12,
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPensando() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TemaGlobal.tarjeta,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(color: acento, strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text('Analizando...',
                style: TextStyle(color: TemaGlobal.textoSecundario)),
          ],
        ),
      ),
    );
  }
}

class _MensajeChat {
  final String rol;
  final String contenido;
  final List<ResultadoLey>? fuentes;

  _MensajeChat({required this.rol, required this.contenido, this.fuentes});
}

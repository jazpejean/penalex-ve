import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../config/app_tokens.dart';
import '../services/coleccion_service.dart';
import '../widgets/app_screen_header.dart';

/// Lista de colecciones de sentencias del usuario.
class MisColeccionesScreen extends StatefulWidget {
  const MisColeccionesScreen({super.key});

  @override
  State<MisColeccionesScreen> createState() => _MisColeccionesScreenState();
}

class _MisColeccionesScreenState extends State<MisColeccionesScreen> {
  List<Coleccion> _colecciones = <Coleccion>[];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final List<Coleccion> lista = await ColeccionService.listar();
    if (!mounted) return;
    setState(() {
      _colecciones = lista;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
      appBar: AppBar(
        backgroundColor: TemaGlobal.superficie,
        elevation: 0,
        iconTheme: IconThemeData(color: TemaGlobal.texto),
        title: Text('Mis colecciones',
            style: TextStyle(color: TemaGlobal.texto, fontSize: 20)),
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppTokens.margen),
                children: <Widget>[
                  const AppScreenHeader(
                    titulo: 'Mis colecciones',
                    subtitulo: 'Sentencias agrupadas por tema o caso',
                  ),
                  const SizedBox(height: 16),
                  if (_colecciones.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Todavía no tienes colecciones. Guarda una sentencia '
                        'desde el buscador con el botón de colección.',
                        style: AppTokens.secundario,
                      ),
                    ),
                  for (final Coleccion c in _colecciones)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: TemaGlobal.tarjeta,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radioTarjeta),
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radioTarjeta),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  _ColeccionDetalleScreen(coleccion: c),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  AppTokens.radioTarjeta),
                              border: Border.all(color: TemaGlobal.capa),
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.folder_outlined,
                                    color: AppColors.azulMarino),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        c.nombre,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: TemaGlobal.texto,
                                        ),
                                      ),
                                      if (c.descripcion != null &&
                                          c.descripcion!.isNotEmpty)
                                        Text(
                                          c.descripcion!,
                                          style: AppTokens.secundario,
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: TemaGlobal.textoTenue),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _ColeccionDetalleScreen extends StatefulWidget {
  const _ColeccionDetalleScreen({required this.coleccion});

  final Coleccion coleccion;

  @override
  State<_ColeccionDetalleScreen> createState() =>
      _ColeccionDetalleScreenState();
}

class _ColeccionDetalleScreenState extends State<_ColeccionDetalleScreen> {
  List<Map<String, dynamic>> _sentencias = <Map<String, dynamic>>[];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final List<Map<String, dynamic>> filas =
        await ColeccionService.sentenciasDe(widget.coleccion.id);
    if (!mounted) return;
    setState(() {
      _sentencias = filas;
      _cargando = false;
    });
  }

  Future<void> _abrir(Map<String, dynamic> s) async {
    final String url = (s['url_html'] ?? s['url_tsj'] ?? '').toString();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta sentencia no tiene enlace.')),
      );
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
      appBar: AppBar(
        backgroundColor: TemaGlobal.superficie,
        elevation: 0,
        iconTheme: IconThemeData(color: TemaGlobal.texto),
        title: Text(widget.coleccion.nombre,
            style: TextStyle(color: TemaGlobal.texto, fontSize: 18)),
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _sentencias.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Esta colección aún no tiene sentencias.'),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppTokens.margen),
                    itemCount: _sentencias.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int i) {
                      final Map<String, dynamic> s = _sentencias[i];
                      return Material(
                        color: TemaGlobal.tarjeta,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radioControl),
                        child: ListTile(
                          onTap: () => _abrir(s),
                          title: Text(
                            'Nº ${s['num_sentencia'] ?? ''} · '
                            '${s['sala'] ?? ''}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: TemaGlobal.texto,
                            ),
                          ),
                          subtitle: Text(
                            '${s['fecha_sentencia'] ?? ''} · '
                            '${s['expediente'] ?? ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: TemaGlobal.textoSecundario,
                            ),
                          ),
                          trailing: const Icon(Icons.open_in_new, size: 18),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

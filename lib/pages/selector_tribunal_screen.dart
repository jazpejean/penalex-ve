import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../services/haptics_service.dart';
import '../services/tribunales_service.dart';
import '../widgets/app_bar_institucional.dart';

/// Selector de tribunal a pantalla completa (catálogo oficial de
/// tribunales penales).
///
/// Flujo por estados: dropdown de estado (circunscripción judicial) +
/// búsqueda por texto. Devuelve el [Tribunal] elegido con
/// `Navigator.pop(context, tribunal)`; `null` si se cancela.
class SelectorTribunalScreen extends StatefulWidget {
  const SelectorTribunalScreen({super.key, this.inicial = ''});

  /// Texto inicial del buscador (si el campo ya tenía un tribunal).
  final String inicial;

  @override
  State<SelectorTribunalScreen> createState() => _SelectorTribunalScreenState();
}

class _SelectorTribunalScreenState extends State<SelectorTribunalScreen> {
  late final TextEditingController _buscadorCtrl =
      TextEditingController(text: widget.inicial);
  List<Tribunal> _resultados = <Tribunal>[];
  bool _buscando = true;
  bool _cacheLista = false;
  String? _filtroEstado; // null = todos los estados

  @override
  void initState() {
    super.initState();
    _asegurarCache();
    _buscar();
  }

  Future<void> _asegurarCache() async {
    if (_cacheLista) return;
    await TribunalesService.listar();
    _cacheLista = true;
  }

  Future<void> _buscar() async {
    final String q = _buscadorCtrl.text.trim();
    if (q.isEmpty) {
      // Catálogo completo (directorio) — no un spinner infinito.
      final List<Tribunal>? todos = TribunalesService.listarEnCache();
      final List<Tribunal> filtrados = todos == null
          ? <Tribunal>[]
          : todos
              .where((Tribunal t) =>
                  _filtroEstado == null || t.estado == _filtroEstado)
              .toList();
      if (!mounted) return;
      setState(() {
        _resultados = filtrados;
        _buscando = false;
      });
      return;
    }
    setState(() => _buscando = true);
    // 1) Filtro local por texto: TODOS los que coinciden.
    List<Tribunal> locales = TribunalesService.filtrarPorTexto(q);
    if (_filtroEstado != null) {
      locales = locales
          .where((Tribunal t) => t.estado == _filtroEstado)
          .toList();
    }
    if (locales.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _resultados = locales;
        _buscando = false;
      });
      return;
    }
    // 2) Refuerzo semántico solo si el texto no dio coincidencias.
    final List<Tribunal>? sem = await TribunalesService.buscarSemantico(
        q,
        limite: 20);
    if (sem == null || sem.isEmpty) {
      if (!mounted) return;
      setState(() {
        _resultados = sem ?? <Tribunal>[];
        _buscando = false;
      });
      return;
    }
    const double umbral = 0.52;
    final List<Tribunal> relevantes = sem
        .where((Tribunal t) =>
            t.distancia != null && t.distancia! < umbral)
        .toList();
    if (!mounted) return;
    setState(() {
      _resultados = relevantes.isNotEmpty ? relevantes : sem;
      _buscando = false;
    });
  }

  /// Estados disponibles para el dropdown.
  List<String> get _todosEstados {
    final List<String> estados = <String>{
      ...?TribunalesService.listarEnCache()?.map((Tribunal t) => t.estado),
    }.toList()
      ..sort();
    return estados;
  }

  @override
  void dispose() {
    _buscadorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
      appBar: AppBarInstitucional(
        title: 'Tribunales',
        mostrarBack: true,

      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: _buscadorCtrl,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Buscar tribunal o ciudad…',
                  prefixIcon: Icon(Icons.search,
                      color: TemaGlobal.textoSecundario),
                  filled: true,
                  fillColor: TemaGlobal.campoTexto,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
                onChanged: (_) => _buscar(),
              ),
              const SizedBox(height: 10),
              // Dropdown por estado (circunscripción judicial).
              DropdownButtonFormField<String>(
                initialValue: _filtroEstado,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Estado (circunscripción judicial)',
                  prefixIcon: Icon(Icons.public,
                      color: TemaGlobal.textoSecundario, size: 20),
                  filled: true,
                  fillColor: TemaGlobal.campoTexto,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                items: <DropdownMenuItem<String>>[
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Todos los estados'),
                  ),
                  ..._todosEstados.map((String e) =>
                      DropdownMenuItem<String>(
                        value: e,
                        child: Text(e, overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (String? v) {
                  setState(() => _filtroEstado = v);
                  _buscar();
                },
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _buscando
                    ? const Center(child: CircularProgressIndicator())
                    : _resultados.isEmpty
                        ? Center(
                            child: Text(
                              'No se encontraron tribunales con esos '
                              'criterios',
                              style:
                                  TextStyle(color: TemaGlobal.textoTenue),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : _listaAgrupada(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Lista agrupada por estado → circuito judicial (con o sin filtro).
  Widget _listaAgrupada() {
    final List<Widget> filas = <Widget>[];
    final Map<String, List<Tribunal>> porEstado =
        <String, List<Tribunal>>{};
    for (final Tribunal t in _resultados) {
      porEstado.putIfAbsent(t.estado, () => <Tribunal>[]).add(t);
    }
    final List<String> estados = porEstado.keys.toList()..sort();
    for (final String estado in estados) {
      final List<Tribunal> tribunalesEstado = porEstado[estado]!;
      if (_filtroEstado == null) {
        filas.add(
            _encabezado(estado, tribunalesEstado.length, nivel: 0));
      }
      final Map<String, List<Tribunal>> porCircuito =
          <String, List<Tribunal>>{};
      for (final Tribunal t in tribunalesEstado) {
        porCircuito
            .putIfAbsent(t.circunscripcionJudicial, () => <Tribunal>[])
            .add(t);
      }
      final List<String> circuitos = porCircuito.keys.toList()..sort();
      for (final String circuito in circuitos) {
        final List<Tribunal> tribunales =
            porCircuito[circuito]!
          ..sort((Tribunal a, Tribunal b) {
            final int f =
                a.etiquetaFuncion.compareTo(b.etiquetaFuncion);
            if (f != 0) return f;
            return a.nombreLimpio.compareTo(b.nombreLimpio);
          });
        if (_filtroEstado != null || circuitos.length > 1) {
          filas.add(
              _encabezado(circuito, tribunales.length, nivel: 1));
        }
        for (final Tribunal t in tribunales) {
          filas.add(ListTile(
            dense: true,
            title: Text(t.nombreLimpio,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${t.etiquetaFuncion}${t.municipio != null ? ' · ${t.municipio}' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5),
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () {
              Haptics.tap();
              Navigator.pop(context, t);
            },
          ));
        }
      }
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: filas,
    );
  }

  Widget _encabezado(String titulo, int cantidad, {int nivel = 0}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, nivel == 0 ? 12 : 8, 4, 4),
      child: Row(
        children: <Widget>[
          Container(
            width: 3,
            height: nivel == 0 ? 18 : 14,
            decoration: BoxDecoration(
              color: nivel == 0
                  ? AppColors.acento
                  : AppColors.acento.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: nivel == 0 ? 13 : 12,
                  color: TemaGlobal.textoSecundario),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$cantidad',
            style: TextStyle(
                fontSize: 11.5,
                color: TemaGlobal.textoTenue,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
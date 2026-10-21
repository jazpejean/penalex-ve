import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

import '../logic/dosimetria_engine.dart';
import '../models/delito.dart';
import '../widgets/app_drawer.dart';
import '../widgets/dosimetria_stepper.dart';
import 'computo_page.dart';

class ConcursoPage extends StatefulWidget {
  const ConcursoPage({required this.delitos, super.key});
  final List<Delito> delitos;

  @override
  State<ConcursoPage> createState() => _ConcursoPageState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<Delito>("delitos", delitos));
  }
}

class _ConcursoPageState extends State<ConcursoPage> {
  late List<bool> _selectedDelitos;
  bool _concursoReal = true;
  bool _admisionHechos = false;
  double _fraccionAdmision = 1 / 3;
  double _penaTotal = 0;
  bool _topeAplicado = false;
  String _articuloConcursoAplicado = '';
  List<String> _pasosConcurso = <String>[];
  bool _mostrarDesglose = false;

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static Color get fondoGris => TemaGlobal.superficie;

  @override
  void initState() {
    super.initState();
    _selectedDelitos = List.generate(widget.delitos.length, (_) => true);
    _calcularTotal();
  }

  void _calcularTotal() {
    final List<Delito> seleccionados = <Delito>[];
    for (int i = 0; i < widget.delitos.length; i++) {
      if (_selectedDelitos[i]) seleccionados.add(widget.delitos[i]);
    }
    if (seleccionados.isEmpty) {
      setState(() {
        _penaTotal = 0.0;
        _topeAplicado = false;
        _articuloConcursoAplicado = '';
        _pasosConcurso = <String>[];
      });
      return;
    }

    // Usar el MISMO motor que el PDF: pantalla y reporte siempre coinciden.
    final ResultadoConcurso res = DosimetriaEngine.calcularConcursoDetallado(
      delitos: seleccionados,
      concurso: _concursoReal ? TipoConcurso.real : TipoConcurso.ideal,
      admisionHechos: _admisionHechos,
      fraccionAdmision: _fraccionAdmision,
    );
    setState(() {
      _penaTotal = res.total;
      _topeAplicado = res.topeAplicado;
      _articuloConcursoAplicado = res.articuloAplicado;
      _pasosConcurso = List<String>.from(res.pasos);
    });
  }

  String _formatearFraccion(double valor) {
    const double epsilon = 0.001;
    if ((valor - 1 / 3).abs() < epsilon) return '1/3';
    if ((valor - 0.5).abs() < epsilon) return '1/2';
    return valor.toStringAsFixed(2);
  }

  void _mostrarInfo(String titulo, String mensaje) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title:
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(mensaje),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        drawer: const AppDrawer(currentRoute: "/concurso"),
        backgroundColor: fondoGris,
        appBar: AppBar(
          backgroundColor: azulMarino,
          title: const Text("CONCURSO Y ADMISIÓN",
              style: TextStyle(
                  color: dorado,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: dorado),
          elevation: 0,
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const DosimetriaStepper(pasoActual: 2),
                    Card(
                      elevation: 0,
                      color: TemaGlobal.tarjeta,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: dorado),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text(
                                  "TIPO DE CONCURSO",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: TemaGlobal.texto.withValues(alpha: 0.85),
                                      letterSpacing: 0.8,
                                      fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    if (_concursoReal) {
                                      _mostrarInfo(
                                        "Concurso Real (Art. 88 CP)",
                                        "Se configura cuando un mismo sujeto comete varios delitos independientes mediante varias acciones. Se aplican todas las penas acumuladas, pero el total no podrá exceder del triple de la pena del delito más grave, ni sobrepasar los 30 años.",
                                      );
                                    } else {
                                      _mostrarInfo(
                                        "Concurso Ideal (Art. 98 CP)",
                                        "Ocurre cuando una sola acción infringe varias disposiciones legales o la misma disposición varias veces. Se aplica exclusivamente la pena establecida para el delito más grave, con el aumento respectivo que determine la ley por la pluralidad de infracciones.",
                                      );
                                    }
                                  },
                                  child: Icon(Icons.info_outline,
                                      color: dorado,
                                      size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SegmentedButton<bool>(
                              segments: const <ButtonSegment<bool>>[
                                ButtonSegment(
                                    value: true,
                                    label: Text("Concurso Real (Material)"),
                                    icon: Icon(Icons.account_tree)),
                                ButtonSegment(
                                    value: false,
                                    label: Text("Concurso Ideal (Formal)"),
                                    icon: Icon(Icons.merge_type)),
                              ],
                              selected: <bool>{_concursoReal},
                              onSelectionChanged: (Set<bool> newSelection) {
                                setState(() {
                                  _concursoReal = newSelection.first;
                                  _calcularTotal();
                                });
                              },
                              style: ButtonStyle(
                                backgroundColor:
                                    WidgetStateProperty.resolveWith(
                                        (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return azulMarino;
                                  }
                                  return fondoGris;
                                }),
                                foregroundColor:
                                    WidgetStateProperty.resolveWith(
                                        (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return dorado;
                                  }
                                  return TemaGlobal.texto;
                                }),
                                side: WidgetStatePropertyAll(
                                    BorderSide(color: TemaGlobal.capa)),
                                shape: WidgetStatePropertyAll(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14))),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Banner informativo con el artículo aplicado
                    if (_concursoReal &&
                        _articuloConcursoAplicado.isNotEmpty) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: dorado.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: dorado.withValues(alpha: 0.35),
                              width: 1.5),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.gavel,
                                color: dorado,
                                size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'ARTÍCULO APLICABLE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _articuloConcursoAplicado,
                                    style: TextStyle(
                                      color: TemaGlobal.texto.withValues(alpha: 0.90),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                String titulo = '';
                                String mensaje = '';

                                if (_articuloConcursoAplicado
                                    .contains('Art. 86')) {
                                  titulo = 'Art. 86 CP - Concurso de Presidios';
                                  mensaje =
                                      'Cuando concurren varios delitos castigados con presidio, se aplicará la pena correspondiente a la infracción más grave, aumentada con la mitad de las otras penas.';
                                } else if (_articuloConcursoAplicado
                                    .contains('Art. 87')) {
                                  titulo =
                                      'Art. 87 CP - Concurso de Presidio y Prisión';
                                  mensaje =
                                      'Cuando concurran delitos castigados con presidio y prisión, se convertirá la pena de prisión en su equivalente de presidio (1 año presidio = 2 años prisión), y se aplicará el Art. 86: pena más grave aumentada con la mitad de las demás.';
                                } else if (_articuloConcursoAplicado
                                    .contains('Art. 88')) {
                                  titulo = 'Art. 88 CP - Concurso de Prisiones';
                                  mensaje =
                                      'Cuando concurran varios delitos castigados con prisión, se aplicará la pena correspondiente a la infracción más grave, aumentada con la mitad de las otras penas.';
                                }

                                if (titulo.isNotEmpty) {
                                  _mostrarInfo(titulo, mensaje);
                                }
                              },
                              child: Icon(Icons.info_outline,
                                  color: dorado,
                                  size: 20),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Card(
                      elevation: 0,
                      color: TemaGlobal.tarjeta,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: dorado),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              "DELITOS PARTICIPANTES",
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: TemaGlobal.texto.withValues(alpha: 0.85),
                                  letterSpacing: 0.8,
                                  fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: widget.delitos.length,
                              separatorBuilder: (_, __) => Divider(
                                  color: TemaGlobal.capa,
                                  height: 1),
                              itemBuilder: (BuildContext context, int index) {
                                final Delito d = widget.delitos[index];
                                final double penaInd =
                                    d.calcularPenaIndividualizada();
                                return CheckboxListTile(
                                  value: _selectedDelitos[index],
                                  onChanged: (bool? val) {
                                    setState(() {
                                      _selectedDelitos[index] = val ?? false;
                                      _calcularTotal();
                                    });
                                  },
                                  title: Text(
                                    d.nombre.isNotEmpty
                                        ? d.nombre
                                        : "Delito sin nombre",
                                    style: TextStyle(
                                        color: TemaGlobal.texto.withValues(alpha: 0.88),
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text("Pena:",
                                          style: TextStyle(
                                              color: TemaGlobal.textoSecundario.withValues(
                                                  alpha: 0.85),
                                              fontSize: 12)),
                                      Text(
                                        DosimetriaEngine.formatYMD(penaInd),
                                        style: TextStyle(
                                            color: TemaGlobal.textoSecundario.withValues(
                                                alpha: 0.85),
                                            fontSize: 12),
                                        softWrap: true,
                                      ),
                                    ],
                                  ),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  activeColor: dorado,
                                  checkColor: azulMarino,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 0,
                      color: TemaGlobal.tarjeta,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: dorado),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    "ADMISIÓN DE HECHOS (Art. 375 COPP)",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color:
                                            TemaGlobal.texto.withValues(alpha: 0.85),
                                        letterSpacing: 0.6,
                                        fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _mostrarInfo(
                                    "Admisión de Hechos (Art. 375 COPP)",
                                    "Institución procesal donde el imputado acepta su responsabilidad en la audiencia. Permite al juez rebajar la pena de un tercio (1/3) a la mitad (1/2), considerando la naturaleza del delito y el momento procesal en que se admita.",
                                  ),
                                  child: Icon(Icons.info_outline,
                                      color: dorado,
                                      size: 20),
                                ),
                              ],
                            ),
                            SwitchListTile(
                              title: Text("Aplicar Admisión de Hechos",
                                  style: TextStyle(
                                      color:
                                          TemaGlobal.texto.withValues(alpha: 0.86))),
                              value: _admisionHechos,
                              onChanged: (bool val) {
                                setState(() {
                                  _admisionHechos = val;
                                  _calcularTotal();
                                });
                              },
                              activeThumbColor: dorado,
                              contentPadding: EdgeInsets.zero,
                            ),
                            if (_admisionHechos) ...<Widget>[
                              const SizedBox(height: 12),
                              Text(
                                "Rebaja: ${_formatearFraccion(_fraccionAdmision)}",
                                style: TextStyle(
                                    color: TemaGlobal.textoSecundario.withValues(alpha: 0.92)),
                              ),
                              Slider(
                                value: _fraccionAdmision,
                                min: 1 / 3,
                                max: 0.5,
                                divisions: 1,
                                label: _formatearFraccion(_fraccionAdmision),
                                onChanged: (double val) {
                                  setState(() {
                                    _fraccionAdmision = (val - (1 / 3)).abs() <
                                            (0.5 - val).abs()
                                        ? 1 / 3
                                        : 0.5;
                                    _calcularTotal();
                                  });
                                },
                                activeColor: dorado,
                                inactiveColor: TemaGlobal.capa,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: fondoGris,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, -6))
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Card(
                      elevation: 0,
                      color: TemaGlobal.texto,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: dorado, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const Text(
                                  "PENA DEFINITIVA",
                                  style: TextStyle(
                                      color: dorado,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      letterSpacing: 0.7),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _mostrarInfo(
                                    "Pena Máxima (Art. 44 CRBV y Art. 94 CP)",
                                    "En el sistema jurídico venezolano, la pena privativa de libertad es de carácter humanista y tiene un límite constitucional absoluto de 30 años. Ningún cálculo aritmético o acumulación de penas puede superar este tope de cumplimiento efectivo.",
                                  ),
                                  child: const Icon(Icons.info_outline,
                                      color: dorado, size: 18),
                                ),
                                if (_topeAplicado) ...<Widget>[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.warning_amber_rounded,
                                      color: Colors.orange, size: 18),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              DosimetriaEngine.formatYMD(_penaTotal),
                              style: const TextStyle(
                                  color: dorado,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: dorado.withValues(alpha: 0.6)),
                              ),
                              child: Text(
                                _articuloConcursoAplicado.isEmpty
                                    ? 'Delito único (sin concurso)'
                                    : _articuloConcursoAplicado,
                                style: const TextStyle(
                                    color: dorado,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (_topeAplicado)
                              const Text(
                                'TOPE DE 30 AÑOS APLICADO (Art. 94 CP)',
                                style: TextStyle(
                                    color: Colors.orangeAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6),
                              ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => setState(
                                  () => _mostrarDesglose = !_mostrarDesglose),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    _mostrarDesglose
                                        ? 'OCULTAR DESGLOSE'
                                        : 'VER DESGLOSE PASO A PASO',
                                    style: const TextStyle(
                                        color: dorado,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5),
                                  ),
                                  Icon(
                                    _mostrarDesglose
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: dorado,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                            if (_mostrarDesglose) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                constraints:
                                    const BoxConstraints(maxHeight: 180),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: TemaGlobal.capa,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: dorado.withValues(alpha: 0.25)),
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: _pasosConcurso.isEmpty
                                        ? <Widget>[
                                            Text('Sin pasos',
                                                style: TextStyle(
                                                    color:
                                                        TemaGlobal.textoSecundario,
                                                    fontSize: 11)),
                                          ]
                                        : _pasosConcurso
                                            .asMap()
                                            .entries
                                            .map((MapEntry<int, String> e) {
                                            final bool esFinal = e.key ==
                                                _pasosConcurso.length - 1;
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 2),
                                              child: Text(
                                                '- ${e.value}',
                                                style: TextStyle(
                                                  color: esFinal
                                                      ? dorado
                                                      : TemaGlobal.texto,
                                                  fontSize: 11,
                                                  fontWeight: esFinal
                                                      ? FontWeight.w800
                                                      : FontWeight.w400,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text("ANTERIOR"),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: dorado),
                              foregroundColor: TemaGlobal.texto,
                              fixedSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final List<Delito> seleccionados = <Delito>[];
                              for (int i = 0; i < widget.delitos.length; i++) {
                                if (_selectedDelitos[i]) {
                                  seleccionados.add(widget.delitos[i]);
                                }
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      ComputoPage(
                                    delitos: seleccionados,
                                    concurso: _concursoReal
                                        ? TipoConcurso.real
                                        : TipoConcurso.ideal,
                                    admisionHechos: _admisionHechos,
                                    fraccionAdmision: _fraccionAdmision,
                                    penaTotal: _penaTotal,
                                    articuloConcurso: _articuloConcursoAplicado,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text("CONTINUAR"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: azulMarino,
                              foregroundColor: dorado,
                              side: const BorderSide(color: dorado),
                              fixedSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

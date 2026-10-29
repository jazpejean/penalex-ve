import 'package:flutter/foundation.dart'; // ← NECESARIO para DiagnosticPropertiesBuilder
import '../services/haptics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/dosimetria_engine.dart';
import '../models/calculation_model.dart';
import '../models/delito.dart';
import '../services/calculation_service.dart';
import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../widgets/buscador_articulos_sheet.dart';
import '../widgets/dosimetria_stepper.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/main_bottom_bar.dart';
import 'concurso_page.dart';

enum UnidadTiempo {
  anos,
  meses,
  dias,
}

class DosimetriaPage extends StatefulWidget {
  const DosimetriaPage({super.key});

  @override
  State<DosimetriaPage> createState() => _DosimetriaPageState();
}

class _DosimetriaPageState extends State<DosimetriaPage> {
  List<Delito> delitos = <Delito>[];
  List<CalculationModel> savedCalculations = <CalculationModel>[];

  // Mapa para rastrear el tipo seleccionado de atenuante/agravante por delito
  Map<String, String> tipoModificadorSeleccionado = <String, String>{};

  
  
  /// Acento de marca: azul marino en modo claro, AppColors.dorado en modo oscuro.
  
  static Color get fondoGris => TemaGlobal.superficie;
  static Color get grisTexto => TemaGlobal.textoSecundario;

  @override
  void initState() {
    super.initState();
    _agregarDelito();
    _loadCalculations();
  }

  Future<void> _loadCalculations() async {
    try {
      final List<CalculationModel> list =
          await CalculationService.getSavedCalculations();
      setState(() => savedCalculations = list);
    } on Exception catch (e) {
      debugPrint('Error cargando cálculos guardados: $e');
      setState(() => savedCalculations = <CalculationModel>[]);
    }
  }

  void _loadCalculation(CalculationModel calc) {
    setState(() {
      delitos =
          calc.delitos.map((Delito d) => Delito.fromMap(d.toMap())).toList();
    });
    // Guía 3.4: AppSnackBar siempre (el navy fijo se funde con el fondo
    // oscuro).
    AppSnackBar.success(context, '"${calc.nombre}" cargado');
  }

  void _resetCalculation() {
    setState(() {
      delitos = [Delito(id: '1')];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cálculo restablecido'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showSavedCalculations() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TemaGlobal.tarjeta,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'CÁLCULOS GUARDADOS',
                    style: TextStyle(
                        color: AppColors.acento,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.6),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.refresh_rounded, color: AppColors.acento),
                        onPressed: _loadCalculations,
                        tooltip: 'Recargar',
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.acento),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: fondoGris,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: savedCalculations.isEmpty
                    ? Center(
                        child: Text(
                          'No hay cálculos guardados',
                          style: TextStyle(
                              color: grisTexto.withValues(alpha: 0.85)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: savedCalculations.length,
                        itemBuilder: (BuildContext context, int index) {
                          final CalculationModel calc =
                              savedCalculations[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 0,
                            color: TemaGlobal.tarjeta,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: TemaGlobal.capa),
                            ),
                            child: ListTile(
                              leading: Icon(Icons.calculate_rounded,
                                  color: TemaGlobal.texto),
                              title: Text(calc.nombre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${calc.delitos.length} delito(s) • ${calc.fecha.day}/${calc.fecha.month}/${calc.fecha.year}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  IconButton(
                                    icon: Icon(Icons.upload_rounded,
                                        color: AppColors.success),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _loadCalculation(calc);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppColors.error),
                                    onPressed: () async {
                                      await CalculationService
                                          .deleteCalculation(calc.id);
                                      await _loadCalculations();
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _agregarDelito() {
    setState(() {
      delitos.add(Delito(id: DateTime.now().millisecondsSinceEpoch.toString()));
    });
  }

  void _actualizarDelito(int index, Delito nuevoDelito) {
    setState(() {
      delitos[index] = nuevoDelito;
    });
  }

  void _eliminarDelito(int index) {
    if (delitos.length > 1) {
      setState(() {
        delitos.removeAt(index);
      });
    }
  }

  String _unidadNombre(UnidadTiempo unidad) {
    switch (unidad) {
      case UnidadTiempo.anos:
        return 'años';
      case UnidadTiempo.meses:
        return 'meses';
      case UnidadTiempo.dias:
        return 'días';
    }
  }

  double _sumarPenas() {
    double total = 0;
    for (final Delito d in delitos) {
      total += d.calcularPenaIndividualizada();
    }
    return total > 30.0 ? 30.0 : total;
  }

  void _showInfoDialog(String title, String content) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required VoidCallback onInfo,
  }) {
    final String? effectiveValue =
        items.contains(value) ? value : (items.isNotEmpty ? items.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 8),
            GestureDetector(
                onTap: onInfo,
                child: Icon(Icons.info_outline, color: AppColors.acento, size: 16)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: TemaGlobal.campoTexto,
            border: Border.all(color: TemaGlobal.capa),
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: effectiveValue,
              isExpanded: true,
              borderRadius: BorderRadius.circular(14),
              items: items
                  .map((String item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double min,
    required double max,
    required double currentValue,
    required ValueChanged<double> onChanged,
    int? divisions,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: Slider(
                  value: currentValue,
                  min: min,
                  max: max,
                  divisions: divisions,
                  label: _fraccionTexto(currentValue),
                  onChanged: onChanged,
                  // Patrón de la guía (3.3): controles de selección dorados,
                  // independientes del modo.
                  activeColor: AppColors.dorado,
                  inactiveColor: AppColors.capa,
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(_fraccionTexto(currentValue),
                    textAlign: TextAlign.center),
              ),
            ],
          ),
        ],
      );

  String _fraccionTexto(double valor) {
    const double epsilon = 0.001;
    if ((valor - 1 / 6).abs() < epsilon) return '1/6';
    if ((valor - 1 / 4).abs() < epsilon) return '1/4';
    if ((valor - 1 / 3).abs() < epsilon) return '1/3';
    if ((valor - 0.5).abs() < epsilon) return '1/2';
    if ((valor - 2 / 3).abs() < epsilon) return '2/3';
    return valor.toStringAsFixed(2);
  }

  GradoEjecucion _parseGradoEjecucion(String value) {
    switch (value.toLowerCase()) {
      case 'frustrado':
        return GradoEjecucion.frustrado;
      case 'tentativa':
        return GradoEjecucion.tentativa;
      default:
        return GradoEjecucion.consumado;
    }
  }

  String _displayGradoEjecucion(GradoEjecucion grado) {
    switch (grado) {
      case GradoEjecucion.frustrado:
        return 'Frustrado';
      case GradoEjecucion.tentativa:
        return 'Tentativa';
      case GradoEjecucion.consumado:
        return 'Consumado';
    }
  }

  String _displayTipoPena(TipoPena tipo) {
    switch (tipo) {
      case TipoPena.presidio:
        return 'Presidio';
      case TipoPena.prision:
        return 'Prisión';
    }
  }

  TipoPena _parseTipoPena(String display) {
    switch (display) {
      case 'Presidio':
        return TipoPena.presidio;
      case 'Prisión':
        return TipoPena.prision;
      default:
        return TipoPena.presidio;
    }
  }

  Widget _buildAjusteTile(int delitoIndex, AjusteAdicional ajuste) => Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.acento),
        ),
        child: ListTile(
          leading: Icon(
              ajuste.esAgravante ? Icons.trending_up : Icons.trending_down,
              color: ajuste.esAgravante ? AppColors.error : AppColors.success),
          title: Text(ajuste.nombre),
          subtitle: Text(
              '${ajuste.esAgravante ? 'Agravante (+)' : 'Atenuante (-)'} ${_fraccionTexto(ajuste.fraccion)}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editarAjuste(delitoIndex, ajuste)),
              IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      delitos[delitoIndex].ajustesAdicionales.remove(ajuste);
                      _actualizarDelito(delitoIndex, delitos[delitoIndex]);
                    });
                  }),
            ],
          ),
        ),
      );

  Future<void> _mostrarDialogoAgregarAjuste(int delitoIndex) async {
    final TextEditingController nombreCtrl = TextEditingController();
    bool esAgravante = true;
    double fraccion = 1 / 3;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, setStateDialog) => AlertDialog(
          title: const Text("Agregar ajuste de pena"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(
                      labelText: "Nombre (ej: Aumento por autoridad)")),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const <ButtonSegment<bool>>[
                  ButtonSegment(
                      value: true, label: Text("Agravante (+ fracción)")),
                  ButtonSegment(
                      value: false, label: Text("Atenuante (- fracción)")),
                ],
                selected: <bool>{esAgravante},
                onSelectionChanged: (Set<bool> set) =>
                    setStateDialog(() => esAgravante = set.first),

                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith(
                      (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.dorado;
                    }
                    return AppColors.capa;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith(
                      (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.onDorado;
                    }
                    return AppColors.texto;
                  }),
                  side: WidgetStatePropertyAll(
                      BorderSide(color: AppColors.capa)),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                    labelText: "Fracción (ej: 1/3, 1/2, 1/4)"),
                onChanged: (String value) {
                  fraccion = _parseFraccion(value);
                  setStateDialog(() {});
                },
              ),
              const SizedBox(height: 8),
              Text("Valor: ${_fraccionTexto(fraccion)}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () {
                if (nombreCtrl.text.isNotEmpty && fraccion != 0) {
                  setState(() {
                    delitos[delitoIndex].ajustesAdicionales.add(AjusteAdicional(
                          nombre: nombreCtrl.text,
                          esAgravante: esAgravante,
                          fraccion: fraccion,
                        ));
                    _actualizarDelito(delitoIndex, delitos[delitoIndex]);
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Agregar"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarAjuste(int delitoIndex, AjusteAdicional ajuste) async {
    final TextEditingController nombreCtrl =
        TextEditingController(text: ajuste.nombre);
    bool esAgravante = ajuste.esAgravante;
    double fraccion = ajuste.fraccion;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, setStateDialog) => AlertDialog(
          title: const Text("Editar ajuste"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: "Nombre")),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const <ButtonSegment<bool>>[
                  ButtonSegment(
                      value: true, label: Text("Agravante (+ fracción)")),
                  ButtonSegment(
                      value: false, label: Text("Atenuante (- fracción)")),
                ],
                selected: <bool>{esAgravante},
                onSelectionChanged: (Set<bool> set) =>
                    setStateDialog(() => esAgravante = set.first),

                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith(
                      (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.dorado;
                    }
                    return AppColors.capa;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith(
                      (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.onDorado;
                    }
                    return AppColors.texto;
                  }),
                  side: WidgetStatePropertyAll(
                      BorderSide(color: AppColors.capa)),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: "Fracción"),
                controller:
                    TextEditingController(text: _fraccionTexto(fraccion)),
                onChanged: (String value) {
                  fraccion = _parseFraccion(value);
                  setStateDialog(() {});
                },
              ),
              const SizedBox(height: 8),
              Text("Valor: ${_fraccionTexto(fraccion)}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () {
                Haptics.light();
                setState(() {
                  ajuste.nombre = nombreCtrl.text;
                  ajuste.esAgravante = esAgravante;
                  ajuste.fraccion = fraccion;
                  _actualizarDelito(delitoIndex, delitos[delitoIndex]);
                });
                Navigator.pop(context);
              },
              child: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }

  double _parseFraccion(String text) {
    if (text.contains('/')) {
      final List<String> parts = text.split('/');
      if (parts.length == 2) {
        final double? num = double.tryParse(parts[0]);
        final double? den = double.tryParse(parts[1]);
        if (num != null && den != null && den != 0) return num / den;
      }
    }
    return double.tryParse(text) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        drawer: const AppDrawer(currentRoute: '/dosimetria'),
        backgroundColor: fondoGris,
        bottomNavigationBar: const MainBottomBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: <Widget>[
                // Menú lateral + acciones de la herramienta.
                Row(
                  children: <Widget>[
                    Builder(
                      builder: (BuildContext menuContext) => IconButton(
                        icon: Icon(Icons.menu, color: AppColors.acento),
                        onPressed: () =>
                            Scaffold.of(menuContext).openDrawer(),
                        tooltip: 'Menú',
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.menu_book_outlined, color: AppColors.acento),
                      onPressed: () {
                        Haptics.tap();
                        mostrarBuscadorArticulos(context);
                      },
                      tooltip: "Consultar artículos de la ley",
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh_rounded, color: AppColors.acento),
                      onPressed: () {
                        Haptics.tap();
                        _resetCalculation();
                      },
                      tooltip: "Restablecer",
                    ),
                    IconButton(
                      icon: Icon(Icons.folder_open_rounded, color: AppColors.acento),
                      onPressed: () {
                        Haptics.tap();
                        _showSavedCalculations();
                      },
                      tooltip: "Cargar cálculo",
                    ),
                  ],
                ),
                const DosimetriaStepper(pasoActual: 1),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: delitos.length,
                  itemBuilder: (BuildContext context, int index) =>
                      _buildDelitoForm(index),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: fondoGris,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Card(
                        elevation: 0,
                        color: TemaGlobal.tarjeta,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppColors.acento, width: 1.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "SUMATORIA DE PENAS",
                                style: TextStyle(
                                    color: AppColors.acento,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    letterSpacing: 0.7),
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  DosimetriaEngine.formatYMD(_sumarPenas()),
                                  style: TextStyle(
                                      color: AppColors.acento,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushNamedAndRemoveUntil(context, "/",
                                    (Route<dynamic> route) => false);
                              },
                              icon: const Icon(Icons.arrow_back),
                              label: const Text("REGRESAR"),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: TemaGlobal.capa),
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (BuildContext context) =>
                                        ConcursoPage(delitos: delitos),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text("SIGUIENTE"),
                              style: ElevatedButton.styleFrom(
                                // Guía 3.2: primario = acento dinámico (navy
                                // en claro / dorado en oscuro).
                                backgroundColor: AppColors.acento,
                                foregroundColor: AppColors.acento ==
                                        AppColors.dorado
                                    ? AppColors.onDorado
                                    : AppColors.onAzulMarino,
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
              ],
            ),
          ),
        ),
      );

  Widget _buildDelitoForm(int index) {
    final Delito delito = delitos[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.acento),
      ),
      color: TemaGlobal.tarjeta,
      surfaceTintColor: TemaGlobal.tarjeta,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'DELITO ${index + 1}',
                  style: TextStyle(
                      color: TemaGlobal.texto,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.8),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: TemaGlobal.capa,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.gavel_rounded, color: AppColors.acento, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        DosimetriaEngine.formatYMD(
                            delito.calcularPenaIndividualizada()),
                        style: TextStyle(
                            color: AppColors.acento,
                            fontSize: 11,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    initialValue: delito.nombre,
                    style: TextStyle(color: TemaGlobal.texto),
                    decoration: InputDecoration(
                      labelText: 'Nombre del delito',
                      labelStyle: TextStyle(color: TemaGlobal.textoSecundario),
                      prefixIcon: Icon(Icons.edit_note_rounded,
                          color: AppColors.acento, size: 20),
                      filled: true,
                      fillColor: TemaGlobal.campoTexto,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: TemaGlobal.capa)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: TemaGlobal.capa)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: AppColors.acento, width: 1.2)),
                    ),
                    onChanged: (String value) {
                      delito.nombre = value;
                      _actualizarDelito(index, delito);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showInfoDialog(
                    'Base legal del tipo penal',
                    'Indique el nombre del delito conforme al Código Penal o leyes especiales.\n\nEjemplo: "Homicidio Calificado" (Art. 406 CPV).',
                  ),
                  child:
                      Icon(Icons.info_outline, color: AppColors.acento, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Selector de tipo de pena: Presidio o Prisión
            _buildDropdownRow(
              label: 'Tipo de pena',
              value: _displayTipoPena(delito.tipoPena),
              items: const <String>['Presidio', 'Prisión'],
              onChanged: (String? val) {
                if (val != null) {
                  delito.tipoPena = _parseTipoPena(val);
                  _actualizarDelito(index, delito);
                }
              },
              onInfo: () {
                // Mostrar información contextual según el tipo seleccionado
                if (delito.tipoPena == TipoPena.presidio) {
                  _showInfoDialog(
                    'Presidio',
                    'Pena privativa de libertad con trabajos forzados. Se caracteriza por imponer al condenado la obligación de realizar labores durante el cumplimiento de la condena.\n\nUtilizado para delitos graves en el Código Penal Venezolano.',
                  );
                } else {
                  _showInfoDialog(
                    'Prisión',
                    'Pena privativa de libertad sin trabajos forzados. El condenado cumple la pena sin obligación de realizar labores específicas.\n\nEn caso de concurso real con presidio, esta pena será convertida conforme al Art. 87 CP (1 año de presidio equivale a 2 años de prisión).',
                  );
                }
              },
            ),
            const SizedBox(height: 20),

            _PenaInputRow(
              label: 'PENA MÍNIMA',
              valorNumerico: delito.minValorNumerico,
              unidad: delito.minUnidad,
              onChanged: (double valor, UnidadTiempo unidad) {
                delito.minValorNumerico = valor;
                delito.minUnidad = _unidadNombre(unidad);
                delito.actualizarPenaDesdeCampos();
                _actualizarDelito(index, delito);
              },
              onInfo: () => _showInfoDialog('Pena mínima',
                  'Límite inferior de la pena establecida en la ley.'),
            ),
            const SizedBox(height: 16),

            _PenaInputRow(
              label: 'PENA MÁXIMA',
              valorNumerico: delito.maxValorNumerico,
              unidad: delito.maxUnidad,
              onChanged: (double valor, UnidadTiempo unidad) {
                delito.maxValorNumerico = valor;
                delito.maxUnidad = _unidadNombre(unidad);
                delito.actualizarPenaDesdeCampos();
                _actualizarDelito(index, delito);
              },
              onInfo: () => _showInfoDialog('Pena máxima',
                  'Límite superior de la pena establecida en la ley.'),
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 16),
            const Text('AJUSTES ADICIONALES',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ...delito.ajustesAdicionales.map(
                (AjusteAdicional ajuste) => _buildAjusteTile(index, ajuste)),
            ElevatedButton.icon(
              onPressed: () => _mostrarDialogoAgregarAjuste(index),
              icon: const Icon(Icons.add),
              label: const Text('Agregar ajuste'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.acento,
                foregroundColor: AppColors.acento == AppColors.dorado
                    ? AppColors.onDorado
                    : AppColors.onAzulMarino,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.acento.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.acento.withValues(alpha: 0.22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Término medio (Art. 37 CP):',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      Text(
                        DosimetriaEngine.formatYMD(delito.terminoMedio),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: TemaGlobal.texto),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showInfoDialog(
                          'Término Medio (Art. 37 CP)',
                          'Punto de partida obligatorio para la dosimetría penal. Se obtiene sumando el límite mínimo y el máximo de la pena prevista para el delito y dividiendo el resultado entre dos. Sobre este valor se aplican las circunstancias atenuantes o agravantes que concurran en el caso.',
                        ),
                        child: Icon(Icons.info_outline,
                            color: AppColors.acento, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('AJUSTES LEGALES',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _buildDropdownRow(
              label: 'Grado de ejecución',
              value: _displayGradoEjecucion(delito.gradoEjecucion),
              items: const <String>['Consumado', 'Frustrado', 'Tentativa'],
              onChanged: (String? val) {
                if (val != null) {
                  delito.gradoEjecucion = _parseGradoEjecucion(val);
                  delito.fraccionEjecucion =
                      delito.gradoEjecucion == GradoEjecucion.frustrado
                          ? 1 / 3
                          : (delito.gradoEjecucion == GradoEjecucion.tentativa
                              ? 0.5
                              : 0);
                  _actualizarDelito(index, delito);
                }
              },
              onInfo: () {
                String titulo = '';
                String mensaje = '';
                switch (delito.gradoEjecucion) {
                  case GradoEjecucion.consumado:
                    titulo = 'Delito Consumado';
                    mensaje =
                        'Se produce cuando el agente ha ejecutado la totalidad de los actos necesarios para la realización del tipo penal y se ha verificado el resultado lesivo. En este supuesto, la pena a aplicar es la que establece la ley para el delito en su extensión íntegra.';
                    break;
                  case GradoEjecucion.frustrado:
                    titulo = 'Delito Frustrado (Arts. 80 y 82 CP)';
                    mensaje =
                        'Ocurre cuando el agente practica todo lo necesario para la consumación del delito, pero esta no se verifica por causas independientes a su voluntad. La pena aplicable será la del delito consumado rebajada en una tercera parte (1/3).';
                    break;
                  case GradoEjecucion.tentativa:
                    titulo = 'Tentativa (Arts. 80 y 82 CP)';
                    mensaje =
                        'Se configura cuando el agente inicia la ejecución del delito mediante actos directos, pero no realiza todo lo necesario para su consumación por causas ajenas a su control. La pena se rebaja entre la mitad (1/2) y las dos terceras partes (2/3).';
                    break;
                }
                _showInfoDialog(titulo, mensaje);
              },
            ),
            const SizedBox(height: 16),

            if (delito.gradoEjecucion == GradoEjecucion.tentativa)
              _buildSliderRow(
                label: 'Rebaja (tentativa)',
                min: 0.5,
                max: 2 / 3,
                currentValue: delito.fraccionEjecucion,
                onChanged: (double val) {
                  const List<double> targets = <double>[0.5, 2 / 3];
                  final double newVal = targets.reduce((double a, double b) =>
                      (a - val).abs() < (b - val).abs() ? a : b);
                  delito.fraccionEjecucion = newVal;
                  _actualizarDelito(index, delito);
                },
                divisions: 1,
              ),

            _buildDropdownRow(
              label: 'Grado de participación',
              value: delito.participacionEspecifica,
              items: const <String>[
                'Autor',
                'Coautor',
                'Cooperador Inmediato',
                'Cómplice Necesario',
                'Cómplice No Necesario',
              ],
              onChanged: (String? val) {
                if (val != null) {
                  delito.participacionEspecifica = val;
                  _actualizarDelito(index, delito);
                }
              },
              onInfo: () {
                if (delito.participacionEspecifica == 'Cómplice No Necesario') {
                  _showInfoDialog(
                    'Cómplice No Necesario (Art. 84 CP)',
                    'Se refiere a quienes coadyuvan en la ejecución del delito mediante instrucciones, suministros o auxilio secundario no indispensable. La pena correspondiente al autor principal se rebajará a la mitad (1/2) para este grado de participación.',
                  );
                } else {
                  _showInfoDialog(
                    'Autoría y Participación (Art. 83 CP)',
                    'Se aplica la pena íntegra del delito al Autor, Coautor y Cooperador Inmediato, por ser piezas esenciales en la ejecución del hecho. Igualmente, el Cómplice Necesario recibe la misma pena al prestar un auxilio sin el cual no habría sido posible el acto.',
                  );
                }
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: <Widget>[
                const Text('Delito continuado',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showInfoDialog(
                    'Delito Continuado (Art. 99 CP)',
                    'Varias violaciones de la misma disposición legal, cometidas en diferentes fechas pero bajo una misma resolución criminal, se consideran un solo hecho punible. Se toma la pena del delito más grave (término medio) y se aumenta entre una sexta parte (1/6) y la mitad (1/2).',
                  ),
                  child:
                      Icon(Icons.info_outline, color: AppColors.acento, size: 18),
                ),
                const Spacer(),
                Switch(
                  value: delito.delitoContinuado,
                  onChanged: (bool val) {
                    delito.delitoContinuado = val;
                    _actualizarDelito(index, delito);
                  },
                  activeColor: AppColors.dorado,
                  activeTrackColor: AppColors.dorado.withValues(alpha: 0.35),
                  inactiveTrackColor: AppColors.capa,
                  inactiveThumbColor: AppColors.textoSecundario,
                ),
              ],
            ),
            if (delito.delitoContinuado) ...<Widget>[
              const SizedBox(height: 12),
              _buildSliderRow(
                label: 'Aumento (Art. 99 CP)',
                min: 1 / 6,
                max: 0.5,
                currentValue: delito.fraccionContinuidad,
                onChanged: (double val) {
                  setState(() {
                    const List<double> targets = <double>[1 / 6, 1 / 4, 1 / 3, 0.5];
                    final double newVal = targets.reduce((double a, double b) =>
                        (a - val).abs() < (b - val).abs() ? a : b);
                    delito.fraccionContinuidad = newVal;
                    _actualizarDelito(index, delito);
                  });
                },
              ),
            ],
            const SizedBox(height: 20),

            const Text('ATENUANTES / AGRAVANTES (Arts. 74 y 77 CP)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const <ButtonSegment<String>>[
                      ButtonSegment(
                          value: 'atenuante', label: Text('Atenuante')),
                      ButtonSegment(
                          value: 'agravante', label: Text('Agravante')),
                    ],
                    selected: <String>{
                      // Usar el tipo guardado en el mapa, o inferir del valor
                      tipoModificadorSeleccionado[delito.id] ??
                          (delito.modificadorManual < 0
                              ? "atenuante"
                              : "agravante"),
                    },
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        final String tipo = newSelection.first;
                        // Guardar el tipo seleccionado
                        tipoModificadorSeleccionado[delito.id] = tipo;

                        // Si ya hay un valor diferente de 0, aplicar el signo
                        final double valorAbs = delito.modificadorManual.abs();
                        if (valorAbs > 0) {
                          delito.modificadorManual =
                              tipo == 'agravante' ? valorAbs : -valorAbs;
                          _actualizarDelito(index, delito);
                        }
                      });
                    },
                    style: ButtonStyle(
                      // Guía 3.3: seleccionado = fondo dorado, texto onDorado;
                      // no seleccionado = fondo capa, texto texto. Nunca navy
                      // con texto dorado (ilegible y se funde en oscuro).
                      backgroundColor: WidgetStateProperty.resolveWith(
                          (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.dorado;
                        }
                        return TemaGlobal.capa;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith(
                          (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.onDorado;
                        }
                        return TemaGlobal.texto;
                      }),
                      side: WidgetStatePropertyAll(BorderSide(
                          color: TemaGlobal.capa)),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showInfoDialog(
                    'Atenuantes (Art. 74 CP) y Agravantes (Art. 77 CP)',
                    'Atenuantes: circunstancias que reducen la responsabilidad penal (como la falta de intención proporcional al daño o la minoridad). Su presencia obliga al juez a mover la pena desde el término medio hacia el límite mínimo.\n\nAgravantes: circunstancias que aumentan la punibilidad debido a la mayor peligrosidad del agente o la forma de ejecución (alevosía, ensañamiento, reincidencia). Su presencia obliga al juez a mover la pena desde el término medio hacia el límite máximo.',
                  ),
                  child:
                      Icon(Icons.info_outline, color: AppColors.acento, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PenaInputRow(
              label: 'Cantidad',
              valorNumerico: delito.modificadorManual.abs(),
              unidad: delito.modificadorUnidad,
              onChanged: (double valor, UnidadTiempo unidad) {
                double valorEnAnios = valor;
                switch (unidad) {
                  case UnidadTiempo.meses:
                    valorEnAnios = valor / 12;
                    break;
                  case UnidadTiempo.dias:
                    valorEnAnios = valor / 360;
                    break;
                  default:
                    break;
                }
                // Usar el tipo seleccionado del mapa, o inferir del valor actual
                final String tipo = tipoModificadorSeleccionado[delito.id] ??
                    (delito.modificadorManual < 0 ? 'atenuante' : 'agravante');
                final int signo = tipo == 'atenuante' ? -1 : 1;
                delito.modificadorManual = signo * valorEnAnios;
                delito.modificadorUnidad = _unidadNombre(unidad);
                _actualizarDelito(index, delito);
              },
              onInfo: () {},
            ),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: TemaGlobal.tarjeta,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.acento, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('PENA INDIVIDUALIZADA',
                      style: TextStyle(
                          color: AppColors.acento, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      DosimetriaEngine.formatYMD(
                          delito.calcularPenaIndividualizada()),
                      style: TextStyle(
                          color: AppColors.acento,
                          fontWeight: FontWeight.w800,
                          fontSize: 14),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _agregarDelito,
                    icon: const Icon(Icons.add),
                    label: const Text('AGREGAR OTRO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.acento,
                      foregroundColor: AppColors.acento == AppColors.dorado
                          ? AppColors.onDorado
                          : AppColors.onAzulMarino,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      fixedSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
            if (delitos.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton.icon(
                  onPressed: () => _eliminarDelito(index),
                  icon:
                      Icon(Icons.delete_outline, color: AppColors.error),
                  label: Text('Eliminar este delito',
                      style: TextStyle(color: AppColors.error)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<Delito>('delitos', delitos));
    properties.add(IterableProperty<CalculationModel>(
        'savedCalculations', savedCalculations));
  }
}

class _PenaInputRow extends StatefulWidget {
  const _PenaInputRow({
    required this.label,
    required this.valorNumerico,
    required this.unidad,
    required this.onChanged,
    required this.onInfo,
  });
  final String label;
  final double valorNumerico;
  final String unidad;
  final Function(double, UnidadTiempo) onChanged;
  final VoidCallback onInfo;

  @override
  State<_PenaInputRow> createState() => _PenaInputRowState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('label', label));
    properties.add(DoubleProperty('valorNumerico', valorNumerico));
    properties.add(StringProperty('unidad', unidad));
    properties.add(ObjectFlagProperty<Function(double, UnidadTiempo)>.has(
        'onChanged', onChanged));
    properties.add(ObjectFlagProperty<VoidCallback>.has('onInfo', onInfo));
  }
}

class _PenaInputRowState extends State<_PenaInputRow> {
  late TextEditingController _anosController;
  late TextEditingController _mesesController;
  late TextEditingController _diasController;
  bool _isUpdatingFromUser = false;

  
  /// Acento de marca: azul marino en modo claro, AppColors.dorado en modo oscuro.
  

  @override
  void initState() {
    super.initState();
    _anosController = TextEditingController();
    _mesesController = TextEditingController();
    _diasController = TextEditingController();
    _updateControllers();
  }

  @override
  void didUpdateWidget(covariant _PenaInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo actualizar si no estamos en medio de una edición del usuario
    if (!_isUpdatingFromUser &&
        (oldWidget.valorNumerico != widget.valorNumerico ||
            oldWidget.unidad != widget.unidad)) {
      _updateControllers();
    }
  }

  void _updateControllers() {
    final Map<String, int> ymd =
        DosimetriaEngine.convertToYMD(widget.valorNumerico);
    _anosController.text = ymd['anos'] == 0 ? '' : ymd['anos']!.toString();
    _mesesController.text = ymd['meses'] == 0 ? '' : ymd['meses']!.toString();
    _diasController.text = ymd['dias'] == 0 ? '' : ymd['dias']!.toString();
  }

  @override
  void dispose() {
    _anosController.dispose();
    _mesesController.dispose();
    _diasController.dispose();
    super.dispose();
  }

  Widget _buildTimeInputField({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly
        ],
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: TemaGlobal.campoTexto,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: TemaGlobal.capa)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: TemaGlobal.capa)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: AppColors.acento, width: 1.2)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        onChanged: onChanged,
      );

  Map<String, int> _parseYMD(String anos, String meses, String dias) {
    final int a = int.tryParse(anos) ?? 0;
    final int m = int.tryParse(meses) ?? 0;
    final int d = int.tryParse(dias) ?? 0;
    final int totalDias = (a * 360) + (m * 30) + d;
    return <String, int>{
      'anos': a,
      'meses': m,
      'dias': d,
      'totalDias': totalDias
    };
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(widget.label,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onInfo,
                child: Icon(Icons.info_outline, color: AppColors.acento, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Table(
            columnWidths: const <int, TableColumnWidth>{
              0: FlexColumnWidth(),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
            },
            children: <TableRow>[
              TableRow(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildTimeInputField(
                      controller: _anosController,
                      label: "Años",
                      onChanged: (String value) {
                        _isUpdatingFromUser = true;
                        final Map<String, int> newYMD = _parseYMD(
                          _anosController.text,
                          _mesesController.text,
                          _diasController.text,
                        );
                        widget.onChanged(
                            newYMD["totalDias"]! / 360.0, UnidadTiempo.anos);
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _isUpdatingFromUser = false;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _buildTimeInputField(
                      controller: _mesesController,
                      label: "Meses",
                      onChanged: (String value) {
                        _isUpdatingFromUser = true;
                        final Map<String, int> newYMD = _parseYMD(
                          _anosController.text,
                          _mesesController.text,
                          _diasController.text,
                        );
                        widget.onChanged(
                            newYMD["totalDias"]! / 360.0, UnidadTiempo.anos);
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _isUpdatingFromUser = false;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _buildTimeInputField(
                      controller: _diasController,
                      label: "Días",
                      onChanged: (String value) {
                        _isUpdatingFromUser = true;
                        final Map<String, int> newYMD = _parseYMD(
                          _anosController.text,
                          _mesesController.text,
                          _diasController.text,
                        );
                        widget.onChanged(
                            newYMD["totalDias"]! / 360.0, UnidadTiempo.anos);
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _isUpdatingFromUser = false;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
}

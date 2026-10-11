import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/dosimetria_engine.dart';
import '../models/delito.dart';

class DelitoCard extends StatelessWidget {
  const DelitoCard({
    required this.delito,
    required this.index,
    required this.totalDelitos,
    required this.onDelete,
    required this.onUpdate,
    required this.onInfoLegal,
    super.key,
  });
  final Delito delito;
  final int index;
  final int totalDelitos;
  final VoidCallback onDelete;
  final Function(Delito) onUpdate;
  final Function(String, String) onInfoLegal;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                "DELITO ${index + 1} de $totalDelitos",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              if (totalDelitos > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: "Eliminar este delito",
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  initialValue: delito.nombre,
                  decoration: InputDecoration(
                    labelText: "Nombre del delito",
                    prefixIcon: const Icon(Icons.edit_note, color: Color(0xFFC5A059)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (String value) {
                    delito.nombre = value;
                    onUpdate(delito);
                  },
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onInfoLegal(
                  "Base legal del tipo penal",
                  "Indique el nombre del delito según el Código Penal o leyes especiales. "
                  "La pena mínima y máxima deben corresponder con el marco legal aplicable.",
                ),
                child: const Icon(Icons.info_outline, color: Color(0xFFC5A059), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text("PENA MÍNIMA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          _buildPenaInputRow(
            valorNumerico: delito.minValorNumerico,
            unidad: delito.minUnidad,
            onChanged: (double valor, String unidad) {
              delito.minValorNumerico = valor;
              delito.minUnidad = unidad;
              delito.actualizarPenaDesdeCampos();
              onUpdate(delito);
            },
            infoText: "Pena mínima establecida en la ley para este delito.",
          ),
          const SizedBox(height: 16),
          const Text("PENA MÁXIMA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          _buildPenaInputRow(
            valorNumerico: delito.maxValorNumerico,
            unidad: delito.maxUnidad,
            onChanged: (double valor, String unidad) {
              delito.maxValorNumerico = valor;
              delito.maxUnidad = unidad;
              delito.actualizarPenaDesdeCampos();
              onUpdate(delito);
            },
            infoText: "Pena máxima establecida en la ley para este delito.",
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFC5A059).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC5A059).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.show_chart, color: Color(0xFFC5A059), size: 16),
                const SizedBox(width: 8),
                const Text("Término medio (Art. 37 CP):", style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  DosimetriaEngine.formatYMD(delito.terminoMedio),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => onInfoLegal(
                    "Término Medio (Art. 37 CP)",
                    "Punto de partida de la dosimetría que se obtiene sumando el límite mínimo y el máximo de la pena y dividiendo entre dos. Sobre este se aplican las atenuantes o agravantes.",
                  ),
                  child: const Icon(Icons.info_outline, color: Color(0xFFC5A059), size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text("AJUSTES LEGALES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          _buildDropdownRow(
            label: "Grado de ejecución",
            value: delito.gradoEjecucion.name.toUpperCase(),
            items: const <String>["CONSUMADO", "FRUSTRADO", "TENTATIVA"],
            onChanged: (String newValue) {
              if (newValue == "CONSUMADO") {
                delito.gradoEjecucion = GradoEjecucion.consumado;
              } else if (newValue == "FRUSTRADO") {
                delito.gradoEjecucion = GradoEjecucion.frustrado;
              } else {
                delito.gradoEjecucion = GradoEjecucion.tentativa;
              }
              if (delito.gradoEjecucion == GradoEjecucion.frustrado) {
                delito.fraccionEjecucion = 1 / 3;
              } else if (delito.gradoEjecucion == GradoEjecucion.tentativa) {
                delito.fraccionEjecucion = 0.5;
              } else {
                delito.fraccionEjecucion = 0;
              }
              onUpdate(delito);
            },
            infoTitle: "Grado de ejecución",
            infoMessage: _getInfoGrado(delito.gradoEjecucion),
          ),
          const SizedBox(height: 12),
          if (delito.gradoEjecucion == GradoEjecucion.tentativa) ...<Widget>[
            const Text("Rebaja (tentativa):", style: TextStyle(fontWeight: FontWeight.w500)),
            _buildFractionSlider(
              values: <double>[0.5, 2 / 3],
              currentValue: delito.fraccionEjecucion,
              onChanged: (double newValue) {
                delito.fraccionEjecucion = newValue;
                onUpdate(delito);
              },
            ),
            const SizedBox(height: 12),
          ],
          _buildDropdownRow(
            label: "Grado de participación",
            value: delito.participacionEspecifica,
            items: const <String>["Autor", "Coautor", "Cooperador Inmediato", "Cómplice Necesario", "Cómplice No Necesario"],
            onChanged: (String newValue) {
              delito.participacionEspecifica = newValue;
              onUpdate(delito);
            },
            infoTitle: "Grado de participación",
            infoMessage: delito.participacionEspecifica == "Cómplice No Necesario"
                ? "Quien coadyuva en la ejecución sin ser indispensable. La pena se rebaja a la mitad (1/2) de la que corresponda al autor principal (Art. 84 CP)."
                : "Sujetos que ejecutan el hecho o prestan una cooperación principal, o cuyo auxilio es indispensable para cometer el delito. Se les aplica la pena correspondiente al delito sin rebajas por su grado de participación (Art. 83 CP).",
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: SwitchListTile(
                  title: const Text("Delito continuado"),
                  value: delito.delitoContinuado,
                  onChanged: (bool value) {
                    delito.delitoContinuado = value;
                    onUpdate(delito);
                  },
                  activeThumbColor: const Color(0xFFC5A059),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              GestureDetector(
                onTap: () => onInfoLegal(
                  "Delito Continuado (Art. 99 CP)",
                  "Varias violaciones de la misma disposición legal con una sola resolución. Se aplica la pena del delito más grave (término medio) aumentada de una sexta parte (1/6) a la mitad (1/2).",
                ),
                child: const Icon(Icons.info_outline, color: Color(0xFFC5A059), size: 20),
              ),
            ],
          ),
          if (delito.delitoContinuado) ...<Widget>[
            const SizedBox(height: 8),
            const Text("Aumento:", style: TextStyle(fontWeight: FontWeight.w500)),
            _buildFractionSlider(
              values: <double>[1 / 6, 0.25, 1 / 3, 0.5],
              currentValue: delito.fraccionContinuidad,
              onChanged: (double newValue) {
                delito.fraccionContinuidad = newValue;
                onUpdate(delito);
              },
            ),
          ],
          const SizedBox(height: 16),
          const Text("ATENUANTES / AGRAVANTES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const <ButtonSegment<String>>[
              ButtonSegment(value: "atenuante", label: Text("Atenuante")),
              ButtonSegment(value: "agravante", label: Text("Agravante")),
            ],
            selected: <String>{if (delito.modificadorManual >= 0) 'agravante' else 'atenuante'},
            onSelectionChanged: (Set<String> newSelection) {
              final String tipo = newSelection.first;
              final double valorAbs = delito.modificadorManual.abs();
              if (tipo == "agravante") {
                delito.modificadorManual = valorAbs;
              } else {
                delito.modificadorManual = -valorAbs;
              }
              onUpdate(delito);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildPenaInputField(
                  valorNumerico: delito.modificadorManual.abs(),
                  onChanged: (double val) {
                    double valorEnAnios = val;
                    switch (delito.modificadorUnidad) {
                      case "meses":
                        valorEnAnios = val / 12;
                        break;
                      case "días":
                        valorEnAnios = val / 360;
                        break;
                    }
                    if (delito.modificadorManual >= 0) {
                      delito.modificadorManual = valorEnAnios;
                    } else {
                      delito.modificadorManual = -valorEnAnios;
                    }
                    onUpdate(delito);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SegmentedButton<String>(
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment(value: "años", label: Text("Años")),
                    ButtonSegment(value: "meses", label: Text("Meses")),
                    ButtonSegment(value: "días", label: Text("Días")),
                  ],
                  selected: <String>{delito.modificadorUnidad},
                  onSelectionChanged: (Set<String> newSelection) {
                    final String unidad = newSelection.first;
                    final double valorAbs = delito.modificadorManual.abs();
                    double valorEnAnios = valorAbs;
                    switch (unidad) {
                      case "meses":
                        valorEnAnios = valorAbs / 12;
                        break;
                      case "días":
                        valorEnAnios = valorAbs / 360;
                        break;
                    }
                    if (delito.modificadorManual >= 0) {
                      delito.modificadorManual = valorEnAnios;
                    } else {
                      delito.modificadorManual = -valorEnAnios;
                    }
                    delito.modificadorUnidad = unidad;
                    onUpdate(delito);
                  },
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onInfoLegal(
                  "Atenuantes y Agravantes",
                  "Atenuantes (Art. 74 CP): Circunstancias que reducen la responsabilidad penal, moviendo la pena del término medio hacia el límite mínimo.\n\nAgravantes (Art. 77 CP): Circunstancias que aumentan la punibilidad (reincidencia, alevosía), moviendo la pena del término medio hacia el límite máximo.",
                ),
                child: const Icon(Icons.info_outline, color: Color(0xFFC5A059), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  "Pena individualizada",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC5A059)),
                ),
                Text(
                  DosimetriaEngine.formatYMD(delito.calcularPenaIndividualizada()),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFC5A059)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    delito.nombre = "";
                    delito.minValorNumerico = 0;
                    delito.minUnidad = "años";
                    delito.maxValorNumerico = 0;
                    delito.maxUnidad = "años";
                    delito.gradoEjecucion = GradoEjecucion.consumado;
                    delito.fraccionEjecucion = 0;
                    delito.participacionEspecifica = "Autor";
                    delito.delitoContinuado = false;
                    delito.fraccionContinuidad = 1 / 6;
                    delito.modificadorManual = 0;
                    delito.modificadorUnidad = "años";
                    delito.actualizarPenaDesdeCampos();
                    onUpdate(delito);
                  },
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text("LIMPIAR FORMULARIO"),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    foregroundColor: Colors.orange,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Presione "AGREGAR DELITO" en la parte inferior')),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("AGREGAR OTRO DELITO"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: const Color(0xFFC5A059),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

  Widget _buildPenaInputRow({
    required double valorNumerico,
    required String unidad,
    required Function(double, String) onChanged,
    required String infoText,
  }) => Row(
      children: <Widget>[
        Expanded(
          child: _buildPenaInputField(
            valorNumerico: valorNumerico,
            onChanged: (double val) => onChanged(val, unidad),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SegmentedButton<String>(
            segments: const <ButtonSegment<String>>[
              ButtonSegment(value: "años", label: Text("Años")),
              ButtonSegment(value: "meses", label: Text("Meses")),
              ButtonSegment(value: "días", label: Text("Días")),
            ],
            selected: <String>{unidad},
            onSelectionChanged: (Set<String> newSelection) {
              onChanged(valorNumerico, newSelection.first);
            },
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => onInfoLegal("Rango legal", infoText),
          child: const Icon(Icons.info_outline, color: Color(0xFFC5A059), size: 20),
        ),
      ],
    );

  Widget _buildPenaInputField({
    required double valorNumerico,
    required Function(double) onChanged,
  }) {
    final TextEditingController controller = TextEditingController(text: valorNumerico == 0 ? '' : valorNumerico.toString());
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      decoration: InputDecoration(
        hintText: '0',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: (String str) {
        final double val = double.tryParse(str) ?? 0;
        onChanged(val);
      },
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
    required String infoTitle,
    required String infoMessage,
  }) => Row(
      children: <Widget>[
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: items.contains(value) ? value : items.first,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: items.map((String item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) onChanged(newValue);
            },
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => onInfoLegal(infoTitle, infoMessage),
          child: const Icon(Icons.info_outline, color: Color(0xFFC5A059), size: 20),
        ),
      ],
    );

  Widget _buildFractionSlider({
    required List<double> values,
    required double currentValue,
    required ValueChanged<double> onChanged,
  }) {
    final double minVal = values.first;
    final double maxVal = values.last;
    return Slider(
      value: currentValue.clamp(minVal, maxVal),
      min: minVal,
      max: maxVal,
      divisions: values.length - 1,
      label: _fraccionTexto(currentValue),
      onChanged: (double newValue) {
        final double best = values.reduce((double a, double b) => (newValue - a).abs() < (newValue - b).abs() ? a : b);
        onChanged(best);
      },
      activeColor: const Color(0xFFC5A059),
    );
  }

  String _fraccionTexto(double valor) {
    const double epsilon = 0.001;
    if ((valor - 1 / 3).abs() < epsilon) return '1/3';
    if ((valor - 0.5).abs() < epsilon) return '1/2';
    if ((valor - 2 / 3).abs() < epsilon) return '2/3';
    if ((valor - 0.25).abs() < epsilon) return '1/4';
    if ((valor - 1 / 6).abs() < epsilon) return '1/6';
    return valor.toStringAsFixed(2);
  }

  String _getInfoGrado(GradoEjecucion g) {
    switch (g) {
      case GradoEjecucion.consumado:
        return 'Se verifica cuando el agente ha realizado todos los actos de ejecución y producido el resultado típico. Se aplica la pena íntegra establecida en la ley.';
      case GradoEjecucion.frustrado:
        return 'El culpable practica todo lo necesario para la consumación sin lograrla por causas ajenas a su voluntad. La pena se reduce en una tercera parte (1/3) respecto a la del delito consumado.';
      case GradoEjecucion.tentativa:
        return 'Inicio de ejecución con actos directos que se interrumpe por causas externas. La pena se reduce de la mitad (1/2) a las dos terceras partes (2/3) de la que correspondería al delito consumado.';
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Delito>('delito', delito));
    properties.add(IntProperty('index', index));
    properties.add(IntProperty('totalDelitos', totalDelitos));
    properties.add(ObjectFlagProperty<VoidCallback>.has('onDelete', onDelete));
    properties.add(ObjectFlagProperty<Function(Delito)>.has('onUpdate', onUpdate));
    properties.add(ObjectFlagProperty<Function(String, String)>.has('onInfoLegal', onInfoLegal));
  }
}
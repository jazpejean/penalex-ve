import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class LapsosPage extends StatefulWidget {
  const LapsosPage({super.key});

  @override
  State<LapsosPage> createState() => _LapsosPageState();
}

class _LapsosPageState extends State<LapsosPage> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _resultado = 'Selecciona las fechas para calcular el lapso.';

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color fondo = Color(0xFF111827);

  Future<void> _selectDate(BuildContext context, bool isInicio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: dorado,
              onPrimary: azulMarino,
              surface: azulMarino,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
    );

    if (picked == null) return;
    setState(() {
      if (isInicio) {
        _fechaInicio = picked;
      } else {
        _fechaFin = picked;
      }
    });
  }

  void _calcularLapso() {
    if (_fechaInicio == null || _fechaFin == null) {
      setState(() => _resultado = 'Selecciona ambas fechas para obtener el cómputo.');
      return;
    }

    if (_fechaFin!.isBefore(_fechaInicio!)) {
      setState(() => _resultado = 'La fecha final debe ser posterior a la fecha inicial.');
      return;
    }

    final Duration diferencia = _fechaFin!.difference(_fechaInicio!);
    final int dias = diferencia.inDays;
    setState(() => _resultado = 'El lapso entre fechas es de $dias días naturales.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text("Cómputo de Días"),
        backgroundColor: azulMarino,
      ),
      drawer: const AppDrawer(currentRoute: "/lapsos"),
      backgroundColor: azulMarino,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              "Cómputo de Días Judicial",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Calcula plazos procesales de manera rápida y confiable.",
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 24),
            _buildDateCard("Fecha de inicio", _fechaInicio, () => _selectDate(context, true)),
            const SizedBox(height: 16),
            _buildDateCard("Fecha de fin", _fechaFin, () => _selectDate(context, false)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _calcularLapso,
              style: ElevatedButton.styleFrom(
                backgroundColor: dorado,
                foregroundColor: azulMarino,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text("Calcular lapso", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: fondo,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: dorado.withValues(alpha: 0.18)),
              ),
              child: Text(
                _resultado,
                style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildDateCard(String label, DateTime? value, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  value != null ? "${value.day}/${value.month}/${value.year}" : "Selecciona una fecha",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Icon(Icons.calendar_month, color: Color(0xFFC5A059)),
          ],
        ),
      ),
    );
}
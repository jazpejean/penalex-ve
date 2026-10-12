import 'package:flutter/material.dart';

/// Indicador de progreso de 3 pasos de la calculadora de dosimetría:
/// 1. Delitos → 2. Concurso → 3. Cómputo.
class DosimetriaStepper extends StatelessWidget {
  const DosimetriaStepper({super.key, required this.pasoActual});

  /// Paso activo: 1 (Delitos), 2 (Concurso), 3 (Cómputo).
  final int pasoActual;

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);

  @override
  Widget build(BuildContext context) {
    const List<String> pasos = <String>['DELITOS', 'CONCURSO', 'CÓMPUTO'];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < pasos.length; i++) ...<Widget>[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  color: i < pasoActual ? azulMarino : Colors.grey.shade300,
                ),
              ),
            _ChipPaso(
              numero: i + 1,
              etiqueta: pasos[i],
              completado: i + 1 < pasoActual,
              activo: i + 1 == pasoActual,
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipPaso extends StatelessWidget {
  const _ChipPaso({
    required this.numero,
    required this.etiqueta,
    required this.completado,
    required this.activo,
  });

  final int numero;
  final String etiqueta;
  final bool completado;
  final bool activo;

  @override
  Widget build(BuildContext context) {
    final bool resaltado = completado || activo;
    final Color bg =
        resaltado ? DosimetriaStepper.azulMarino : const Color(0xFFE2E8F0);
    final Color fg =
        resaltado ? DosimetriaStepper.dorado : Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: resaltado ? DosimetriaStepper.dorado : Colors.grey.shade400,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (completado)
            const Icon(Icons.check_rounded, size: 14, color: Color(0xFFC5A059))
          else
            Text(
              '$numero',
              style: TextStyle(
                  color: fg, fontSize: 11, fontWeight: FontWeight.w800),
            ),
          const SizedBox(width: 5),
          Text(
            etiqueta,
            style: TextStyle(
                color: fg,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}

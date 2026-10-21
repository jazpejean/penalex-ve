import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/ley_estructurada.dart';

/// Renderiza una tabla/anexo de un artículo (campo `tablas` del JSON de la ley)
/// como una tabla real: encabezado (ej. "ANEXO I"), nombre de la tabla y
/// columnas/filas con scroll horizontal.
class TablaAnexoView extends StatelessWidget {
  static const Color dorado = Color(0xFFC5A059);
  static const Color azulMarino = Color(0xFF0F172A);

  final TablaAnexo tabla;

  const TablaAnexoView({super.key, required this.tabla});

  @override
  Widget build(BuildContext context) {
    final cols = tabla.columnas;
    if (cols.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: azulMarino.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dorado.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tabla.titulo != null && tabla.titulo!.isNotEmpty)
            Text(
              tabla.titulo!,
              style: const TextStyle(
                color: dorado,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          if (tabla.tabla != null && tabla.tabla!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              tabla.tabla!,
              style: TextStyle(
                color: TemaGlobal.textoSecundario,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(dorado.withOpacity(0.18)),
              headingTextStyle: const TextStyle(
                color: dorado,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              dataTextStyle: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              columnSpacing: 24,
              horizontalMargin: 8,
              columns: [
                for (final c in cols) DataColumn(label: Text(c['titulo'] ?? '')),
              ],
              rows: [
                for (final f in tabla.filas)
                  DataRow(cells: [
                    for (final c in cols)
                      DataCell(Text(f[c['id']] ?? '', softWrap: true)),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Estado vacío único de la app (APP-18).
///
/// Icono, título y mensaje con la misma escala y los mismos colores en todas
/// las pantallas. La acción es opcional.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icono,
    required this.titulo,
    this.mensaje,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String? mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icono, size: 44, color: TemaGlobal.textoTenue),
          const SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: TemaGlobal.textoSecundario,
            ),
          ),
          if (mensaje != null && mensaje!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              mensaje!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: TemaGlobal.textoTenue),
            ),
          ],
          if (accion != null) ...<Widget>[
            const SizedBox(height: 16),
            accion!,
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../config/app_tokens.dart';

/// Header único de todas las pantallas de Penalex VE.
///
/// Título con la escala de la app, subtítulo opcional y acciones a la
/// derecha. Se usa igual en Inicio, Agenda, Consulta, Asistente y en las
/// herramientas, para que todas las secciones se vean idénticas.
class AppScreenHeader extends StatelessWidget {
  const AppScreenHeader({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acciones = const <Widget>[],
  });

  final String titulo;
  final String? subtitulo;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(titulo, style: AppTokens.tituloPantalla),
              if (subtitulo != null && subtitulo!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(subtitulo!, style: AppTokens.secundario),
              ],
            ],
          ),
        ),
        if (acciones.isNotEmpty) ...<Widget>[
          const SizedBox(width: 12),
          ...acciones,
        ],
      ],
    );
  }
}

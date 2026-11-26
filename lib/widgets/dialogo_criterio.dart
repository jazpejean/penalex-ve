import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../config/app_tokens.dart';
import '../models/sentencia_model.dart';
import '../services/criterio_dia_service.dart';
import '../services/tarjeta_service.dart';
import 'tarjeta_criterio.dart';

/// Popup que aparece al abrir la app con el criterio del día.
///
/// Muestra la tarjeta lista para redes y permite compartirla como imagen.
class DialogoCriterio extends StatefulWidget {
  const DialogoCriterio({super.key, required this.sentencia, this.tip});

  final SentenciaModel sentencia;
  final TipDelDia? tip;

  @override
  State<DialogoCriterio> createState() => _DialogoCriterioState();
}

class _DialogoCriterioState extends State<DialogoCriterio> {
  final GlobalKey _claveTarjeta = GlobalKey();
  bool _compartiendo = false;

  List<String> get _bullets {
    final String texto = widget.tip?.texto ?? widget.sentencia.resumen;
    final List<String> partes = texto
        .split(RegExp(r'(?<=\.)\s+'))
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList();
    if (partes.length <= 1) return <String>[texto];
    return partes.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            RepaintBoundary(
              key: _claveTarjeta,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: TarjetaCriterio(
                  sala: widget.sentencia.sala,
                  fecha: widget.sentencia.fechaSentencia,
                  numero: widget.sentencia.numeroSentencia,
                  magistrado: widget.sentencia.ponente,
                  categoria: 'Criterio del día',
                  titulo: widget.tip?.titulo ?? 'Sentencia del día',
                  bullets: _bullets,
                  cta: '¿Analizando un caso? Consulta en Ulpiano',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _compartiendo
                        ? null
                        : () async {
                            setState(() => _compartiendo = true);
                            await TarjetaService.compartirImagen(
                              _claveTarjeta,
                              texto: 'Criterio del día · Penalex VE',
                            );
                            if (mounted) setState(() => _compartiendo = false);
                          },
                    icon: const Icon(Icons.share, size: 18),
                    label: Text(_compartiendo ? 'Generando…' : 'Compartir'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.dorado,
                      foregroundColor: AppColors.azulMarino,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTokens.radioControl),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

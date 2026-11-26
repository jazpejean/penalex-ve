import 'package:flutter/material.dart';

import '../config/app_colors.dart';

/// Tarjeta visual de una sentencia o tip, pensada para compartir en redes.
///
/// Réplica del formato editorial: cabecera negra con sala, fecha, número y
/// magistrado; categoría en dorado; título en serif; bullets con negritas
/// doradas; CTA al pie.
class TarjetaCriterio extends StatelessWidget {
  const TarjetaCriterio({
    super.key,
    required this.sala,
    required this.fecha,
    required this.numero,
    required this.categoria,
    required this.titulo,
    required this.bullets,
    this.magistrado,
    this.cta,
  });

  final String sala;
  final String fecha;
  final String numero;
  final String categoria;
  final String titulo;
  final List<String> bullets;
  final String? magistrado;
  final String? cta;

  static const Color _tinta = Color(0xFF111111);
  static const Color _gris = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.dorado, width: 12),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Cabecera negra
          Container(
            color: _tinta,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Column(
              children: <Widget>[
                Text(
                  sala.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$fecha · Nro. $numero',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (magistrado != null && magistrado!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    'Mag. $magistrado',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            categoria.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.dorado,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _tinta,
              fontFamily: 'serif',
              fontSize: 54,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 30),
          for (final String bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 12, right: 16),
                    child: Icon(Icons.square, size: 16, color: _tinta),
                  ),
                  Expanded(
                    child: Text.rich(
                      _conNegritas(bullet),
                      style: const TextStyle(
                        color: _tinta,
                        fontSize: 30,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (cta != null && cta!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(24),
              color: const Color(0xFFF8F6F1),
              child: Text(
                cta!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _gris,
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: <Widget>[
              Image.asset(
                'assets/images/logo-horizontal.png',
                height: 56,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              Text(
                'penalexve.com',
                style: TextStyle(
                  color: _gris,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Convierte **texto** en negrita dorada.
  TextSpan _conNegritas(String texto) {
    final List<TextSpan> spans = <TextSpan>[];
    final RegExp patron = RegExp(r'\*\*(.+?)\*\*');
    int inicio = 0;
    for (final RegExpMatch m in patron.allMatches(texto)) {
      if (m.start > inicio) {
        spans.add(TextSpan(text: texto.substring(inicio, m.start)));
      }
      spans.add(TextSpan(
        text: m.group(1),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.dorado,
        ),
      ));
      inicio = m.end;
    }
    if (inicio < texto.length) {
      spans.add(TextSpan(text: texto.substring(inicio)));
    }
    return TextSpan(children: spans);
  }
}

/// Insignia del rango judicial — medallón pintado con CustomPainter.
/// Paleta Penalex: azul marino 0xFF0F172A + oro 0xFFC5A059.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class QuizInsignia extends StatelessWidget {
  const QuizInsignia({
    super.key,
    required this.rango,
    this.tamano = 52,
    this.estrellas = 0,
    this.brillo = false,
  });

  /// Nombre del rango (se usa la inicial en el medallón).
  final String rango;
  final double tamano;

  /// Estrellas alrededor (cuantos más rangos, más estrellas).
  final int estrellas;

  /// True = reflejo dorado animado (rangos altos).
  final bool brillo;

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color anilloSuave = Color(0xFFE2C88A);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamano,
      height: tamano,
      child: CustomPaint(
        painter: _InsigniaPainter(
          inicial: rango.isNotEmpty ? rango.trim().characters.first : '?',
          estrellas: estrellas.clamp(0, 5),
          brillo: brillo,
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}

class _InsigniaPainter extends CustomPainter {
  const _InsigniaPainter({
    required this.inicial,
    required this.estrellas,
    required this.brillo,
  });

  final String inicial;
  final int estrellas;
  final bool brillo;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.shortestSide / 2;
    final centro = Offset(size.width / 2, size.height / 2);

    // Reflejo radial (solo rangos altos).
    if (brillo) {
      final shine = Paint()
        ..shader = RadialGradient(
          colors: [
            QuizInsignia.dorado.withValues(alpha: 0.55),
            QuizInsignia.dorado.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55],
        ).createShader(Rect.fromCircle(center: centro, radius: c * 1.05));
      canvas.drawCircle(centro, c * 1.02, shine);
    }

    // Anillo exterior dorado.
    canvas.drawCircle(
      centro,
      c,
      Paint()
        ..style = PaintingStyle.fill
        ..color = QuizInsignia.dorado,
    );
    canvas.drawCircle(
      centro,
      c * 0.90,
      Paint()
        ..style = PaintingStyle.fill
        ..color = QuizInsignia.anilloSuave,
    );

    // Medallón azul marino.
    canvas.drawCircle(
      centro,
      c * 0.80,
      Paint()
        ..style = PaintingStyle.fill
        ..color = QuizInsignia.azulMarino,
    );

    // Estrellas alrededor del medallón (dentro del anillo dorado).
    final estrella = Paint()..color = QuizInsignia.dorado;
    for (var i = 0; i < estrellas; i++) {
      final ang = (i / 5) * math.pi * 2 - math.pi / 2;
      final p = centro +
          Offset(
            (c * 0.86) * math.cos(ang),
            (c * 0.86) * math.sin(ang),
          );
      _drawEstrella(canvas, p, c * 0.055, estrella);
    }

    // Inicial del rango en oro.
    final tp = TextPainter(
      text: TextSpan(
        text: inicial.toUpperCase(),
        style: TextStyle(
          color: QuizInsignia.dorado,
          fontSize: c * 0.72,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      centro - Offset(tp.width / 2, tp.height / 2),
    );
  }

  void _drawEstrella(Canvas canvas, Offset p, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? r : r * 0.45;
      final ang = (i / 10) * math.pi * 2 - math.pi / 2;
      final punto = p + Offset(rad * math.cos(ang), rad * math.sin(ang));
      if (i == 0) {
        path.moveTo(punto.dx, punto.dy);
      } else {
        path.lineTo(punto.dx, punto.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_InsigniaPainter oldDelegate) =>
      oldDelegate.inicial != inicial ||
      oldDelegate.estrellas != estrellas ||
      oldDelegate.brillo != brillo;
}
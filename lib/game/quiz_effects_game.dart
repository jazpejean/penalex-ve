import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Partícula con física simple (gravedad, fricción, rotación, vida).
class _Particula {
  double x;
  double y;
  double vx;
  double vy;
  double rot;
  double vr;
  double vida;
  final double vidaMax;
  final double tam;
  final Color color;
  final bool circulo;

  _Particula({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rot,
    required this.vr,
    required this.vida,
    required this.tam,
    required this.color,
    required this.circulo,
  }) : vidaMax = vida;

  bool get viva => vida > 0;

  void update(double dt) {
    vy += 950 * dt; // gravedad
    vx *= max(0.0, 1 - 1.4 * dt); // fricción
    x += vx * dt;
    y += vy * dt;
    rot += vr * dt;
    vida -= dt;
  }
}

/// Capa de efectos del quiz: partículas 60fps con [FlameGame].
///
/// Se monta como [GameWidget] transparente sobre la UI de Material.
/// Coordenadas = píxeles lógicos de pantalla (sin cámara), así que se puede
/// llamar a [explosion] con posiciones de la UI directamente.
class QuizEffectsGame extends FlameGame {
  final Random _rnd = Random();
  final List<_Particula> _particulas = [];

  /// Fondo transparente: flame 1.38 usa [Game.backgroundColor] (negro por
  /// defecto) para el lienzo; antes se pasaba por GameWidget y el parámetro
  /// fue eliminado. Sin esto, las capas de efectos tapan el diseño con negro.
  @override
  Color backgroundColor() => const Color(0x00000000);

  /// Explosión de confeti/chispas en un punto de la pantalla.
  void explosion({
    required Offset centro,
    int cantidad = 42,
    double fuerza = 620,
    List<Color>? colores,
  }) {
    final cols = colores ??
        const [
          Color(0xFFE9C86A),
          Color(0xFFC5A059),
          Color(0xFFFFFFFF),
          Color(0xFF81C784),
          Color(0xFFFFB74D),
        ];
    for (var i = 0; i < cantidad; i++) {
      final ang = _rnd.nextDouble() * 2 * pi;
      final vel = (0.25 + _rnd.nextDouble()) * fuerza;
      _particulas.add(_Particula(
        x: centro.dx,
        y: centro.dy,
        vx: cos(ang) * vel,
        vy: sin(ang) * vel - 260, // impulso inicial hacia arriba
        rot: _rnd.nextDouble() * 2 * pi,
        vr: (_rnd.nextDouble() - 0.5) * 16,
        vida: 0.9 + _rnd.nextDouble(),
        tam: 3.5 + _rnd.nextDouble() * 6,
        color: cols[_rnd.nextInt(cols.length)],
        circulo: _rnd.nextBool(),
      ));
    }
  }

  /// Partícula ambiental dorada que sube flotando desde abajo (lobby).
  void particulaAmbiente(double ancho, double alto) {
    final x = _rnd.nextDouble() * ancho;
    _particulas.add(_Particula(
      x: x,
      y: alto + 20,
      vx: (_rnd.nextDouble() - 0.5) * 18,
      vy: -(28 + _rnd.nextDouble() * 45),
      rot: _rnd.nextDouble() * 2 * pi,
      vr: (_rnd.nextDouble() - 0.5) * 1.2,
      vida: 5 + _rnd.nextDouble() * 4,
      tam: 2 + _rnd.nextDouble() * 3.5,
      color: const Color(0xFFE9C86A),
      circulo: true,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final p in _particulas) {
      p.update(dt);
    }
    _particulas.removeWhere((p) => !p.viva);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (final p in _particulas) {
      final alpha = (p.vida / p.vidaMax).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: alpha);
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rot);
      if (p.circulo) {
        canvas.drawCircle(Offset.zero, p.tam, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.tam * 2.1,
              height: p.tam * 1.15,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }
}

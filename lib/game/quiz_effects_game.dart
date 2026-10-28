import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Formas disponibles para las partículas del quiz.
enum FormaParticula { circulo, rombo, estrella, gema, pluma, chispa }

/// Paleta del kit Queezy adaptada al quiz: violetas/lavanda/rosa/menta con el
/// oro de Penalex como acento (premios, medallas).
const _primario = Color(0xFF6A5AE0);
const _secundario = Color(0xFF9087E5);
const _lavanda = Color(0xFFC4D0FB);
const _rosaPink = Color(0xFFFF8FA2);
const _menta = Color(0xFFC9F2E9);
const _oroBrillante = Color(0xFFE9C86A);

/// Partícula con física simple (gravedad, fricción, rotación, vida) y una
/// forma propia; conserva un pequeño historial de posiciones para dibujar
/// estelas (trails) con opacidad decreciente.
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
  final FormaParticula forma;
  final List<Offset> historial;

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
    this.forma = FormaParticula.circulo,
  })  : vidaMax = vida,
        historial = <Offset>[];

  bool get viva => vida > 0;

  void update(double dt) {
    // Historial: últimas 3 posiciones (para las estelas).
    historial.add(Offset(x, y));
    if (historial.length > 3) historial.removeAt(0);

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

  /// Explosión ceremonial de partículas en un punto de la pantalla.
  ///
  /// Distribución por defecto: 35% estrella, 25% gema, 20% chispa, 15% pluma,
  /// 5% rombo. [cantidad] por defecto 80 (150 para ascensos).
  void explosion({
    required Offset centro,
    int cantidad = 80,
    double fuerza = 620,
    List<Color>? colores,
  }) {
    final cols = colores ??
        const [_primario, _secundario, _lavanda, _rosaPink, _menta, _oroBrillante];
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
        forma: _formaAzar(),
      ));
    }
  }

  FormaParticula _formaAzar() {
    final r = _rnd.nextDouble();
    if (r < 0.35) return FormaParticula.estrella;
    if (r < 0.60) return FormaParticula.gema;
    if (r < 0.80) return FormaParticula.chispa;
    if (r < 0.95) return FormaParticula.pluma;
    return FormaParticula.rombo;
  }

  /// Partícula ambiental del kit (violeta/lavanda suave) que sube flotando
  /// desde abajo (lobby) — visible sobre el fondo claro.
  void particulaAmbiente(double ancho, double alto) {
    final x = _rnd.nextDouble() * ancho;
    final colorAmbiente = const [_lavanda, _secundario, _primario, _rosaPink]
        [_rnd.nextInt(4)];
    _particulas.add(_Particula(
      x: x,
      y: alto + 20,
      vx: (_rnd.nextDouble() - 0.5) * 18,
      vy: -(28 + _rnd.nextDouble() * 45),
      rot: _rnd.nextDouble() * 2 * pi,
      vr: (_rnd.nextDouble() - 0.5) * 1.2,
      vida: 5 + _rnd.nextDouble() * 4,
      tam: 2 + _rnd.nextDouble() * 3.5,
      color: colorAmbiente,
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
      final color = p.color.withValues(alpha: alpha);

      // Estelas: líneas hacia las últimas posiciones (0.3 / 0.2 / 0.1).
      _dibujarTrails(canvas, p, color);

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rot);
      final paint = Paint()..color = color;
      switch (p.forma) {
        case FormaParticula.circulo:
          canvas.drawCircle(Offset.zero, p.tam, paint);
        case FormaParticula.rombo:
          _drawRombo(canvas, p.tam, paint);
        case FormaParticula.estrella:
          _drawEstrella(canvas, p.tam, paint);
        case FormaParticula.gema:
          _drawGema(canvas, p.tam, paint);
        case FormaParticula.pluma:
          _drawPluma(canvas, p.tam, paint);
        case FormaParticula.chispa:
          _drawChispa(canvas, p.tam, paint);
      }
      canvas.restore();
    }
  }

  void _dibujarTrails(Canvas canvas, _Particula p, Color color) {
    if (p.historial.isEmpty) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final puntos = [Offset(p.x, p.y), ...p.historial];
    for (var i = 0; i < puntos.length - 1; i++) {
      paint.color = color.withValues(alpha: (0.3 - i * 0.1));
      canvas.drawLine(puntos[i], puntos[i + 1], paint);
    }
  }

  /// Estrella de 5 puntas.
  void _drawEstrella(Canvas canvas, double t, Paint paint) {
    final path = Path();
    final exterior = t * 2.0;
    final interior = t * 0.95;
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? exterior : interior;
      final a = -pi / 2 + i * pi / 5;
      final pto = Offset(cos(a) * r, sin(a) * r);
      i == 0 ? path.moveTo(pto.dx, pto.dy) : path.lineTo(pto.dx, pto.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  /// Gema: rombo con facetas.
  void _drawGema(Canvas canvas, double t, Paint paint) {
    final path = Path()
      ..moveTo(0, -t * 1.7)
      ..lineTo(t * 0.85, 0)
      ..lineTo(0, t * 1.5)
      ..lineTo(-t * 0.85, 0)
      ..close();
    canvas.drawPath(path, paint);
    final facetas = Paint()
      ..color = paint.color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(0, -t * 1.7), Offset(0, t * 1.5), facetas);
  }

  /// Pluma: gota alargada (teardrop).
  void _drawPluma(Canvas canvas, double t, Paint paint) {
    final path = Path()
      ..moveTo(0, -t * 1.6)
      ..quadraticBezierTo(t * 0.7, -t * 0.2, 0, t * 1.4)
      ..quadraticBezierTo(-t * 0.7, -t * 0.2, 0, -t * 1.6)
      ..close();
    canvas.drawPath(path, paint);
  }

  /// Chispa: estrella de 4 puntas fina (asterisco).
  void _drawChispa(Canvas canvas, double t, Paint paint) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final r = i.isEven ? t * 1.8 : t * 0.35;
      final a = i * pi / 4;
      final pto = Offset(cos(a) * r, sin(a) * r);
      i == 0 ? path.moveTo(pto.dx, pto.dy) : path.lineTo(pto.dx, pto.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  /// Rombo: diamante simple (la rotación la aporta `canvas.rotate`).
  void _drawRombo(Canvas canvas, double t, Paint paint) {
    final path = Path()
      ..moveTo(0, -t)
      ..lineTo(t, 0)
      ..lineTo(0, t)
      ..lineTo(-t, 0)
      ..close();
    canvas.drawPath(path, paint);
  }
}
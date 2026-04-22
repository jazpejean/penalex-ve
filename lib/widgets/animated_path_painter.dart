import 'package:flutter/material.dart';

class AnimatedPathPainter extends CustomPainter {
  AnimatedPathPainter({required this.itemCount, required this.progress});
  final int itemCount;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFC5A059).withValues(alpha: 0.5)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final Paint paintGlow = Paint()
      ..color = const Color(0xFFC5A059).withValues(alpha: 0.2)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    final double startX = size.width / 2 - 10;
    const double startY = 40;

    final List<Offset> points = <Offset>[];
    points.add(Offset(startX, startY));
    for (int i = 0; i <= itemCount; i++) {
      final double y = startY + (i * 75.0);
      final int offset = (i % 2 == 0) ? 35 : -15;
      points.add(Offset(startX + offset, y));
    }

    if (progress == 1.0) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    } else {
      final int totalSegments = points.length - 1;
      final int segmentsToDraw = (totalSegments * progress).floor();
      final double remainder = (totalSegments * progress) - segmentsToDraw;

      if (segmentsToDraw > 0) {
        path.moveTo(points[0].dx, points[0].dy);
        for (int i = 1; i <= segmentsToDraw; i++) {
          path.lineTo(points[i].dx, points[i].dy);
        }
      }
      if (segmentsToDraw < totalSegments && remainder > 0) {
        final Offset p1 = points[segmentsToDraw];
        final Offset p2 = points[segmentsToDraw + 1];
        final double dx = p2.dx - p1.dx;
        final double dy = p2.dy - p1.dy;
        path.lineTo(p1.dx + dx * remainder, p1.dy + dy * remainder);
      }
    }

    canvas.drawPath(path, paintGlow);
    canvas.drawPath(path, paint);

    final Paint pointPaint = Paint()..color = const Color(0xFFC5A059);
    final int nodesToShow = ((itemCount + 1) * progress).ceil();
    for (int i = 0; i <= itemCount && i < nodesToShow; i++) {
      final double y = startY + (i * 75.0);
      final int offset = (i % 2 == 0) ? 35 : -15;
      canvas.drawCircle(Offset(startX + offset, y), 4, pointPaint);
      canvas.drawCircle(Offset(startX + offset, y), 8, paintGlow);
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedPathPainter oldDelegate) => oldDelegate.progress != progress;
}
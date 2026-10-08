import 'package:flutter/material.dart';

/// Pulso continuo (escala 1 → maxScale → 1) para botones, insignias y rachas.
class QuizPulso extends StatefulWidget {
  final Widget child;
  final double maxScale;
  final Duration periodo;

  const QuizPulso({
    super.key,
    required this.child,
    this.maxScale = 1.06,
    this.periodo = const Duration(milliseconds: 1100),
  });

  @override
  State<QuizPulso> createState() => _QuizPulsoState();
}

class _QuizPulsoState extends State<QuizPulso>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.periodo,
  )..repeat(reverse: true);
  late final Animation<double> _s = Tween(begin: 1.0, end: widget.maxScale)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _s, child: widget.child);
  }
}

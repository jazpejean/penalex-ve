import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class QuizTimerWidget extends StatelessWidget {
  const QuizTimerWidget({
    required this.animation,
    required this.controller,
    super.key,
  });
  
  final Animation<double> animation;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double progress = animation.value;
          final int remainingTime = (progress * 30).ceil();

          Color barColor;
          Color textColor;
          if (progress > 0.5) {
            barColor = const Color(0xFF27AE60); // Verde
            textColor = const Color(0xFF27AE60);
          } else if (progress > 0.2) {
            barColor = const Color(0xFFF39C12); // Naranja
            textColor = const Color(0xFFF39C12);
          } else {
            barColor = const Color(0xFFE74C3C); // Rojo
            textColor = const Color(0xFFE74C3C);
          }

          return Column(
            children: <Widget>[
              Container(
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF2C1810),
                  border: Border.all(
                    color: const Color(0xFFC5A059).withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            barColor,
                            barColor.withValues(alpha: 0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: barColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.timer_outlined,
                    color: textColor,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "$remainingTime segundos",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<Animation<double>>('animation', animation));
    properties
        .add(DiagnosticsProperty<AnimationController>('controller', controller));
  }
}

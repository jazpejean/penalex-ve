import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/app_colors.dart';

class QuizTimerWidget extends StatelessWidget {
  const QuizTimerWidget({
    required this.animation, required this.controller, super.key,
  });
  final Animation<double> animation;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double progress = animation.value;
        final int remainingTime = (progress * 30).ceil();

        return Column(
          children: <Widget>[
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[300],
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: <Color>[
                        if (progress > 0.5) AppColors.secondary else Colors.orange,
                        if (progress > 0.2) Colors.orange else Colors.red,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "$remainingTime s",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: progress > 0.5 ? AppColors.secondary : progress > 0.2 ? Colors.orange : Colors.red,
              ),
            ),
          ],
        );
      },
    );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Animation<double>>("animation", animation));
    properties.add(DiagnosticsProperty<AnimationController>("controller", controller));
  }
}/* import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../config/app_colors.dart';

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

        return Column(
          children: <Widget>[
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[300],
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: <Color>[
                        if (progress > 0.5) AppColors.secondary else Colors.orange,
                        if (progress > 0.2) Colors.orange else Colors.red,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "$remainingTime s",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: progress > 0.5
                    ? AppColors.secondary
                    : progress > 0.2
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ],
        );
      },
    );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Animation<double>>('animation', animation));
    properties.add(DiagnosticsProperty<AnimationController>('controller', controller));
  }
} */
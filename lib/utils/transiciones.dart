import 'package:flutter/material.dart';

/// Transición "cortina dorada": la página entra con escala+desvanecido mientras
/// dos mitades doradas se cierran (0→1) y se abren (1→0) en 700 ms.
///
/// Se usa en toda la navegación del módulo quiz (lobby → juego → logros).
Route<void> cortinaDorada(Widget page) {
  const oro = Color(0xFFC5A059);
  const oroBrillante = Color(0xFFE9C86A);

  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 700),
    pageBuilder: (context, _, __) => page,
    transitionsBuilder: (context, anim, _, child) {
      final curved =
          CurvedAnimation(parent: anim, curve: Curves.easeInOutCubic);
      return Stack(
        children: [
          ScaleTransition(
            scale: Tween(begin: 1.08, end: 1.0).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          ),
          // Cortina: dos mitades doradas que se cierran y abren.
          AnimatedBuilder(
            animation: curved,
            builder: (context, _) {
              final t = curved.value;
              final cierre = t < 0.5 ? t * 2 : (1 - t) * 2;
              return IgnorePointer(
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: cierre,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [oro, oroBrillante],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FractionallySizedBox(
                          widthFactor: cierre,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [oroBrillante, oro],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      );
    },
  );
}
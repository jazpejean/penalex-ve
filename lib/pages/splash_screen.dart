import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _fadeScaleController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final AnimationController _colorController;
  late final Animation<Color?> _ringColor;

  static const List<Color> flagColors = <Color>[
    Color(0xFFFFD700),
    Color(0xFF00247D),
    Color(0xFFEF3340)
  ];

  @override
  void initState() {
    super.initState();

    _fadeScaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
    _fade = CurvedAnimation(parent: _fadeScaleController, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(parent: _fadeScaleController, curve: Curves.elasticOut));

    _colorController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _ringColor = _colorController.drive(
      ColorTween(begin: flagColors[0], end: flagColors[2]).chain(CurveTween(curve: Curves.linear)),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      unawaited(_checkAndRedirect());
    });
  }

  Future<void> _checkAndRedirect() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.emailVerified) {
      if (mounted) {
        unawaited(Navigator.pushReplacementNamed(context, '/dashboard'));
      }
    } else {
      if (user != null && !user.emailVerified) {
        unawaited(FirebaseAuth.instance.signOut());
      }
      if (mounted) {
        unawaited(Navigator.pushReplacementNamed(context, '/login'));
      }
    }
  }

  @override
  void dispose() {
    _fadeScaleController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  AnimatedBuilder(
                    animation: _ringColor,
                    builder: (BuildContext context, Widget? child) => Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _ringColor.value ?? flagColors[0], width: 2.5),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                              color: (_ringColor.value ?? flagColors[0]).withValues(alpha: 0.3),
                              blurRadius: 15,
                              spreadRadius: 2),
                        ],
                      ),
                      child: const Icon(Icons.gavel_rounded, color: Color(0xFFC5A059), size: 65),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "PENALEX VE",
                    style: TextStyle(
                        color: Color(0xFFC5A059), fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: flagColors
                        .map((Color color) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text("Venezuela",
                      style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1.2)),
                  const SizedBox(height: 48),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5A059))),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Desarrollado por: Jean Jazpe Lizcano",
                    style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      );
}
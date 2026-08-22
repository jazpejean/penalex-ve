import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../models/caso_hipotetico_model.dart';
import '../services/casos_service.dart';
import '../providers/game_provider.dart';

/// Quiz Question Game con Flame
/// Muestra casos hipotéticos con 4 opciones
class QuizQuestionGame extends FlameGame {
  final GameState gameState;
  final CasoHipotetico caso;
  final Function(bool correcto) onAnswered;

  QuizQuestionGame({
    required this.gameState,
    required this.caso,
    required this.onAnswered,
  });

  late BackgroundComponent fondo;
  late QuestionCardComponent questionCard;
  late OptionsComponent optionsComponent;
  
  int? selectedIndex;
  bool answered = false;
  ResultadoRespuesta? resultado;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Agregar componentes
    add(fondo = BackgroundComponent());
    add(questionCard = QuestionCardComponent(caso: caso));
    add(optionsComponent = OptionsComponent(
      opciones: caso.opciones,
      onOptionSelected: _onOptionSelected,
    ));
  }

  void _onOptionSelected(int index) {
    if (answered) return;

    selectedIndex = index;
    optionsComponent.setSelected(index);
  }

  void verifyAnswer() {
    if (answered || selectedIndex == null) return;

    answered = true;
    
    resultado = CasosService.verificarRespuesta(
      caso: caso,
      respuestaUsuario: selectedIndex!,
      vecesIntentadas: 1,
    );

    optionsComponent.showResult(
      selectedIndex: selectedIndex!,
      correctIndex: caso.respuestaCorrecta,
      isCorrect: resultado!.correcto,
    );

    // Callback después de mostrar resultado
    Future.delayed(const Duration(seconds: 2), () {
      onAnswered(resultado!.correcto);
    });
  }
}

/// Fondo con gradiente institucional
class BackgroundComponent extends PositionComponent with HasGameRef<QuizQuestionGame> {
  @override
  Future<void> onLoad() async {
    size = Vector2(gameRef.size.x, gameRef.size.y);
    position = Vector2.zero();
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF003893).withOpacity(0.1), // Azul venezolano suave
        Colors.white,
      ],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }
}

/// Card con la pregunta (caso hipotético)
class QuestionCardComponent extends PositionComponent with HasGameRef<QuizQuestionGame> {
  final CasoHipotetico caso;

  QuestionCardComponent({required this.caso});

  @override
  Future<void> onLoad() async {
    size = Vector2(gameRef.size.x - 32, 280);
    position = Vector2(16, 60);
  }

  @override
  void render(Canvas canvas) {
    // Fondo
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    // Sombra
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(rRect.shift(const Offset(0, 4)), shadowPaint);

    // Fondo blanco
    canvas.drawRRect(rRect, Paint()..color = Colors.white);

    // Borde dorado
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = const Color(0xFFD4AF37)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Header con nivel
    _drawText(
      canvas,
      'Nivel ${caso.nivel}',
      const Offset(20, 20),
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF003893),
    );

    // Título del delito
    _drawText(
      canvas,
      caso.delitoBase,
      const Offset(20, 50),
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: const Color(0xFFD4AF37),
    );

    // Línea separadora
    canvas.drawLine(
      const Offset(20, 85),
      Offset(size.x - 20, 85),
      Paint()
        ..color = Colors.grey.shade300
        ..strokeWidth = 1,
    );

    // Caso hipotético
    _drawText(
      canvas,
      caso.contextoNarrativo,
      const Offset(20, 100),
      fontSize: 15,
      color: Colors.black87,
      maxWidth: size.x - 40,
      maxLines: 8,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black,
    double? maxWidth,
    int maxLines = 1,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
    );

    if (maxWidth != null) {
      textPainter.layout(maxWidth: maxWidth);
    } else {
      textPainter.layout();
    }

    textPainter.paint(canvas, offset);
  }
}

/// Componente de opciones (A, B, C, D)
class OptionsComponent extends PositionComponent with HasGameRef<QuizQuestionGame> {
  final List<String> opciones;
  final Function(int) onOptionSelected;

  OptionsComponent({
    required this.opciones,
    required this.onOptionSelected,
  });

  final List<OptionButtonComponent> buttons = [];

  @override
  Future<void> onLoad() async {
    size = Vector2(gameRef.size.x - 32, 400);
    position = Vector2(16, 360);

    // Crear 4 botones de opciones
    for (int i = 0; i < 4; i++) {
      final button = OptionButtonComponent(
        index: i,
        text: opciones[i],
        onTap: () => onOptionSelected(i),
      );
      button.position = Vector2(0, i * 90.0);
      buttons.add(button);
      add(button);
    }
  }

  void setSelected(int index) {
    for (int i = 0; i < buttons.length; i++) {
      buttons[i].setSelected(i == index);
    }
  }

  void showResult({
    required int selectedIndex,
    required int correctIndex,
    required bool isCorrect,
  }) {
    for (int i = 0; i < buttons.length; i++) {
      if (i == correctIndex) {
        buttons[i].showCorrect();
      } else if (i == selectedIndex && !isCorrect) {
        buttons[i].showIncorrect();
      } else {
        buttons[i].setEnabled(false);
      }
    }
  }
}

/// Botón individual de opción
class OptionButtonComponent extends PositionComponent with HasGameRef<QuizQuestionGame> {
  final int index;
  final String text;
  final VoidCallback onTap;

  OptionButtonComponent({
    required this.index,
    required this.text,
    required this.onTap,
  });

  static const labels = ['A', 'B', 'C', 'D'];
  
  bool isSelected = false;
  bool showingCorrect = false;
  bool showingIncorrect = false;
  bool enabled = true;
  bool _isPressed = false;

  @override
  Future<void> onLoad() async {
    size = Vector2(gameRef.size.x - 32, 75);
  }

  bool containsPoint(Vector2 point) {
    return point.x >= position.x &&
        point.x <= position.x + size.x &&
        point.y >= position.y &&
        point.y <= position.y + size.y;
  }

  void handleTapDown() {
    if (!enabled) return;
    _isPressed = true;
  }

  void handleTapUp() {
    if (!enabled) return;
    _isPressed = false;
    onTap();
  }

  void setSelected(bool selected) {
    isSelected = selected;
  }

  void showCorrect() {
    showingCorrect = true;
    enabled = false;
  }

  void showIncorrect() {
    showingIncorrect = true;
    enabled = false;
  }

  void setEnabled(bool value) {
    enabled = value;
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (showingCorrect) {
      backgroundColor = const Color(0xFF4CAF50).withOpacity(0.2);
      borderColor = const Color(0xFF4CAF50);
      textColor = const Color(0xFF2E7D32);
    } else if (showingIncorrect) {
      backgroundColor = const Color(0xFFF44336).withOpacity(0.2);
      borderColor = const Color(0xFFF44336);
      textColor = const Color(0xFFC62828);
    } else if (isSelected) {
      backgroundColor = const Color(0xFFD4AF37).withOpacity(0.2);
      borderColor = const Color(0xFFD4AF37);
      textColor = const Color(0xFF003893);
    } else if (!enabled) {
      backgroundColor = Colors.grey.shade200;
      borderColor = Colors.grey.shade400;
      textColor = Colors.grey.shade600;
    } else {
      backgroundColor = Colors.white;
      borderColor = const Color(0xFF003893).withOpacity(0.3);
      textColor = Colors.black87;
    }

    // Sombra
    if (enabled && !_isPressed) {
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRRect(rRect.shift(const Offset(0, 2)), shadowPaint);
    }

    // Fondo
    canvas.drawRRect(
      _isPressed ? rRect.shift(const Offset(0, 2)) : rRect,
      Paint()..color = backgroundColor,
    );

    // Borde
    canvas.drawRRect(
      _isPressed ? rRect.shift(const Offset(0, 2)) : rRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final yOffset = _isPressed ? 2.0 : 0.0;

    // Label (A, B, C, D)
    final labelPainter = TextPainter(
      text: TextSpan(
        text: labels[index],
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: borderColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(canvas, Offset(20, (size.y - labelPainter.height) / 2 + yOffset));

    // Texto de la opción
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 15,
          color: textColor,
          height: 1.3,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    );
    textPainter.layout(maxWidth: size.x - 80);
    textPainter.paint(canvas, Offset(60, (size.y - textPainter.height) / 2 + yOffset));

    // Icono de resultado
    if (showingCorrect || showingIncorrect) {
      final icon = showingCorrect ? '✓' : '✗';
      final iconPainter = TextPainter(
        text: TextSpan(
          text: icon,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: showingCorrect ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      iconPainter.layout();
      iconPainter.paint(
        canvas,
        Offset(size.x - 40, (size.y - iconPainter.height) / 2 + yOffset),
      );
    }
  }
}

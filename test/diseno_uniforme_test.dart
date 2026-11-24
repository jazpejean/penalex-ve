import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:penalex_ve/config/app_tokens.dart';
import 'package:penalex_ve/widgets/app_screen_header.dart';

/// Verifica que el patrón de diseño de docs/DISENO.md se cumpla en los
/// widgets compartidos, sin necesidad de un dispositivo.
void main() {
  group('AppScreenHeader', () {
    testWidgets('título con la escala de la app (28 / w700)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppScreenHeader(
              titulo: 'Agenda',
              subtitulo: 'Audiencias, lapsos y días sin despacho',
            ),
          ),
        ),
      );

      final List<Text> textos =
          tester.widgetList<Text>(find.byType(Text)).toList();
      expect(textos.length, 2);
      expect(textos[0].data, 'Agenda');
      expect(textos[0].style?.fontSize, AppTokens.tituloPantalla.fontSize);
      expect(textos[0].style?.fontWeight, FontWeight.w700);
      expect(textos[1].style?.fontSize, AppTokens.secundario.fontSize);
    });

    testWidgets('sin subtítulo no agrega una segunda línea',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppScreenHeader(titulo: 'Solo título')),
        ),
      );
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('un título largo no desborda en pantalla estrecha',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: AppScreenHeader(
                titulo:
                    'Ley Orgánica para la Protección de Niños, Niñas y Adolescentes en el contexto penal venezolano',
                subtitulo:
                    'Un subtítulo largo que también debe ajustarse sin desbordar',
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('las acciones se muestran a la derecha',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppScreenHeader(
              titulo: 'Con acciones',
              acciones: <Widget>[IconButton(onPressed: () {}, icon: const Icon(Icons.refresh))],
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  group('Biblioteca de leyes', () {
    test('el nombre de la ley no se trunca en la lista', () {
      final String fuente =
          File('lib/pages/repositorio_leyes_screen.dart').readAsStringSync();
      final int idx = fuente.indexOf('ley.nombre');
      expect(idx, greaterThan(0));
      final String bloque = fuente.substring(idx, idx + 220);
      expect(bloque.contains('maxLines'), isFalse);
      expect(bloque.contains('TextOverflow.ellipsis'), isFalse);
    });

    test('los títulos de libro y capítulo no se truncan', () {
      final String fuente =
          File('lib/pages/ley_estructura_screen.dart').readAsStringSync();
      final int idx = fuente.indexOf('nodo.etiqueta');
      expect(idx, greaterThan(0));
      final String bloque = fuente.substring(idx, idx + 220);
      expect(bloque.contains('maxLines'), isFalse);
      expect(bloque.contains('TextOverflow.ellipsis'), isFalse);
    });
  });

  group('Tokens de diseño', () {
    test('radios: tarjeta 20 y control 12', () {
      expect(AppTokens.radioTarjeta, 20);
      expect(AppTokens.radioControl, 12);
    });

    test('margen lateral 20', () {
      expect(AppTokens.margen, 20);
    });

    test('escala de títulos', () {
      expect(AppTokens.tituloPantalla.fontSize, 28);
      expect(AppTokens.tituloSeccion.fontSize, 18);
    });
  });
}

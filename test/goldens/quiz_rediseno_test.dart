// Prints del rediseño del quiz (navy + oro).
// Regenerar: flutter test --update-goldens test/goldens/quiz_rediseno_test.dart
// Los PNG quedan en test/goldens/goldens/.
// Supabase se inicializa con un httpClient mock (package:http/testing) que
// responde '[]' al instante: evita que las llamadas reales (Storage del banco
// de preguntas y del ranking) cuelguen el fake-async. El audio se desactiva de
// fábrica (audioplayers no tiene canal en tests). El lobby renderiza porque
// QuizStorageService._uid tolera la ausencia de Firebase (progreso por defecto).
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:penalex_ve/pages/quiz_game_screen.dart';
import 'package:penalex_ve/pages/quiz_lobby_screen.dart';
import 'package:penalex_ve/pages/quiz_logros_screen.dart';
import 'package:penalex_ve/pages/quiz_resumen_screen.dart';
import 'package:penalex_ve/services/sfx_service.dart';
import 'package:penalex_ve/widgets/racha_overlay.dart';

void main() {
  setUpAll(() async {
    // Mute de fábrica: audioplayers no tiene canal de plataforma y su play()
    // nunca completa bajo fake-async; con el mute activo init() deja el audio
    // deshabilitado y ambienteStart/play retornan de inmediato (sin tocar el
    // código de la app).
    SharedPreferences.setMockInitialValues(
        <String, Object>{'quiz_sfx_muted': true});
    GoogleFonts.config.allowRuntimeFetching = false;
    try {
      await Supabase.initialize(
        url: 'https://example.supabase.co',
        anonKey: 'example-anon-key',
        // Respuesta vacía instantánea para cualquier petición (Storage, REST).
        httpClient: MockClient((http.Request req) async => http.Response(
              '[]',
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            )),
      );
    } catch (_) {}
    final bytes =
        File('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf').readAsBytesSync();
    final loader = FontLoader('Roboto')
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  });

  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await runZonedGuarded(() async {
      // Sin audio en tests: audioplayers no tiene canal de plataforma y su
      // play() nunca completa bajo fake-async; deshabilitado evita el colgado
      // (ambienteStart/play devuelven de inmediato) sin tocar código de la app.
      SfxService.instance.habilitado = false;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {};
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(useMaterial3: true),
          home: page,
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 600));
      FlutterError.onError = originalOnError;
    }, (Object error, StackTrace stack) {
      // plugins no disponibles en tests: ignorar
    });
    tester.takeException();
  }

  /// Desmonta la pantalla para cancelar sus temporizadores (lobby/game/logros
  /// tienen Timer.periodic) antes de que termine el test.
  Future<void> desmontar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    tester.takeException();
  }

  testWidgets('quiz lobby rediseñado', (tester) async {
    await pumpPage(tester, const QuizLobbyScreen());
    expect(find.text('JUGAR'), findsOneWidget,
        reason: 'el lobby debe salir del estado de carga');
    // Cierra el SnackBar de primera visita (4s) para que la captura muestre
    // solo el lobby: hero, rango, misiones, JUGAR, certificado y logros.
    await tester.pump(const Duration(seconds: 5));
    await expectLater(
      find.byType(QuizLobbyScreen),
      matchesGoldenFile('goldens/quiz_lobby_rediseno.png'),
    );
    await desmontar(tester);
  });

  testWidgets('quiz juego rediseñado (pregunta + opciones)', (tester) async {
    await pumpPage(tester, const QuizGameScreen());
    await tester.pump(const Duration(milliseconds: 600));
    await expectLater(
      find.byType(QuizGameScreen),
      matchesGoldenFile('goldens/quiz_game_rediseno.png'),
    );
    await desmontar(tester);
  });

  testWidgets('quiz logros rediseñados', (tester) async {
    await pumpPage(tester, const QuizLogrosScreen());
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(QuizLogrosScreen),
      matchesGoldenFile('goldens/quiz_logros_rediseno.png'),
    );
    await desmontar(tester);
  });

  testWidgets('quiz resumen rediseñado', (tester) async {
    await pumpPage(
      tester,
      const QuizResumenScreen(
        casosResueltos: 12,
        aciertos: 9,
        fallos: 3,
        xpGanado: 260,
        rachaMaxima: 6,
        tiempoTotal: 183,
      ),
    );
    await expectLater(
      find.byType(QuizResumenScreen),
      matchesGoldenFile('goldens/quiz_resumen_rediseno.png'),
    );
    await desmontar(tester);
  });

  testWidgets('racha overlay rediseñado', (tester) async {
    await pumpPage(
      tester,
      Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        body: Center(child: RachaOverlay(racha: 10, onDone: () {})),
      ),
    );
    await expectLater(
      find.byType(RachaOverlay),
      matchesGoldenFile('goldens/quiz_racha_rediseno.png'),
    );
    // Temporizador de autodesvanecido: disparar antes de terminar el test.
    await tester.pump(const Duration(milliseconds: 1600));
    await desmontar(tester);
  });
}
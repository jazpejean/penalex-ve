// Prints del rediseño del quiz (navy + oro).
// Regenerar: flutter test --update-goldens test/goldens/quiz_rediseno_test.dart
// Los PNG quedan en test/goldens/goldens/.
// Supabase se inicializa con un httpClient mock (package:http/testing) que
// responde '[]' al instante: evita que las llamadas reales (Storage del banco
// de preguntas y del ranking) cuelguen el fake-async. El audio se desactiva de
// fábrica (audioplayers no tiene canal en tests). El lobby NO se captura: su
// _inicializar depende de FirebaseAuth (pigeon) y quedaría en el estado de
// carga; las 4 pantallas restantes renderizan su contenido completo.
import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:penalex_ve/pages/quiz_game_screen.dart';
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
    // Firebase falso: QuizStorageService lee _uid de FirebaseAuth en
    // cargarProgreso; sin el mock, FirebaseException rompe la inicialización
    // del lobby. Los canales responden al instante (usuario anónimo: null).
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_core'),
      (MethodCall call) async {
        if (call.method == 'Firebase#initializeCore') return <Object?>[];
        if (call.method == 'Firebase#initializeApp') {
          return <String, dynamic>{
            'name': call.arguments['name'] ?? '[DEFAULT]',
            'options': <String, dynamic>{
              'apiKey': 'AIzaSyA-test-key',
              'appId': '1:123:android:test',
              'messagingSenderId': '123',
              'projectId': 'test-project',
              'storageBucket': 'test.appspot.com',
            },
          };
        }
        if (call.method == 'Firebase#app') {
          return <String, dynamic>{
            'name': '[DEFAULT]',
            'options': <String, dynamic>{
              'apiKey': 'AIzaSyA-test-key',
              'appId': '1:123:android:test',
              'messagingSenderId': '123',
              'projectId': 'test-project',
              'storageBucket': 'test.appspot.com',
            },
          };
        }
        return null;
      },
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_auth'),
      (MethodCall call) async => null,
    );
    try {
      await Firebase.initializeApp();
    } catch (_) {}
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
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
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
    await pumpPage(tester, RachaOverlay(racha: 10, onDone: () {}));
    await expectLater(
      find.byType(RachaOverlay),
      matchesGoldenFile('goldens/quiz_racha_rediseno.png'),
    );
    // Temporizador de autodesvanecido: disparar antes de terminar el test.
    await tester.pump(const Duration(milliseconds: 1600));
    await desmontar(tester);
  });
}
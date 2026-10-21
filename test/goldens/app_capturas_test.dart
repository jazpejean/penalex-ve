// Capturas de pantalla (goldens) para diagnóstico visual.
// Regenerar: flutter test --update-goldens test/goldens/app_capturas_test.dart
// Los PNG quedan en test/goldens/. Los errores async de Supabase/Firebase
// en tests se esperan (no inicializados); lo que importa es el layout.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:penalex_ve/pages/dosimetria_page.dart';
import 'package:penalex_ve/pages/main_screen.dart';
import 'package:penalex_ve/pages/buscador_juridico_screen.dart';
import 'package:penalex_ve/pages/repositorio_jurisprudencia_screen.dart';
import 'package:provider/provider.dart';
import 'package:penalex_ve/config/app_theme.dart';
import 'package:penalex_ve/services/auth_service.dart';

/// AuthService falso para capturas: implementa toda la interfaz vía
/// noSuchMethod (cualquier getter/método devuelve null -> currentUser null
/// -> el Dashboard muestra "¡Bienvenido, Usuario!" sin Firebase).
class _FakeAuthService implements AuthService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    // Supabase "falso": permite construir la página (las llamadas HTTP reales
    // fallan en tests, pero el layout renderiza con su estado de carga).
    try {
      await Supabase.initialize(
          url: 'https://example.supabase.co', anonKey: 'example-anon-key');
    } catch (_) {
      // ya inicializado o sin red — continuar
    }
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
    // Herramienta de captura: traga errores de render y de zonas async
    // (Firebase/Supabase/plugins no existen en tests) para generar el PNG.
    await runZonedGuarded(() async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {};
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: TemaGlobal.isDark
              ? ThemeData.dark(useMaterial3: true)
              : ThemeData.light(useMaterial3: true),
          home: page,
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      FlutterError.onError = originalOnError;
    }, (Object error, StackTrace stack) {
      // ignorar: plugins no disponibles en tests
    });
    tester.takeException();
  }

  testWidgets('calculadora (dosimetría)', (tester) async {
    await pumpPage(tester, const DosimetriaPage());
    tester.takeException(); // errores async de Firebase esperados en test
    await expectLater(
      find.byType(DosimetriaPage),
      matchesGoldenFile('goldens/calculadora_dosimetria.png'),
    );
    await tester.pump();
    tester.takeException();
    tester.takeException();
  });

  testWidgets('calculadora MODO OSCURO (suiche activado)', (tester) async {
    TemaGlobal.oscuro.value = true;
    await pumpPage(tester, const DosimetriaPage());
    tester.takeException();
    await expectLater(
      find.byType(DosimetriaPage),
      matchesGoldenFile('goldens/calculadora_dosimetria_oscura.png'),
    );
    TemaGlobal.oscuro.value = false;
    await tester.pump();
    tester.takeException();
    tester.takeException();
  });

  Future<void> capturaOscura(WidgetTester tester, Widget page, String archivo) async {
    TemaGlobal.oscuro.value = true;
    await pumpPage(tester, page);
    tester.takeException();
    await expectLater(
      find.byType(page.runtimeType),
      matchesGoldenFile('goldens/$archivo.png'),
    );
    TemaGlobal.oscuro.value = false;
    await tester.pump();
    tester.takeException();
    tester.takeException();
  }

  testWidgets('jurisprudencia MODO OSCURO', (tester) async {
    await capturaOscura(tester, const RepositorioJurisprudenciaScreen(),
        'jurisprudencia_filtros_oscura');
  });

  testWidgets('leyes MODO OSCURO', (tester) async {
    await capturaOscura(
        tester,
        const BuscadorJuridicoScreen(alcanceInicial: AlcanceBusqueda.leyes),
        'leyes_oscura');
  });

  testWidgets('main_screen (barra inferior + 5 pestañas)', (tester) async {
    await pumpPage(
      tester,
      MultiProvider(
        providers: [
          Provider<AuthService>(create: (_) => _FakeAuthService()),
        ],
        child: const MainScreen(),
      ),
    );
    tester.takeException();
    await expectLater(
      find.byType(MainScreen),
      matchesGoldenFile('goldens/main_screen.png'),
    );
    await tester.pump();
    tester.takeException();
    tester.takeException();
  });

  testWidgets('buscador jurídico (nivel Venley, claro)', (tester) async {
    await pumpPage(tester, const BuscadorJuridicoScreen());
    tester.takeException();
    await expectLater(
      find.byType(BuscadorJuridicoScreen),
      matchesGoldenFile('goldens/buscador_juridico.png'),
    );
    await tester.pump();
    tester.takeException();
    tester.takeException();
  });

  testWidgets('buscador jurídico MODO OSCURO', (tester) async {
    await capturaOscura(tester, const BuscadorJuridicoScreen(),
        'buscador_juridico_oscura');
  });

  testWidgets('jurisprudencia (filtros)', (tester) async {
    await pumpPage(tester, const RepositorioJurisprudenciaScreen());
    // El error async de Supabase (no inicializado en tests) queda pendiente:
    // se bombea un último frame y se limpia para que el test termine en verde.
    await tester.pump(const Duration(milliseconds: 200));
    tester.takeException();
    await expectLater(
      find.byType(RepositorioJurisprudenciaScreen),
      matchesGoldenFile('goldens/jurisprudencia_filtros.png'),
    );
    await tester.pump();
    tester.takeException();
    tester.takeException();
  });
}
// MOCKUP (propuesta visual, NO es la implementación): rediseño de la
// pantalla de Jurisprudencia a "nivel Venley" con el sistema de diseño
// de Penalex (navy+oro). Solo genera PNGs de propuesta; no toca la app.
// Regenerar: flutter test --update-goldens test/goldens/venley_propuesta_test.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:penalex_ve/config/app_theme.dart';

class _PropuestaJurisprudencia extends StatelessWidget {
  const _PropuestaJurisprudencia();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Header hero =====
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: TemaGlobal.dorado.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.gavel, color: TemaGlobal.dorado, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jurisprudencia',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: TemaGlobal.texto,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Tribunal Supremo de Justicia · Venezuela',
                          style: TextStyle(
                            fontSize: 13,
                            color: TemaGlobal.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: TemaGlobal.dorado,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '263.984 sentencias',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: TemaGlobal.azulMarino,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ===== Pills de modo (Venley: Buscar / Filtros / Kelsen) =====
              Row(
                children: [
                  _pill('Buscar', activo: true, icon: Icons.search),
                  const SizedBox(width: 8),
                  _pill('Filtros', activo: false, icon: Icons.tune),
                  const SizedBox(width: 8),
                  _pill('Preguntar a Ulpiano',
                      activo: false, icon: Icons.auto_awesome),
                ],
              ),
              const SizedBox(height: 14),

              // ===== Barra de búsqueda grande =====
              Container(
                height: 56,
                padding: const EdgeInsets.only(left: 16, right: 6),
                decoration: BoxDecoration(
                  color: TemaGlobal.tarjeta,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: TemaGlobal.capa,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: TemaGlobal.azulMarino.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: TemaGlobal.dorado, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Escribe aquí para empezar a buscar...',
                        style: TextStyle(
                          fontSize: 14.5,
                          color: TemaGlobal.textoTenue,
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: TemaGlobal.dorado,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: TemaGlobal.dorado.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_forward,
                          color: TemaGlobal.azulMarino, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ===== Alcance de búsqueda segmentado =====
              Text(
                'Selecciona dónde buscar:',
                style: TextStyle(
                  fontSize: 13,
                  color: TemaGlobal.textoSecundario,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _segmento('Sentencias', activo: true),
                  _segmento('Leyes', activo: false),
                  _segmento('Glosario', activo: false),
                ],
              ),
              const SizedBox(height: 12),

              // ===== Ayuda sutil =====
              Row(
                children: [
                  Icon(Icons.auto_awesome,
                      size: 12, color: TemaGlobal.dorado),
                  const SizedBox(width: 5),
                  Text(
                    'Busca por número, delito, partes o palabras clave',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: TemaGlobal.textoTenue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ===== Enlaces rápidos con contadores (Venley) =====
              _enlaceRapido(
                titulo: 'Ver todas las sentencias',
                contador: '263.984',
              ),
              const SizedBox(height: 12),
              _enlaceRapido(
                titulo: 'Ver decisiones vinculantes',
                contador: '12.401',
              ),
              const SizedBox(height: 12),
              _enlaceRapido(
                titulo: 'Ver sentencias más recientes',
                contador: 'Hoy',
              ),
              const SizedBox(height: 28),

              // ===== Sugerencia de resultados (ejemplo) =====
              Text(
                'Resultados sugeridos',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: TemaGlobal.texto,
                ),
              ),
              const SizedBox(height: 12),
              _resultadoEjemplo(
                delito: 'Homicidio Calificado',
                numero: 'Sentencia N° 1000 · Sala Penal',
                fecha: '2024-05-14',
                resumen:
                    'Dolo eventual en el homicidio calificado: el agente se representa la muerte como resultado probable...',
                vinculante: true,
              ),
              const SizedBox(height: 12),
              _resultadoEjemplo(
                delito: 'Robo Agravado',
                numero: 'Sentencia N° 314 · Sala Penal',
                fecha: '2023-11-02',
                resumen:
                    'Agravante de uso de arma de fuego: la pluralidad de partícipes y la nocturnidad...',
                vinculante: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String texto, {required bool activo, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: activo ? TemaGlobal.azulMarino : TemaGlobal.tarjeta,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: activo ? TemaGlobal.azulMarino : TemaGlobal.capa,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: activo ? TemaGlobal.dorado : TemaGlobal.textoSecundario,
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: activo ? Colors.white : TemaGlobal.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmento(String texto, {required bool activo}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: activo ? TemaGlobal.azulMarino : TemaGlobal.tarjeta,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: activo ? TemaGlobal.azulMarino : TemaGlobal.capa,
          ),
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
            color: activo ? Colors.white : TemaGlobal.textoSecundario,
          ),
        ),
      ),
    );
  }

  Widget _enlaceRapido({required String titulo, required String contador}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: TemaGlobal.tarjeta,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TemaGlobal.capa, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: TemaGlobal.texto,
              ),
            ),
          ),
          Text(
            contador,
            style: TextStyle(
              fontSize: 12.5,
              color: TemaGlobal.textoTenue,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios,
              size: 13, color: TemaGlobal.dorado),
        ],
      ),
    );
  }

  Widget _resultadoEjemplo({
    required String delito,
    required String numero,
    required String fecha,
    required String resumen,
    required bool vinculante,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TemaGlobal.tarjeta,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TemaGlobal.capa, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  delito,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: TemaGlobal.texto,
                  ),
                ),
              ),
              if (vinculante)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: TemaGlobal.dorado,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'VINCULANTE',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: TemaGlobal.azulMarino,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            numero,
            style: TextStyle(
              fontSize: 12,
              color: TemaGlobal.textoSecundario,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            resumen,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: TemaGlobal.textoSecundario,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 11, color: TemaGlobal.textoTenue),
              const SizedBox(width: 4),
              Text(
                fecha,
                style: TextStyle(fontSize: 11, color: TemaGlobal.textoTenue),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final bytes =
        File('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf').readAsBytesSync();
    final loader = FontLoader('Roboto')
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  });

  Future<void> pumpPropuesta(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await runZonedGuarded(() async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {};
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: TemaGlobal.isDark
              ? ThemeData.dark(useMaterial3: true)
              : ThemeData.light(useMaterial3: true),
          home: const _PropuestaJurisprudencia(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      FlutterError.onError = originalOnError;
    }, (Object error, StackTrace stack) {});
    tester.takeException();
  }

  testWidgets('propuesta jurisprudencia nivel Venley (claro)',
      (tester) async {
    TemaGlobal.oscuro.value = false;
    await pumpPropuesta(tester);
    await expectLater(
      find.byType(_PropuestaJurisprudencia),
      matchesGoldenFile('goldens/venley_jurisprudencia_propuesta.png'),
    );
    tester.takeException();
  });

  testWidgets('propuesta jurisprudencia nivel Venley (oscuro)',
      (tester) async {
    TemaGlobal.oscuro.value = true;
    await pumpPropuesta(tester);
    await expectLater(
      find.byType(_PropuestaJurisprudencia),
      matchesGoldenFile('goldens/venley_jurisprudencia_propuesta_oscura.png'),
    );
    TemaGlobal.oscuro.value = false;
    tester.takeException();
  });
}
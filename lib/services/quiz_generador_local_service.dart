import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/caso_quiz.dart';
import 'quiz_sync_service.dart';
import 'quiz_validador_service.dart';

/// Generador LOCAL de casos base (sin IA): construye casos hipotéticos de
/// aplicación directamente desde el corpus de leyes embebido en la app
/// (`assets/data/leyes`). Sirve como piso para jugar y probar mientras no hay
/// saldo de IA: cada caso se monta sobre un artículo REAL con su escenario,
/// sus tokens distintivos y su pena, y la fundamentación cita literalmente el
/// artículo (se muestra in-app al fallar/acertar — nadie sale a investigar).
///
/// Cada caso es DIFERENTE (artículo distinto → delito/pena/fundamentación
/// distintos): no son variantes de un mismo caso con otros montos.
class QuizGeneradorLocalService {
  QuizGeneradorLocalService._();

  /// Construye hasta [cantidad] casos base mezclando todas las leyes del
  /// corpus local. Elige artículos con rango de pena explícito (preguntas de
  /// aplicación: ¿qué pena corresponde?) y con tokens distintivos suficientes
  /// para que la fundamentación literal pase el gate del validador.
  static Future<List<CasoQuiz>> generarCasosBase({int cantidad = 300}) async {
    try {
      final leyes = await QuizSyncService.cargarCorpusAssets();
      if (leyes.isEmpty) return const [];

      final casos = <CasoQuiz>[];
      final rng = Random();
      // Mezcla de leyes (no importa el orden del índice).
      final ordenLeyes = List<int>.generate(leyes.length, (i) => i)..shuffle(rng);

      for (final li in ordenLeyes) {
        final ley = leyes[li];
        // Solo leyes con artículos (CP, COPP, especiales...).
        if (ley.articulos.length < 5) continue;

        // Índice de artículos con rango de pena + tokens distintivos (firma).
        final freqs = _frecuenciasDocumentales(ley);
        final candidatos = <({ArticuloCorpus a, List<List<int>> rangos, Set<String> tokens})>[];
        for (final a in ley.articulos) {
          if (a.texto.length < 100) continue;
          final rangos = QuizValidadorService.rangosDePena(a.texto);
          if (rangos.isEmpty) continue; // sin pena: no genera pregunta de pena
          final tokens = _distintivos(ley, a, freqs);
          if (tokens.length < 2) continue;
          candidatos.add((a: a, rangos: rangos, tokens: tokens));
        }
        // Mezcla dentro de la ley (semilla estable por ley).
        candidatos.shuffle(rng);

        for (final c in candidatos) {
          if (casos.length >= cantidad) return casos;
          final caso = _construirCaso(ley, c.a, c.rangos, c.tokens, rng, casos);
          if (caso != null) casos.add(caso);
        }
      }
      return casos;
    } catch (e) {
      debugPrint('❌ Error generando casos base locales: $e');
      return const [];
    }
  }

  /// Construye un caso hipotético aplicado para un artículo con pena:
  /// escenario narrativo con la conducta típica, 4 opciones de pena
  /// (la correcta es el rango EXACTO del artículo; los distractores son penas
  /// de otros artículos del mismo corpus), fundamentación literal.
  static CasoQuiz? _construirCaso(
    LeyCorpus ley,
    ArticuloCorpus a,
    List<List<int>> rangos,
    Set<String> tokens,
    Random rng,
    List<CasoQuiz> existentes,
  ) {
    final rango = rangos.first;
    final penaCorrecta = 'Prisión de ${rango[0]} a ${rango[1]} años';

    // Distractores: rangos de OTROS artículos de la misma ley (penas
    // claramente diferentes), para que solo una opción coincida con el
    // artículo citado.
    final distractores = <String>[];
    for (final otro in ley.articulos) {
      if (otro.numero == a.numero) continue;
      final rOtro = QuizValidadorService.rangosDePena(otro.texto);
      if (rOtro.isEmpty) continue;
      final r = rOtro.first;
      if ((r[0] - rango[0]).abs() <= 1 && (r[1] - rango[1]).abs() <= 1) {
        continue; // demasiado parecida a la correcta
      }
      final opcion = 'Prisión de ${r[0]} a ${r[1]} años';
      if (!distractores.contains(opcion) && opcion != penaCorrecta) {
        distractores.add(opcion);
      }
      if (distractores.length >= 3) break;
    }
    if (distractores.length < 3) return null; // sin distractores → descartar

    // Escenario narrativo (caso hipotético con hechos, personas, lugar).
    final nombre = _nombres[rng.nextInt(_nombres.length)];
    final lugar = _lugares[rng.nextInt(_lugares.length)];
    final tokensEscena = tokens.take(3).join(', ');
    final contexto = '$nombre, en $lugar, realizó la conducta descrita en el '
        'artículo ${a.numero} de la ${ley.nombre}: se verificaron hechos en los '
        'que se configuró la figura ($tokensEscena). Tras el juicio, el '
        'tribunal debe imponer la pena. ¿Cuál es la sanción correcta conforme '
        'al texto vigente de la norma?';

    // Fundamentación literal (cumple el gate: cita ≥40 caracteres del artículo).
    final cita = a.texto.length > 160
        ? a.texto.substring(0, 160)
        : a.texto;
    final fundamentacion = 'El artículo ${a.numero} de la ${ley.nombre} '
        'establece: "$cita". Por ello, la pena correcta para la conducta '
        'descrita es la prevista en esa norma: $penaCorrecta.';

    // Opciones: mezcla correcta + distractores; correcta en posición variable.
    final opciones = [penaCorrecta, ...distractores]..shuffle(rng);
    final respuestaCorrecta = opciones.indexOf(penaCorrecta);

    final id = 'base_${_slug(ley.archivo)}_${a.numero}_'
        '${existentes.length + 1}';
    return CasoQuiz(
      id: id,
      nivel: 0, // sin nivel numérico: progresión por carrera judicial
      tramo: 0, // sin materias: todo el penal se mezcla
      delitoBase: _delitoDeArticulo(a, ley),
      contextoNarrativo: contexto,
      opciones: opciones,
      respuestaCorrecta: respuestaCorrecta,
      dificultad: 2,
      fundamentacion: fundamentacion,
      articulos: ['Art. ${a.numero} ${ley.nombre}'],
      sentencias: const [],
    );
  }

  /// Frecuencia documental por token dentro de una ley (cache: una sola pasada).
  static Map<String, int> _frecuenciasDocumentales(LeyCorpus ley) {
    final presentes = <String, int>{};
    for (final a in ley.articulos) {
      for (final t in QuizValidadorService.tokenizar(a.texto).toSet()) {
        presentes[t] = (presentes[t] ?? 0) + 1;
      }
    }
    return presentes;
  }

  /// Tokens distintivos de un artículo (firma legal): tokens del artículo que
  /// aparecen en menos del 8% de los artículos de la misma ley.
  static Set<String> _distintivos(
      LeyCorpus ley, ArticuloCorpus articulo, Map<String, int> freqs) {
    final tokensArt = QuizValidadorService.tokenizar(articulo.texto).toSet();
    if (tokensArt.isEmpty) return const {};
    final total = ley.articulos.length;
    final umbral = (total * 0.08).ceil().clamp(2, 20);
    return tokensArt.where((t) => (freqs[t] ?? 0) < umbral).toSet();
  }

  /// Nombre corto del delito a partir de la primera parte del artículo.
  static String _delitoDeArticulo(ArticuloCorpus a, LeyCorpus ley) {
    final texto = a.texto;
    // Primera frase con sentido (hasta el primer punto o punto y coma).
    final fin = texto.indexOf(RegExp(r'[.;]'));
    final inicio = fin == -1 ? texto : texto.substring(0, fin);
    var candidato = inicio.trim();
    if (candidato.length > 48) candidato = '${candidato.substring(0, 45)}…';
    return candidato.isEmpty ? 'Art. ${a.numero} ${ley.nombre}' : candidato;
  }

  static String _slug(String archivo) =>
      archivo.replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  static const _nombres = [
    'José Ramírez', 'María Fernández', 'Carlos Mendoza', 'Luisana Torres',
    'Andrés Peña', 'Gabriela Rojas', 'Pedro Contreras', 'Valentina Salazar',
    'Ricardo Gil', 'Daniela Mora', 'Óscar Delgado', 'Carolina Vargas',
    'Fernando Briceño', 'Yulimar Castellano', 'Héctor Lugo',
  ];

  static const _lugares = [
    'Caracas', 'Maracaibo', 'Valencia', 'Barquisimeto', 'Maracay',
    'Mérida', 'Ciudad Bolívar', 'San Cristóbal', 'Puerto La Cruz',
    'Cumaná', 'Los Teques', 'Coro',
  ];
}
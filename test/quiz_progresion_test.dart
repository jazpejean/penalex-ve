import 'package:flutter_test/flutter_test.dart';
import 'package:penalex_ve/services/misiones_diarias_service.dart';
import 'package:penalex_ve/services/quiz_progresion_service.dart';
import 'package:penalex_ve/services/racha_diaria_service.dart';

void main() {
  group('RachaDiariaService', () {
    final lunes = DateTime(2026, 4, 13); // lunes
    final martes = DateTime(2026, 4, 14); // martes
    final miercoles = DateTime(2026, 4, 15);

    test('mismo día mantiene la racha (no suma doble)', () {
      expect(
        RachaDiariaService.nuevaRacha(
          ultimoDia: RachaDiariaService.claveDia(lunes),
          racha: 4,
          hoy: lunes,
        ),
        4,
      );
    });

    test('día consecutivo suma +1', () {
      expect(
        RachaDiariaService.nuevaRacha(
          ultimoDia: RachaDiariaService.claveDia(lunes),
          racha: 4,
          hoy: martes,
        ),
        5,
      );
    });

    test('hueco de más de un día reinicia a 1', () {
      expect(
        RachaDiariaService.nuevaRacha(
          ultimoDia: RachaDiariaService.claveDia(lunes),
          racha: 7,
          hoy: miercoles,
        ),
        1,
      );
    });

    test('sin historial inicia en 1', () {
      expect(
        RachaDiariaService.nuevaRacha(ultimoDia: '', racha: 0, hoy: lunes),
        1,
      );
    });

    test('bono por día crece hasta 5 y se estabiliza', () {
      expect(RachaDiariaService.bonoDia(1), 2);
      expect(RachaDiariaService.bonoDia(3), 6);
      expect(RachaDiariaService.bonoDia(5), 10);
      expect(RachaDiariaService.bonoDia(9), 10); // tope
    });
  });

  group('MisionesDiariasService', () {
    final hoy = DateTime(2026, 4, 13);
    final manana = DateTime(2026, 4, 14);

    test('mismas misiones para la misma fecha (determinístico)', () {
      final a = MisionesDiariasService.misionesDe(hoy);
      final b = MisionesDiariasService.misionesDe(DateTime(2026, 4, 13));
      expect(a.length, 3);
      expect(a.map((m) => m.id), b.map((m) => m.id));
    });

    test('3 misiones con tipos distintos', () {
      final misiones = MisionesDiariasService.misionesDe(hoy);
      expect(misiones.map((m) => m.tipo).toSet().length, 3);
      expect(misiones.every((m) => m.meta > 0 && m.recompensa > 0), isTrue);
    });

    test('registrarAcierto acumula y guarda racha máxima del día', () {
      var p = <String, dynamic>{};
      p = MisionesDiariasService.registrarAcierto(
        p,
        hoy,
        rachaActual: 6,
        xpGanado: 24,
      );
      p = MisionesDiariasService.registrarAcierto(
        p,
        hoy,
        rachaActual: 3,
        xpGanado: 14,
      );
      final c = MisionesDiariasService.contadores(p, hoy);
      expect(c.aciertos, 2);
      expect(c.rachaMax, 6);
      expect(c.xpHoy, 38);

      // Otro día: contadores en cero.
      final c2 = MisionesDiariasService.contadores(p, manana);
      expect(c2.aciertos, 0);
    });

    test('reclamar otorga XP una sola vez', () {
      final mision = MisionesDiariasService.misionesDe(hoy).first;
      // Completamos la misión con un progreso artificial.
      var p = <String, dynamic>{
        'xp': 100,
        'dia': {
          'fecha': RachaDiariaService.claveDia(hoy),
          'aciertos': 999,
          'racha_max': 999,
          'xp_hoy': 999,
        },
      };
      final antes = p['xp'] as int;
      p = MisionesDiariasService.reclamar(p, mision, hoy);
      expect(p['xp'], antes + mision.recompensa);

      // Re-clamar no vuelve a dar XP.
      final xpTrasReclamo = p['xp'];
      p = MisionesDiariasService.reclamar(p, mision, hoy);
      expect(p['xp'], xpTrasReclamo);
    });

    test('reclamar sin completar no otorga nada', () {
      final mision = MisionesDiariasService.misionesDe(hoy).first;
      var p = <String, dynamic>{'xp': 50};
      p = MisionesDiariasService.reclamar(p, mision, hoy);
      expect(p['xp'], 50);
    });
  });

  group('QuizProgresionService.prepararDia', () {
    test('primer día: racha 1 + bono por volver', () {
      final hoy = DateTime(2026, 4, 13);
      final r = QuizProgresionService.prepararDia(
        <String, dynamic>{'xp': 0},
        hoy,
      );
      expect(r.progreso['racha_dias'], 1);
      expect(r.bono, RachaDiariaService.bonoPorVolver(1));
      expect(r.progreso['xp'], r.bono);
      expect(r.progreso['ultimo_dia_jugado'], '2026-04-13');
    });

    test('segunda llamada el mismo día: sin bono extra', () {
      final hoy = DateTime(2026, 4, 13);
      final r1 = QuizProgresionService.prepararDia(
        <String, dynamic>{'xp': 10},
        hoy,
      );
      final r2 = QuizProgresionService.prepararDia(r1.progreso, hoy);
      expect(r2.bono, 0);
      expect(r2.progreso['xp'], r1.progreso['xp']);
      expect(r2.progreso['racha_dias'], 1);
    });

    test('día consecutivo: racha +1 y bono mayor', () {
      final ayer = DateTime(2026, 4, 12);
      final hoy = DateTime(2026, 4, 13);
      final r1 = QuizProgresionService.prepararDia(
        <String, dynamic>{'xp': 0},
        ayer,
      );
      final r2 = QuizProgresionService.prepararDia(r1.progreso, hoy);
      expect(r2.progreso['racha_dias'], 2);
      expect(r2.bono, RachaDiariaService.bonoPorVolver(2));
    });
  });
}
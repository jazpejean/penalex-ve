import 'package:flutter_test/flutter_test.dart';

import 'package:penalex_ve/logic/lapsos_engine.dart';
import 'package:penalex_ve/logic/secuencia_procesal.dart';
import 'package:penalex_ve/models/lapso_procesal.dart';

void main() {
  group('calcularFecha — cómputo continuo', () {
    test('suma días corridos incluyendo fin de semana', () {
      // Jueves 1 oct 2026 + 3 días continuos → domingo 4 oct.
      final DateTime base = DateTime(2026, 10, 1);
      final DateTime r = calcularFecha(
        base: base,
        cantidad: 3,
        unidad: UnidadLapso.dias,
        computo: TipoComputo.continuo,
      );
      expect(r, DateTime(2026, 10, 4));
    });

    test('suma meses saltando correctamente fin de mes', () {
      final DateTime base = DateTime(2026, 1, 31);
      final DateTime r = calcularFecha(
        base: base,
        cantidad: 1,
        unidad: UnidadLapso.meses,
        computo: TipoComputo.continuo,
      );
      // 31 ene + 1 mes → 28 feb 2026 (no bisiesto).
      expect(r, DateTime(2026, 2, 28));
    });

    test('suma horas continuas', () {
      final DateTime base = DateTime(2026, 10, 1, 9, 0);
      final DateTime r = calcularFecha(
        base: base,
        cantidad: 36,
        unidad: UnidadLapso.horas,
        computo: TipoComputo.continuo,
      );
      expect(r, DateTime(2026, 10, 2, 21, 0));
    });
  });

  group('calcularFecha — días hábiles/despacho', () {
    test('salta sábado y domingo', () {
      // Jueves 1 oct 2026 + 2 días hábiles → lunes 5 oct.
      final DateTime base = DateTime(2026, 10, 1);
      final DateTime r = calcularFecha(
        base: base,
        cantidad: 2,
        unidad: UnidadLapso.dias,
        computo: TipoComputo.habiles,
        excluidos: <DateTime>{},
      );
      expect(r, DateTime(2026, 10, 5));
    });

    test('salta feriado judicial incluido en excluidos', () {
      // Jueves 1 oct + 1 día hábil con el viernes 2 oct excluido → lunes 5.
      final DateTime base = DateTime(2026, 10, 1);
      final DateTime r = calcularFecha(
        base: base,
        cantidad: 1,
        unidad: UnidadLapso.dias,
        computo: TipoComputo.despacho,
        excluidos: <DateTime>{DateTime(2026, 10, 2)},
      );
      expect(r, DateTime(2026, 10, 5));
    });

    test('despacho y hábil tratan igual sábados/domingos', () {
      final DateTime base = DateTime(2026, 10, 2); // viernes
      final DateTime r = calcularFecha(
        base: base,
        cantidad: 1,
        unidad: UnidadLapso.dias,
        computo: TipoComputo.despacho,
        excluidos: <DateTime>{},
      );
      expect(r, DateTime(2026, 10, 5)); // lunes
    });
  });

  group('restarDiasHabiles — antelación (Art. 311)', () {
    test('5 días hábiles antes de la preliminar', () {
      // Preliminar lunes 12 oct 2026 → 5 días hábiles antes = lunes 5 oct.
      final DateTime preliminar = DateTime(2026, 10, 12);
      final DateTime limite = restarDiasHabiles(
        base: preliminar,
        cantidad: 5,
        excluidos: <DateTime>{},
      );
      expect(limite, DateTime(2026, 10, 5));
    });

    test('salta feriados al restar', () {
      // Preliminar jueves 8 oct, viernes 9 NO; excluimos 7 oct.
      // 5 días hábiles antes: 1(mar) 2(mié) 3(jue) 5(lun) 6(mar)...
      // recorriendo: 7 excluido, 6 mar ok(1), 5 lun ok(2), 2 vie? no:
      // oct 2 es viernes. Caminemos desde 8 oct: -1→7(excl) -2→6(mar) ok1
      // -3→5(lun) ok2 -4→2? no, -5→1? no... basta ver que salta el feriado.
      final DateTime preliminar = DateTime(2026, 10, 8);
      final Set<DateTime> excluidos = <DateTime>{DateTime(2026, 10, 7)};
      final DateTime limite = restarDiasHabiles(
        base: preliminar,
        cantidad: 1,
        excluidos: excluidos,
      );
      // 7 oct excluido → el primer día hábil hacia atrás es martes 6 oct.
      expect(limite, DateTime(2026, 10, 6));
    });
  });

  group('fechasExcluidasDe', () {
    test('normaliza a medianoche para comparar', () {
      final Set<DateTime> set = fechasExcluidasDe(<DateTime>[
        DateTime(2026, 10, 2, 15, 30),
        DateTime(2026, 10, 3),
      ]);
      expect(set, contains(DateTime(2026, 10, 2)));
      expect(set, contains(DateTime(2026, 10, 3)));
    });
  });

  group('secuencia procesal — ordinario', () {
    test('genera hitos desde la fecha base sin gatillo', () {
      final List<HitoCalculado> hitos = generarHitosIniciales(
        via: ViaProcesal.ordinario,
        fechaBase: DateTime(2026, 10, 1, 9, 0),
        excluidos: <DateTime>{},
      );
      // Debe incluir la revisión de medidas (3 meses) calculada.
      final HitoCalculado revision = hitos.firstWhere(
        (h) => h.lapso.acto.contains('Revisión judicial'),
      );
      expect(revision.fechaMin, DateTime(2027, 1, 1, 9, 0));
      expect(revision.pendienteDe, isNull);
    });

    test('marca pendientes los hitos con gatillo', () {
      final List<HitoCalculado> hitos = generarHitosIniciales(
        via: ViaProcesal.ordinario,
        fechaBase: DateTime(2026, 10, 1),
        excluidos: <DateTime>{},
      );
      final HitoCalculado preliminar = hitos.firstWhere(
        (h) => h.lapso.acto.contains('Audiencia Preliminar'),
      );
      expect(preliminar.pendienteDe, Gatillos.acusacion);
      expect(preliminar.fechaMin, isNull);
    });

    test('acto conclusivo: 45 días continuos desde la presentación', () {
      final List<HitoCalculado> hitos = generarHitosIniciales(
        via: ViaProcesal.ordinario,
        fechaBase: DateTime(2026, 10, 1),
        excluidos: <DateTime>{},
      );
      final HitoCalculado conclusivo = hitos.firstWhere(
        (h) => h.lapso.acto.contains('Acto conclusivo'),
      );
      // 1 oct + 45 días continuos = 15 nov 2026.
      expect(conclusivo.fechaMin, DateTime(2026, 11, 15));
    });
  });

  group('secuencia procesal — violencia y menos graves', () {
    test('violencia: catálogo tiene apelación 3 días (pendiente verificación)', () {
      final List<LapsoCatalogo> catalogo = catalogoPorVia(ViaProcesal.violencia);
      final LapsoCatalogo apelacion = catalogo.firstWhere(
        (l) => l.acto.contains('Apelación de la sentencia'),
      );
      expect(apelacion.cantidadMin, 3);
      expect(apelacion.pendienteVerificacion, isTrue);
    });

    test('menos graves: preliminar municipal 10-15 días hábiles', () {
      final List<LapsoCatalogo> catalogo = catalogoPorVia(ViaProcesal.menosGraves);
      final LapsoCatalogo preliminar = catalogo.firstWhere(
        (l) => l.acto.contains('Preliminar Municipal'),
      );
      expect(preliminar.cantidadMin, 10);
      expect(preliminar.cantidadMax, 15);
      expect(preliminar.computo, TipoComputo.habiles);
      // Calculado desde la acusación (gatillo).
      final HitoCalculado hito = calcularHito(
        lapso: preliminar,
        fechaBase: DateTime(2026, 10, 1),
        excluidos: <DateTime>{},
      );
      expect(hito.fechaMin, isNotNull);
      expect(hito.fechaMax, isNotNull);
      expect(hito.fechaMax!.isAfter(hito.fechaMin!), isTrue);
    });

    test('antelación: excepciones hasta 5 días hábiles antes de la preliminar', () {
      final List<LapsoCatalogo> catalogo = catalogoPorVia(ViaProcesal.ordinario);
      final LapsoCatalogo excepciones = catalogo.firstWhere(
        (l) => l.acto.contains('Cargas escritas'),
      );
      expect(excepciones.antelacion, isTrue);
      // Preliminar lunes 12 oct 2026.
      final HitoCalculado hito = calcularHito(
        lapso: excepciones,
        fechaBase: DateTime(2026, 10, 12),
        excluidos: <DateTime>{},
      );
      expect(hito.fechaMin, DateTime(2026, 10, 5));
    });
  });

  group('catálogo — consistencia', () {
    test('cada lapso tiene base legal', () {
      for (final ViaProcesal via in ViaProcesal.values) {
        for (final LapsoCatalogo l in catalogoPorVia(via)) {
          expect(l.baseLegal, isNotEmpty, reason: '${l.acto} sin base legal');
        }
      }
    });

    test('ningún lapso usa cómputo sin sentido (meses con hábil)', () {
      for (final ViaProcesal via in ViaProcesal.values) {
        for (final LapsoCatalogo l in catalogoPorVia(via)) {
          if (l.unidad == UnidadLapso.meses || l.unidad == UnidadLapso.anos) {
            expect(l.computo, TipoComputo.continuo,
                reason: '${l.acto} usa meses con cómputo ${l.computo}');
          }
        }
      }
    });

    test('no hay actos duplicados dentro de una vía', () {
      for (final ViaProcesal via in ViaProcesal.values) {
        final List<String> actos =
            catalogoPorVia(via).map((l) => l.acto).toList();
        expect(actos.toSet().length, actos.length,
            reason: 'Actos duplicados en $via');
      }
    });
  });
}
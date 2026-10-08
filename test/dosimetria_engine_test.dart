import 'package:flutter_test/flutter_test.dart';
import 'package:penalex_ve/logic/dosimetria_engine.dart';
import 'package:penalex_ve/models/delito.dart';

Delito _delito({
  String id = '1',
  String nombre = 'Delito',
  required double min,
  required double max,
  TipoPena tipoPena = TipoPena.prision,
  double modificadorManual = 0,
  List<AjusteAdicional>? ajustes,
  bool continuado = false,
  double fraccionContinuidad = 1 / 6,
  GradoEjecucion grado = GradoEjecucion.consumado,
  double fraccionEjecucion = 0,
}) =>
    Delito(
      id: id,
      nombre: nombre,
      penaMin: min,
      penaMax: max,
      tipoPena: tipoPena,
      modificadorManual: modificadorManual,
      delitoContinuado: continuado,
      fraccionContinuidad: fraccionContinuidad,
      gradoEjecucion: grado,
      fraccionEjecucion: fraccionEjecucion,
    )..ajustesAdicionales.addAll(ajustes ?? <AjusteAdicional>[]);

void main() {
  group('Individualización (pena 8-12, término medio 10)', () {
    test('término medio es 10', () {
      final d = _delito(min: 8, max: 12);
      expect(d.terminoMedio, 10.0);
    });

    test('ajuste legal +1/3 (Ley de Drogas, ocultación) da 13 años y 4 meses',
        () {
      final d = _delito(
        min: 8,
        max: 12,
        ajustes: <AjusteAdicional>[
          AjusteAdicional(
              nombre: 'Ocultación', esAgravante: true, fraccion: 1 / 3),
        ],
      );
      expect(d.calcularPenaIndividualizada(), closeTo(13.3333, 0.001));
    });

    test('atenuante 74/77 de 3 años baja hasta el mínimo (8), sin pasarlo', () {
      final d = _delito(min: 8, max: 12, modificadorManual: -3);
      expect(d.calcularPenaIndividualizada(), 8.0);
    });

    test('agravante 74/77 de 3 años sube hasta el máximo (12), sin pasarlo',
        () {
      final d = _delito(min: 8, max: 12, modificadorManual: 3);
      expect(d.calcularPenaIndividualizada(), 12.0);
    });

    test('agravante 74/77 de 2 años queda en 12 (dentro del límite)', () {
      final d = _delito(min: 8, max: 12, modificadorManual: 2);
      expect(d.calcularPenaIndividualizada(), 12.0);
    });

    test('atenuante 74/77 de 1 año queda en 9', () {
      final d = _delito(min: 8, max: 12, modificadorManual: -1);
      expect(d.calcularPenaIndividualizada(), 9.0);
    });

    test('delito continuado 1/6 sobre 10 da 11.6667 (sin techo del tipo)', () {
      final d = _delito(min: 8, max: 12, continuado: true);
      expect(d.calcularPenaIndividualizada(), closeTo(11.6667, 0.001));
    });

    test('ajuste legal +1/3 y continuado 1/6: 13.3333 * 7/6 = 15.5556', () {
      final d = _delito(
        min: 8,
        max: 12,
        continuado: true,
        ajustes: <AjusteAdicional>[
          AjusteAdicional(
              nombre: 'Ocultación', esAgravante: true, fraccion: 1 / 3),
        ],
      );
      expect(d.calcularPenaIndividualizada(), closeTo(15.5556, 0.001));
    });

    test('frustrado 1/3 baja del mínimo: 10 * 2/3 = 6.6667', () {
      final d = _delito(
        min: 8,
        max: 12,
        grado: GradoEjecucion.frustrado,
        fraccionEjecucion: 1 / 3,
      );
      expect(d.calcularPenaIndividualizada(), closeTo(6.6667, 0.001));
    });

    test('atenuante 74/77 al mínimo (8) y frustrado: 8 * 2/3 = 5.3333', () {
      final d = _delito(
        min: 8,
        max: 12,
        modificadorManual: -5,
        grado: GradoEjecucion.frustrado,
        fraccionEjecucion: 1 / 3,
      );
      expect(d.calcularPenaIndividualizada(), closeTo(5.3333, 0.001));
    });
  });

  group('Concurso real (Arts. 86/87/88 CP)', () {
    test('solo presidios: mayor + 2/3 de las demás (Art. 86)', () {
      final d1 = _delito(id: '1', min: 8, max: 12, tipoPena: TipoPena.presidio);
      final d2 = _delito(id: '2', min: 4, max: 6, tipoPena: TipoPena.presidio);
      final res = DosimetriaEngine.calcularConcursoDetallado(
        delitos: <Delito>[d1, d2],
        concurso: TipoConcurso.real,
        admisionHechos: false,
        fraccionAdmision: 1 / 3,
      );
      // 10 + 2/3 * 5 = 13.3333
      expect(res.total, closeTo(13.3333, 0.001));
      expect(res.articuloAplicado, contains('Art. 86'));
    });

    test('solo prisiones: mayor + 1/2 de las demás (Art. 88)', () {
      final d1 = _delito(id: '1', min: 8, max: 12);
      final d2 = _delito(id: '2', min: 4, max: 6);
      final res = DosimetriaEngine.calcularConcursoDetallado(
        delitos: <Delito>[d1, d2],
        concurso: TipoConcurso.real,
        admisionHechos: false,
        fraccionAdmision: 1 / 3,
      );
      // 10 + 1/2 * 5 = 12.5
      expect(res.total, closeTo(12.5, 0.001));
      expect(res.articuloAplicado, contains('Art. 88'));
    });

    test('mixto presidio+prisión: conversión Art. 87 y luego 2/3', () {
      final d1 = _delito(id: '1', min: 8, max: 12, tipoPena: TipoPena.presidio);
      final d2 =
          _delito(id: '2', min: 6, max: 10); // prisión -> 8 -> 4 presidio
      final res = DosimetriaEngine.calcularConcursoDetallado(
        delitos: <Delito>[d1, d2],
        concurso: TipoConcurso.real,
        admisionHechos: false,
        fraccionAdmision: 1 / 3,
      );
      // mayor 10 + 2/3 * 4 = 12.6667
      expect(res.total, closeTo(12.6667, 0.001));
      expect(res.articuloAplicado, contains('Art. 87'));
    });

    test('ideal: solo la pena más grave (Art. 98)', () {
      final d1 = _delito(id: '1', min: 8, max: 12);
      final d2 = _delito(id: '2', min: 6, max: 10);
      final res = DosimetriaEngine.calcularConcursoDetallado(
        delitos: <Delito>[d1, d2],
        concurso: TipoConcurso.ideal,
        admisionHechos: false,
        fraccionAdmision: 1 / 3,
      );
      expect(res.total, 10.0);
      expect(res.articuloAplicado, contains('Art. 98'));
    });
  });

  group('Tope de 30 años y admisión de hechos', () {
    test('pena 35 + admisión 1/3: tope 30 primero, luego 30 * 2/3 = 20', () {
      final d = _delito(id: '1', min: 20, max: 50);
      final res = DosimetriaEngine.calcularConcursoDetallado(
        delitos: <Delito>[d],
        concurso: TipoConcurso.real,
        admisionHechos: true,
        fraccionAdmision: 1 / 3,
      );
      expect(res.total, closeTo(20.0, 0.001));
      expect(res.topeAplicado, isTrue);
    });

    test('pena 35 + admisión 1/2: 30 * 1/2 = 15', () {
      final d = _delito(id: '1', min: 20, max: 50);
      final res = DosimetriaEngine.calcularConcursoDetallado(
        delitos: <Delito>[d],
        concurso: TipoConcurso.real,
        admisionHechos: true,
        fraccionAdmision: 0.5,
      );
      expect(res.total, closeTo(15.0, 0.001));
    });

    test('pena 35 sin admisión: se clampa a 30', () {
      final d = _delito(id: '1', min: 20, max: 50);
      final res = DosimetriaEngine.calcularConcursoDetallado(
        delitos: <Delito>[d],
        concurso: TipoConcurso.real,
        admisionHechos: false,
        fraccionAdmision: 1 / 3,
      );
      expect(res.total, 30.0);
      expect(res.topeAplicado, isTrue);
    });

    test('pena 25 con admisión 1/3: 25 * 2/3 = 16.6667, sin tope', () {
      final d = _delito(id: '1', min: 15, max: 35);
      final res = DosimetriaEngine.calcularConcursoDetallado(
        delitos: <Delito>[d],
        concurso: TipoConcurso.real,
        admisionHechos: true,
        fraccionAdmision: 1 / 3,
      );
      expect(res.total, closeTo(16.6667, 0.001));
      expect(res.topeAplicado, isFalse);
    });

    test('concurso ideal también respeta el tope de 30', () {
      final d = _delito(id: '1', min: 20, max: 50);
      final res = DosimetriaEngine.calcularConcursoDetallado(
        delitos: <Delito>[d],
        concurso: TipoConcurso.ideal,
        admisionHechos: true,
        fraccionAdmision: 1 / 3,
      );
      expect(res.total, closeTo(20.0, 0.001));
    });

    test('el desglose incluye el tope y la rebaja por admisión', () {
      final d = _delito(id: '1', min: 20, max: 50);
      final res = DosimetriaEngine.calcularConcursoDetallado(
        delitos: <Delito>[d],
        concurso: TipoConcurso.real,
        admisionHechos: true,
        fraccionAdmision: 1 / 3,
      );
      final String pasos = res.pasos.join('\n');
      expect(pasos, contains('Tope de 30 años'));
      expect(pasos, contains('Art. 375 COPP'));
    });
  });
}

import '../models/delito.dart';

/// Resultado completo del cálculo de concurso, con los pasos matemáticos
/// para que pantalla y PDF muestren exactamente lo mismo.
class ResultadoConcurso {
  ResultadoConcurso({
    required this.total,
    required this.pasos,
    required this.topeAplicado,
    required this.articuloAplicado,
  });

  final double total;
  final List<String> pasos;
  final bool topeAplicado;
  final String articuloAplicado;
}

// ignore: avoid_classes_with_only_static_members
class DosimetriaEngine {
  // Convierte años decimales a mapa YMD (360 días al año)
  static Map<String, int> convertToYMD(double totalYears) {
    if (totalYears <= 0) {
      return <String, int>{'anos': 0, 'meses': 0, 'dias': 0};
    }

    final int totalDias = (totalYears * 360).round();
    int anos = totalDias ~/ 360;
    int meses = (totalDias % 360) ~/ 30;
    int dias = totalDias % 30;

    if (meses == 12) {
      anos += 1;
      meses = 0;
    }
    return <String, int>{'anos': anos, 'meses': meses, 'dias': dias};
  }

  // Formatea a String legible siempre mostrando años, meses y días.
  static String formatYMD(double totalYears) {
    final Map<String, int> ymd = convertToYMD(totalYears);
    final int anos = ymd['anos'] ?? 0;
    final int meses = ymd['meses'] ?? 0;
    final int dias = ymd['dias'] ?? 0;

    return '$anos años, $meses meses y $dias días';
  }

  static String formatNumero(double valor) {
    if (valor == valor.toInt()) {
      return valor.toInt().toString();
    }
    return valor.toStringAsFixed(2);
  }

  static String _fraccionTexto(double valor) {
    const double epsilon = 0.001;
    if ((valor - 1 / 6).abs() < epsilon) return '1/6';
    if ((valor - 1 / 4).abs() < epsilon) return '1/4';
    if ((valor - 1 / 3).abs() < epsilon) return '1/3';
    if ((valor - 0.5).abs() < epsilon) return '1/2';
    if ((valor - 2 / 3).abs() < epsilon) return '2/3';
    return formatNumero(valor);
  }

  /// API simple (compatibilidad): solo el total.
  static double calcularConcurso({
    required List<Delito> delitos,
    required TipoConcurso concurso,
    required bool admisionHechos,
    required double fraccionAdmision,
  }) =>
      calcularConcursoDetallado(
              delitos: delitos,
              concurso: concurso,
              admisionHechos: admisionHechos,
              fraccionAdmision: fraccionAdmision)
          .total;

  /// Lógica del concurso (Arts. 86, 87, 88 y 98 CP) con pasos verificables.
  ///
  /// Reglas:
  /// - Concurso real solo presidios (Art. 86 CP): pena mayor + 2/3 de las demás.
  /// - Concurso real mixto (Art. 87 CP): las prisiones se convierten a presidio
  ///   (1 año de presidio = 2 años de prisión) y se aplica la fórmula de presidios.
  /// - Concurso real solo prisiones (Art. 88 CP): pena mayor + 1/2 de las demás.
  /// - Concurso ideal (Art. 98 CP): solo la pena más grave.
  /// - Tope absoluto de 30 años (Art. 94 CP): se aplica ANTES de la rebaja por
  ///   admisión de hechos (el descuento de 1/3 a 1/2 va sobre los 30 años).
  static ResultadoConcurso calcularConcursoDetallado({
    required List<Delito> delitos,
    required TipoConcurso concurso,
    required bool admisionHechos,
    required double fraccionAdmision,
  }) {
    if (delitos.isEmpty) {
      return ResultadoConcurso(
        total: 0,
        pasos: <String>['Sin delitos para calcular'],
        topeAplicado: false,
        articuloAplicado: '',
      );
    }

    final List<String> pasos = <String>[];
    final List<double> penas =
        delitos.map((Delito d) => d.calcularPenaIndividualizada()).toList();

    double penaBase;
    String articulo;

    if (concurso == TipoConcurso.real && delitos.length == 1) {
      // Delito único: no hay concurso, pero tope y admisión aplican igual.
      articulo = 'Delito único (sin concurso)';
      penaBase = penas.first;
      pasos.add('Pena individualizada: ${formatYMD(penaBase)}');
    } else if (concurso == TipoConcurso.real) {
      final bool hayPresidio =
          delitos.any((Delito d) => d.tipoPena == TipoPena.presidio);
      final bool hayPrision =
          delitos.any((Delito d) => d.tipoPena == TipoPena.prision);

      if (hayPresidio && hayPrision) {
        // Art. 87 CP: convertir prisiones a presidio primero.
        articulo = 'Art. 87 CP (Presidio + Prisión)';
        final List<double> convertidas =
            delitos.map((Delito d) => d.convertirAPresidio()).toList();
        for (int i = 0; i < delitos.length; i++) {
          if (delitos[i].tipoPena == TipoPena.prision) {
            pasos.add(
                'Conversión Art. 87 CP: prisión ${formatYMD(penas[i])} -> presidio ${formatYMD(convertidas[i])}');
          }
        }
        convertidas.sort((double a, double b) => b.compareTo(a));
        penaBase = convertidas.first;
        pasos.add('Pena mayor (presidio): ${formatYMD(penaBase)}');
        for (int i = 1; i < convertidas.length; i++) {
          final double inc = convertidas[i] * (2 / 3);
          pasos
              .add('+ 2/3 de ${formatYMD(convertidas[i])} = ${formatYMD(inc)}');
          penaBase += inc;
        }
      } else if (hayPrision) {
        // Art. 88 CP: solo prisiones -> pena mayor + 1/2 de las demás.
        articulo = 'Art. 88 CP (Prisión + Prisión)';
        penas.sort((double a, double b) => b.compareTo(a));
        penaBase = penas.first;
        pasos.add('Pena mayor (prisión): ${formatYMD(penaBase)}');
        for (int i = 1; i < penas.length; i++) {
          final double inc = penas[i] * 0.5;
          pasos.add('+ 1/2 de ${formatYMD(penas[i])} = ${formatYMD(inc)}');
          penaBase += inc;
        }
      } else {
        // Art. 86 CP: solo presidios -> pena mayor + 2/3 de las demás.
        articulo = 'Art. 86 CP (Presidio + Presidio)';
        penas.sort((double a, double b) => b.compareTo(a));
        penaBase = penas.first;
        pasos.add('Pena mayor (presidio): ${formatYMD(penaBase)}');
        for (int i = 1; i < penas.length; i++) {
          final double inc = penas[i] * (2 / 3);
          pasos.add('+ 2/3 de ${formatYMD(penas[i])} = ${formatYMD(inc)}');
          penaBase += inc;
        }
      }
    } else {
      // Art. 98 CP: concurso ideal -> solo la pena más grave.
      articulo = 'Art. 98 CP (Concurso Ideal)';
      penaBase = penas.reduce((double a, double b) => a > b ? a : b);
      pasos.add('Pena más grave (Art. 98 CP): ${formatYMD(penaBase)}');
    }

    // Tope absoluto de 30 años (Art. 94 CP): SIEMPRE antes de la admisión.
    bool topeAplicado = false;
    if (penaBase > 30.0) {
      pasos.add(
          'Tope de 30 años (Art. 94 CP): ${formatYMD(penaBase)} -> 30 años');
      penaBase = 30.0;
      topeAplicado = true;
    }

    // Rebaja por admisión de hechos (Art. 375 COPP): sobre la pena final
    // (que ya incluye el tope de 30 años si aplicó).
    if (admisionHechos) {
      final double rebaja = penaBase * fraccionAdmision;
      pasos.add(
          'Rebaja por admisión de hechos (Art. 375 COPP, ${_fraccionTexto(fraccionAdmision)}): -${formatYMD(rebaja)}');
      penaBase = penaBase * (1 - fraccionAdmision);
    }

    pasos.add('PENA DEFINITIVA: ${formatYMD(penaBase)}');

    return ResultadoConcurso(
      total: penaBase,
      pasos: pasos,
      topeAplicado: topeAplicado,
      articuloAplicado: articulo,
    );
  }
}

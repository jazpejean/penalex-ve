import '../models/delito.dart';

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

    if (dias == 30) {
      meses += 1;
      dias = 0;
    }
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

  // Lógica del cálculo del Concurso (Art. 86 - 98 del Código Penal Venezolano)
  static double calcularConcurso({
    required List<Delito> delitos,
    required TipoConcurso concurso,
    required bool admisionHechos,
    required double fraccionAdmision,
  }) {
    if (delitos.isEmpty) {
      return 0;
    }

    double sumaPenas = 0;
    double penaMayor = 0;

    for (final Delito d in delitos) {
      final double penaInd = d.calcularPenaIndividualizada();
      sumaPenas += penaInd;
      if (penaInd > penaMayor) {
        penaMayor = penaInd;
      }
    }

    double penaBase = 0;

    if (concurso == TipoConcurso.real) {
      // Art. 88 CPV: No puede exceder del triple de la mayor
      final double tripleMayor = penaMayor * 3;
      penaBase = sumaPenas > tripleMayor ? tripleMayor : sumaPenas;

      // Tope absoluto de 30 años en Venezuela
      if (penaBase > 30.0) {
        penaBase = 30.0;
      }
    } else {
      // Art. 98 CPV Concurso Ideal: Pena mayor aumentada hasta la mitad
      penaBase = penaMayor + (penaMayor / 2);
    }

    // Aplicar rebaja por Admisión de Hechos (COPP)
    if (admisionHechos) {
      penaBase = penaBase * (1 - fraccionAdmision);
    }

    return penaBase;
  }
}
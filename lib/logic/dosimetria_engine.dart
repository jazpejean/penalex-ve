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

  // Lógica del cálculo del Concurso (Art. 86, 87, 88 del Código Penal Venezolano)
  static double calcularConcurso({
    required List<Delito> delitos,
    required TipoConcurso concurso,
    required bool admisionHechos,
    required double fraccionAdmision,
  }) {
    if (delitos.isEmpty) {
      return 0;
    }

    double penaMayor = 0;

    for (final Delito d in delitos) {
      final double penaInd = d.calcularPenaIndividualizada();
      if (penaInd > penaMayor) {
        penaMayor = penaInd;
      }
    }

    double penaBase = 0;

    if (concurso == TipoConcurso.real) {
      // Verificar tipos de pena
      final hayPresidio = delitos.any((d) => d.tipoPena == TipoPena.presidio);
      final hayPrision = delitos.any((d) => d.tipoPena == TipoPena.prision);
      
      if (hayPresidio && hayPrision) {
        // CASO 1: Mezcla de Presidio + Prisión
        // Art. 87 CP: Convertir prisiones a presidio primero
        // (1 año presidio = 2 años prisión → dividir entre 2)
        // Luego aplicar: Pena mayor + 2/3 de las demás
        
        final List<double> penasConvertidas = delitos
            .map((d) => d.convertirAPresidio())
            .toList();
        
        penasConvertidas.sort((a, b) => b.compareTo(a));
        final double mayor = penasConvertidas.first;
        
        double suma = mayor;
        for (int i = 1; i < penasConvertidas.length; i++) {
          suma += penasConvertidas[i] * (2 / 3); // 2/3
        }
        
        penaBase = suma;
        
      } else if (hayPrision && !hayPresidio) {
        // CASO 2: Solo Prisiones
        // Art. 88 CP: Pena mayor + 1/2 de las demás
        // (NO se convierten a presidio, se mantienen como prisión)
        
        final List<double> penas = delitos
            .map((d) => d.calcularPenaIndividualizada())
            .toList();
        
        penas.sort((a, b) => b.compareTo(a));
        final double mayor = penas.first;
        
        double suma = mayor;
        for (int i = 1; i < penas.length; i++) {
          suma += penas[i] * 0.5; // 1/2
        }
        
        penaBase = suma;
        
      } else {
        // CASO 3: Solo Presidios
        // Art. 86 CP: Pena mayor + 2/3 de las demás
        
        final List<double> penas = delitos
            .map((d) => d.calcularPenaIndividualizada())
            .toList();
        
        penas.sort((a, b) => b.compareTo(a));
        final double mayor = penas.first;
        
        double suma = mayor;
        for (int i = 1; i < penas.length; i++) {
          suma += penas[i] * (2 / 3); // 2/3
        }
        
        penaBase = suma;
      }

      // Tope absoluto de 30 años (Art. 44 CRBV y Art. 94 CP)
      if (penaBase > 30.0) {
        penaBase = 30.0;
      }
    } else {
      // Art. 98 CP - Concurso Ideal: Solo se aplica la pena del delito más grave
      penaBase = penaMayor;
    }

    // Aplicar rebaja por Admisión de Hechos (Art. 375 COPP)
    if (admisionHechos) {
      penaBase = penaBase * (1 - fraccionAdmision);
    }

    return penaBase;
  }
}
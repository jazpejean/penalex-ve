import '../models/delito.dart';
import '../utils/pena_utils.dart';

// ignore_for_file: avoid_classes_with_only_static_members, cascade_invocations, lines_longer_than_80_chars

class ComputoData {
  ComputoData({
    required this.fechaDetencion,
    required this.tiempoDetenidoTexto,
    required this.tiempoRestanteTexto,
    required this.fechaCumplimiento,
    this.fechaCondena,
  });

  final DateTime fechaDetencion;
  final String tiempoDetenidoTexto;
  final String tiempoRestanteTexto;
  final DateTime fechaCumplimiento;
  final DateTime? fechaCondena;
}

class ReportGenerator {
  static String _getNombreConcurso(TipoConcurso c) {
    switch (c) {
      case TipoConcurso.real:
        return 'REAL (Art. 88 CP)';
      case TipoConcurso.ideal:
        return 'IDEAL (Art. 98 CP)';
    }
  }

  static String _fraccionTexto(double valor) {
    const double epsilon = 0.001;
    if ((valor - 1 / 6).abs() < epsilon) {
      return '1/6';
    }
    if ((valor - 1 / 4).abs() < epsilon) {
      return '1/4';
    }
    if ((valor - 1 / 3).abs() < epsilon) {
      return '1/3';
    }
    if ((valor - 0.5).abs() < epsilon) {
      return '1/2';
    }
    if ((valor - 2 / 3).abs() < epsilon) {
      return '2/3';
    }
    if ((valor - 0.75).abs() < epsilon) {
      return '3/4';
    }
    return valor.toStringAsFixed(2);
  }

  static String _formatearFecha(DateTime fecha) {
    final String dia = fecha.day.toString().padLeft(2, '0');
    final String mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  static String generarReporteCompleto({
    required List<Delito> delitos,
    required TipoConcurso concurso,
    required bool admisionHechos,
    required double fraccionAdmision,
    ComputoData? computo,
    String expediente = 'S/N',
    String acusado = 'No especificado',
  }) {
    final StringBuffer buffer = StringBuffer();
    final DateTime fecha = DateTime.now();

    // ENCABEZADO
    buffer.write('# INFORME TÉCNICO DE DOSIMETRÍA JURÍDICA\n\n');
    buffer.write('| | |\n');
    buffer.write('|---|---|\n');
    buffer.write('| **[LOGO PENALEX VE]** | **N° de Expediente:** ');
    buffer.write('$expediente |\n');
    buffer.write('| **Fecha:** ${fecha.day}/${fecha.month}/${fecha.year} |\n');
    buffer.write('| **Acusado:** $acusado |\n\n');
    buffer.write('---\n\n');

    // 1. DELITOS Y MARCOS PENALES
    buffer.write('## 1. DELITOS PROCESADOS\n\n');
    buffer.write('| # | Delito | Pena mínima | Pena máxima |\n');
    buffer.write('|   |        | Término medio (Art. 37 CP) |\n');
    buffer.write('|---|--------|-------------|-------------|\n');
    
    for (int i = 0; i < delitos.length; i++) {
      final Delito d = delitos[i];
      final String termino = PenaUtils.formatPena(d.terminoMedio);
      final String nombreDelito = d.nombre.isEmpty 
          ? 'SIN ESPECIFICAR' 
          : d.nombre;
      buffer.write('| ${i + 1} | $nombreDelito | ');
      buffer.write('${PenaUtils.formatPena(d.penaMin)} |\n');
      buffer.write('|   | | ${PenaUtils.formatPena(d.penaMax)} |\n');
      buffer.write('|   | | $termino |\n');
    }
    buffer.write('\n');

    // 2. DESGLOSE POR DELITO
    buffer.write('## 2. DESGLOSE INDIVIDUAL DE LA PENA\n\n');

    for (int i = 0; i < delitos.length; i++) {
      final Delito d = delitos[i];
      final String tituloDelito = d.nombre.isEmpty 
          ? 'DELITO SIN ESPECIFICAR' 
          : d.nombre.toUpperCase();
      
      buffer.write('### ${i + 1}. $tituloDelito\n\n');
      buffer.write('**Marco penal:** ');
      buffer.write('${PenaUtils.formatPena(d.penaMin)} – ');
      buffer.write('${PenaUtils.formatPena(d.penaMax)}\n\n');
      buffer.write('**Cálculo del término medio (Art. 37 CP):**\n');
      buffer.write('```\n');
      buffer.write('Término medio = (Pena máxima - Pena mínima) / 2 + Pena mínima\n');
      buffer.write('              = (${d.penaMax} - ${d.penaMin}) / 2 + ${d.penaMin}\n');
      buffer.write('              = ${d.terminoMedio} años\n');
      buffer.write('              → ${PenaUtils.formatPena(d.terminoMedio)}\n');
      buffer.write('```\n\n');
      buffer.write('**Modificadores aplicados:**\n\n');
      buffer.write('| Concepto | Fundamento legal |\n');
      buffer.write('| Fracción / Valor | Efecto |\n');
      buffer.write('|----------|------------------|\n');

      // Ajustes adicionales
      for (final AjusteAdicional ajuste in d.ajustesAdicionales) {
        final String fraccion = _fraccionTexto(ajuste.fraccion);
        final String efecto = ajuste.esAgravante 
            ? 'Aumento (+)' 
            : 'Reducción (-)';
        buffer.write('| Ajuste adicional | ${ajuste.nombre} |\n');
        buffer.write('| $fraccion | $efecto |\n');
      }

      // Grado de ejecución
      if (d.gradoEjecucion != GradoEjecucion.consumado) {
        final String fundamento = d.gradoEjecucion == GradoEjecucion.frustrado
            ? 'Art. 80 CP (Frustrado)'
            : 'Art. 82 CP (Tentativa)';
        final String fraccion = d.gradoEjecucion == GradoEjecucion.frustrado
            ? '1/3'
            : _fraccionTexto(d.fraccionEjecucion);
        buffer.write('| Grado de ejecución | $fundamento |\n');
        buffer.write('| $fraccion | Reducción (-) |\n');
      }

      // Participación
      if (d.participacionEspecifica == 'Cómplice No Necesario') {
        buffer.write('| Participación | Art. 84 CP (Cómplice no necesario) |\n');
        buffer.write('| 1/2 | Reducción (-) |\n');
      }

      // Delito continuado
      if (d.delitoContinuado) {
        buffer.write('| Delito continuado | Art. 99 CP |\n');
        buffer.write('| ${_fraccionTexto(d.fraccionContinuidad)} | Aumento (+) |\n');
      }

      // Modificador manual
      if (d.modificadorManual != 0) {
        final double valorAbs = d.modificadorManual.abs();
        final String unidad = d.modificadorUnidad;
        final String articulo = d.modificadorManual > 0 
            ? 'Art. 77 CP (Agravante)' 
            : 'Art. 74 CP (Atenuante)';
        final String valorTexto = '$valorAbs $unidad';
        final String efecto = d.modificadorManual > 0 
            ? 'Aumento (+)' 
            : 'Reducción (-)';
        buffer.write('| Modificador genérico | $articulo |\n');
        buffer.write('| $valorTexto | $efecto |\n');
      }

      buffer.write('\n');

      // Pena individualizada final
      final double penaInd = d.calcularPenaIndividualizada();
      buffer.write('**▶ PENA INDIVIDUALIZADA:** ');
      buffer.write('${PenaUtils.formatPena(penaInd)}\n\n');
      buffer.write('---\n\n');
    }

    // 3. CONCURSO DE DELITOS
    buffer.write('## 3. CONCURSO DE DELITOS\n\n');
    
    final List<double> penas = delitos
        .map((Delito d) => d.calcularPenaIndividualizada())
        .toList();
    penas.sort((double a, double b) => b.compareTo(a));
    
    double penaConcurso = penas[0];

    buffer.write('**Tipo de concurso:** ${_getNombreConcurso(concurso)}\n\n');
    
    if (concurso == TipoConcurso.real && delitos.length > 1) {
      buffer.write('**Cálculo según Art. 88 CP (Concurso real):**\n');
      buffer.write('```\n');
      buffer.write('Pena base (delito más grave):\n');
      buffer.write('${PenaUtils.formatPena(penas[0])}\n');
      
      for (int i = 1; i < penas.length; i++) {
        final double inc = penas[i] * 0.5;
        buffer.write('+ 1/2 de ${PenaUtils.formatPena(penas[i])} =\n');
        buffer.write('${PenaUtils.formatPena(inc)}\n');
        penaConcurso += inc;
      }
      
      buffer.write('────────────────────────────────\n');
      buffer.write('= SUBTOTAL: ${PenaUtils.formatPena(penaConcurso)}\n');
      buffer.write('```\n');
    } else if (concurso == TipoConcurso.ideal) {
      buffer.write('**Según Art. 98 CP (Concurso ideal):**\n');
      buffer.write('se aplica la pena más grave.\n');
      buffer.write('```\n');
      buffer.write('Pena aplicada: ${PenaUtils.formatPena(penas[0])}\n');
      buffer.write('```\n');
      penaConcurso = penas[0];
    } else {
      buffer.write('No aplica concurso (único delito).\n');
    }
    
    buffer.write('\n');

    // Límite constitucional de 30 años
    if (penaConcurso > 30) {
      buffer.write('**Límite máximo (Art. 44 CRBV y Art. 94 CP):** 30 años\n');
      buffer.write('```\n');
      buffer.write('Pena ajustada: ${PenaUtils.formatPena(30)}\n');
      buffer.write('```\n');
      penaConcurso = 30;
      buffer.write('\n');
    }

    // 4. ADMISIÓN DE HECHOS
    if (admisionHechos) {
      buffer.write('## 4. ADMISIÓN DE HECHOS (Art. 375 COPP)\n\n');
      
      final double descuento = penaConcurso * fraccionAdmision;
      final double penaFinal = penaConcurso - descuento;
      
      buffer.write('| Concepto | Valor |\n');
      buffer.write('|----------|-------|\n');
      buffer.write('| Pena base | ${PenaUtils.formatPena(penaConcurso)} |\n');
      buffer.write('| Rebaja aplicada | ${_fraccionTexto(fraccionAdmision)} =\n');
      buffer.write('${PenaUtils.formatPena(descuento)} |\n');
      buffer.write('| **Pena con admisión** | **${PenaUtils.formatPena(penaFinal)}** |\n\n');
      
      penaConcurso = penaFinal;
    }

    // 5. PENA DEFINITIVA
    buffer.write('## 5. PENA DEFINITIVA A IMPONER\n\n');
    buffer.write('> **${PenaUtils.formatPena(penaConcurso)}**\n\n');

    // 6. CÓMPUTO (si existe)
    if (computo != null) {
      buffer.write('## 6. CÓMPUTO DE PENA\n\n');
      buffer.write('| Concepto | Fecha / Duración |\n');
      buffer.write('|----------|------------------|\n');
      buffer.write('| Fecha de detención | ');
      buffer.write('${_formatearFecha(computo.fechaDetencion)} |\n');
      
      if (computo.fechaCondena != null) {
        buffer.write('| Fecha de condena | ');
        buffer.write('${_formatearFecha(computo.fechaCondena!)} |\n');
      }
      
      buffer.write('| Tiempo detenido | ');
      buffer.write('${computo.tiempoDetenidoTexto} |\n');
      buffer.write('| Tiempo restante por cumplir | ');
      buffer.write('${computo.tiempoRestanteTexto} |\n');
      buffer.write('| Fecha de cumplimiento estimada |\n');
      buffer.write('${_formatearFecha(computo.fechaCumplimiento)} |\n\n');
    }

    // 7. FUNDAMENTACIÓN JURÍDICA
    buffer.write('## 7. FUNDAMENTACIÓN JURÍDICA\n\n');
    buffer.write('La individualización judicial de la pena constituye una fase\n');
    buffer.write('esencial del proceso penal, donde el juez debe ajustar la sanción\n');
    buffer.write('al hecho concreto y a las circunstancias personales del acusado,\n');
    buffer.write('respetando los límites legales y los principios de proporcionalidad\n');
    buffer.write('y necesidad. En tal sentido, la jurisprudencia patria (Véase\n');
    buffer.write('Sentencia Nº 056 de la Sala de Casación Penal del TSJ, expediente\n');
    buffer.write('2023-0012) ha reiterado que la dosimetría penal debe ser **expresa,\n');
    buffer.write('motivada y matemáticamente verificable**, utilizando el término\n');
    buffer.write('medio del Art. 37 CP como punto de partida y aplicando de manera\n');
    buffer.write('acumulativa las atenuantes (Art. 74 CP) y agravantes (Art. 77 CP),\n');
    buffer.write('así como los modificadores por concurso real de delitos (Art. 88 CP)\n');
    buffer.write('o admisión de hechos (Art. 375 COPP). El presente informe refleja\n');
    buffer.write('dicha metodología, garantizando la transparencia del cómputo.\n\n');
    buffer.write('---\n\n');
    buffer.write('**Penalex VE** – Herramienta profesional de apoyo a la decisión\n');
    buffer.write('judicial\n');
    buffer.write('*Dosimetría Penal Venezolana | Conforme al Código Penal y Leyes\n');
    buffer.write('Especiales*\n');

    return buffer.toString();
  }
}
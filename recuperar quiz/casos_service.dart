import '../models/caso_hipotetico_model.dart';
import '../data/quiz_questions_data.dart';

/// Servicio para gestionar casos hipotéticos y sus respuestas
/// Sistema anti-trampa: fundamentación solo si correcta, pistas vagas si incorrecta
class CasosService {
  
  /// Obtiene un caso aleatorio para un nivel
  static CasoHipotetico getCasoParaNivel(int nivel) {
    return QuizQuestionsData.getCasoForLevel(nivel);
  }

  /// Verifica respuesta y retorna resultado
  static ResultadoRespuesta verificarRespuesta({
    required CasoHipotetico caso,
    required int respuestaUsuario,
    required int vecesIntentadas,
  }) {
    final correcto = respuestaUsuario == caso.respuestaCorrecta;

    if (correcto) {
      // ✅ CORRECTO: Devolver fundamentación completa
      return ResultadoRespuesta(
        correcto: true,
        fundamentacion: _getFundamentacion(caso),
        mensaje: _getMensajeExito(vecesIntentadas),
      );
    } else {
      // ❌ INCORRECTO: Devolver pista vaga
      return ResultadoRespuesta(
        correcto: false,
        pista: _getPistaVaga(caso, vecesIntentadas),
        bloqueoCaso: vecesIntentadas >= 3,
        mensaje: _getMensajeError(vecesIntentadas),
      );
    }
  }

  /// Genera fundamentación legal (solo si respuesta correcta)
  static Fundamentacion _getFundamentacion(CasoHipotetico caso) {
    final fundamentaciones = _fundamentacionesMap[caso.delitoBase] ?? _fundamentacionDefault;
    
    return Fundamentacion(
      id: 'fund_${caso.id}',
      casoId: caso.id,
      explicacion: fundamentaciones['explicacion'] as String,
      articulos: (fundamentaciones['articulos'] as List)
          .map((a) => ArticuloReferencia(
                codigo: a['codigo'] as String,
                articulo: a['articulo'] as String,
                texto: a['texto'] as String,
              ))
          .toList(),
      sentenciasIds: List<String>.from(fundamentaciones['sentencias'] as List),
      jurisprudenciasIds: List<String>.from(fundamentaciones['jurisprudencias'] as List),
    );
  }

  /// Genera pista vaga (NO revela respuesta)
  static Pista _getPistaVaga(CasoHipotetico caso, int nivel) {
    final pistas = _pistasMap[caso.delitoBase] ?? _pistasDefault;
    final textoNivel = nivel <= 3 ? pistas[nivel - 1] : pistas.last;
    
    return Pista(
      id: 'pista_${caso.id}_$nivel',
      casoId: caso.id,
      nivelPista: nivel,
      textoPista: textoNivel as String,
      articulosSugeridos: null, // NO dar artículos específicos
      busquedaSugerida: _getBusquedaSugerida(caso),
    );
  }

  static String _getMensajeExito(int intentos) {
    if (intentos == 1) return '¡Perfecto! Respuesta correcta al primer intento 🎯';
    if (intentos == 2) return '¡Correcto! Segunda oportunidad aprovechada ✓';
    return '¡Correcto! Has demostrado persistencia ⚖️';
  }

  static String _getMensajeError(int intentos) {
    if (intentos == 1) return 'Respuesta incorrecta. Analiza los elementos del caso.';
    if (intentos == 2) return 'Incorrecto nuevamente. Última oportunidad antes de usar apelación.';
    return 'Caso bloqueado. Usa una apelación para desbloquearlo o espera.';
  }

  static String? _getBusquedaSugerida(CasoHipotetico caso) {
    return 'Revisa: ${caso.delitoBase} en Código Penal Venezolano';
  }

  // ========== MAPA DE FUNDAMENTACIONES ==========
  
  static final Map<String, Map<String, dynamic>> _fundamentacionesMap = {
    'Tentativa de Hurto': {
      'explicacion': 'La tentativa se configura cuando el autor inicia la ejecución del delito pero no lo consuma por causas ajenas a su voluntad. En este caso, José realizó actos de apoderamiento pero fue interrumpido.',
      'articulos': [
        {'codigo': 'CP', 'articulo': 'Art. 80', 'texto': 'Tentativa: quien con el fin de cometer un delito comienza su ejecución pero no lo consuma por causas independientes de su voluntad'},
        {'codigo': 'CP', 'articulo': 'Art. 453', 'texto': 'Hurto: quien se apodere de cosa mueble ajena para aprovecharse de ella'},
      ],
      'sentencias': ['TSJ-SCP-2015-0234', 'TSJ-SCP-2018-0567'],
      'jurisprudencias': [],
    },
    'Legítima Defensa': {
      'explicacion': 'La legítima defensa exime de responsabilidad cuando hay agresión ilegítima, necesidad racional del medio empleado y falta de provocación. María cumple estos requisitos.',
      'articulos': [
        {'codigo': 'CP', 'articulo': 'Art. 65.3', 'texto': 'No es punible: el que obra en defensa de su propia persona o derecho'},
        {'codigo': 'CP', 'articulo': 'Art. 425', 'texto': 'Lesiones en legítima defensa: quedan exentas de pena'},
      ],
      'sentencias': ['TSJ-SCP-2016-0889', 'TSJ-SCP-2019-1234'],
      'jurisprudencias': [],
    },
    'Complicidad': {
      'explicacion': 'El cómplice es quien coopera a la ejecución del hecho con actos anteriores o simultáneos. Pedro facilitó el transporte conscientemente.',
      'articulos': [
        {'codigo': 'CP', 'articulo': 'Art. 84', 'texto': 'Cómplice: quien haya cooperado a la ejecución del hecho con actos anteriores o simultáneos'},
      ],
      'sentencias': ['TSJ-SCP-2017-0445'],
      'jurisprudencias': [],
    },
    'Error de Tipo': {
      'explicacion': 'El error de tipo esencial excluye el dolo cuando el autor desconoce un elemento del tipo penal. Carlos creía disparar a un animal.',
      'articulos': [
        {'codigo': 'CP', 'articulo': 'Art. 61', 'texto': 'Error de hecho esencial e invencible: excluye la responsabilidad'},
        {'codigo': 'CP', 'articulo': 'Art. 409', 'texto': 'Homicidio culposo: si el error es vencible'},
      ],
      'sentencias': ['TSJ-SCP-2014-0778'],
      'jurisprudencias': [],
    },
    'Autoría Mediata': {
      'explicacion': 'El autor mediato comete el delito utilizando a otro como instrumento. El jefe usa la subordinación del menor para ejecutar el robo.',
      'articulos': [
        {'codigo': 'CP', 'articulo': 'Art. 83', 'texto': 'Autor: quien ejecuta el hecho por sí o valiéndose de otro'},
      ],
      'sentencias': ['TSJ-SCP-2018-0991'],
      'jurisprudencias': [],
    },
  };

  static final Map<String, dynamic> _fundamentacionDefault = {
    'explicacion': 'La fundamentación se basa en la correcta interpretación de los elementos del tipo penal y las circunstancias del caso concreto.',
    'articulos': [
      {'codigo': 'CP', 'articulo': 'Art. 1', 'texto': 'Principio de legalidad'},
    ],
    'sentencias': [],
    'jurisprudencias': [],
  };

  // ========== MAPA DE PISTAS VAGAS (NO revelan respuesta) ==========
  
  static final Map<String, List<String>> _pistasMap = {
    'Tentativa de Hurto': [
      'Analiza si el delito se consumó o quedó en fase de ejecución.',
      'Considera el momento en que fue interrumpida la acción.',
      'Revisa la diferencia entre consumación y tentativa punible.',
    ],
    'Legítima Defensa': [
      'Evalúa si hubo agresión ilegítima previa.',
      'Analiza la proporcionalidad del medio empleado.',
      'Considera las circunstancias de necesidad de defensa.',
    ],
    'Complicidad': [
      'Diferencia entre autor, cómplice y encubridor.',
      'Analiza el momento y tipo de cooperación.',
      'Considera el grado de conocimiento del plan.',
    ],
    'Error de Tipo': [
      'Evalúa si hubo intención o error sobre los hechos.',
      'Analiza el conocimiento del autor al actuar.',
      'Diferencia entre error de tipo y error de prohibición.',
    ],
    'Autoría Mediata': [
      'Considera quién tiene el dominio del hecho.',
      'Analiza el uso de terceros como instrumentos.',
      'Evalúa la relación de subordinación.',
    ],
  };

  static final List<String> _pistasDefault = [
    'Revisa los elementos del tipo penal aplicable.',
    'Analiza las circunstancias específicas del caso.',
    'Consulta la doctrina sobre este tipo de delitos.',
  ];
}

import '../models/caso_hipotetico_model.dart';
import '../data/quiz_questions_data.dart';

/// Servicio para gestionar casos hipotéticos y sus respuestas
class CasosService {
  /// Obtiene un caso para el nivel
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
      return ResultadoRespuesta(
        correcto: true,
        fundamentacion: _getFundamentacion(caso),
        mensaje: _getMensajeExito(vecesIntentadas),
      );
    } else {
      return ResultadoRespuesta(
        correcto: false,
        pista: _getPistaVaga(caso, vecesIntentadas),
        bloqueoCaso: vecesIntentadas >= 3,
        mensaje: _getMensajeError(vecesIntentadas),
      );
    }
  }

  static Fundamentacion _getFundamentacion(CasoHipotetico caso) {
    final fundamentaciones = _fundamentacionesMap[caso.delitoBase] ??
        _fundamentacionDefault;

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
      jurisprudenciasIds:
          List<String>.from(fundamentaciones['jurisprudencias'] as List),
    );
  }

  static Pista _getPistaVaga(CasoHipotetico caso, int nivel) {
    final pistas = _pistasMap[caso.delitoBase] ?? _pistasDefault;
    final textoNivel = nivel <= pistas.length ? pistas[nivel - 1] : pistas.last;

    return Pista(
      id: 'pista_${caso.id}_$nivel',
      casoId: caso.id,
      nivelPista: nivel,
      textoPista: textoNivel,
      busquedaSugerida: 'Revisa: ${caso.delitoBase} en Código Penal',
    );
  }

  static String _getMensajeExito(int intentos) {
    if (intentos == 1) return '¡Perfecto! Respuesta correcta al primer intento 🎯';
    if (intentos == 2) return '¡Correcto! Segunda oportunidad aprovechada ✓';
    return '¡Correcto! Has demostrado persistencia ⚖️';
  }

  static String _getMensajeError(int intentos) {
    if (intentos == 1) return 'Respuesta incorrecta. Analiza los elementos del caso.';
    if (intentos == 2) return 'Incorrecto nuevamente. Última oportunidad.';
    return 'Caso bloqueado. Usa una apelación para desbloquearlo.';
  }

  static final Map<String, Map<String, dynamic>> _fundamentacionesMap = {
    'Tentativa de Hurto': {
      'explicacion':
          'La tentativa se configura cuando el autor inicia la ejecución del delito pero no lo consuma por causas ajenas a su voluntad.',
      'articulos': [
        {'codigo': 'CP', 'articulo': 'Art. 80', 'texto': 'Tentativa: quien con el fin de cometer un delito comienza su ejecución pero no lo consuma'},
        {'codigo': 'CP', 'articulo': 'Art. 453', 'texto': 'Hurto: quien se apodere de cosa mueble ajena'},
      ],
      'sentencias': ['TSJ-SCP-2015-0234'],
      'jurisprudencias': [],
    },
    'Legítima Defensa': {
      'explicacion':
          'La legítima defensa exime de responsabilidad cuando hay agresión ilegítima, necesidad racional del medio empleado y falta de provocación.',
      'articulos': [
        {'codigo': 'CP', 'articulo': 'Art. 65.3', 'texto': 'No es punible: el que obra en defensa de su propia persona'},
      ],
      'sentencias': ['TSJ-SCP-2016-0889'],
      'jurisprudencias': [],
    },
    'Homicidio Calificado': {
      'explicacion':
          'El homicidio calificado por premeditación implica reflexión y tiempo entre la decisión y la ejecución.',
      'articulos': [
        {'codigo': 'CP', 'articulo': 'Art. 406.1', 'texto': 'Homicidio calificado por premeditación'},
      ],
      'sentencias': ['TSJ-SCP-2017-0445'],
      'jurisprudencias': [],
    },
    'Femicidio': {
      'explicacion':
          'El femicidio es la muerte de una mujer por razones de género, con antecedentes de violencia.',
      'articulos': [
        {'codigo': 'LODMVLV', 'articulo': 'Art. 15', 'texto': 'Femicidio: quien cause la muerte de una mujer'},
      ],
      'sentencias': ['TSJ-SCP-2018-0991'],
      'jurisprudencias': [],
    },
    'Robo Agravado': {
      'explicacion':
          'El robo agravado se configura por el uso de armas, nocturnidad, o pluralidad de agentes.',
      'articulos': [
        {'codigo': 'CP', 'articulo': 'Art. 458', 'texto': 'Robo agravado por armas y nocturnidad'},
      ],
      'sentencias': ['TSJ-SCP-2016-0556'],
      'jurisprudencias': [],
    },
    'Estafa': {
      'explicacion':
          'La estafa requiere engaño, inducción a error y perjuicio patrimonial.',
      'articulos': [
        {'codigo': 'CP', 'articulo': 'Art. 462', 'texto': 'Estafa: quien con artificios o medios engañosos induzca en error'},
      ],
      'sentencias': ['TSJ-SCP-2015-0778'],
      'jurisprudencias': [],
    },
    'Tráfico de Drogas': {
      'explicacion':
          'El tráfico internacional de drogas tiene penas agravadas por la cantidad y cruce de fronteras.',
      'articulos': [
        {'codigo': 'LOD', 'articulo': 'Art. 149', 'texto': 'Tráfico ilícito de sustancias estupefacientes'},
      ],
      'sentencias': ['TSJ-SCP-2019-0234'],
      'jurisprudencias': [],
    },
    'Corrupción': {
      'explicacion':
          'La concusión es el abuso del cargo público para exigir beneficios indebidos.',
      'articulos': [
        {'codigo': 'LAC', 'articulo': 'Art. 54', 'texto': 'Concusión: funcionario que exija beneficio indebido'},
      ],
      'sentencias': ['TSJ-SCP-2017-0889'],
      'jurisprudencias': [],
    },
    'Flagrancia': {
      'explicacion':
          'La cuasi-flagrancia permite detención sin orden cuando hay persecución inmediata tras el delito.',
      'articulos': [
        {'codigo': 'COPP', 'articulo': 'Art. 234', 'texto': 'Flagrancia: comisión actual o inmediatamente después del delito'},
      ],
      'sentencias': ['TSJ-SCP-2016-0445'],
      'jurisprudencias': [],
    },
  };

  static final Map<String, dynamic> _fundamentacionDefault = {
    'explicacion':
        'La fundamentación se basa en la correcta interpretación de los elementos del tipo penal.',
    'articulos': [
      {'codigo': 'CP', 'articulo': 'Art. 1', 'texto': 'Principio de legalidad'},
    ],
    'sentencias': [],
    'jurisprudencias': [],
  };

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
  };

  static final List<String> _pistasDefault = [
    'Revisa los elementos del tipo penal aplicable.',
    'Analiza las circunstancias específicas del caso.',
    'Consulta la doctrina sobre este tipo de delitos.',
  ];
}

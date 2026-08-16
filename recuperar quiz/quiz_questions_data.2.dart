import '../models/caso_hipotetico_model.dart';

/// Banco de 100 preguntas de prueba - Derecho Penal Venezolano
/// Testing inicial del sistema de quiz gamificado
class QuizQuestionsData {
  
  /// Obtiene un caso para un nivel específico (1-100)
  static CasoHipotetico getCasoForLevel(int nivel) {
    final allCases = getAllCases();
    if (nivel > 0 && nivel <= allCases.length) {
      return allCases[nivel - 1];
    }
    return allCases[0]; // Fallback
  }

  /// Retorna todas las 100 preguntas organizadas
  static List<CasoHipotetico> getAllCases() {
    return _generateTestCases();
  }

  /// Genera 100 casos de prueba automáticamente
  static List<CasoHipotetico> _generateTestCases() {
    List<CasoHipotetico> cases = [];
    int caseId = 1;

    // Parte General (20 casos)
    for (int i = 0; i < 20; i++) {
      cases.add(_createCase(
        caseId++,
        'Parte General',
        _parteGeneralTemplates[i % _parteGeneralTemplates.length],
      ));
    }

    // Delitos contra Personas (20 casos)
    for (int i = 0; i < 20; i++) {
      cases.add(_createCase(
        caseId++,
        'Delitos contra Personas',
        _delitosPersonasTemplates[i % _delitosPersonasTemplates.length],
      ));
    }

    // Delitos contra Propiedad (20 casos)
    for (int i = 0; i < 20; i++) {
      cases.add(_createCase(
        caseId++,
        'Delitos contra Propiedad',
        _delitosPropiedadTemplates[i % _delitosPropiedadTemplates.length],
      ));
    }

    // COPP y Procedimiento (20 casos)
    for (int i = 0; i < 20; i++) {
      cases.add(_createCase(
        caseId++,
        'COPP',
        _coppTemplates[i % _coppTemplates.length],
      ));
    }

    // Drogas y Leyes Especiales (20 casos)
    for (int i = 0; i < 20; i++) {
      cases.add(_createCase(
        caseId++,
        'Drogas y Especiales',
        _drogasTemplates[i % _drogasTemplates.length],
      ));
    }

    return cases;
  }

  static CasoHipotetico _createCase(int id, String categoria, Map<String, dynamic> template) {
    return CasoHipotetico(
      id: 'caso_$id',
      nivel: id,
      poolId: 1,
      delitoBase: template['delito'] as String,
      contextoNarrativo: template['contexto'] as String,
      opciones: List<String>.from(template['opciones'] as List),
      respuestaCorrecta: template['correcta'] as int,
      dificultad: (id / 20).ceil(),
    );
  }

  // ========== TEMPLATES PARTE GENERAL ==========
  static final List<Map<String, dynamic>> _parteGeneralTemplates = [
    {
      'delito': 'Tentativa de Hurto',
      'contexto': 'José intenta robar un celular de una mesa en un café pero el dueño lo detiene antes de salir. ¿Calificación?',
      'opciones': ['Hurto consumado', 'Tentativa de hurto', 'Apropiación indebida', 'Acto preparatorio'],
      'correcta': 1,
    },
    {
      'delito': 'Legítima Defensa',
      'contexto': 'María es atacada con cuchillo y se defiende con piedra causando lesiones al agresor. ¿Situación jurídica?',
      'opciones': ['Lesiones graves', 'Legítima defensa', 'Exceso en defensa', 'Riña mutua'],
      'correcta': 1,
    },
    {
      'delito': 'Complicidad',
      'contexto': 'Pedro conduce el auto mientras su amigo roba un banco, consciente del delito. ¿Su rol?',
      'opciones': ['Cómplice necesario', 'Autor inmediato', 'Encubridor', 'Sin responsabilidad'],
      'correcta': 0,
    },
    {
      'delito': 'Error de Tipo',
      'contexto': 'Carlos dispara pensando que caza un animal pero resulta ser una persona. ¿Qué figura aplica?',
      'opciones': ['Homicidio intencional', 'Homicidio culposo', 'Error de tipo esencial', 'Caso fortuito'],
      'correcta': 2,
    },
    {
      'delito': 'Autoría Mediata',
      'contexto': 'Un jefe ordena a empleado menor cometer robo usando su autoridad. ¿Conducta del jefe?',
      'opciones': ['Instigador', 'Autor mediato', 'Cómplice', 'Sin responsabilidad'],
      'correcta': 1,
    },
  ];

  // ========== TEMPLATES DELITOS CONTRA PERSONAS ==========
  static final List<Map<String, dynamic>> _delitosPersonasTemplates = [
    {
      'delito': 'Homicidio Calificado',
      'contexto': 'Luis planea 2 semanas el asesinato comprando armas y vigilando a su enemigo. Finalmente lo ejecuta. ¿Calificación?',
      'opciones': ['Homicidio simple', 'Homicidio calificado por premeditación', 'Homicidio culposo', 'Homicidio en riña'],
      'correcta': 1,
    },
    {
      'delito': 'Lesiones Gravísimas',
      'contexto': 'Antonio hiere a su vecino causando pérdida permanente de un ojo durante una pelea. ¿Tipificación?',
      'opciones': ['Lesiones leves', 'Lesiones graves', 'Lesiones gravísimas', 'Tentativa de homicidio'],
      'correcta': 2,
    },
    {
      'delito': 'Femicidio',
      'contexto': 'Roberto mata a su expareja por celos y control. Hay antecedentes de violencia. ¿Qué delito configura?',
      'opciones': ['Homicidio simple', 'Homicidio calificado', 'Femicidio', 'Parricidio'],
      'correcta': 2,
    },
    {
      'delito': 'Aborto Consentido',
      'contexto': 'Una mujer decide interrumpir su embarazo en el 4to mes con ayuda de terceros. ¿Situación jurídica?',
      'opciones': ['No hay delito', 'Aborto culposo', 'Aborto consentido', 'Lesiones al feto'],
      'correcta': 2,
    },
    {
      'delito': 'Secuestro Simple',
      'contexto': 'Marcos retiene a Sandra contra su voluntad por 48 horas sin pedir rescate. ¿Qué delito comete?',
      'opciones': ['Privación ilegítima', 'Secuestro simple', 'Secuestro extorsivo', 'Detención ilegal'],
      'correcta': 1,
    },
  ];

  // ========== TEMPLATES DELITOS CONTRA PROPIEDAD ==========
  static final List<Map<String, dynamic>> _delitosPropiedadTemplates = [
    {
      'delito': 'Robo Agravado',
      'contexto': 'Tres sujetos armados asaltan farmacia de madrugada llevándose dinero y medicinas. ¿Calificación?',
      'opciones': ['Hurto calificado', 'Robo simple', 'Robo agravado', 'Extorsión'],
      'correcta': 2,
    },
    {
      'delito': 'Hurto de Vehículo',
      'contexto': 'Pedro toma auto ajeno sin violencia y lo usa temporalmente antes de abandonarlo. ¿Delito?',
      'opciones': ['Hurto de uso', 'Robo de vehículo', 'Apropiación indebida', 'Receptación'],
      'correcta': 0,
    },
    {
      'delito': 'Estafa Agravada',
      'contexto': 'Juan vende falsos bonos gubernamentales a 20 ancianos defraudando más de 50,000 USD. ¿Tipificación?',
      'opciones': ['Estafa simple', 'Estafa agravada', 'Apropiación indebida', 'Fraude'],
      'correcta': 1,
    },
    {
      'delito': 'Daño Calificado',
      'contexto': 'Miguel incendia cultivo de su vecino causando pérdida total de cosecha. ¿Qué delito?',
      'opciones': ['Daño simple', 'Daño calificado por incendio', 'Sabotaje agrícola', 'Terrorismo'],
      'correcta': 1,
    },
    {
      'delito': 'Extorsión',
      'contexto': 'Banda amenaza a comerciante con quemar su negocio si no paga "vacuna" mensual. ¿Delito cometido?',
      'opciones': ['Amenazas simples', 'Robo', 'Extorsión', 'Asociación ilícita'],
      'correcta': 2,
    },
  ];

  // ========== TEMPLATES COPP ==========
  static final List<Map<String, dynamic>> _coppTemplates = [
    {
      'delito': 'Flagrancia',
      'contexto': 'Policía detiene a sujeto 20 minutos después del robo con objetos robados. ¿Hay flagrancia?',
      'opciones': ['No hay flagrancia', 'Flagrancia inmediata', 'Cuasi-flagrancia', 'Detención ilegal'],
      'correcta': 2,
    },
    {
      'delito': 'Medida Cautelar',
      'contexto': 'Juez ordena arresto domiciliario a imputado primario por hurto de 200 dólares. ¿Es proporcional?',
      'opciones': ['Sí, es proporcional', 'No, debe ser privativa', 'No, debe ser presentación', 'Es ilegal'],
      'correcta': 2,
    },
    {
      'delito': 'Prueba Ilícita',
      'contexto': 'Policía entra sin orden a casa y encuentra drogas. ¿Validez de la prueba?',
      'opciones': ['Válida por flagrancia', 'Válida por urgencia', 'Ilícita por violación domicilio', 'Válida con ratificación'],
      'correcta': 2,
    },
    {
      'delito': 'Acusación Fiscal',
      'contexto': 'Fiscal presenta acusación sin señalar calificación jurídica precisa. ¿Es admisible?',
      'opciones': ['Sí, es admisible', 'No, falta tipificación', 'Admisible si hay pruebas', 'Inadmisible por forma'],
      'correcta': 1,
    },
    {
      'delito': 'Recurso Apelación',
      'contexto': 'Defensa apela sentencia condenatoria 6 días después de notificación. ¿Está en término?',
      'opciones': ['Sí, dentro de plazo', 'No, extemporáneo', 'Depende del delito', 'Requiere prórroga'],
      'correcta': 0,
    },
  ];

  // ========== TEMPLATES DROGAS Y LEYES ESPECIALES ==========
  static final List<Map<String, dynamic>> _drogasTemplates = [
    {
      'delito': 'Tráfico de Drogas',
      'contexto': 'Interceptan a María con 2kg de cocaína en aeropuerto. Es su primer delito. ¿Calificación?',
      'opciones': ['Microtráfico', 'Tráfico agravado', 'Posesión para consumo', 'Tráfico internacional'],
      'correcta': 3,
    },
    {
      'delito': 'Legitimación de Capitales',
      'contexto': 'Banco recibe depósitos fraccionados diarios de narcotraficante sin reportar. ¿Delito del banco?',
      'opciones': ['Cómplice narcotráfico', 'Legitimación capitales', 'Encubrimiento', 'Asociación ilícita'],
      'correcta': 1,
    },
    {
      'delito': 'Corrupción',
      'contexto': 'Juez acepta 5,000 dólares para dictar sentencia favorable. ¿Qué delito comete?',
      'opciones': ['Cohecho pasivo', 'Prevaricación', 'Peculado', 'Tráfico influencias'],
      'correcta': 0,
    },
    {
      'delito': 'Delitos Informáticos',
      'contexto': 'Hacker accede sin autorización a base datos bancaria y roba información clientes. ¿Delito?',
      'opciones': ['Hurto', 'Acceso indebido sistemas', 'Estafa informática', 'Sabotaje'],
      'correcta': 1,
    },
    {
      'delito': 'Trata de Personas',
      'contexto': 'Red capta jóvenes venezolanas con promesas laborales y las explota sexualmente en exterior. ¿Delito?',
      'opciones': ['Proxenetismo', 'Trata de personas', 'Secuestro', 'Explotación laboral'],
      'correcta': 1,
    },
  ];
}

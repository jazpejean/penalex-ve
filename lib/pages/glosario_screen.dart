import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/glosario_service.dart';

import '../config/app_colors.dart';
import '../widgets/app_drawer.dart';

class GlosarioScreen extends StatefulWidget {
  const GlosarioScreen({super.key});

  /// Términos del glosario (compartidos con el Buscador Jurídico).
  ///
  /// Prioriza los términos aprobados cargados desde Supabase
  /// (`glosario_terminos`); si aún no se cargaron (app sin red o en el primer
  /// instante), usa la lista local de respaldo. Se rellena con
  /// [precargarDesdeSupabase] (arranque) y en initState.
  static List<Map<String, String>> get terminos {
    final remotos = _GlosarioScreenState.terminosRemotos;
    if (remotos.isNotEmpty) return remotos;
    return _GlosarioScreenState.terminos;
  }

  /// Precarga los términos aprobados desde Supabase (usado en el arranque de
  /// la app para que el RAG y el buscador siempre tengan el glosario).
  static Future<void> precargarDesdeSupabase() async {
    final remotos = await GlosarioService.cargarDesdeSupabase();
    if (remotos.isNotEmpty) {
      _GlosarioScreenState.terminosRemotos = remotos;
    }
  }

  @override
  State<GlosarioScreen> createState() => _GlosarioScreenState();
}

class _GlosarioScreenState extends State<GlosarioScreen> {
  final TextEditingController _searchController = TextEditingController();

  /// Términos aprobados cargados desde Supabase (se rellenan en initState).
  static List<Map<String, String>> terminosRemotos = [];
  static bool _cargandoRemotos = false;

  // Glosario ampliado con más de 150 términos (RESPALDO)
  static const List<Map<String, String>> terminos = <Map<String, String>>[
    // A
    <String, String>{'term': 'Abogado', 'definition': 'Profesional del derecho que asesora, representa y defiende a las partes en un proceso judicial.'},
    <String, String>{'term': 'Absolución', 'definition': 'Declaración judicial que libera a una persona de la responsabilidad penal por el hecho imputado.'},
    <String, String>{'term': 'Acción penal', 'definition': 'Facultad del Estado o de la víctima para promover la persecución penal y solicitar el castigo del culpable.'},
    <String, String>{'term': 'Acusación', 'definition': 'Acto procesal mediante el cual el Ministerio Público o la víctima atribuye formalmente un delito a una persona.'},
    <String, String>{'term': 'Ad hoc', 'definition': 'Locución latina: "para esto". Designa a un tribunal o juez designado especialmente para un caso concreto.'},
    <String, String>{'term': 'Ad litem', 'definition': 'Locución latina: "para el litigio". Se aplica al representante nombrado para un proceso específico.'},
    <String, String>{'term': 'Agravante', 'definition': 'Circunstancia que aumenta la responsabilidad penal y, en consecuencia, la pena a imponer.'},
    <String, String>{'term': 'Alevosía', 'definition': 'Circunstancia agravante que consiste en cometer el delito a traición o sobre seguro, sin riesgo para el agresor.'},
    <String, String>{'term': 'Allanamiento', 'definition': 'Entrada y registro de un domicilio ordenado por autoridad judicial con fines de investigación.'},
    <String, String>{'term': 'Amnistía', 'definition': 'Ley que extingue la acción penal y la pena para determinados delitos, generalmente por motivos políticos.'},
    <String, String>{'term': 'Antijuridicidad', 'definition': 'Contrariedad de una conducta con el ordenamiento jurídico; elemento esencial del delito.'},
    <String, String>{'term': 'Apelación', 'definition': 'Recurso ordinario contra resoluciones judiciales para que un tribunal superior las revise.'},
    <String, String>{'term': 'Arresto', 'definition': 'Pena privativa de libertad de corta duración, generalmente cumplida en establecimientos locales.'},
    <String, String>{'term': 'Atenuante', 'definition': 'Circunstancia que disminuye la responsabilidad penal y permite rebajar la pena.'},
    <String, String>{'term': 'Audiencia preliminar', 'definition': 'Acto procesal en el que se decide si la acusación es admisible y se prepara el juicio oral.'},
    <String, String>{'term': 'Autor', 'definition': 'Persona que realiza por sí misma el hecho punible o se sirve de otro como instrumento.'},
    // B
    <String, String>{'term': 'Bien jurídico', 'definition': 'Interés o valor protegido por la norma penal (vida, propiedad, libertad, etc.).'},
    <String, String>{'term': 'Bis in idem', 'definition': 'Principio que prohíbe sancionar dos veces a una persona por el mismo hecho.'},
    // C
    <String, String>{'term': 'Cadena de custodia', 'definition': 'Procedimiento que garantiza la integridad y autenticidad de las evidencias desde su recolección hasta el juicio.'},
    <String, String>{'term': 'Calificación jurídica', 'definition': 'Determinación del tipo penal aplicable a los hechos investigados.'},
    <String, String>{'term': 'Casación', 'definition': 'Recurso extraordinario ante el Tribunal Supremo para anular sentencias que violen la ley.'},
    <String, String>{'term': 'Causa de justificación', 'definition': 'Circunstancia que elimina la antijuridicidad de una conducta típica (legítima defensa, estado de necesidad, etc.).'},
    <String, String>{'term': 'Cómplice', 'definition': 'Persona que coopera en la ejecución del delito sin ser autor principal.'},
    <String, String>{'term': 'Concurso de delitos', 'definition': 'Situación en que una persona comete varios delitos independientes (concurso real) o con una sola acción infringe varias normas (concurso ideal).'},
    <String, String>{'term': 'Concurso ideal', 'definition': 'Una sola acción constituye dos o más delitos. Se aplica la pena del delito más grave.'},
    <String, String>{'term': 'Concurso real', 'definition': 'Varias acciones independientes constituyen varios delitos. Se acumulan las penas con límites legales.'},
    <String, String>{'term': 'Confesión', 'definition': 'Declaración del imputado reconociendo su participación en el hecho punible.'},
    <String, String>{'term': 'Confiscación', 'definition': 'Pena accesoria que priva definitivamente de la propiedad de bienes relacionados con el delito.'},
    <String, String>{'term': 'Consumación', 'definition': 'Realización completa del tipo penal; el delito se ha perfeccionado.'},
    <String, String>{'term': 'Contumacia', 'definition': 'Rebeldía del imputado que, debidamente citado, no comparece al proceso.'},
    <String, String>{'term': 'Corpus delicti', 'definition': 'Locución latina: "cuerpo del delito". Conjunto de elementos materiales que prueban la existencia del hecho punible.'},
    <String, String>{'term': 'Cosa juzgada', 'definition': 'Autoridad y eficacia de una sentencia firme, que impide un nuevo juicio sobre el mismo asunto.'},
    <String, String>{'term': 'Culpa', 'definition': 'Forma de responsabilidad en que el resultado dañoso se produce por imprudencia, negligencia o impericia, sin intención de causarlo.'},
    <String, String>{'term': 'Culpabilidad', 'definition': 'Juicio de reproche personal al autor de un hecho típico y antijurídico.'},
    // D
    <String, String>{'term': 'Debido proceso', 'definition': 'Garantía constitucional que asegura un juicio justo, con respeto a los derechos de defensa, prueba y juez natural.'},
    <String, String>{'term': 'Defensa', 'definition': 'Derecho del imputado a ser asistido por un abogado y a contradecir la acusación.'},
    <String, String>{'term': 'Delito', 'definition': 'Conducta típica, antijurídica y culpable sancionada con una pena.'},
    <String, String>{'term': 'Delito continuado', 'definition': 'Varias acciones homogéneas ejecutadas con unidad de resolución que se consideran un solo delito.'},
    <String, String>{'term': 'Delito flagrante', 'definition': 'El que se está cometiendo o acaba de cometerse, permitiendo la detención sin orden judicial.'},
    <String, String>{'term': 'Delito frustrado', 'definition': 'Aquel en que el autor realiza todos los actos necesarios para consumarlo, pero el resultado no se produce por causas ajenas a su voluntad.'},
    <String, String>{'term': 'Denuncia', 'definition': 'Acto por el cual se pone en conocimiento de la autoridad la comisión de un hecho punible.'},
    <String, String>{'term': 'Desistimiento', 'definition': 'Renuncia a continuar con la acción penal o el recurso interpuesto.'},
    <String, String>{'term': 'Detención preventiva', 'definition': 'Medida cautelar que priva de libertad al imputado antes de la sentencia para asegurar el proceso.'},
    <String, String>{'term': 'Dolo', 'definition': 'Intención deliberada de cometer un delito con conocimiento de su ilicitud.'},
    <String, String>{'term': 'Dolo eventual', 'definition': 'El autor prevé el resultado como posible y, aunque no lo desea directamente, acepta su producción.'},
    <String, String>{'term': 'Dosimetría penal', 'definition': 'Cálculo y determinación de la pena concreta aplicable según las reglas del Código Penal.'},
    // E
    <String, String>{'term': 'Ejecución penal', 'definition': 'Fase del proceso en que se cumple la sanción impuesta por sentencia firme.'},
    <String, String>{'term': 'Encubrimiento', 'definition': 'Delito consistente en ayudar al autor de un hecho punible a eludir la acción de la justicia.'},
    <String, String>{'term': 'Ensañamiento', 'definition': 'Circunstancia agravante que consiste en aumentar deliberadamente el sufrimiento de la víctima.'},
    <String, String>{'term': 'Error de prohibición', 'definition': 'Creencia errónea de que la conducta es lícita; puede excluir la culpabilidad.'},
    <String, String>{'term': 'Error de tipo', 'definition': 'Falsa representación de los elementos del tipo penal; excluye el dolo.'},
    <String, String>{'term': 'Estado de necesidad', 'definition': 'Causa de justificación: se sacrifica un bien jurídico para salvar otro de mayor valor.'},
    <String, String>{'term': 'Estafa', 'definition': 'Delito que consiste en obtener un beneficio ilícito mediante engaño que induce a error a la víctima.'},
    <String, String>{'term': 'Excepción', 'definition': 'Mecanismo de defensa que alega un obstáculo al ejercicio de la acción penal.'},
    <String, String>{'term': 'Eximente', 'definition': 'Circunstancia que excluye la responsabilidad penal (inimputabilidad, legítima defensa, etc.).'},
    <String, String>{'term': 'Experticia', 'definition': 'Prueba pericial realizada por expertos en determinada ciencia, arte u oficio.'},
    <String, String>{'term': 'Extradición', 'definition': 'Procedimiento de entrega de un acusado o condenado por un Estado a otro que lo reclama.'},
    // F
    <String, String>{'term': 'Fallo', 'definition': 'Parte dispositiva de la sentencia que contiene la decisión del tribunal.'},
    <String, String>{'term': 'Femicidio', 'definition': 'Delito de homicidio cometido contra una mujer por razones de género u odio a su condición femenina.'},
    <String, String>{'term': 'Flagrancia', 'definition': 'Situación en que el delito se comete en presencia de testigos o el autor es perseguido inmediatamente.'},
    <String, String>{'term': 'Fuero', 'definition': 'Prerrogativa de ciertos funcionarios para ser juzgados por tribunales especiales.'},
    <String, String>{'term': 'Fundamentación', 'definition': 'Motivación jurídica y fáctica de una decisión judicial.'},
    // G
    <String, String>{'term': 'Garantías constitucionales', 'definition': 'Derechos fundamentales que protegen al ciudadano frente al poder punitivo del Estado.'},
    // H
    <String, String>{'term': 'Habeas corpus', 'definition': 'Locución latina: "que tengas el cuerpo". Acción constitucional para proteger la libertad individual contra detenciones ilegales.'},
    <String, String>{'term': 'Hecho punible', 'definition': 'Acción u omisión tipificada por la ley como delito o falta.'},
    <String, String>{'term': 'Homicidio', 'definition': 'Delito que consiste en matar a otra persona.'},
    <String, String>{'term': 'Homicidio calificado', 'definition': 'Homicidio agravado por circunstancias como alevosía, premeditación, ensañamiento o parentesco.'},
    <String, String>{'term': 'Homicidio concausal', 'definition': 'Muerte causada por la concurrencia de la acción del agente y circunstancias preexistentes desconocidas por él.'},
    <String, String>{'term': 'Homicidio culposo', 'definition': 'Muerte causada por imprudencia, negligencia o impericia, sin intención de matar.'},
    <String, String>{'term': 'Hurto', 'definition': 'Apoderamiento de una cosa mueble ajena sin violencia ni intimidación.'},
    // I
    <String, String>{'term': 'Imputabilidad', 'definition': 'Capacidad de una persona para comprender la ilicitud de su conducta y actuar conforme a esa comprensión.'},
    <String, String>{'term': 'Imputado', 'definition': 'Persona a quien se atribuye la comisión de un delito durante la fase de investigación.'},
    <String, String>{'term': 'In dubio pro reo', 'definition': 'Locución latina: "en la duda, a favor del reo". Principio que obliga a absolver si no hay certeza de culpabilidad.'},
    <String, String>{'term': 'In fraganti', 'definition': 'En el momento mismo de cometerse el delito.'},
    <String, String>{'term': 'Incidente', 'definition': 'Cuestión accesoria que se suscita durante el proceso y requiere decisión judicial.'},
    <String, String>{'term': 'Indemnización', 'definition': 'Compensación económica por los daños y perjuicios derivados del delito.'},
    <String, String>{'term': 'Indulto', 'definition': 'Perdón de la pena impuesta por sentencia firme, concedido por el Ejecutivo.'},
    <String, String>{'term': 'Inhabilitación', 'definition': 'Pena que priva del ejercicio de ciertos derechos, cargos o profesiones.'},
    <String, String>{'term': 'Inimputabilidad', 'definition': 'Incapacidad de ser considerado culpable por minoría de edad, trastorno mental u otra causa legal.'},
    <String, String>{'term': 'Injuria', 'definition': 'Delito contra el honor que consiste en ofender la dignidad de una persona.'},
    <String, String>{'term': 'Instrucción', 'definition': 'Fase del proceso penal dirigida a investigar los hechos y recabar pruebas.'},
    <String, String>{'term': 'Interés difuso', 'definition': 'Interés que pertenece a una colectividad indeterminada de personas.'},
    <String, String>{'term': 'Interés legítimo', 'definition': 'Situación jurídica que permite a una persona intervenir en un proceso por tener un vínculo con el objeto del mismo.'},
    <String, String>{'term': 'Iter criminis', 'definition': 'Locución latina: "camino del delito". Fases por las que atraviesa la comisión de un delito (ideación, preparación, ejecución, consumación).'},
    // J
    <String, String>{'term': 'Juez natural', 'definition': 'Principio que garantiza ser juzgado por el tribunal preestablecido por la ley, no por comisiones especiales.'},
    <String, String>{'term': 'Juicio oral', 'definition': 'Fase del proceso penal donde se practican las pruebas y se debate ante el juez de forma pública y oral.'},
    <String, String>{'term': 'Jurisdicción', 'definition': 'Potestad del Estado para administrar justicia a través de sus tribunales.'},
    <String, String>{'term': 'Jurisprudencia', 'definition': 'Conjunto de sentencias reiteradas de los tribunales que interpretan y aplican la ley.'},
    <String, String>{'term': 'Jus puniendi', 'definition': 'Locución latina: "derecho de castigar". Facultad exclusiva del Estado para imponer penas.'},
    // L
    <String, String>{'term': 'Legítima defensa', 'definition': 'Causa de justificación que exime de responsabilidad a quien repele una agresión ilegítima, actual o inminente.'},
    <String, String>{'term': 'Lesa humanidad', 'definition': 'Delitos graves contra la humanidad cometidos como parte de un ataque generalizado o sistemático.'},
    <String, String>{'term': 'Lesiones', 'definition': 'Delito que causa un daño a la integridad física o salud de una persona.'},
    <String, String>{'term': 'Libertad condicional', 'definition': 'Beneficio que permite al condenado cumplir el resto de la pena en libertad bajo ciertas condiciones.'},
    <String, String>{'term': 'Libertad bajo fianza', 'definition': 'Medida cautelar que permite la libertad del imputado mediante garantía económica.'},
    // M
    <String, String>{'term': 'Magistrado', 'definition': 'Juez integrante de un tribunal colegiado o del Tribunal Supremo de Justicia.'},
    <String, String>{'term': 'Medida cautelar', 'definition': 'Disposición judicial que restringe derechos del imputado para asegurar el proceso.'},
    <String, String>{'term': 'Medida de seguridad', 'definition': 'Sanción aplicable a inimputables peligrosos, consistente en internamiento o tratamiento.'},
    <String, String>{'term': 'Ministerio Público', 'definition': 'Órgano del Estado encargado de dirigir la investigación penal y ejercer la acción penal.'},
    <String, String>{'term': 'Motivación', 'definition': 'Exigencia legal de que las sentencias expresen las razones de hecho y de derecho que las fundamentan.'},
    <String, String>{'term': 'Multa', 'definition': 'Pena pecuniaria consistente en el pago de una cantidad de dinero al Estado.'},
    // N
    <String, String>{'term': 'Ne bis in idem', 'definition': 'Principio que prohíbe juzgar o sancionar dos veces a una persona por el mismo hecho.'},
    <String, String>{'term': 'Nulidad', 'definition': 'Sanción procesal que priva de efectos a un acto realizado con violación de formas esenciales.'},
    // O
    <String, String>{'term': 'Obiter dictum', 'definition': 'Locución latina: "dicho de paso". Opinión accesoria en una sentencia que no constituye precedente vinculante.'},
    <String, String>{'term': 'Objeto material', 'definition': 'Persona o cosa sobre la que recae físicamente la acción delictiva.'},
    <String, String>{'term': 'Objeto jurídico', 'definition': 'Bien jurídico protegido por la norma penal.'},
    <String, String>{'term': 'Omisión', 'definition': 'Delito que consiste en no realizar la acción debida (ej. omisión de socorro).'},
    <String, String>{'term': 'Orden de aprehensión', 'definition': 'Mandato judicial para la detención de una persona imputada.'},
    // P
    <String, String>{'term': 'Parrícida', 'definition': 'Persona que mata a un pariente cercano, especialmente ascendiente, descendiente o cónyuge.'},
    <String, String>{'term': 'Parte', 'definition': 'Sujeto que interviene en el proceso penal con legitimación para actuar (Ministerio Público, imputado, víctima).'},
    <String, String>{'term': 'Pena', 'definition': 'Sanción jurídica impuesta por el Estado al autor de un delito.'},
    <String, String>{'term': 'Pena accesoria', 'definition': 'Sanción que acompaña necesariamente a la pena principal (inhabilitación, sujeción a vigilancia, etc.).'},
    <String, String>{'term': 'Perito', 'definition': 'Experto en una ciencia, arte u oficio que emite dictamen sobre hechos relevantes para el proceso.'},
    <String, String>{'term': 'Perjurio', 'definition': 'Delito de falso testimonio prestado bajo juramento ante autoridad judicial.'},
    <String, String>{'term': 'Plazo razonable', 'definition': 'Garantía de que el proceso penal se resolverá en un tiempo prudencial sin dilaciones indebidas.'},
    <String, String>{'term': 'Preclusión', 'definition': 'Pérdida de la oportunidad para realizar un acto procesal por haber transcurrido el lapso legal.'},
    <String, String>{'term': 'Premeditación', 'definition': 'Circunstancia agravante que consiste en planificar fríamente el delito antes de su ejecución.'},
    <String, String>{'term': 'Prescripción', 'definition': 'Extinción de la acción penal o de la pena por el transcurso del tiempo fijado por la ley.'},
    <String, String>{'term': 'Presidio', 'definition': 'Pena privativa de libertad que se cumple en penitenciaría con obligación de trabajos forzados.'},
    <String, String>{'term': 'Presunción de inocencia', 'definition': 'Principio fundamental que obliga a tratar al imputado como inocente hasta que se pruebe su culpabilidad.'},
    <String, String>{'term': 'Prevaricación', 'definition': 'Delito del juez que dicta a sabiendas una resolución injusta.'},
    <String, String>{'term': 'Principio acusatorio', 'definition': 'Separación de funciones entre quien acusa (Ministerio Público) y quien juzga (juez).'},
    <String, String>{'term': 'Principio de legalidad', 'definition': 'Garantía de que no hay delito ni pena sin ley previa que los establezca (nullum crimen, nulla poena sine lege).'},
    <String, String>{'term': 'Prisión', 'definition': 'Pena privativa de libertad que se cumple en establecimiento penitenciario, sin obligación de trabajos forzados.'},
    <String, String>{'term': 'Prueba', 'definition': 'Medio para demostrar la verdad de los hechos alegados en el proceso.'},
    <String, String>{'term': 'Prueba anticipada', 'definition': 'Diligencia probatoria realizada antes del juicio oral por razones de urgencia o imposibilidad de reproducción.'},
    // Q
    <String, String>{'term': 'Querella', 'definition': 'Acto por el cual la víctima o persona legitimada ejerce la acción penal y se constituye en parte acusadora.'},
    // R
    <String, String>{'term': 'Ratio decidendi', 'definition': 'Locución latina: "razón para decidir". Fundamento jurídico esencial de una sentencia que constituye precedente.'},
    <String, String>{'term': 'Rebeldía', 'definition': 'Situación del imputado que, citado legalmente, no comparece al proceso sin justa causa.'},
    <String, String>{'term': 'Reincidencia', 'definition': 'Circunstancia agravante por cometer un nuevo delito tras haber sido condenado anteriormente.'},
    <String, String>{'term': 'Reparación del daño', 'definition': 'Obligación del condenado de resarcir los perjuicios causados a la víctima.'},
    <String, String>{'term': 'Robo', 'definition': 'Apoderamiento de una cosa mueble ajena mediante violencia o intimidación.'},
    // S
    <String, String>{'term': 'Sana crítica', 'definition': 'Sistema de valoración de la prueba en que el juez aprecia libremente según la lógica, ciencia y experiencia.'},
    <String, String>{'term': 'Secuestro', 'definition': 'Delito que consiste en privar de libertad a una persona para obtener un rescate o condición.'},
    <String, String>{'term': 'Sentencia', 'definition': 'Decisión definitiva del tribunal que resuelve el fondo del asunto penal.'},
    <String, String>{'term': 'Sentencia absolutoria', 'definition': 'La que declara la inocencia del acusado y ordena su libertad.'},
    <String, String>{'term': 'Sentencia condenatoria', 'definition': 'La que declara culpable al acusado e impone una pena o medida de seguridad.'},
    <String, String>{'term': 'Sobreseimiento', 'definition': 'Resolución judicial que pone fin al proceso sin condena ni absolución, por falta de méritos o extinción de la acción penal.'},
    <String, String>{'term': 'Sujeto activo', 'definition': 'Persona que realiza la conducta descrita en el tipo penal.'},
    <String, String>{'term': 'Sujeto pasivo', 'definition': 'Titular del bien jurídico protegido que resulta afectado por el delito (víctima).'},
    // T
    <String, String>{'term': 'Tentativa', 'definition': 'Comienzo de ejecución del delito que no llega a consumarse por causas ajenas a la voluntad del autor.'},
    <String, String>{'term': 'Testigo', 'definition': 'Persona que declara sobre hechos que ha percibido y son relevantes para el proceso.'},
    <String, String>{'term': 'Tipo penal', 'definition': 'Descripción legal abstracta de una conducta prohibida a la que se asigna una pena.'},
    <String, String>{'term': 'Tipicidad', 'definition': 'Adecuación de una conducta concreta a la descripción legal del delito.'},
    <String, String>{'term': 'Tribunal', 'definition': 'Órgano jurisdiccional encargado de administrar justicia.'},
    // U
    <String, String>{'term': 'Usurpación', 'definition': 'Delito contra la propiedad que consiste en despojar a otro de la posesión de un inmueble.'},
    // V
    <String, String>{'term': 'Veredicto', 'definition': 'Decisión del tribunal de juicio sobre la culpabilidad o inocencia del acusado.'},
    <String, String>{'term': 'Víctima', 'definition': 'Persona directamente ofendida por el delito o sus familiares en caso de muerte.'},
    <String, String>{'term': 'Violación', 'definition': 'Delito sexual que consiste en el acceso carnal mediante violencia, amenaza o con persona vulnerable.'},
    <String, String>{'term': 'Violencia de género', 'definition': 'Toda conducta que cause daño a la mujer por su condición femenina.'},
    <String, String>{'term': 'Vista', 'definition': 'Acto procesal oral ante el tribunal para la práctica de pruebas o informes.'},
    <String, String>{'term': 'Vulnerabilidad', 'definition': 'Situación de especial desprotección de la víctima por edad, discapacidad u otras circunstancias.'},
  ];

  late List<Map<String, String>> _filteredGlossary;
  String _selectedLetter = 'Todos';
  final ScrollController _scrollController = ScrollController();

  List<String> get _alphabet => <String>['Todos', ...List.generate(26, (int index) => String.fromCharCode(65 + index))];

  @override
  void initState() {
    super.initState();
    // Cargar términos desde Supabase (tabla glosario_terminos); mientras
    // tanto se muestra la lista local de respaldo. Una sola carga por sesión.
    _cargarTerminosSupabase();
    // Usar glosario local directamente
    _filteredGlossary = List.from(terminos);
  }

  Future<void> _cargarTerminosSupabase() async {
    if (_cargandoRemotos) return;
    _cargandoRemotos = true;
    final remotos = await GlosarioService.cargarDesdeSupabase();
    _cargandoRemotos = false;
    if (!mounted || remotos.isEmpty) return;
    setState(() {
      terminosRemotos = remotos;
      _filteredGlossary = List.from(GlosarioScreen.terminos);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _normalize(String text) => text
        .toLowerCase()
        .replaceAll("á", "a")
        .replaceAll("é", "e")
        .replaceAll("í", "i")
        .replaceAll("ó", "o")
        .replaceAll("ú", "u")
        .replaceAll("ü", "u");

  void _filterGlossary(String value) {
    final String normalized = _normalize(value.trim());
    final List<Map<String, String>> results = GlosarioScreen.terminos.where((Map<String, String> entry) {
      final String term = _normalize(entry['term'] ?? '');
      final String definition = _normalize(entry['definition'] ?? '');
      final bool matchesSearch = normalized.isEmpty || term.contains(normalized) || definition.contains(normalized);
      final bool matchesLetter = _selectedLetter == 'Todos' || term.startsWith(_selectedLetter.toLowerCase());
      return matchesSearch && matchesLetter;
    }).toList();
    setState(() => _filteredGlossary = results);
  }

  void _selectLetter(String letter) {
    setState(() => _selectedLetter = letter);
    _filterGlossary(_searchController.text);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      drawer: const AppDrawer(currentRoute: "/glosario"),
      appBar: AppBar(
        title: const Text("Glosario Jurídico"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Contador de términos
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${terminos.length} términos',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: TemaGlobal.superficie,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Buscador
            TextField(
              controller: _searchController,
              onChanged: _filterGlossary,
              style: TextStyle(color: TemaGlobal.texto, fontSize: 16),
              decoration: InputDecoration(
                hintText: "Buscar término o definición...",
                hintStyle: TextStyle(color: TemaGlobal.textoTenue),
                prefixIcon: Icon(Icons.search, color: TemaGlobal.texto),
                filled: true,
                fillColor: TemaGlobal.campoTexto,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.secondary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),
            const SizedBox(height: 16),
            // Filtro por letras
            Text(
              "Filtrar por letra",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TemaGlobal.texto.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                controller: _scrollController,
                itemCount: _alphabet.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (BuildContext context, int index) {
                  final String letter = _alphabet[index];
                  final bool selected = letter == _selectedLetter;
                  return InkWell(
                    onTap: () => _selectLetter(letter),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.secondary : TemaGlobal.tarjeta,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? AppColors.secondary : AppColors.primary.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        boxShadow: selected
                            ? <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        letter,
                        style: TextStyle(
                          color: selected ? AppColors.primary : TemaGlobal.texto,
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Contador de resultados
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  '${_filteredGlossary.length} término${_filteredGlossary.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: TemaGlobal.texto.withValues(alpha: 0.7),
                  ),
                ),
                if (_selectedLetter != "Todos" || _searchController.text.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _selectedLetter = "Todos");
                      _filterGlossary("");
                    },
                    child: const Text(
                      "Limpiar filtros",
                      style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Lista de términos
            Expanded(
              child: _filteredGlossary.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No se encontraron términos",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: TemaGlobal.texto.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Prueba con otra palabra o letra",
                            style: TextStyle(
                              fontSize: 14,
                              color: TemaGlobal.texto.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredGlossary.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Map<String, String> item = _filteredGlossary[index];
                        final String term = item["term"] ?? "";
                        final String definition = item["definition"] ?? "";
                        return Card(
                          color: TemaGlobal.tarjeta,
                          elevation: 2,
                          shadowColor: AppColors.secondary.withValues(alpha: 0.1),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: AppColors.secondary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  term.isNotEmpty ? term[0].toUpperCase() : '',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              term,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 0.3,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    definition,
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),
                                  if ((item["reference"] ?? "").isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: <Widget>[
                                        Icon(
                                          Icons.balance,
                                          size: 14,
                                          color: AppColors.secondary.withValues(alpha: 0.8),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            item["reference"]!,
                                            style: TextStyle(
                                              color: AppColors.secondary.withValues(alpha: 0.85),
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
}
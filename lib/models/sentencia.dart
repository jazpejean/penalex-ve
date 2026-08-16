import 'package:cloud_firestore/cloud_firestore.dart';

class Sentencia {
  final String id;
  final String numero;
  final DateTime fecha;
  final String sala;
  final String tribunal;
  final String magistradoPonente;
  final String delito;
  final List<String> articulosCitados;
  final String resumen;
  final String doctrina;
  final String? urlPDF;
  final int relevancia; // 1-5 estrellas
  final List<String> tags;
  final DateTime createdAt;

  Sentencia({
    required this.id,
    required this.numero,
    required this.fecha,
    required this.sala,
    required this.tribunal,
    required this.magistradoPonente,
    required this.delito,
    required this.articulosCitados,
    required this.resumen,
    required this.doctrina,
    this.urlPDF,
    this.relevancia = 3,
    required this.tags,
    required this.createdAt,
  });

  factory Sentencia.fromMap(Map<String, dynamic> map, String id) {
    return Sentencia(
      id: id,
      numero: map['numero'] as String? ?? '',
      fecha: (map['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sala: map['sala'] as String? ?? '',
      tribunal: map['tribunal'] as String? ?? '',
      magistradoPonente: map['magistradoPonente'] as String? ?? '',
      delito: map['delito'] as String? ?? '',
      articulosCitados: (map['articulosCitados'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      resumen: map['resumen'] as String? ?? '',
      doctrina: map['doctrina'] as String? ?? '',
      urlPDF: map['urlPDF'] as String?,
      relevancia: map['relevancia'] as int? ?? 3,
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'fecha': Timestamp.fromDate(fecha),
      'sala': sala,
      'tribunal': tribunal,
      'magistradoPonente': magistradoPonente,
      'delito': delito,
      'articulosCitados': articulosCitados,
      'resumen': resumen,
      'doctrina': doctrina,
      'urlPDF': urlPDF,
      'relevancia': relevancia,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Sentencias de ejemplo (hardcoded para demostración)
  static List<Sentencia> getSentenciasEjemplo() {
    final now = DateTime.now();
    return [
      Sentencia(
        id: '1',
        numero: 'TSJ-SCP-0247/2023',
        fecha: DateTime(2023, 6, 15),
        sala: 'Sala de Casación Penal',
        tribunal: 'Tribunal Supremo de Justicia',
        magistradoPonente: 'Dr. Maikel José Moreno Pérez',
        delito: 'Homicidio Calificado',
        articulosCitados: ['Art. 406 CP', 'Art. 74 CP', 'Art. 37 CP'],
        resumen:
            'La Sala ratifica el criterio según el cual la alevosía como circunstancia agravante del homicidio debe constatarse objetivamente mediante pruebas que demuestren que el agresor actuó sobre seguro, sin riesgo para su persona, aprovechándose de circunstancias que eliminaron la posibilidad de defensa de la víctima.',
        doctrina:
            'Se establece que la alevosía requiere: 1) Empleo de medios, modos o formas que tiendan directa y especialmente a asegurar la ejecución del delito sin riesgo para el agresor; 2) Aprovechamiento consciente de dicha situación por parte del autor. No basta la simple indefensión de la víctima, sino que el agente debe haber buscado o aprovechado conscientemente tal situación. En materia de dosimetría penal, el juez debe partir del término medio de la pena prevista en el tipo base y aplicar las circunstancias agravantes específicas.',
        urlPDF: null,
        relevancia: 5,
        tags: ['homicidio', 'alevosía', 'dosimetría', 'agravantes'],
        createdAt: now,
      ),
      Sentencia(
        id: '2',
        numero: 'TSJ-SCP-0412/2023',
        fecha: DateTime(2023, 9, 22),
        sala: 'Sala de Casación Penal',
        tribunal: 'Tribunal Supremo de Justicia',
        magistradoPonente: 'Dra. Elsa Janeth Gómez Moreno',
        delito: 'Concurso de Delitos',
        articulosCitados: ['Art. 88 CP', 'Art. 98 CP', 'Art. 99 CP'],
        resumen:
            'La Sala aclara la diferencia entre concurso real, ideal y continuado de delitos, estableciendo los criterios para su determinación y las consecuencias punitivas correspondientes según lo previsto en el Código Penal.',
        doctrina:
            'CONCURSO REAL (Art. 88 CP): Existe cuando un mismo agente realiza varias acciones independientes que constituyen diversos delitos. Las penas se acumulan hasta el máximo de 30 años. CONCURSO IDEAL (Art. 98 CP): Una sola acción constituye dos o más delitos. Se aplica únicamente la pena del delito más grave. DELITO CONTINUADO (Art. 99 CP): Varias violaciones de la misma disposición legal ejecutadas en momentos distintos con actos ejecutivos de la misma resolución criminal. Se considera un solo delito aumentando la pena del más grave entre 1/6 y 1/2.',
        urlPDF: null,
        relevancia: 5,
        tags: ['concurso', 'acumulación', 'penas', 'dosimetría'],
        createdAt: now,
      ),
      Sentencia(
        id: '3',
        numero: 'TSJ-SCP-0089/2024',
        fecha: DateTime(2024, 2, 10),
        sala: 'Sala de Casación Penal',
        tribunal: 'Tribunal Supremo de Justicia',
        magistradoPonente: 'Dr. Juan Luis Ibarra Verenzuela',
        delito: 'Tentativa de Delito',
        articulosCitados: ['Art. 80 CP', 'Art. 82 CP'],
        resumen:
            'Se establecen los requisitos para configurar la tentativa de delito y se determina la dosimetría penal aplicable, diferenciando entre tentativa simple y delito frustrado conforme a los artículos 80 y 82 del Código Penal.',
        doctrina:
            'Para la existencia de TENTATIVA se requiere: 1) Inicio de ejecución del delito mediante actos directos. 2) No realización de todos los actos necesarios para la consumación. 3) Interrupción por causas ajenas a la voluntad del autor. La pena se reduce entre 1/2 y 2/3 de la prevista para el delito consumado. En el DELITO FRUSTRADO: Se realizan todos los actos necesarios pero no se produce el resultado por causas independientes. La pena es 1/3 menos que la del delito consumado.',
        urlPDF: null,
        relevancia: 4,
        tags: ['tentativa', 'frustrado', 'iter criminis', 'dosimetría'],
        createdAt: now,
      ),
      Sentencia(
        id: '4',
        numero: 'TSJ-SCP-0156/2024',
        fecha: DateTime(2024, 4, 8),
        sala: 'Sala de Casación Penal',
        tribunal: 'Tribunal Supremo de Justicia',
        magistradoPonente: 'Dr. Maikel José Moreno Pérez',
        delito: 'Robo Agravado',
        articulosCitados: ['Art. 458 CP', 'Art. 77 CP'],
        resumen:
            'La Sala establece criterios sobre las circunstancias agravantes del delito de robo, particularmente la diferencia entre violencia sobre las personas y violencia sobre las cosas, y su incidencia en la determinación de la pena.',
        doctrina:
            'El robo agravado se perfecciona cuando concurren circunstancias que aumentan la gravedad del hecho, tales como: escalamiento, fractura, ganzúa, violencia o amenaza con armas, participación de dos o más personas, o cuando se comete en despoblado o de noche. La dosimetría penal debe considerar cada agravante específica y su fundamentación. La violencia en el robo no solo se refiere a la física sobre personas, sino también al empleo de medios intimidatorios que anulen la voluntad de la víctima.',
        urlPDF: null,
        relevancia: 4,
        tags: ['robo', 'violencia', 'agravantes', 'propiedad'],
        createdAt: now,
      ),
      Sentencia(
        id: '5',
        numero: 'TSJ-SCP-0298/2024',
        fecha: DateTime(2024, 7, 3),
        sala: 'Sala de Casación Penal',
        tribunal: 'Tribunal Supremo de Justicia',
        magistradoPonente: 'Dra. Elsa Janeth Gómez Moreno',
        delito: 'Prescripción de la Acción Penal',
        articulosCitados: ['Art. 108 CP', 'Art. 109 CP', 'Art. 110 CP'],
        resumen:
            'Se desarrollan los criterios para el cómputo de la prescripción de la acción penal, incluyendo las causales de interrupción y suspensión, así como los plazos aplicables según la gravedad del delito.',
        doctrina:
            'La prescripción de la acción penal opera según el término de la pena máxima prevista para el delito: si es presidio, el término es igual a la pena pero no menor de 4 años ni mayor de 10. La prescripción se INTERRUMPE por: 1) Comisión de nuevo delito. 2) Secuela del juicio. Se SUSPENDE durante procedimientos judiciales. El cómputo inicia desde el día de perpetración del hecho o desde que cesó la ejecución en delitos permanentes o continuados.',
        urlPDF: null,
        relevancia: 5,
        tags: ['prescripción', 'acción penal', 'términos', 'procedimiento'],
        createdAt: now,
      ),
      Sentencia(
        id: '6',
        numero: 'TSJ-SCP-0534/2024',
        fecha: DateTime(2024, 11, 18),
        sala: 'Sala de Casación Penal',
        tribunal: 'Tribunal Supremo de Justicia',
        magistradoPonente: 'Dr. Juan Luis Ibarra Verenzuela',
        delito: 'Circunstancias Atenuantes',
        articulosCitados: ['Art. 74 CP', 'Art. 37 CP'],
        resumen:
            'La Sala precisa el alcance de las circunstancias atenuantes genéricas y su aplicación en la dosimetría penal, especialmente la atenuante de no haber tenido intención de causar un mal de tanta gravedad.',
        doctrina:
            'Las circunstancias ATENUANTES (Art. 74 CP) obligan al juez a rebajar la pena desde el término medio hacia el límite mínimo. Entre las principales: 1) No haber tenido intención proporcional al mal causado. 2) Haber precedido inmediatamente provocación o amenaza. 3) Haber ejecutado el hecho en vindicación próxima de ofensa grave. 4) Haber obrado por estímulos nobles o altruistas. 5) Presentarse voluntariamente a la autoridad. La valoración debe ser individualizada y fundada en las circunstancias concretas del caso.',
        urlPDF: null,
        relevancia: 5,
        tags: ['atenuantes', 'dosimetría', 'individualización', 'pena'],
        createdAt: now,
      ),
    ];
  }
}

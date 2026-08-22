class QuizQuestion {
  final int id;
  final int nivel;
  final int variantId; // 1 to 5 for randomized anti-cheat
  final String caso;
  final List<String> opciones;
  final int respuestaCorrectaIndex;
  final String fundamentacionLegal;
  final String pistaVaga;
  final String tipoDelito;

  const QuizQuestion({
    required this.id,
    required this.nivel,
    required this.variantId,
    required this.caso,
    required this.opciones,
    required this.respuestaCorrectaIndex,
    required this.fundamentacionLegal,
    required this.pistaVaga,
    required this.tipoDelito,
  });
}

class JudicialRank {
  final String titulo;
  final int nivelRequerido;
  final String descripcion;

  const JudicialRank({
    required this.titulo,
    required this.nivelRequerido,
    required this.descripcion,
  });
}

const List<JudicialRank> RANGOS_JUDICIALES = [
  JudicialRank(titulo: "Alguacil de Sala", nivelRequerido: 1, descripcion: "Custodio del orden en las audiencias penales preliminares."),
  JudicialRank(titulo: "Escribano Tribunalicio", nivelRequerido: 50, descripcion: "Redactor de actas, autos y sentencias interlocutorias."),
  JudicialRank(titulo: "Secretario de Juzgado", nivelRequerido: 150, descripcion: "Fedatario judicial de los procedimientos del circuito."),
  JudicialRank(titulo: "Defensor Público Penal", nivelRequerido: 300, descripcion: "Garante de la tutela judicial efectiva y el debido proceso."),
  JudicialRank(titulo: "Fiscal Auxiliar del MP", nivelRequerido: 500, descripcion: "Director de la investigación y titular de la acción penal."),
  JudicialRank(titulo: "Fiscal Provisorio Superior", nivelRequerido: 750, descripcion: "Representante de la vindicta pública ante los tribunales."),
  JudicialRank(titulo: "Juez de Control", nivelRequerido: 1000, descripcion: "Garante de derechos fundamentales en la fase preparatoria."),
  JudicialRank(titulo: "Juez de Juicio Oral", nivelRequerido: 1350, descripcion: "Director del debate probatorio y autor de sentencias de mérito."),
  JudicialRank(titulo: "Juez de Ejecución", nivelRequerido: 1700, descripcion: "Supervisor de penas, medidas cautelares y beneficios de ley."),
  JudicialRank(titulo: "Juez Superior de Apelaciones", nivelRequerido: 2100, descripcion: "Revisor de sentencias impugnadas y jurisprudencia ordinaria."),
  JudicialRank(titulo: "Presidente de Circuito Penal", nivelRequerido: 2500, descripcion: "Máxima autoridad de administración de justicia en el Estado."),
  JudicialRank(titulo: "Magistrado Sala Penal TSJ", nivelRequerido: 2800, descripcion: "Casacionista de la Sala Penal del Máximo Tribunal."),
  JudicialRank(titulo: "Magistrado Presidente del TSJ", nivelRequerido: 3000, descripcion: "Cúspide de la Magistratura y rector del Poder Judicial."),
];

JudicialRank getRankForLevel(int level) {
  for (int i = RANGOS_JUDICIALES.length - 1; i >= 0; i--) {
    if (level >= RANGOS_JUDICIALES[i].nivelRequerido) {
      return RANGOS_JUDICIALES[i];
    }
  }
  return RANGOS_JUDICIALES.first;
}

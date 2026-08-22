class GameState {
  final int nivelActual;
  final int xp;
  final int apelaciones;
  final int racha;
  final DateTime? ultimoGastoApelacion;
  final Map<int, int> fallosPorNivel; // nivel -> conteo de fallos (3 = bloqueado)
  final Set<int> nivelesCompletados;

  const GameState({
    required this.nivelActual,
    required this.xp,
    required this.apelaciones,
    required this.racha,
    required this.ultimoGastoApelacion,
    required this.fallosPorNivel,
    required this.nivelesCompletados,
  });

  bool isLevelLocked(int level) {
    return (fallosPorNivel[level] ?? 0) >= 3;
  }

  int getFailures(int level) {
    return fallosPorNivel[level] ?? 0;
  }

  GameState copyWith({
    int? nivelActual,
    int? xp,
    int? apelaciones,
    int? racha,
    DateTime? ultimoGastoApelacion,
    Map<int, int>? fallosPorNivel,
    Set<int>? nivelesCompletados,
  }) {
    return GameState(
      nivelActual: nivelActual ?? this.nivelActual,
      xp: xp ?? this.xp,
      apelaciones: apelaciones ?? this.apelaciones,
      racha: racha ?? this.racha,
      ultimoGastoApelacion: ultimoGastoApelacion ?? this.ultimoGastoApelacion,
      fallosPorNivel: fallosPorNivel ?? this.fallosPorNivel,
      nivelesCompletados: nivelesCompletados ?? this.nivelesCompletados,
    );
  }
}

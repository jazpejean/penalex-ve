class UserProgress {

  UserProgress({
    required this.apelaciones,
    required this.ultimaRegeneracion,
  });

  // ✅ Para leer desde Firestore
  factory UserProgress.fromMap(Map<String, dynamic> map) => UserProgress(
      apelaciones: (map['apelaciones'] as num?)?.toInt() ?? 
                   (map['vidas'] as num?)?.toInt() ?? 5, // Fallback para compatibilidad
      ultimaRegeneracion: DateTime.tryParse(
          (map['ultimaRegeneracion'] as String?) ?? '',) ?? DateTime.now(),
    );
  final int apelaciones;
  final DateTime ultimaRegeneracion;

  // ✅ Para guardar en Firestore
  Map<String, dynamic> toMap() => <String, dynamic>{
      "apelaciones": apelaciones,
      "vidas": apelaciones, // Mantener compatibilidad con versión anterior
      "ultimaRegeneracion": ultimaRegeneracion.toIso8601String(),
    };
}
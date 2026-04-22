class UserProgress {

  UserProgress({
    required this.vidas,
    required this.ultimaRegeneracion,
  });

  // ✅ Para leer desde Firestore
  factory UserProgress.fromMap(Map<String, dynamic> map) => UserProgress(
      vidas: (map['vidas'] as num?)?.toInt() ?? 5,
      ultimaRegeneracion: DateTime.tryParse(
          (map['ultimaRegeneracion'] as String?) ?? '',) ?? DateTime.now(),
    );
  final int vidas;
  final DateTime ultimaRegeneracion;

  // ✅ Para guardar en Firestore
  Map<String, dynamic> toMap() => <String, dynamic>{
      "vidas": vidas,
      "ultimaRegeneracion": ultimaRegeneracion.toIso8601String(),
    };
}
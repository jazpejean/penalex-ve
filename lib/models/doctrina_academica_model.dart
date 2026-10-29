/// Doctrina Académica: cita de autor/obra que las sentencias del TSJ invocan.
///
/// Tabla `doctrinas_academicas` (extraídas por IA con cita textual literal).
/// Es un resultado del Super Buscador en la categoría "Doctrinas Académicas":
/// el autor, la obra y el párrafo de evidencia son lo que se muestra.
class DoctrinaAcademicaModel {
  final String id;
  final String sentenciaId;
  final String autor;
  final String obra;
  final String pagina;
  final String parrafoEvidencia;

  const DoctrinaAcademicaModel({
    required this.id,
    required this.sentenciaId,
    this.autor = '',
    this.obra = '',
    this.pagina = '',
    this.parrafoEvidencia = '',
  });

  /// Título de la ficha: "Autor — Obra" (o lo que exista).
  String get titulo {
    final a = autor.trim();
    final o = obra.trim();
    if (a.isNotEmpty && o.isNotEmpty) return '$a — $o';
    return a.isNotEmpty ? a : (o.isNotEmpty ? o : 'Doctrina académica');
  }

  factory DoctrinaAcademicaModel.fromSupabase(Map<String, dynamic> data) {
    return DoctrinaAcademicaModel(
      id: data['id']?.toString() ?? '',
      sentenciaId: data['sentencia_id']?.toString() ?? '',
      autor: data['autor']?.toString() ?? '',
      obra: data['obra']?.toString() ?? '',
      pagina: data['pagina']?.toString() ?? '',
      parrafoEvidencia: data['parrafo_evidencia']?.toString() ?? '',
    );
  }
}
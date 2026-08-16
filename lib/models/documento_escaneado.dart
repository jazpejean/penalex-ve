class DocumentoEscaneado {
  final String id;
  final String userId;
  final String titulo;
  final List<String> paginasUrls; // URLs en Supabase Storage
  final String? textoOcr;
  final DateTime fechaCreacion;
  final String? thumbnailUrl;

  DocumentoEscaneado({
    required this.id,
    required this.userId,
    required this.titulo,
    required this.paginasUrls,
    this.textoOcr,
    required this.fechaCreacion,
    this.thumbnailUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'titulo': titulo,
        'paginas_urls': paginasUrls,
        'texto_ocr': textoOcr,
        'fecha_creacion': fechaCreacion.toIso8601String(),
        'thumbnail_url': thumbnailUrl,
      };

  factory DocumentoEscaneado.fromJson(Map<String, dynamic> json) {
    return DocumentoEscaneado(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      titulo: json['titulo'] as String,
      paginasUrls: (json['paginas_urls'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      textoOcr: json['texto_ocr'] as String?,
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }

  // Helper para compatibilidad con ScannedDocument local
  int get numeroPaginas => paginasUrls.length;
}

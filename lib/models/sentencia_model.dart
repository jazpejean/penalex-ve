import 'package:cloud_firestore/cloud_firestore.dart';

class SentenciaModel {
  final String id;
  final String tipo;
  final String sala;
  final String numeroSentencia;
  final String fechaSentencia;
  final String ponente;
  final String tipoSentencia;
  final String materia;
  final String partes;
  final String delito;
  final String decision;
  final String resumen;
  final String extracto;
  final String ratioDecidendi;
  final String analisisIa;
  final String urlTSJ;
  final String urlHTML;
  final String urlTXT;
  final String urlFichaPenalex;
  final String contenidoCompleto;
  final bool esJurisprudencia;
  final bool tienePDF;
  final DateTime? timestamp;

  SentenciaModel({
    required this.id,
    required this.tipo,
    required this.sala,
    required this.numeroSentencia,
    required this.fechaSentencia,
    required this.ponente,
    required this.tipoSentencia,
    required this.materia,
    required this.partes,
    required this.delito,
    required this.decision,
    required this.resumen,
    required this.extracto,
    this.ratioDecidendi = '',
    this.analisisIa = '',
    required this.urlTSJ,
    required this.urlHTML,
    required this.urlTXT,
    required this.urlFichaPenalex,
    required this.contenidoCompleto,
    required this.esJurisprudencia,
    required this.tienePDF,
    this.timestamp,
  });

  /// URL priorizada para ABRIR la sentencia completa.
  ///
  /// [urlTXT] NO se usa aquí: es exclusivo del RAG (contexto/IA). Para abrir
  /// se prioriza la copia HTML propia alojada en R2, luego la ficha y por
  /// último el servidor del TSJ.
  String get urlParaVer {
    if (urlHTML.isNotEmpty && urlHTML != 'null') return urlHTML;
    if (urlFichaPenalex.isNotEmpty && urlFichaPenalex != 'null') {
      return urlFichaPenalex;
    }
    if (urlTSJ.isNotEmpty && urlTSJ != 'null') return urlTSJ;
    return '';
  }

  /// `true` si la sentencia tiene una copia HTML propia en R2.
  bool get tieneCopiaR2 {
    final html = urlHTML.trim();
    return html.isNotEmpty && html != 'null';
  }

  /// Constructor desde Supabase
  factory SentenciaModel.fromSupabase(Map<String, dynamic> data) {
    return SentenciaModel(
      id: data['id'] ?? '',
      tipo: data['tipo'] ?? '',
      sala: data['sala'] ?? '',
      numeroSentencia: data['num_sentencia'] ?? '',
      fechaSentencia: data['fecha'] ?? '',
      ponente: data['ponente'] ?? '',
      tipoSentencia: data['tipo'] ?? '',
      materia: data['procedimiento'] ?? '',
      partes: data['partes'] ?? '',
      delito: data['delito'] ?? '',
      decision: data['decision'] ?? '',
      resumen: data['resumen_ia'] ?? data['extracto'] ?? '',
      extracto: data['extracto'] ?? '',
      ratioDecidendi: data['ratio_decidendi'] ?? '',
      analisisIa: data['analisis_ia'] ?? '',
      urlTSJ: data['url_tsj'] ?? '',
      urlHTML: data['url_html'] ?? '',
      urlTXT: data['url_txt'] ?? '',
      // Priorizar la copia HTML propia (estable) antes que el servidor del TSJ.
      // (El TXT queda solo para RAG, no para abrir la sentencia.)
      urlFichaPenalex: data['url_html'] ?? data['url_tsj'] ?? '',
      contenidoCompleto: data['extracto'] ?? '',
      esJurisprudencia: data['es_jurisprudencia'] ?? false,
      tienePDF: data['tiene_pdf'] ?? false,
      timestamp: data['created_at'] != null 
          ? DateTime.tryParse(data['created_at'])
          : null,
    );
  }

  /// Constructor desde Firestore (legacy, mantener por compatibilidad)
  factory SentenciaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SentenciaModel(
      id: doc.id,
      tipo: data['tipo'] ?? 'sentencia',
      sala: data['sala'] ?? '',
      numeroSentencia: data['numero_sentencia'] ?? '',
      fechaSentencia: data['fecha_sentencia'] ?? '',
      ponente: data['ponente'] ?? '',
      tipoSentencia: data['tipo_sentencia'] ?? '',
      materia: data['materia'] ?? '',
      partes: data['partes'] ?? '',
      delito: data['delito'] ?? '',
      decision: data['decision'] ?? '',
      resumen: data['resumen'] ?? '',
      extracto: data['extracto'] ?? '',
      ratioDecidendi: data['ratio_decidendi'] ?? '',
      analisisIa: data['analisis_ia'] ?? '',
      urlTSJ: data['url_tsj_original'] ?? '',
      urlHTML: data['url_html'] ?? '',
      urlTXT: data['url_txt'] ?? '',
      urlFichaPenalex: data['url_ficha_penalex'] ?? '',
      contenidoCompleto: data['contenido_completo'] ?? '',
      esJurisprudencia: data['es_jurisprudencia'] ?? false,
      tienePDF: data['tiene_pdf'] ?? false,
      timestamp: (data['fecha_indexacion'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'sala': sala,
      'num_sentencia': numeroSentencia,
      'fecha': fechaSentencia,
      'ponente': ponente,
      'partes': partes,
      'delito': delito,
      'decision': decision,
      'resumen_ia': resumen,
      'extracto': extracto,
      'ratio_decidendi': ratioDecidendi,
      'analisis_ia': analisisIa,
      'url_tsj': urlTSJ,
      'url_html': urlHTML,
      'url_txt': urlTXT,
      'es_jurisprudencia': esJurisprudencia,
      'tiene_pdf': tienePDF,
    };
  }
}

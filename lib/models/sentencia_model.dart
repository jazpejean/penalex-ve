import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  /// URL priorizada para ABRIR la sentencia completa en el WebView.
  ///
  /// SIEMPRE la copia HTML propia alojada en R2 (copia fiel del TSJ, estable).
  /// NUNCA cae al servidor del TSJ: el WebView muestra la copia de R2; si no
  /// existe, la UI muestra un aviso de "copia no disponible".
  String get urlParaVer {
    if (urlHTML.isNotEmpty && urlHTML != 'null') return urlHTML;
    if (urlFichaPenalex.isNotEmpty && urlFichaPenalex != 'null') {
      return urlFichaPenalex;
    }
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
      // Las copias íntegras viven en Cloudflare R2: la base guarda la CLAVE
      // del objeto (r2_html_key / r2_txt_key) y la URL pública se arma con
      // el dominio del bucket. Antes se leía 'url_html'/'url_txt', columnas
      // que NO existen en la base → la app mostraba el resumen en vez de la
      // sentencia. Corregido: urlHTML/urlTXT apuntan a la copia de R2.
      urlHTML: _urlR2(data['r2_html_key']),
      urlTXT: _urlR2(data['r2_txt_key']),
      // La ficha es SIEMPRE la copia HTML propia en R2 (estable); nunca la
      // URL del TSJ. El WebView muestra la copia de R2; si no existe, la UI
      // avisa que la copia no está disponible.
      urlFichaPenalex: _urlR2(data['r2_html_key']),
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

  /// Base de la URL pública de Cloudflare R2 donde viven las copias íntegras
  /// de las sentencias (dominio del bucket; verificado HTTP 200).
  ///
  /// Se puede sobreescribir con `R2_PUBLIC_URL` en el .env; el valor por
  /// defecto es el dominio real del bucket de Penalex.
  static String get _r2PublicBase =>
      dotenv.env['R2_PUBLIC_URL']?.trim().isNotEmpty == true
          ? dotenv.env['R2_PUBLIC_URL']!.trim().replaceAll(RegExp(r'/+$'), '')
          : 'https://pub-ccca0a4f4395464da7752af871c16943.r2.dev';

  /// Convierte la clave del objeto R2 (ej. `html/scon/2005/....html`) en la
  /// URL pública completa. Vacío si no hay clave.
  static String _urlR2(dynamic r2Key) {
    final key = r2Key?.toString().trim() ?? '';
    if (key.isEmpty || key == 'null') return '';
    return '$_r2PublicBase/${key.replaceAll(RegExp(r'^/+'), '')}';
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

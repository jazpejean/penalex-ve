import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/document_template.dart';
import 'template_service.dart';
import 'ai_service.dart';
import 'ai_analytics_service.dart';
import 'rag_service.dart';
import 'leyes_repositorio_service.dart';
import 'catalogo_documentos.dart';

class DocumentChatService {
  final TemplateService _templateService = TemplateService();
  
  String _currentTemplateId = '';
  String _procesalPhase = '';
  Map<String, String> _collectedData = {};
  List<TemplateField> _remainingFields = [];
  int _currentFieldIndex = 0;

  // Flujo por catálogo (lenguaje natural + requisitos legales)
  TipoDocumentoLegal? _tipoActivo;
  List<int> _datosPendientes = [];
  String _requisitosTexto = '';

  /// Último documento generado (para guardarlo en el historial).
  String? _ultimoDocumento;
  String? _ultimoTitulo;
  String? get ultimoDocumento => _ultimoDocumento;
  String? get ultimoTitulo => _ultimoTitulo;

  /// Genera un documento a partir de una indicación libre (sin catálogo).
  Future<String> _generarDocumentoLibre(String userMessage) async {
    _ultimoDocumento = null;
    _ultimoTitulo = null;
    final consulta =
        userMessage.length > 500 ? userMessage.substring(0, 500) : userMessage;
    final contextoLegal = await _obtenerLeyesContexto(consulta);
    final contextoJurisprudencial = await _obtenerJurisprudenciaContexto(consulta);

    final prompt = 'Redacta un escrito/documento legal venezolano a partir de '
        'la siguiente indicación del usuario. Determina el tipo de documento y '
        'su estructura según el COPP o la ley aplicable. Usa la terminología '
        'correcta (imputado en control, acusado en juicio, penado en ejecución). '
        'Adapta el formato a las indicaciones; si falta un dato esencial, '
        'indícalo al final en "DATOS FALTANTES" (NO dejes marcadores [Completar]). '
        'Escribe el documento completo.\n\n'
        'INDICACIÓN: $userMessage\n\n'
        '${contextoLegal.isNotEmpty ? 'LEYES: $contextoLegal\n\n' : ''}'
        '${contextoJurisprudencial.isNotEmpty ? 'JURISPRUDENCIA: $contextoJurisprudencial\n\n' : ''}';

    final documento = await _askAI(prompt);
    _ultimoDocumento = documento;
    _ultimoTitulo = 'Documento Legal';
    return '✅ Documento generado:\n\n'
        '━━━━━━━━━━━━━━━━━━━━━━\n\n'
        '$documento\n\n'
        '━━━━━━━━━━━━━━━━━━━━━━\n\n'
        '⚠️ Revísalo y pídeme los cambios que quieras.';
  }

  Future<String> startDocumentCreation(String userMessage) async {
    _ultimoDocumento = null;
    _ultimoTitulo = null;

    // 1. Clasificación por lenguaje natural (catálogo + requisitos del COPP)
    final tipoCatalogo = CatalogoDocumentos.clasificar(userMessage);
    if (tipoCatalogo != null) {
      return await _iniciarDocumentoCatalogo(tipoCatalogo, promptOriginal: userMessage);
    }

    // 2. Buscar template JSON por palabras clave
    final templates = _templateService.getAllTemplates();
    DocumentTemplate? selectedTemplate;
    
    // Buscar coincidencias por palabras clave
    final messageLower = userMessage.toLowerCase();
    for (final template in templates) {
      final templateNameLower = template.name.toLowerCase();
      if (messageLower.contains(templateNameLower) ||
          templateNameLower.contains(messageLower)) {
        selectedTemplate = template;
        break;
      }
    }
    
    // Si no encuentra coincidencia directa, usar palabras clave comunes
    if (selectedTemplate == null) {
      if (messageLower.contains('acusatorio') || messageLower.contains('acusación')) {
        selectedTemplate = templates.firstWhere(
          (t) => t.name.contains('Acusatorio'),
          orElse: () => templates.first,
        );
      } else if (messageLower.contains('apelación') || messageLower.contains('recurso')) {
        selectedTemplate = templates.firstWhere(
          (t) => t.name.contains('Apelación'),
          orElse: () => templates.first,
        );
      } else if (messageLower.contains('libertad') || messageLower.contains('excarcelación')) {
        selectedTemplate = templates.firstWhere(
          (t) => t.name.contains('Libertad'),
          orElse: () => templates.first,
        );
      } else if (messageLower.contains('amparo')) {
        selectedTemplate = templates.firstWhere(
          (t) => t.name.contains('Amparo'),
          orElse: () => templates.first,
        );
      } else if (messageLower.contains('nulidad')) {
        selectedTemplate = templates.firstWhere(
          (t) => t.name.contains('Nulidad'),
          orElse: () => templates.first,
        );
      } else if (messageLower.contains('oposición') || messageLower.contains('medida cautelar')) {
        selectedTemplate = templates.firstWhere(
          (t) => t.name.contains('Oposición'),
          orElse: () => templates.first,
        );
      }
    }
    
    // Si no hay tipo ni template reconocido, generar un documento libre
    // a partir del prompt (sin entrar en un bucle de preguntas).
    if (selectedTemplate == null) {
      return await _generarDocumentoLibre(userMessage);
    }

    // Configurar el template seleccionado
    _currentTemplateId = selectedTemplate.id;
    _remainingFields = List.from(selectedTemplate.fields);
    _currentFieldIndex = 0;
    _collectedData.clear();
    _procesalPhase = selectedTemplate.category;

    return '✅ Perfecto, vamos a redactar un **${selectedTemplate.name}**.\n\n'
           '${selectedTemplate.description ?? ''}\n\n'
           '━━━━━━━━━━━━━━━━━━━━━━\n\n'
           '${_generateNextQuestion(selectedTemplate)}';
  }

  Future<String> processUserResponse(String userMessage) async {
    if (_tipoActivo != null) {
      return await _procesarRespuestaCatalogo(userMessage);
    }

    // Revisión del último documento generado (cambios solicitados en el chat)
    if (_ultimoDocumento != null &&
        _ultimoDocumento!.isNotEmpty &&
        _esRevision(userMessage)) {
      return await _revisarDocumento(userMessage);
    }

    if (_currentTemplateId.isEmpty) {
      return await startDocumentCreation(userMessage);
    }

    final template = _templateService.getTemplateById(_currentTemplateId);
    if (template == null) {
      return 'Error: Template no encontrado';
    }

    // Guardar respuesta del campo actual
    if (_currentFieldIndex < _remainingFields.length) {
      final currentField = _remainingFields[_currentFieldIndex];
      
      // Extraer valor con IA si es necesario
      String extractedValue = await _extractValue(userMessage, currentField);
      _collectedData[currentField.key] = extractedValue;
      
      _currentFieldIndex++;
    }

    // Si ya completamos todos los campos, generar documento
    if (_currentFieldIndex >= _remainingFields.length) {
      return await _generateFinalDocument(template);
    }

    // Hacer siguiente pregunta
    return _generateNextQuestion(template);
  }

  String _generateNextQuestion(DocumentTemplate template) {
    if (_currentFieldIndex >= _remainingFields.length) {
      return '✅ Información completa. Generando documento...';
    }

    final field = _remainingFields[_currentFieldIndex];
    String question = '📝 ${field.label}:\n';

    if (field.hint != null) {
      question += '\n💡 ${field.hint}\n';
    }

    if (field.options != null && field.options!.isNotEmpty) {
      question += '\nOpciones:\n';
      for (int i = 0; i < field.options!.length; i++) {
        question += '${i + 1}. ${field.options![i]}\n';
      }
    }

    // Mostrar progreso
    final progress = '(${_currentFieldIndex + 1}/${_remainingFields.length})';
    return '$question\n$progress';
  }

  // ---------------------------------------------------------------------------
  // Flujo por catálogo (lenguaje natural + requisitos legales)
  // ---------------------------------------------------------------------------

  Future<String> _iniciarDocumentoCatalogo(TipoDocumentoLegal tipo,
      {String? promptOriginal}) async {
    _tipoActivo = tipo;
    _currentTemplateId = '';
    _procesalPhase = tipo.rol;
    _collectedData.clear();

    _requisitosTexto = await _obtenerRequisitosTexto(tipo);

    // Extraer del prompt original todo lo que el usuario ya dio.
    if (promptOriginal != null && promptOriginal.trim().isNotEmpty) {
      final extraidos =
          await _extraerDatosBulk(promptOriginal, tipo.datosRequeridos);
      extraidos.forEach((i, v) {
        if (v.isNotEmpty && v.toLowerCase() != 'omitir') {
          _collectedData['dato_$i'] = v;
        }
      });
    }

    _recalcularFaltantes(tipo);

    final requisitosSeccion = _requisitosTexto.isNotEmpty
        ? '\n\n**Requisitos legales aplicables:**\n$_requisitosTexto\n'
        : '';

    if (_datosPendientes.isEmpty) {
      return await _generarDocumentoCatalogo();
    }

    return '✅ Voy a redactar un(a) **${tipo.nombre}** ${_rolLabel(tipo.rol)}.\n'
        'Base legal: ${tipo.baseLegalResumen}.$requisitosSeccion\n'
        '━━━━━━━━━━━━━━━━━━━━━━\n\n'
        '${_listaFaltantes(tipo)}';
  }

  void _recalcularFaltantes(TipoDocumentoLegal tipo) {
    _datosPendientes = <int>[];
    for (var i = 0; i < tipo.datosRequeridos.length; i++) {
      final v = _collectedData['dato_$i'] ?? '';
      if (v.isEmpty || v.toLowerCase() == 'omitir') {
        _datosPendientes.add(i);
      }
    }
  }

  String _listaFaltantes(TipoDocumentoLegal tipo) {
    final b = StringBuffer(
        'Para redactarlo completo necesito estos datos (puedes dármelos '
        'todos en un solo mensaje):\n');
    for (final i in _datosPendientes) {
      b.writeln('- ${tipo.datosRequeridos[i]}');
    }
    return b.toString();
  }

  String _rolLabel(String rol) {
    switch (rol) {
      case 'juez':
        return '(documento de juez)';
      case 'abogado':
        return '(documento de abogado/fiscal)';
      default:
        return '(para juez o abogado)';
    }
  }

  Future<String> _procesarRespuestaCatalogo(String userMessage) async {
    final tipo = _tipoActivo!;
    final texto = userMessage.trim();

    final extraidos = await _extraerDatosBulk(texto, tipo.datosRequeridos);
    for (final i in _datosPendientes) {
      final v = extraidos[i] ?? '';
      if (v.isNotEmpty && v.toLowerCase() != 'omitir') {
        _collectedData['dato_$i'] = v;
      }
    }

    _recalcularFaltantes(tipo);

    if (_datosPendientes.isEmpty) {
      return await _generarDocumentoCatalogo();
    }
    return 'Aún me faltan estos datos:\n${_listaFaltantes(tipo)}';
  }

  Future<Map<int, String>> _extraerDatosBulk(
      String userMessage, List<String> campos) async {
    if (campos.isEmpty) return {};
    try {
      final prompt = 'Del siguiente texto, extrae el valor de cada campo. '
          'Responde SOLO con un JSON cuyas claves sean los números 0..${campos.length - 1} '
          '(en el orden de los campos) y los valores lo extraído. Si un dato no '
          'aparece, deja el valor como cadena vacía.\n\n'
          'CAMPOS:\n${campos.asMap().entries.map((e) => '${e.key}: ${e.value}').join('\n')}\n\n'
          'TEXTO DEL USUARIO: "$userMessage"\n\n'
          'JSON:';
      final resp = await _askAI(prompt);
      final json = _parseJson(resp);
      if (json is Map<String, dynamic>) {
        final out = <int, String>{};
        json.forEach((k, v) {
          final idx = int.tryParse(k);
          if (idx != null && idx >= 0 && idx < campos.length) {
            out[idx] = v.toString().trim();
          }
        });
        return out;
      }
      return {};
    } catch (e) {
      debugPrint('⚠️ Error extrayendo datos en bloque: $e');
      return {};
    }
  }

  dynamic _parseJson(String raw) {
    var t = raw.trim();
    if (t.startsWith('```json')) t = t.substring(7);
    if (t.startsWith('```')) t = t.substring(3);
    if (t.endsWith('```')) t = t.substring(0, t.length - 3);
    try {
      return _jsonDecode(t);
    } catch (_) {}
    final m = RegExp(r'(\{[\s\S]*\})').firstMatch(t);
    if (m != null) {
      try {
        return _jsonDecode(m.group(0)!);
      } catch (_) {}
    }
    return null;
  }

  dynamic _jsonDecode(String t) {
    // usa dart:convert jsonDecode (import ya presente como 'convert')
    return jsonDecode(t);
  }

  Future<String> _obtenerRequisitosTexto(TipoDocumentoLegal tipo) async {
    final buffer = StringBuffer();
    final servicio = LeyesRepositorioService();
    for (final ref in tipo.baseLegal) {
      try {
        final arts =
            await servicio.obtenerArticulos(ref.leySlug, ref.articulos);
        for (final art in arts) {
          final texto = '${art.encabezado ?? ''} ${art.texto}'.trim();
          final corto =
              texto.length > 600 ? '${texto.substring(0, 600)}...' : texto;
          buffer.writeln('- Art. ${art.identificador} ${ref.leyNombre}: $corto');
        }
      } catch (e) {
        debugPrint('⚠️ No se pudo recuperar base legal ${ref.leyNombre}: $e');
      }
    }
    return buffer.toString().trim();
  }

  Future<String> _generarDocumentoCatalogo() async {
    final tipo = _tipoActivo!;

    final datosBuffer = StringBuffer();
    for (var i = 0; i < tipo.datosRequeridos.length; i++) {
      final label = tipo.datosRequeridos[i];
      final value = _collectedData['dato_$i'] ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'omitir') {
        datosBuffer.writeln('- $label: $value');
      }
    }
    final datos = datosBuffer.toString().trim();

    // RAG: jurisprudencia real del TSJ
    final consultaRAG = '${tipo.nombre} $datos';
    final corta =
        consultaRAG.length > 500 ? consultaRAG.substring(0, 500) : consultaRAG;
    final contextoJurisprudencial =
        await _obtenerJurisprudenciaContexto(corta);

    final rolInstruccion = tipo.rol == 'juez'
        ? 'Es una DECISIÓN JUDICIAL. Usa la estructura de una decisión venezolana: '
              'encabezado "REPÚBLICA BOLIVARIANA DE VENEZUELA" / "PODER JUDICIAL", '
              'tribunal, fecha, secciones en MAYÚSCULAS (IDENTIFICACIÓN DE LAS PARTES, '
              'DE LOS HECHOS, CONSIDERACIONES PARA DECIDIR, DISPOSITIVA) y cierre con firmas.'
        : 'Es un ESCRITO/SOLICITUD de parte. Usa la estructura forense venezolana: '
              'encabezado "Ciudadano(a) Juez del Tribunal... Su despacho.-" dirigido a '
              '"${tipo.destinatarioEfectivo}", identificación de las partes, '
              'capítulos (DE LOS HECHOS, DEL DERECHO, PETITORIO) y firma del abogado.';

    final jurisprudenciaSection = contextoJurisprudencial.isNotEmpty
        ? '\n\nJURISPRUDENCIA REAL DEL TSJ DISPONIBLE PARA CITAR:\n'
              '$contextoJurisprudencial\n\n'
              'INSTRUCCIONES DE JURISPRUDENCIA (CRÍTICAS — cero margen de error):\n'
              '- Cuando el contexto indique "Sentencia citada (fuente del criterio)", '
              'copia ESA referencia EXACTA tal cual (número, fecha, sala, ponente). '
              'NO la cambies, NO la reformules, NO la completes con datos que no '
              'aparezcan en el contexto.\n'
              '- Cita TEXTUALMENTE (entre comillas) SOLO el texto de "Cita textual" '
              'del contexto. Nunca atribuyas un criterio a una sentencia distinta '
              'de la indicada.\n'
              '- Si NO hay sentencia citada en el contexto, NO inventes número, '
              'fecha ni ponente: cita el criterio sin atribución a sentencia '
              'específica.\n'
              '- NO inventes sentencias, números, fechas, ponentes ni criterios.\n'
               'INSTRUCCIONES DE DOCTRINA ACADÉMICA (CRÍTICAS — cero margen de error):\n'
               '- Si el contexto incluye "DOCTRINA ACADÉMICA", puedes fundamentar '
               'con esas obras: cita SOLO el autor, la obra y la página que '
               'aparezcan EXACTAMENTE en el contexto.\n'
               '- Formato de cita: "Autor, Nombre de la Obra, p. X" (usa la página '
               'solo si el contexto la indica; si dice "(no indicada)", omite la página).\n'
               '- NO inventes autores, obras ni páginas que no estén en el contexto '
               'de doctrina académica.'
        : '';

    final requisitosSection = _requisitosTexto.isNotEmpty
        ? '\n\nREQUISITOS LEGALES (deben cumplirse/verificarse en el documento):\n'
              '$_requisitosTexto\n'
        : '';

    final prompt = 'Redacta un(a) **${tipo.nombre}** con base en la ley venezolana vigente.\n'
        '$rolInstruccion\n'
        '\nDATOS DEL CASO:\n'
        '${datos.isEmpty ? '(No se proporcionaron datos; usa marcadores [DATOS] donde corresponda)' : datos}'
        '$requisitosSection'
        '$jurisprudenciaSection\n'
        'Escribe el documento completo, en español, con lenguaje jurídico formal. '
        'Determina la fase procesal según el tipo de documento y usa la terminología '
        'correcta: en fase de CONTROL el sujeto es "IMPUTADO"; en fase de JUICIO es '
        '"ACUSADO"; en fase de EJECUCIÓN es "PENADO". '
        'Usa "##" para el título de cada sección/capítulo (así salen centrados y en negrita). '
        'Cita SOLO artículos vigentes (no derogados ni reformados). '
        'NO dejes marcadores "[Completar]", "[Indicar...]" ni "[DATOS]": si falta un dato '
        'esencial, escríbelo de forma genérica y añade al final una lista de "DATOS FALTANTES". '
        'No agregues texto introductorio ni de cierre distinto al documento mismo.';

    final documento = await _askAI(prompt);

    _ultimoDocumento = documento;
    _ultimoTitulo = tipo.nombre;

    // Reiniciar estado del catálogo
    _tipoActivo = null;
    _datosPendientes.clear();
    _requisitosTexto = '';
    _collectedData.clear();

    return '✅ Documento generado:\n\n'
        '━━━━━━━━━━━━━━━━━━━━━━\n\n'
        '$documento\n\n'
        '━━━━━━━━━━━━━━━━━━━━━━\n\n'
        '⚠️ **IMPORTANTE**: Documento generado por IA. Revísalo y ajústalo antes de presentarlo.\n\n'
        '¿Deseas redactar otro documento?';
  }

  Future<String> _extractValue(String userMessage, TemplateField field) async {
    // Para campos simples, usar el mensaje directamente
    if (field.type == FieldType.text || field.type == FieldType.multiline) {
      return userMessage.trim();
    }

    // Para campos complejos, usar IA para extraer
    final prompt = 'Del siguiente texto, extrae SOLO el valor para "${field.label}": "$userMessage". '
                   'Responde únicamente con el valor extraído, sin explicaciones.';
    
    try {
      return await _askAI(prompt);
    } catch (e) {
      return userMessage.trim();
    }
  }

  Future<String> _generateFinalDocument(DocumentTemplate template) async {
    final document = _templateService.generateDocument(
      template,
      _collectedData,
      _procesalPhase,
    );

    // 🔍 RAG: recuperar jurisprudencia real del TSJ relevante al documento
    // (a partir del tipo de documento + datos recopilados del usuario)
    final consultaRAG = [
      template.name,
      _procesalPhase,
      ..._collectedData.values
          .where((v) => v != null && v.toString().trim().isNotEmpty),
    ].join(' ');
    final contextoJurisprudencial = await _obtenerJurisprudenciaContexto(
      consultaRAG.length > 500 ? consultaRAG.substring(0, 500) : consultaRAG,
    );
    final contextoLegal = await _obtenerLeyesContexto(
      consultaRAG.length > 500 ? consultaRAG.substring(0, 500) : consultaRAG,
    );

    // Mejorar redacción con IA incorporando leyes + jurisprudencia real
    final improvedDocument = await _improveDocument(
      document,
      template.name,
      jurisprudenciaContexto: contextoJurisprudencial,
      leyesContexto: contextoLegal,
    );

    // Guardar referencia del último documento generado (para el historial)
    _ultimoDocumento = improvedDocument;
    _ultimoTitulo = template.name;

    // Reiniciar estado
    _currentTemplateId = '';
    _collectedData.clear();
    _remainingFields.clear();
    _currentFieldIndex = 0;

    final leyesSeccion = contextoLegal.isNotEmpty
        ? '\n\n━━━━━━━━━━━━━━━━━━━━━━\n\n'
              '📚 **LEYES CONSULTADAS:**\n\n'
              '$contextoLegal'
        : '';

    final fuentesSeccion = contextoJurisprudencial.isNotEmpty
        ? '\n\n━━━━━━━━━━━━━━━━━━━━━━\n\n'
              '⚖️ **JURISPRUDENCIA DE RESPALDO CONSULTADA (TSJ):**\n\n'
              '$contextoJurisprudencial'
        : '';

    return '✅ Documento generado:\n\n'
           '━━━━━━━━━━━━━━━━━━━━━━\n\n'
           '$improvedDocument$leyesSeccion$fuentesSeccion\n\n'
           '━━━━━━━━━━━━━━━━━━━━━━\n\n'
           '⚠️ **IMPORTANTE**: Este documento fue generado por IA. '
           'Debe ser revisado y ajustado por un abogado antes de presentarlo ante tribunales.\n\n'
           '¿Deseas redactar otro documento?';
  }

  bool _esRevision(String msg) {
    final m = msg.toLowerCase();
    const claves = [
      'cambia', 'cambie', 'quita', 'quite', 'elimina', 'agrega', 'agregue',
      'añade', 'corrige', 'corrija', 'modifica', 'modifique', 'sustituye',
      'sustituya', 'ajusta', 'ajuste', 'pon ',
    ];
    return claves.any((c) => m.contains(c));
  }

  Future<String> _revisarDocumento(String userMessage) async {
    final doc = _ultimoDocumento;
    if (doc == null || doc.trim().isEmpty) {
      return startDocumentCreation(userMessage);
    }
    try {
      final prompt = 'Tienes el siguiente documento legal venezolano:\n\n'
          '"""\n$doc\n"""\n\n'
          'El usuario solicita este cambio: "$userMessage".\n'
          'Aplica SOLO ese cambio al documento y devuelve el documento COMPLETO '
          'corregido, sin explicaciones ni texto adicional. Mantén el formato, '
          'los subtítulos, la terminología y la fundamentación original.';
      final revisado = await _askAI(prompt);
      _ultimoDocumento = revisado;
      return '✅ Documento actualizado:\n\n'
          '━━━━━━━━━━━━━━━━━━━━━━\n\n'
          '$revisado\n\n'
          '━━━━━━━━━━━━━━━━━━━━━━\n\n'
          '¿Algún otro cambio?';
    } catch (e) {
      debugPrint('⚠️ Error revisando documento: $e');
      return 'No pude aplicar el cambio. Inténtalo de nuevo con más detalle.';
    }
  }

  /// 🔍 RAG: recupera jurisprudencia real del TSJ relevante para el documento.
  /// Devuelve contexto formateado (vacío si no hay resultados o hay error).
  Future<String> _obtenerJurisprudenciaContexto(String consulta) async {
    if (consulta.trim().isEmpty) return '';
    try {
      final rag = await RAGService.obtenerContextoYFuentes(
        consulta: consulta,
        limit: 5,
      );
      debugPrint(
          '⚖️ RAG redactor: ${rag.sentencias.length} sentencias reales recuperadas');
      return rag.contexto;
    } catch (e) {
      debugPrint('⚠️ RAG redactor no disponible: $e');
      return '';
    }
  }

  /// 📚 RAG: recupera artículos de ley relevantes del repositorio de leyes.
  Future<String> _obtenerLeyesContexto(String consulta) async {
    if (consulta.trim().isEmpty) return '';
    try {
      final resultados = await LeyesRepositorioService().buscar(consulta, limite: 6);
      if (resultados.isEmpty) return '';
      final buffer = StringBuffer();
      for (final r in resultados) {
        final reg = r.registro;
        final tipo = reg.tipoNorma == 'Artículo'
            ? 'Artículo ${reg.identificador}'
            : reg.tipoNorma;
        final texto = '${reg.encabezado ?? ''} ${reg.texto}'.trim();
        buffer.writeln('- $tipo de ${reg.leyNombre}:');
        buffer.writeln('  $texto');
      }
      debugPrint('📚 RAG leyes: ${resultados.length} artículos recuperados');
      return buffer.toString().trim();
    } catch (e) {
      debugPrint('⚠️ RAG leyes no disponible: $e');
      return '';
    }
  }

  Future<String> _improveDocument(
    String document,
    String documentType, {
    String jurisprudenciaContexto = '',
    String leyesContexto = '',
  }) async {
    final jurisprudenciaSection = jurisprudenciaContexto.isNotEmpty
        ? '\n\nJURISPRUDENCIA REAL DEL TSJ DISPONIBLE PARA CITAR:\n'
              '$jurisprudenciaContexto\n\n'
              'INSTRUCCIONES DE JURISPRUDENCIA (CRÍTICAS — cero margen de error):\n'
              '- Si el documento requiere fundamento jurisprudencial, cita SOLO '
              'estas sentencias reales.\n'
              '- Cuando el contexto indique "Sentencia citada (fuente del criterio)", '
              'copia ESA referencia EXACTA tal cual (número, fecha, sala, ponente). '
              'NO la cambies ni la completes con datos ausentes.\n'
              '- Cita TEXTUALMENTE (entre comillas) el criterio de la sala con el '
              'texto exacto del contexto, sin atribuirlo a otra sentencia.\n'
              '- Si no hay sentencia citada, cita el criterio sin número de '
              'sentencia (solo "la Sala de Casación Penal ha sostenido que...").\n'
              '- NO inventes sentencias, números, ponentes, fechas ni criterios.\n'
              '- Incorpóralas en la fundamentación del escrito cuando sea pertinente.'
        : '';

    final leyesSection = leyesContexto.isNotEmpty
        ? '\n\nLEYES DISPONIBLES PARA CITAR:\n'
              '$leyesContexto\n\n'
              'INSTRUCCIONES DE LEYES:\n'
              '- Fundamenta el escrito en estos artículos reales, citándolos '
              'correctamente (ley y artículo).\n'
              '- Usa SOLO artículos vigentes (no derogados ni reformados).\n'
              '- NO inventes artículos ni números.\n'
              '- Incorpóralos en la fundamentación jurídica del escrito.'
        : '';

    final prompt = 'Mejora la redacción legal de este $documentType venezolano. '
                   'Mantén el contenido pero perfecciona el lenguaje jurídico, la estructura y la coherencia. '
                   'NO inventes información nueva, solo mejora la redacción:'
                   '$leyesSection$jurisprudenciaSection\n\n$document';

    try {
      return await _askAI(prompt);
    } catch (e) {
      return document; // Si falla, devolver original
    }
  }

  Future<String> _askAI(String prompt) async {
    // Telemetría silenciosa (cronómetro automático + registro de uso)
    return await AIAnalyticsService.trackOperation(
      toolName: AIAnalyticsService.redactorDocumentos,
      actionType: AIAnalyticsService.generation,
      operation: () async {
        try {
          // Inicializar AIService si no está inicializado
          await AIService.inicializar();
          
          // Usar el método de consulta general del AIService
          final response = await AIService.procesarConsultaGeneral(prompt);
          
          return response;
        } catch (e) {
          debugPrint('❌ Error en _askAI: $e');
          // Fallback: devolver mensaje de error claro
          return 'Error al procesar con IA. Por favor, intenta reformular tu solicitud.';
        }
      },
    );
  }

  // Obtener estado actual para UI
  Map<String, dynamic> getCurrentState() {
    return {
      'templateId': _currentTemplateId,
      'phase': _procesalPhase,
      'collectedData': Map.from(_collectedData),
      'progress': _currentFieldIndex,
      'total': _remainingFields.length,
    };
  }

  // Reiniciar conversación
  void reset() {
    _currentTemplateId = '';
    _procesalPhase = '';
    _collectedData.clear();
    _remainingFields.clear();
    _currentFieldIndex = 0;
    _tipoActivo = null;
    _datosPendientes.clear();
    _requisitosTexto = '';
    _ultimoDocumento = null;
    _ultimoTitulo = null;
  }
}

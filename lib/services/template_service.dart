import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/document_template.dart';

class TemplateService {
  static final TemplateService _instance = TemplateService._internal();
  factory TemplateService() => _instance;
  TemplateService._internal();

  List<DocumentTemplate> _templates = [];
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Cargar templates desde assets
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      final templateFiles = manifestMap.keys
          .where((String key) => key.startsWith('assets/templates/') && key.endsWith('.json'))
          .toList();

      for (String path in templateFiles) {
        try {
          final content = await rootBundle.loadString(path);
          final templateJson = json.decode(content);
          _templates.add(DocumentTemplate.fromJson(templateJson));
        } catch (e) {
          print('Error cargando template $path: $e');
        }
      }

      _initialized = true;
      print('Templates cargados: ${_templates.length}');
    } catch (e) {
      print('Error inicializando templates: $e');
    }
  }

  List<DocumentTemplate> getAllTemplates() {
    return List.unmodifiable(_templates);
  }

  List<DocumentTemplate> getTemplatesByCategory(String category) {
    return _templates
        .where((t) => t.category == category || t.category == 'general')
        .toList();
  }

  DocumentTemplate? getTemplateById(String id) {
    try {
      return _templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  String generateDocument(DocumentTemplate template, Map<String, String> values, String procesalPhase) {
    String result = template.content;

    // Reemplazar sujeto procesal según fase
    final sujetoProcesal = _getSujetoProcesal(procesalPhase);
    result = result.replaceAll('[SUJETO_PROCESAL]', sujetoProcesal);
    result = result.replaceAll('[SUJETO_PROCESAL_MAYUS]', sujetoProcesal.toUpperCase());

    // Reemplazar todos los campos
    values.forEach((key, value) {
      result = result.replaceAll('[$key]', value);
    });

    // Reemplazar fecha actual si existe
    final now = DateTime.now();
    result = result.replaceAll('[FECHA_ACTUAL]', _formatDate(now));
    result = result.replaceAll('[FECHA_ACTUAL_LARGA]', _formatDateLong(now));

    return result;
  }

  String _getSujetoProcesal(String phase) {
    switch (phase.toLowerCase()) {
      case 'control':
        return 'imputado';
      case 'juicio':
        return 'acusado';
      case 'ejecucion':
      case 'ejecución':
        return 'penado';
      default:
        return 'imputado';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateLong(DateTime date) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  List<TemplateField> extractMissingFields(String content) {
    final RegExp fieldPattern = RegExp(r'\[([A-Z_]+)\]');
    final matches = fieldPattern.allMatches(content);
    final Set<String> fieldKeys = {};
    
    for (var match in matches) {
      final key = match.group(1);
      if (key != null && 
          key != 'FECHA_ACTUAL' && 
          key != 'FECHA_ACTUAL_LARGA' &&
          key != 'SUJETO_PROCESAL' &&
          key != 'SUJETO_PROCESAL_MAYUS') {
        fieldKeys.add(key);
      }
    }

    return fieldKeys.map((key) {
      return TemplateField(
        key: key,
        label: _beautifyFieldName(key),
        type: _guessFieldType(key),
        required: true,
      );
    }).toList();
  }

  String _beautifyFieldName(String key) {
    return key
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  FieldType _guessFieldType(String key) {
    if (key.contains('FECHA')) return FieldType.date;
    if (key.contains('CEDULA')) return FieldType.cedula;
    if (key.contains('EXPEDIENTE')) return FieldType.expediente;
    if (key.contains('HECHOS') || key.contains('FUNDAMENTO') || key.contains('PETITORIO')) {
      return FieldType.multiline;
    }
    if (key.contains('NUMERO') || key.contains('NUM')) return FieldType.number;
    return FieldType.text;
  }

  // Validar que todos los campos requeridos estén llenos
  Map<String, String> validateFields(DocumentTemplate template, Map<String, String> values) {
    Map<String, String> errors = {};
    
    for (var field in template.fields) {
      if (field.required) {
        final value = values[field.key];
        if (value == null || value.trim().isEmpty) {
          errors[field.key] = 'Este campo es obligatorio';
        }
      }
    }

    return errors;
  }
}

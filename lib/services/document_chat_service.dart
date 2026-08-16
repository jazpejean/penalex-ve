import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/document_template.dart';
import 'template_service.dart';
import 'ai_service.dart';
import 'ai_analytics_service.dart';

class DocumentChatService {
  final TemplateService _templateService = TemplateService();
  
  String _currentTemplateId = '';
  String _procesalPhase = '';
  Map<String, String> _collectedData = {};
  List<TemplateField> _remainingFields = [];
  int _currentFieldIndex = 0;

  Future<String> startDocumentCreation(String userMessage) async {
    // Buscar template directamente por palabras clave en el mensaje
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
    
    // Si aún no hay template, mostrar opciones
    if (selectedTemplate == null) {
      return '📄 Por favor, especifica qué documento deseas redactar:\n\n'
             '• Escrito acusatorio\n'
             '• Recurso de apelación\n'
             '• Solicitud de libertad\n'
             '• Amparo constitucional\n'
             '• Solicitud de nulidad\n'
             '• Oposición a medida cautelar\n\n'
             'Ejemplo: "Quiero redactar una solicitud de libertad"';
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

    // Mejorar redacción con IA
    final improvedDocument = await _improveDocument(document, template.name);

    // Reiniciar estado
    _currentTemplateId = '';
    _collectedData.clear();
    _remainingFields.clear();
    _currentFieldIndex = 0;

    return '✅ Documento generado:\n\n'
           '━━━━━━━━━━━━━━━━━━━━━━\n\n'
           '$improvedDocument\n\n'
           '━━━━━━━━━━━━━━━━━━━━━━\n\n'
           '⚠️ **IMPORTANTE**: Este documento fue generado por IA. '
           'Debe ser revisado y ajustado por un abogado antes de presentarlo ante tribunales.\n\n'
           '¿Deseas redactar otro documento?';
  }

  Future<String> _improveDocument(String document, String documentType) async {
    final prompt = 'Mejora la redacción legal de este $documentType venezolano. '
                   'Mantén el contenido pero perfecciona el lenguaje jurídico, la estructura y la coherencia. '
                   'NO inventes información nueva, solo mejora la redacción:\n\n$document';

    try {
      return await _askAI(prompt);
    } catch (e) {
      return document; // Si falla, devolver original
    }
  }

  Future<String> _askAI(String prompt) async {
    // Track con cronómetro automático
    return await AIAnalyticsService.trackOperation(
      toolName: AIToolName.redactorDocumentos,
      actionType: AIActionType.generation,
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
  }
}

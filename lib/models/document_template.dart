class DocumentTemplate {
  final String id;
  final String name;
  final String category; // 'control', 'juicio', 'ejecucion', 'general'
  final String content;
  final List<TemplateField> fields;
  final String? description;

  DocumentTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.content,
    required this.fields,
    this.description,
  });

  factory DocumentTemplate.fromJson(Map<String, dynamic> json) {
    return DocumentTemplate(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      content: json['content'],
      fields: (json['fields'] as List)
          .map((f) => TemplateField.fromJson(f))
          .toList(),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'content': content,
      'fields': fields.map((f) => f.toJson()).toList(),
      'description': description,
    };
  }
}

class TemplateField {
  final String key; // e.g., 'NOMBRE_ABOGADO'
  final String label; // e.g., 'Nombre del Abogado'
  final FieldType type;
  final bool required;
  final String? hint;
  final List<String>? options; // Para campos de selección
  final String? defaultValue;

  TemplateField({
    required this.key,
    required this.label,
    required this.type,
    this.required = true,
    this.hint,
    this.options,
    this.defaultValue,
  });

  factory TemplateField.fromJson(Map<String, dynamic> json) {
    return TemplateField(
      key: json['key'],
      label: json['label'],
      type: FieldType.values.firstWhere(
        (e) => e.toString() == 'FieldType.${json['type']}',
      ),
      required: json['required'] ?? true,
      hint: json['hint'],
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
      defaultValue: json['defaultValue'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'type': type.toString().split('.').last,
      'required': required,
      'hint': hint,
      'options': options,
      'defaultValue': defaultValue,
    };
  }
}

enum FieldType {
  text,
  multiline,
  date,
  select,
  number,
  cedula,
  expediente,
}

class GeneratedDocument {
  final String templateId;
  final String templateName;
  final String content;
  final Map<String, String> filledFields;
  final DateTime createdAt;
  final String? caseId; // Vinculado a un caso de la agenda

  GeneratedDocument({
    required this.templateId,
    required this.templateName,
    required this.content,
    required this.filledFields,
    required this.createdAt,
    this.caseId,
  });

  Map<String, dynamic> toJson() {
    return {
      'templateId': templateId,
      'templateName': templateName,
      'content': content,
      'filledFields': filledFields,
      'createdAt': createdAt.toIso8601String(),
      'caseId': caseId,
    };
  }

  factory GeneratedDocument.fromJson(Map<String, dynamic> json) {
    return GeneratedDocument(
      templateId: json['templateId'],
      templateName: json['templateName'],
      content: json['content'],
      filledFields: Map<String, String>.from(json['filledFields']),
      createdAt: DateTime.parse(json['createdAt']),
      caseId: json['caseId'],
    );
  }
}

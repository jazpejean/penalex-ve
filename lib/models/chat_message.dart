/// Rol del mensaje en el chat
enum MessageRole {
  user,
  assistant,
  system,
}

/// Tipo de contenido citado
enum SourceType {
  ley,
  jurisprudencia,
  articulo,
  doctrina,
}

/// Fuente citada en el mensaje
class MessageSource {
  MessageSource({
    required this.type,
    required this.title,
    required this.reference,
    this.url,
    this.excerpt,
  });

  factory MessageSource.fromMap(Map<String, dynamic> map) {
    return MessageSource(
      type: SourceType.values[map['type'] as int? ?? 0],
      title: map['title'] as String? ?? '',
      reference: map['reference'] as String? ?? '',
      url: map['url'] as String?,
      excerpt: map['excerpt'] as String?,
    );
  }

  final SourceType type;
  final String title;
  final String reference;
  final String? url;
  final String? excerpt;

  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'title': title,
      'reference': reference,
      if (url != null) 'url': url,
      if (excerpt != null) 'excerpt': excerpt,
    };
  }

  String get typeLabel {
    switch (type) {
      case SourceType.ley:
        return 'Ley';
      case SourceType.jurisprudencia:
        return 'Jurisprudencia';
      case SourceType.articulo:
        return 'Artículo';
      case SourceType.doctrina:
        return 'Doctrina';
    }
  }
}

/// Mensaje individual del chat
class ChatMessage {
  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.sources = const [],
    this.modelUsed,
    this.tokenCount,
    this.isLoading = false,
    this.error,
    this.attachmentUrl,
    this.attachmentType,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      role: _parseRole(map['role'] as String),
      content: map['content'] as String? ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
      sources: (map['sources'] as List<dynamic>?)
              ?.map((s) => MessageSource.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      modelUsed: map['model_used'] as String?,
      tokenCount: map['token_count'] as int?,
      attachmentUrl: map['attachment_url'] as String?,
      attachmentType: map['attachment_type'] as String?,
    );
  }

  static MessageRole _parseRole(String role) {
    switch (role) {
      case 'user':
        return MessageRole.user;
      case 'assistant':
        return MessageRole.assistant;
      case 'system':
        return MessageRole.system;
      default:
        return MessageRole.user;
    }
  }

  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final List<MessageSource> sources;
  final String? modelUsed;
  final int? tokenCount;
  final bool isLoading;
  final String? error;
  final String? attachmentUrl;
  final String? attachmentType;

  Map<String, dynamic> toMap() {
    return {
      'role': role.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'sources': sources.map((s) => s.toMap()).toList(),
      if (modelUsed != null) 'model_used': modelUsed,
      if (tokenCount != null) 'token_count': tokenCount,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      if (attachmentType != null) 'attachment_type': attachmentType,
    };
  }

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    List<MessageSource>? sources,
    String? modelUsed,
    int? tokenCount,
    bool? isLoading,
    String? error,
    String? attachmentUrl,
    String? attachmentType,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      sources: sources ?? this.sources,
      modelUsed: modelUsed ?? this.modelUsed,
      tokenCount: tokenCount ?? this.tokenCount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentType: attachmentType ?? this.attachmentType,
    );
  }

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get hasError => error != null;
  bool get hasSources => sources.isNotEmpty;
  bool get hasAttachment => attachmentUrl != null;
}

/// Conversación completa del chat
class ChatConversation {
  ChatConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.summary,
    this.messageCount = 0,
    this.tags = const [],
    this.isPinned = false,
  });

  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Nueva conversación',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      summary: map['summary'] as String?,
      messageCount: map['message_count'] as int? ?? 0,
      tags: (map['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isPinned: map['is_pinned'] as bool? ?? false,
    );
  }

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? summary;
  final int messageCount;
  final List<String> tags;
  final bool isPinned;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (summary != null) 'summary': summary,
      'message_count': messageCount,
      'tags': tags,
      'is_pinned': isPinned,
    };
  }

  ChatConversation copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? summary,
    int? messageCount,
    List<String>? tags,
    bool? isPinned,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      summary: summary ?? this.summary,
      messageCount: messageCount ?? this.messageCount,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';

import '../config/app_colors.dart';

/// Tipos de archivos adjuntos soportados
enum AttachmentType {
  image,
  pdf,
  document,
  audio,
  video,
  other,
}

/// Modelo para archivos adjuntos en chats y herramientas
class ChatAttachment {
  final String id;
  final String fileName;
  final String filePath;
  final int fileSize;
  final AttachmentType type;

  ChatAttachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.type,
  });

  /// Obtener el archivo como File
  File get file => File(filePath);

  /// Obtener icono según tipo de archivo
  IconData get icon {
    switch (type) {
      case AttachmentType.image:
        return Icons.image;
      case AttachmentType.pdf:
        return Icons.picture_as_pdf;
      case AttachmentType.document:
        return Icons.description;
      case AttachmentType.audio:
        return Icons.audiotrack;
      case AttachmentType.video:
        return Icons.videocam;
      case AttachmentType.other:
        return Icons.insert_drive_file;
    }
  }

  /// Obtener color según tipo de archivo
  Color get color {
    switch (type) {
      case AttachmentType.image:
        return Colors.blue;
      case AttachmentType.pdf:
        return AppColors.error;
      case AttachmentType.document:
        return AppColors.success;
      case AttachmentType.audio:
        return Colors.purple;
      case AttachmentType.video:
        return Colors.orange;
      case AttachmentType.other:
        return Colors.grey;
    }
  }

  /// Obtener tamaño formateado
  String get formattedSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileSize': fileSize,
      'type': type.toString(),
    };
  }

  /// Crear desde JSON
  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      id: json['id'],
      fileName: json['fileName'],
      filePath: json['filePath'],
      fileSize: json['fileSize'],
      type: AttachmentType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => AttachmentType.other,
      ),
    );
  }
}

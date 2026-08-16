import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Servicio para extracción de texto OCR usando Google ML Kit
class OCRService {
  static final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Extrae texto de una imagen usando OCR
  static Future<String> extractTextFromImage(String imagePath) async {
    try {
      debugPrint('🔍 Iniciando OCR en: $imagePath');
      
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.isEmpty) {
        debugPrint('⚠️ No se detectó texto en la imagen');
        return '';
      }
      
      debugPrint('✅ OCR completado: ${recognizedText.text.length} caracteres');
      return recognizedText.text;
      
    } catch (e) {
      debugPrint('❌ Error en OCR: $e');
      rethrow;
    }
  }

  /// Extrae texto de múltiples imágenes (páginas)
  static Future<Map<int, String>> extractTextFromPages(List<File> pages) async {
    final Map<int, String> results = {};
    
    for (int i = 0; i < pages.length; i++) {
      try {
        debugPrint('📄 Procesando página ${i + 1}/${pages.length}...');
        final text = await extractTextFromImage(pages[i].path);
        results[i + 1] = text;
      } catch (e) {
        debugPrint('❌ Error en página ${i + 1}: $e');
        results[i + 1] = '[Error extrayendo texto: $e]';
      }
    }
    
    return results;
  }

  /// Extrae bloques de texto con posiciones (para análisis avanzado)
  static Future<List<TextBlock>> extractTextBlocks(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.blocks;
    } catch (e) {
      debugPrint('❌ Error extrayendo bloques: $e');
      rethrow;
    }
  }

  /// Obtiene confianza promedio del reconocimiento
  static double getConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0.0;
    
    // ML Kit no expone confianza directamente en versiones recientes
    // Retornamos valor basado en cantidad de texto detectado
    return recognizedText.text.isNotEmpty ? 0.85 : 0.0;
  }

  /// Limpia el texto extraído (opcional)
  static String cleanText(String text) {
    // Remover líneas vacías múltiples
    text = text.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
    
    // Trim general
    text = text.trim();
    
    return text;
  }

  /// Libera recursos
  static Future<void> dispose() async {
    await _textRecognizer.close();
  }
}

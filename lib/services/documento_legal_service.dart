import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/documento_legal.dart';
import 'deepseek_service.dart';
import 'document_scanner_service.dart';

class DocumentoLegalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final ImagePicker _picker = ImagePicker();
  
  /// Genera documento desde prompt con IA
  static Future<DocumentoLegal> generarDocumentoDesdePrompt({
    required TipoDocumento tipo,
    required String prompt,
    String? caso,
    String? tribunal,
    String? expediente,
    List<String>? partes,
  }) async {
    try {
      debugPrint('📝 Generando documento tipo: ${tipo.nombre}');
      debugPrint('📋 Prompt: $prompt');
      
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');
      
      // Construir prompt de sistema (rol del asistente)
      const String systemPrompt = '''Eres un abogado venezolano experto en redacción de documentos legales. 
Tu especialidad es el derecho penal y procesal penal venezolano.
Debes redactar documentos formales, profesionales y bien estructurados, siguiendo las normas y formatos establecidos en Venezuela.
Siempre cita artículos del Código Orgánico Procesal Penal (COPP), Código Penal y otras leyes aplicables.
Usa lenguaje técnico-jurídico apropiado y mantén un tono formal.''';
      
      // Construir prompt del usuario
      final String userPrompt = _construirPromptDocumento(
        tipo: tipo,
        instrucciones: prompt,
        caso: caso,
        tribunal: tribunal,
        expediente: expediente,
        partes: partes,
      );
      
      // Generar documento con DeepSeek
      debugPrint('🤖 Llamando a DeepSeek...');
      final String contenido = await DeepSeekService.generateDocument(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        temperature: 0.7, // Creatividad moderada
        maxTokens: 4000, // Documentos largos
      );
      
      debugPrint('✅ Documento generado por DeepSeek');
      
      // Crear documento
      final documento = DocumentoLegal(
        id: '', // Firestore generará el ID
        userId: userId,
        tipo: tipo,
        titulo: _generarTitulo(tipo, caso),
        contenido: contenido,
        estado: EstadoDocumento.borrador,
        createdAt: DateTime.now(),
        caso: caso,
        tribunal: tribunal,
        expediente: expediente,
        partes: partes ?? [],
        promptOriginal: prompt,
        modeloIA: 'Ulpiano',
        generadoPorIA: true,
      );
      
      // Guardar en Firestore
      final docRef = await _firestore
          .collection('documentos')
          .add(documento.toFirestore());
      
      debugPrint('✅ Documento guardado en Firestore: ${docRef.id}');
      
      return documento.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('❌ Error generando documento: $e');
      rethrow;
    }
  }
  
  /// Genera documento desde imagen escaneada (OCR + vista previa + IA)
  static Future<DocumentoLegal> generarDocumentoDesdeImagen({
    required TipoDocumento tipo,
    required ImageSource source,
    required BuildContext context,
    String? instruccionesAdicionales,
  }) async {
    try {
      debugPrint('📷 Iniciando captura de imagen...');
      
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');
      
      // 1. Capturar imagen
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 3000,
        maxHeight: 3000,
        imageQuality: 95,
      );
      
      if (image == null) {
        debugPrint('⚠️ No se seleccionó imagen');
        throw Exception('No se seleccionó ninguna imagen');
      }
      
      debugPrint('🔍 Procesando imagen con DocumentScanner...');
      
      // 2. Procesar imagen (detección de bordes, corrección, mejoras) - NO BLOQUEA UI
      final Uint8List processedImageBytes = await DocumentScannerService.procesarDocumento(image.path);
      
      // 3. Guardar imagen procesada temporalmente
      final tempDir = await getTemporaryDirectory();
      final tempImagePath = '${tempDir.path}/scanned_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File(tempImagePath);
      await tempFile.writeAsBytes(processedImageBytes);
      
      debugPrint('🔍 Extrayendo texto con OCR...');
      
      // 4. Extraer texto con OCR de la imagen procesada
      final textoOCR = await _extraerTextoOCR(tempImagePath);
      
      if (textoOCR.isEmpty) {
        throw Exception('No se pudo extraer texto de la imagen. Asegúrate de que el documento sea legible.');
      }
      
      debugPrint('📝 Texto extraído: ${textoOCR.length} caracteres');
      
      // 5. VISTA PREVIA DESHABILITADA (archivo documento_escaneado_preview.dart eliminado)
      // El usuario puede revisar el documento en el editor después de generarlo
      /*
      if (!context.mounted) throw Exception('Contexto no disponible');
      
      final continuar = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentoEscaneadoPreview(
            imageBytes: processedImageBytes,
            textoExtraido: textoOCR,
            onContinuar: () => Navigator.pop(context, true),
          ),
        ),
      );
      
      if (continuar != true) {
        throw Exception('Proceso cancelado por el usuario');
      }
      */
      
      debugPrint('📤 Subiendo imagen procesada a Firebase Storage...');
      
      // 6. Subir imagen procesada a Storage
      String imageUrl;
      try {
        imageUrl = await _subirImagenProcesada(processedImageBytes, userId);
      } catch (storageError) {
        debugPrint('⚠️ Error subiendo a Storage (usando URL local): $storageError');
        imageUrl = tempImagePath;
      }
      
      // 7. Procesar con IA para estructurar
      final promptIA = _construirPromptDesdeOCR(
        tipo: tipo,
        textoOCR: textoOCR,
        instruccionesAdicionales: instruccionesAdicionales,
      );
      
      debugPrint('🤖 Procesando con DeepSeek...');
      
      const String systemPrompt = '''Eres un asistente legal venezolano experto en análisis y estructuración de documentos legales.
Tu tarea es leer texto extraído por OCR (puede tener errores), corregirlo y estructurarlo como documento legal formal.
Usa formato legal venezolano estándar y mantén un tono profesional.
Corrige errores ortográficos y de puntuación que pueda tener el OCR.
Mantén toda la información importante del documento original.''';
      
      final String contenido = await DeepSeekService.generateDocument(
        systemPrompt: systemPrompt,
        userPrompt: promptIA,
        temperature: 0.5,
        maxTokens: 4000,
      );
      
      // 8. Crear documento
      final documento = DocumentoLegal(
        id: '',
        userId: userId,
        tipo: tipo,
        titulo: _generarTitulo(tipo, null),
        contenido: contenido,
        estado: EstadoDocumento.borrador,
        createdAt: DateTime.now(),
        imagenesURL: [imageUrl],
        creadoDesdeImagen: true,
        textoOCR: textoOCR,
        modeloIA: 'Ulpiano',
        generadoPorIA: true,
      );
      
      // 9. Guardar en Firestore
      final docRef = await _firestore
          .collection('documentos')
          .add(documento.toFirestore());
      
      debugPrint('✅ Documento creado desde imagen: ${docRef.id}');
      
      // Limpiar archivo temporal
      try {
        await tempFile.delete();
      } catch (e) {
        debugPrint('⚠️ No se pudo eliminar archivo temporal: $e');
      }
      
      return documento.copyWith(id: docRef.id);
    } catch (e, stack) {
      debugPrint('❌ Error creando documento desde imagen: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }
  
  /// Genera documento desde MÚLTIPLES imágenes (como CamScanner)
  static Future<DocumentoLegal> generarDocumentoDesdeImagenes({
    required TipoDocumento tipo,
    required List<String> imagePaths,
    String? instruccionesAdicionales,
    Map<int, String>? extractedTexts, // Texto ya extraído por OCR (opcional)
  }) async {
    try {
      debugPrint('📷 Procesando ${imagePaths.length} imágenes...');
      
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');
      
      List<String> imagenesURL = [];
      StringBuffer textoCompleto = StringBuffer();
      
      // Procesar cada imagen
      for (int i = 0; i < imagePaths.length; i++) {
        debugPrint('📄 Procesando página ${i + 1}/${imagePaths.length}...');
        
        // 1. Procesar imagen (ya viene editada desde CamScanner flow)
        final imageBytes = await File(imagePaths[i]).readAsBytes();
        
        // 2. Subir a Storage
        try {
          final imageUrl = await _subirImagenProcesada(imageBytes, userId, i);
          imagenesURL.add(imageUrl);
        } catch (e) {
          debugPrint('⚠️ Error subiendo imagen $i: $e');
          imagenesURL.add(imagePaths[i]); // Usar ruta local como fallback
        }
        
        // 3. Usar texto ya extraído o extraer con OCR
        String textoOCR;
        if (extractedTexts != null && extractedTexts.containsKey(i + 1)) {
          debugPrint('✅ Usando texto ya extraído para página ${i + 1}');
          textoOCR = extractedTexts[i + 1]!;
        } else {
          debugPrint('🔍 Extrayendo texto con OCR para página ${i + 1}...');
          textoOCR = await _extraerTextoOCR(imagePaths[i]);
        }
        
        if (textoOCR.isNotEmpty) {
          textoCompleto.writeln('--- PÁGINA ${i + 1} ---');
          textoCompleto.writeln(textoOCR);
          textoCompleto.writeln();
        }
      }
      
      final textoFinal = textoCompleto.toString();
      
      if (textoFinal.isEmpty) {
        throw Exception('No se pudo extraer texto de ninguna imagen');
      }
      
      debugPrint('📝 Texto total extraído: ${textoFinal.length} caracteres');
      
      // 4. Procesar con IA
      final promptIA = _construirPromptDesdeOCR(
        tipo: tipo,
        textoOCR: textoFinal,
        instruccionesAdicionales: instruccionesAdicionales,
      );
      
      debugPrint('🤖 Estructurando con IA...');
      
      const String systemPrompt = '''Eres un asistente legal venezolano experto en análisis y estructuración de documentos legales.
Tu tarea es leer texto extraído por OCR de múltiples páginas, corregirlo y estructurarlo como documento legal formal.
Usa formato legal venezolano estándar y mantén un tono profesional.
Corrige errores ortográficos y de puntuación del OCR.
Mantén toda la información importante del documento original.
El texto puede venir de varias páginas separadas por "--- PÁGINA X ---".''';
      
      final String contenido = await DeepSeekService.generateDocument(
        systemPrompt: systemPrompt,
        userPrompt: promptIA,
        temperature: 0.5,
        maxTokens: 4000,
      );
      
      // 5. Crear documento
      final documento = DocumentoLegal(
        id: '',
        userId: userId,
        tipo: tipo,
        titulo: _generarTitulo(tipo, null),
        contenido: contenido,
        estado: EstadoDocumento.borrador,
        createdAt: DateTime.now(),
        imagenesURL: imagenesURL,
        creadoDesdeImagen: true,
        textoOCR: textoFinal,
        modeloIA: 'Ulpiano',
        generadoPorIA: true,
      );
      
      // 6. Guardar en Firestore
      final docRef = await _firestore
          .collection('documentos')
          .add(documento.toFirestore());
      
      debugPrint('✅ Documento multi-página creado: ${docRef.id}');
      
      return documento.copyWith(id: docRef.id);
    } catch (e, stack) {
      debugPrint('❌ Error creando documento multi-página: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }
  
  /// Guarda imagen procesada localmente (sin Firebase Storage)
  static Future<String> _subirImagenProcesada(
    Uint8List imageBytes, 
    String userId,
    [int? index]
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final indexStr = index != null ? '_page${index + 1}' : '';
      final fileName = 'scanned_$timestamp$indexStr.jpg';
      
      // Guardar localmente
      final directory = await getApplicationDocumentsDirectory();
      final docsDir = Directory('${directory.path}/Penalex_VE/Documentos');
      if (!docsDir.existsSync()) await docsDir.create(recursive: true);
      
      final localPath = '${docsDir.path}/$fileName';
      final file = File(localPath);
      await file.writeAsBytes(imageBytes);
      
      debugPrint('✅ Imagen guardada localmente: $localPath');
      return localPath; // Retornar ruta local
    } catch (e, stack) {
      debugPrint('❌ Error guardando imagen: $e');
      debugPrint('Stack: $stack');
      throw Exception('Error al guardar imagen: $e');
    }
  }
  
  /// Extrae texto de imagen con Google ML Kit OCR
  static Future<String> _extraerTextoOCR(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    
    try {
      final RecognizedText recognizedText = 
          await textRecognizer.processImage(inputImage);
      
      final StringBuffer texto = StringBuffer();
      
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          texto.writeln(line.text);
        }
      }
      
      return texto.toString().trim();
    } finally {
      textRecognizer.close();
    }
  }
  
  /// Construye prompt para generar documento
  static String _construirPromptDocumento({
    required TipoDocumento tipo,
    required String instrucciones,
    String? caso,
    String? tribunal,
    String? expediente,
    List<String>? partes,
  }) {
    return '''Eres un asistente legal especializado en redactar documentos legales venezolanos.

TIPO DE DOCUMENTO: ${tipo.nombre}

${caso != null ? 'CASO: $caso\n' : ''}${tribunal != null ? 'TRIBUNAL: $tribunal\n' : ''}${expediente != null ? 'EXPEDIENTE: $expediente\n' : ''}${partes != null && partes.isNotEmpty ? 'PARTES: ${partes.join(", ")}\n' : ''}
INSTRUCCIONES:
$instrucciones

REQUISITOS:
1. Redacta un ${tipo.nombre} completo y profesional
2. Usa formato legal venezolano estándar
3. Incluye todas las formalidades requeridas:
   - Encabezado con identificación del tribunal
   - Identificación de las partes
   - Objeto del escrito
   - Desarrollo argumentativo
   - Petitorio claro
   - Cierre formal
4. Usa lenguaje técnico-jurídico apropiado
5. Cita artículos legales relevantes cuando aplique
6. Estructura el texto con secciones claras

FORMATO:
- Usa mayúsculas para títulos de secciones
- Numera los capítulos y peticiones
- Incluye espacios entre secciones
- Finaliza con firma y fecha

Genera el documento completo ahora:''';
  }
  
  /// Construye prompt para procesar OCR
  static String _construirPromptDesdeOCR({
    required TipoDocumento tipo,
    required String textoOCR,
    String? instruccionesAdicionales,
  }) {
    return '''Eres un asistente legal. Recibí el siguiente texto extraído de una imagen escaneada (puede tener errores de OCR):

TEXTO EXTRAÍDO:
${textoOCR.length > 3000 ? '${textoOCR.substring(0, 3000)}...' : textoOCR}

TAREA:
1. Corrige errores de OCR (palabras mal reconocidas)
2. Estructura el texto como un ${tipo.nombre} formal
3. Organiza en secciones apropiadas
4. Completa información faltante con [COMPLETAR]
5. Mejora la redacción manteniendo el contenido original
6. Agrega formato legal venezolano estándar

${instruccionesAdicionales != null ? '\nINSTRUCCIONES ADICIONALES:\n$instruccionesAdicionales\n' : ''}
Genera el documento estructurado:''';
  }
  
  /// Genera título automático
  static String _generarTitulo(TipoDocumento tipo, String? caso) {
    final fecha = DateTime.now();
    final fechaStr = '${fecha.day}/${fecha.month}/${fecha.year}';
    
    if (caso != null && caso.isNotEmpty) {
      return '${tipo.nombre} - $caso - $fechaStr';
    }
    
    return '${tipo.nombre} - $fechaStr';
  }
  
  /// Obtiene todos los documentos del usuario
  static Future<List<DocumentoLegal>> getDocumentos() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];
      
      final snapshot = await _firestore
          .collection('documentos')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => DocumentoLegal.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo documentos: $e');
      return [];
    }
  }
  
  /// Guarda documento
  static Future<String> guardarDocumento(DocumentoLegal documento) async {
    try {
      if (documento.id.isEmpty) {
        // Crear nuevo
        final docRef = await _firestore
            .collection('documentos')
            .add(documento.toFirestore());
        return docRef.id;
      } else {
        // Actualizar existente
        await _firestore
            .collection('documentos')
            .doc(documento.id)
            .update(documento.copyWith(
              updatedAt: DateTime.now(),
            ).toFirestore());
        return documento.id;
      }
    } catch (e) {
      debugPrint('❌ Error guardando documento: $e');
      rethrow;
    }
  }
  
  /// Elimina documento
  static Future<void> eliminarDocumento(String id) async {
    try {
      await _firestore.collection('documentos').doc(id).delete();
      debugPrint('✅ Documento eliminado: $id');
    } catch (e) {
      debugPrint('❌ Error eliminando documento: $e');
      rethrow;
    }
  }
  
  /// Stream de documentos en tiempo real
  static Stream<List<DocumentoLegal>> streamDocumentos() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);
    
    return _firestore
        .collection('documentos')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DocumentoLegal.fromFirestore(doc))
            .toList());
  }
  
  /// Placeholder para notificaciones (implementar según tu sistema)
  static void showLoadingNotification(String message) {
    debugPrint('🔔 $message');
  }
}

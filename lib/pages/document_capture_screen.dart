import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

import '../config/app_colors.dart';
import '../services/document_scanner_service_pro.dart';
import 'crop_adjust_screen.dart';

/// Pantalla de captura de documento con detección de bordes en tiempo real
/// Simula la experiencia de CamScanner
class DocumentCaptureScreen extends StatefulWidget {
  const DocumentCaptureScreen({super.key});

  @override
  State<DocumentCaptureScreen> createState() => _DocumentCaptureScreenState();
}

class _DocumentCaptureScreenState extends State<DocumentCaptureScreen> {
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Fondo con guías visuales
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono de cámara grande
                  Icon(
                    Icons.document_scanner_outlined,
                    size: 120,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 24),
                  
                  // Texto instructivo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Coloca el documento dentro del marco',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Text(
                    'Los bordes se detectarán automáticamente',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Marco visual (rectángulo con esquinas)
                  _buildDocumentFrame(),
                ],
              ),
            ),
            
            // Header con botón cerrar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón cerrar
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  
                  // Indicador de modo
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Auto',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Botón flash (placeholder)
                  IconButton(
                    icon: const Icon(Icons.flash_off, color: Colors.white, size: 28),
                    onPressed: () {
                      // Toggle flash
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Flash no disponible en simulación'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Botones inferiores
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Botón de captura principal
                  _isProcessing
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                        )
                      : GestureDetector(
                          onTap: _captureDocument,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: AppColors.secondary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera,
                              color: AppColors.primary,
                              size: 40,
                            ),
                          ),
                        ),
                  
                  const SizedBox(height: 24),
                  
                  // Botón galería
                  TextButton.icon(
                    onPressed: _isProcessing ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    label: const Text(
                      'Seleccionar desde galería',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Marco visual para guiar al usuario
  Widget _buildDocumentFrame() {
    return Container(
      width: 280,
      height: 380,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.5),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Esquinas decorativas
          _buildCorner(Alignment.topLeft, true, true),
          _buildCorner(Alignment.topRight, true, false),
          _buildCorner(Alignment.bottomLeft, false, true),
          _buildCorner(Alignment.bottomRight, false, false),
        ],
      ),
    );
  }

  /// Esquina decorativa del marco
  Widget _buildCorner(Alignment alignment, bool isTop, bool isLeft) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? BorderSide(color: AppColors.secondary, width: 4) : BorderSide.none,
            bottom: !isTop ? BorderSide(color: AppColors.secondary, width: 4) : BorderSide.none,
            left: isLeft ? BorderSide(color: AppColors.secondary, width: 4) : BorderSide.none,
            right: !isLeft ? BorderSide(color: AppColors.secondary, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// Captura documento con la cámara
  Future<void> _captureDocument() async {
    setState(() => _isProcessing = true);

    try {
      // Capturar imagen con cámara
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 3000,
        maxHeight: 3000,
        imageQuality: 100, // Alta calidad para detección
      );

      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }

      await _processImage(image.path);

    } catch (e) {
      debugPrint('❌ Error capturando documento: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Selecciona imagen desde galería
  Future<void> _pickFromGallery() async {
    setState(() => _isProcessing = true);

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 3000,
        maxHeight: 3000,
        imageQuality: 100,
      );

      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }

      await _processImage(image.path);

    } catch (e) {
      debugPrint('❌ Error seleccionando imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Procesa imagen capturada: detecta bordes y navega a ajuste
  Future<void> _processImage(String imagePath) async {
    try {
      debugPrint('📸 Procesando imagen capturada...');

      // Copiar imagen a directorio temporal
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempPath = '${tempDir.path}/capture_$timestamp.jpg';
      
      await File(imagePath).copy(tempPath);

      // Detectar bordes automáticamente
      debugPrint('🔍 Detectando bordes...');
      
      // Usar edge_detection para detectar y recortar automáticamente
      String? processedImagePath;
      
      try {
        debugPrint('🔍 Intentando detección automática con edge_detection...');
        processedImagePath = await DocumentScannerServicePro.detectEdges(tempPath);
        
        if (processedImagePath != null) {
          debugPrint('✅ Detección automática exitosa');
          
          // edge_detection ya procesó la imagen, retornarla directamente
          if (!mounted) return;
          
          final processedFile = File(processedImagePath);
          if (await processedFile.exists()) {
            Navigator.pop(context, processedFile);
            return;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Detección automática falló, usando método manual: $e');
      }

      // Si edge_detection falla o usuario cancela, usar detección manual + ajuste
      List<Offset>? corners = await DocumentScannerServicePro.detectEdgesManual(tempPath);
      
      if (corners == null) {
        // Si falla detección manual, usar esquinas por defecto
        final img.Image? image = img.decodeImage(await File(tempPath).readAsBytes());
        if (image != null) {
          corners = [
            Offset(0, 0),
            Offset(image.width.toDouble(), 0),
            Offset(image.width.toDouble(), image.height.toDouble()),
            Offset(0, image.height.toDouble()),
          ];
        } else {
          if (!mounted) return;
          Navigator.pop(context);
          return;
        }
      }

      if (!mounted) return;

      // Navegar a pantalla de ajuste manual de esquinas
      final result = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => CropAdjustScreen(
            imagePath: tempPath,
            detectedCorners: corners!,
          ),
        ),
      );

      if (result != null && mounted) {
        // Devolver imagen procesada a la pantalla anterior
        Navigator.pop(context, result);
      }

    } catch (e) {
      debugPrint('❌ Error procesando imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error procesando imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

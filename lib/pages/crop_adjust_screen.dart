import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../services/document_scanner_service_pro.dart';
import 'filter_preview_screen.dart';
import '../widgets/app_bar_institucional.dart';

/// Pantalla para ajustar manualmente las 4 esquinas del documento
/// Permite arrastrar cada esquina para perfeccionar la detección automática
class CropAdjustScreen extends StatefulWidget {
  final String imagePath;
  final List<Offset> detectedCorners;

  const CropAdjustScreen({
    super.key,
    required this.imagePath,
    required this.detectedCorners,
  });

  @override
  State<CropAdjustScreen> createState() => _CropAdjustScreenState();
}

class _CropAdjustScreenState extends State<CropAdjustScreen> {
  late List<Offset> _corners;
  int? _draggedCornerIndex;
  bool _isProcessing = false;
  
  ui.Image? _image;
  Size? _imageSize;
  
  @override
  void initState() {
    super.initState();
    _corners = List.from(widget.detectedCorners);
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    
    setState(() {
      _image = frame.image;
      _imageSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
            appBar: AppBarInstitucional(
        title: 'Ajustar Bordes',
        mostrarBack: true,
        mostrarHome: true,
      ),
      body: Column(
        children: [
          // Instrucciones
          Container(
            padding: const EdgeInsets.all(16),
            color: TemaGlobal.tarjeta,
            child: Row(
              children: [
                const Icon(
                  Icons.touch_app,
                  color: AppColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Arrastra las esquinas para ajustar el área del documento',
                    style: TextStyle(
                      color: TemaGlobal.textoSecundario,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Área de imagen con esquinas ajustables
          Expanded(
            child: _image == null
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                    ),
                  )
                : GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: Container(
                      color: Colors.black,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: _imageSize!.width / _imageSize!.height,
                          child: CustomPaint(
                            painter: _CropOverlayPainter(
                              image: _image!,
                              corners: _corners,
                              imageSize: _imageSize!,
                              draggedIndex: _draggedCornerIndex,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          
          // Botones de acción
          Container(
            padding: const EdgeInsets.all(16),
            color: TemaGlobal.tarjeta,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón redetectar
                _buildActionButton(
                  icon: Icons.refresh,
                  label: 'Redetectar',
                  onPressed: _redetectCorners,
                ),
                
                // Botón resetear
                _buildActionButton(
                  icon: Icons.restore,
                  label: 'Resetear',
                  onPressed: _resetCorners,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: TemaGlobal.capa,
        foregroundColor: TemaGlobal.texto,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: TemaGlobal.texto.withValues(alpha: AppColors.a18)),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (_image == null || _imageSize == null) return;
    
    // Encontrar qué esquina está siendo arrastrada
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    
    // Calcular escala de imagen a pantalla
    final screenSize = box.size;
    final imageAspect = _imageSize!.width / _imageSize!.height;
    final screenAspect = screenSize.width / screenSize.height;
    
    double scale;
    Offset offset;
    
    if (screenAspect > imageAspect) {
      // Imagen más alta que ancha
      scale = screenSize.height / _imageSize!.height;
      offset = Offset((screenSize.width - _imageSize!.width * scale) / 2, 0);
    } else {
      // Imagen más ancha que alta
      scale = screenSize.width / _imageSize!.width;
      offset = Offset(0, (screenSize.height - _imageSize!.height * scale) / 2);
    }
    
    // Buscar esquina más cercana al toque
    double minDistance = double.infinity;
    int? closestIndex;
    
    for (int i = 0; i < _corners.length; i++) {
      final screenCorner = Offset(
        _corners[i].dx * scale + offset.dx,
        _corners[i].dy * scale + offset.dy,
      );
      
      final distance = (screenCorner - localPosition).distance;
      
      if (distance < 50 && distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }
    
    setState(() {
      _draggedCornerIndex = closestIndex;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_draggedCornerIndex == null || _image == null || _imageSize == null) return;
    
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    
    // Calcular posición en coordenadas de imagen
    final screenSize = box.size;
    final imageAspect = _imageSize!.width / _imageSize!.height;
    final screenAspect = screenSize.width / screenSize.height;
    
    double scale;
    Offset offset;
    
    if (screenAspect > imageAspect) {
      scale = screenSize.height / _imageSize!.height;
      offset = Offset((screenSize.width - _imageSize!.width * scale) / 2, 0);
    } else {
      scale = screenSize.width / _imageSize!.width;
      offset = Offset(0, (screenSize.height - _imageSize!.height * scale) / 2);
    }
    
    // Convertir posición de pantalla a coordenadas de imagen
    final imageX = ((localPosition.dx - offset.dx) / scale)
        .clamp(0.0, _imageSize!.width);
    final imageY = ((localPosition.dy - offset.dy) / scale)
        .clamp(0.0, _imageSize!.height);
    
    setState(() {
      _corners[_draggedCornerIndex!] = Offset(imageX, imageY);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _draggedCornerIndex = null;
    });
  }

  Future<void> _redetectCorners() async {
    setState(() => _isProcessing = true);
    
    try {
      final corners = await DocumentScannerServicePro.detectEdgesManual(widget.imagePath);
      
      if (corners != null) {
        setState(() {
          _corners = corners;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Bordes redetectados'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error redetectando: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _resetCorners() {
    setState(() {
      _corners = List.from(widget.detectedCorners);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Esquinas reseteadas'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _applyAndContinue() async {
    setState(() => _isProcessing = true);
    
    try {
      debugPrint('✂️ Aplicando recorte con esquinas ajustadas...');
      
      // Aplicar corrección de perspectiva
      final croppedPath = await DocumentScannerServicePro.cropAndCorrectPerspective(
        imagePath: widget.imagePath,
        corners: _corners,
      );
      
      if (croppedPath == null) {
        throw Exception('No se pudo recortar la imagen');
      }
      
      if (!mounted) return;
      
      // Navegar a pantalla de filtros
      final result = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => FilterPreviewScreen(
            imagePath: croppedPath,
          ),
        ),
      );
      
      if (result != null && mounted) {
        Navigator.pop(context, result);
      }
      
    } catch (e) {
      debugPrint('❌ Error aplicando recorte: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }
}

/// Painter para dibujar la imagen, overlay y esquinas draggables
class _CropOverlayPainter extends CustomPainter {
  final ui.Image image;
  final List<Offset> corners;
  final Size imageSize;
  final int? draggedIndex;

  _CropOverlayPainter({
    required this.image,
    required this.corners,
    required this.imageSize,
    this.draggedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calcular escala y offset para centrar imagen
    final imageAspect = imageSize.width / imageSize.height;
    final screenAspect = size.width / size.height;
    
    double scale;
    Offset offset;
    
    if (screenAspect > imageAspect) {
      scale = size.height / imageSize.height;
      offset = Offset((size.width - imageSize.width * scale) / 2, 0);
    } else {
      scale = size.width / imageSize.width;
      offset = Offset(0, (size.height - imageSize.height * scale) / 2);
    }
    
    // Dibujar imagen
    final srcRect = Rect.fromLTWH(0, 0, imageSize.width, imageSize.height);
    final dstRect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      imageSize.width * scale,
      imageSize.height * scale,
    );
    
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
    
    // Convertir esquinas a coordenadas de pantalla
    final screenCorners = corners.map((corner) {
      return Offset(
        corner.dx * scale + offset.dx,
        corner.dy * scale + offset.dy,
      );
    }).toList();
    
    // Dibujar overlay oscuro fuera del documento
    _drawOverlay(canvas, size, screenCorners);
    
    // Dibujar líneas del documento
    _drawDocumentLines(canvas, screenCorners);
    
    // Dibujar esquinas draggables
    _drawCorners(canvas, screenCorners);
  }

  void _drawOverlay(Canvas canvas, Size size, List<Offset> screenCorners) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final docPath = Path()
      ..moveTo(screenCorners[0].dx, screenCorners[0].dy)
      ..lineTo(screenCorners[1].dx, screenCorners[1].dy)
      ..lineTo(screenCorners[2].dx, screenCorners[2].dy)
      ..lineTo(screenCorners[3].dx, screenCorners[3].dy)
      ..close();
    
    // Cambiar fillType por fillType del path (API nueva de Flutter)
    docPath.fillType = PathFillType.evenOdd;
    path.addPath(docPath, Offset.zero);
    
    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: AppColors.a48),
    );
  }

  void _drawDocumentLines(Canvas canvas, List<Offset> screenCorners) {
    final paint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final path = Path()
      ..moveTo(screenCorners[0].dx, screenCorners[0].dy)
      ..lineTo(screenCorners[1].dx, screenCorners[1].dy)
      ..lineTo(screenCorners[2].dx, screenCorners[2].dy)
      ..lineTo(screenCorners[3].dx, screenCorners[3].dy)
      ..close();
    
    canvas.drawPath(path, paint);
  }

  void _drawCorners(Canvas canvas, List<Offset> screenCorners) {
    for (int i = 0; i < screenCorners.length; i++) {
      final isBeingDragged = i == draggedIndex;
      
      // Círculo exterior
      canvas.drawCircle(
        screenCorners[i],
        isBeingDragged ? 18 : 15,
        Paint()
          ..color = AppColors.secondary
          ..style = PaintingStyle.fill,
      );
      
      // Círculo interior
      canvas.drawCircle(
        screenCorners[i],
        isBeingDragged ? 12 : 10,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.fill,
      );
      
      // Borde blanco
      canvas.drawCircle(
        screenCorners[i],
        isBeingDragged ? 18 : 15,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.corners != corners ||
        oldDelegate.draggedIndex != draggedIndex ||
        oldDelegate.image != image;
  }
}

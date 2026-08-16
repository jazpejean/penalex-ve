import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageEditorScreen extends StatefulWidget {
  final String imagePath;

  const ImageEditorScreen({super.key, required this.imagePath});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  late File _currentImage;
  late img.Image _editedImage;
  bool _loading = true;
  int _rotation = 0;
  double _brightness = 1.0;
  double _contrast = 1.0;

  @override
  void initState() {
    super.initState();
    _currentImage = File(widget.imagePath);
    _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() => _loading = true);

    try {
      final bytes = await _currentImage.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image != null) {
        setState(() {
          _editedImage = image;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar imagen: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _applyRotation() async {
    setState(() => _loading = true);

    await Future.delayed(Duration(milliseconds: 100));

    setState(() {
      _editedImage = img.copyRotate(_editedImage, angle: 90);
      _rotation = (_rotation + 90) % 360;
      _loading = false;
    });
  }

  Future<void> _applyEnhancements() async {
    setState(() => _loading = true);

    await Future.delayed(Duration(milliseconds: 100));

    img.Image enhanced = img.copyResize(_editedImage, 
        width: _editedImage.width, 
        height: _editedImage.height);

    // Aplicar brillo
    if (_brightness != 1.0) {
      enhanced = img.adjustColor(enhanced, brightness: _brightness);
    }

    // Aplicar contraste
    if (_contrast != 1.0) {
      final contrastValue = ((_contrast - 1.0) * 100 + 100).toInt();
      enhanced = img.contrast(enhanced, contrast: contrastValue);
    }

    setState(() {
      _editedImage = enhanced;
      _loading = false;
    });
  }

  Future<void> _resetAdjustments() async {
    setState(() {
      _brightness = 1.0;
      _contrast = 1.0;
    });
    await _loadImage();
  }

  Future<void> _saveAndReturn() async {
    setState(() => _loading = true);

    try {
      // Guardar imagen editada
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = '${tempDir.path}/edited_$timestamp.jpg';

      final bytes = img.encodeJpg(_editedImage, quality: 90);
      final file = File(newPath);
      await file.writeAsBytes(bytes);

      if (mounted) {
        Navigator.pop(context, file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Editar Imagen'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: const Color(0xFFC5A059),
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.check, color: Color(0xFFC5A059)),
              onPressed: _saveAndReturn,
              tooltip: 'Guardar',
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5A059)),
              ),
            )
          : Column(
              children: [
                // Vista previa de la imagen
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC5A059), width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Center(
                          child: Image.memory(
                            Uint8List.fromList(img.encodeJpg(_editedImage)),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Controles
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Barra de herramientas
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildToolButton(
                                icon: Icons.rotate_right,
                                label: 'Rotar',
                                onPressed: _applyRotation,
                              ),
                              _buildToolButton(
                                icon: Icons.refresh,
                                label: 'Reiniciar',
                                onPressed: _resetAdjustments,
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                          const Divider(color: Color(0xFFC5A059)),
                          const SizedBox(height: 16),

                          // Ajustes de brillo y contraste
                          _buildSlider(
                            label: 'Brillo',
                            value: _brightness,
                            min: 0.5,
                            max: 1.5,
                            onChanged: (value) {
                              setState(() => _brightness = value);
                            },
                            onChangeEnd: (value) => _applyEnhancements(),
                          ),

                          const SizedBox(height: 16),

                          _buildSlider(
                            label: 'Contraste',
                            value: _contrast,
                            min: 0.5,
                            max: 1.5,
                            onChanged: (value) {
                              setState(() => _contrast = value);
                            },
                            onChangeEnd: (value) => _applyEnhancements(),
                          ),

                          const SizedBox(height: 24),

                          // Botón guardar grande
                          ElevatedButton.icon(
                            onPressed: _saveAndReturn,
                            icon: const Icon(Icons.check_circle, size: 28),
                            label: const Text(
                              'GUARDAR Y CONTINUAR',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC5A059),
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC5A059), width: 2),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: const Color(0xFFC5A059)),
            iconSize: 32,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFC5A059),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFFC5A059),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
            thumbColor: const Color(0xFFC5A059),
            overlayColor: const Color(0xFFC5A059).withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: 20,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }
}

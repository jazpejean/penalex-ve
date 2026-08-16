import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_filter_service.dart';

class DocumentEditorScreen extends StatefulWidget {
  final String imagePath;

  const DocumentEditorScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<DocumentEditorScreen> createState() => _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends State<DocumentEditorScreen> {
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);

  String _currentImagePath = '';
  bool _isProcessing = false;
  
  // Valores de filtros
  double _brightness = 0;
  double _contrast = 100;
  bool _blancoYNegro = false;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.imagePath;
  }

  Future<void> _aplicarFiltros() async {
    setState(() => _isProcessing = true);

    final filteredPath = await ImageFilterService.aplicarFiltrosMultiples(
      imagePath: widget.imagePath,
      brightness: _brightness.round(),
      contrast: _contrast.round(),
      blancoYNegro: _blancoYNegro,
    );

    if (mounted) {
      setState(() {
        _isProcessing = false;
        if (filteredPath != null) {
          _currentImagePath = filteredPath;
        }
      });

      if (filteredPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error aplicando filtros'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _optimizarDocumento() async {
    setState(() => _isProcessing = true);

    final optimizedPath = await ImageFilterService.optimizarParaDocumento(widget.imagePath);

    if (mounted) {
      setState(() {
        _isProcessing = false;
        if (optimizedPath != null) {
          _currentImagePath = optimizedPath;
          // Reset filtros después de optimizar
          _brightness = 0;
          _contrast = 100;
          _blancoYNegro = false;
        }
      });

      if (optimizedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Documento optimizado'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error optimizando'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rotarImagen() async {
    setState(() => _isProcessing = true);

    final rotatedPath = await ImageFilterService.rotarImagen(_currentImagePath, 90);

    if (mounted) {
      setState(() {
        _isProcessing = false;
        if (rotatedPath != null) {
          _currentImagePath = rotatedPath;
        }
      });

      if (rotatedPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error rotando imagen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _aplicarBlancoYNegro() async {
    setState(() => _isProcessing = true);

    final bwPath = await ImageFilterService.aplicarBlancoYNegro(_currentImagePath);

    if (mounted) {
      setState(() {
        _isProcessing = false;
        if (bwPath != null) {
          _currentImagePath = bwPath;
          _blancoYNegro = true;
        }
      });

      if (bwPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error aplicando B&N'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _guardarYSalir() {
    // Retornar la ruta de la imagen editada
    Navigator.pop(context, _currentImagePath);
  }

  void _mostrarPanelFiltros() {
    showModalBottomSheet(
      context: context,
      backgroundColor: azulMarino,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ajustar Filtros',
                      style: TextStyle(
                        color: dorado,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Brillo
                const Text(
                  'Brillo',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Slider(
                  value: _brightness,
                  min: -100,
                  max: 100,
                  divisions: 40,
                  label: _brightness.round().toString(),
                  activeColor: dorado,
                  inactiveColor: Colors.white24,
                  onChanged: (value) {
                    setState(() => _brightness = value);
                    setModalState(() => _brightness = value);
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Contraste
                const Text(
                  'Contraste',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Slider(
                  value: _contrast,
                  min: 50,
                  max: 200,
                  divisions: 30,
                  label: _contrast.round().toString(),
                  activeColor: dorado,
                  inactiveColor: Colors.white24,
                  onChanged: (value) {
                    setState(() => _contrast = value);
                    setModalState(() => _contrast = value);
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Blanco y Negro
                SwitchListTile(
                  title: const Text(
                    'Blanco y Negro',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: _blancoYNegro,
                  activeColor: dorado,
                  onChanged: (value) {
                    setState(() => _blancoYNegro = value);
                    setModalState(() => _blancoYNegro = value);
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _brightness = 0;
                          _contrast = 100;
                          _blancoYNegro = false;
                        });
                        setModalState(() {
                          _brightness = 0;
                          _contrast = 100;
                          _blancoYNegro = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Resetear'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _aplicarFiltros();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dorado,
                        foregroundColor: azulMarino,
                      ),
                      child: const Text('Aplicar'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: azulMarino,
      appBar: AppBar(
        title: const Text(
          'Editar Página',
          style: TextStyle(color: dorado, fontWeight: FontWeight.bold),
        ),
        backgroundColor: azulMarino,
        elevation: 0,
        iconTheme: const IconThemeData(color: dorado),
        actions: [
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(dorado),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _guardarYSalir,
              tooltip: 'Guardar',
            ),
        ],
      ),
      body: Column(
        children: [
          // Vista previa de la imagen
          Expanded(
            child: Center(
              child: _isProcessing
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: dorado),
                        SizedBox(height: 16),
                        Text(
                          'Procesando...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    )
                  : Image.file(
                      File(_currentImagePath),
                      fit: BoxFit.contain,
                    ),
            ),
          ),
          
          // Barra de herramientas
          Container(
            color: Colors.black.withOpacity(0.3),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildToolButton(
                    icon: Icons.tune,
                    label: 'Filtros',
                    onPressed: _mostrarPanelFiltros,
                  ),
                  const SizedBox(width: 8),
                  _buildToolButton(
                    icon: Icons.auto_fix_high,
                    label: 'Optimizar',
                    onPressed: _optimizarDocumento,
                  ),
                  const SizedBox(width: 8),
                  _buildToolButton(
                    icon: Icons.rotate_90_degrees_ccw,
                    label: 'Rotar',
                    onPressed: _rotarImagen,
                  ),
                  const SizedBox(width: 8),
                  _buildToolButton(
                    icon: Icons.filter_b_and_w,
                    label: 'B&N',
                    onPressed: _aplicarBlancoYNegro,
                  ),
                ],
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
        IconButton(
          icon: Icon(icon, color: dorado),
          onPressed: _isProcessing ? null : onPressed,
          iconSize: 28,
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../config/app_colors.dart';
import '../services/image_filter_service.dart';

/// Pantalla para previsualizar y seleccionar filtros
/// Estilo CamScanner con previews de todos los filtros
class FilterPreviewScreen extends StatefulWidget {
  final String imagePath;

  const FilterPreviewScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<FilterPreviewScreen> createState() => _FilterPreviewScreenState();
}

class _FilterPreviewScreenState extends State<FilterPreviewScreen> {
  DocumentFilter _selectedFilter = DocumentFilter.auto;
  Map<DocumentFilter, String> _filterPreviews = {};
  bool _isGeneratingPreviews = true;
  bool _isApplying = false;
  String? _currentPreviewPath;

  @override
  void initState() {
    super.initState();
    _generateFilterPreviews();
  }

  Future<void> _generateFilterPreviews() async {
    setState(() => _isGeneratingPreviews = true);

    try {
      debugPrint('🎨 Generando previews de filtros...');
      
      final previews = await ImageFilterService.generatePreviews(widget.imagePath);
      
      setState(() {
        _filterPreviews = previews;
        _currentPreviewPath = previews[_selectedFilter];
        _isGeneratingPreviews = false;
      });
      
      debugPrint('✅ ${previews.length} previews generados');
      
    } catch (e) {
      debugPrint('❌ Error generando previews: $e');
      setState(() => _isGeneratingPreviews = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generando filtros: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Aplicar Filtro',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (_isApplying)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  ),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _isGeneratingPreviews ? null : _applyFilterAndContinue,
              icon: const Icon(Icons.check, color: AppColors.secondary),
              label: const Text(
                'Usar',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _isGeneratingPreviews
          ? _buildLoadingState()
          : Column(
              children: [
                // Preview grande de imagen con filtro seleccionado
                Expanded(
                  flex: 3,
                  child: _buildImagePreview(),
                ),
                
                // Galería horizontal de filtros
                Container(
                  height: 180,
                  color: const Color(0xFF1E293B),
                  child: _buildFilterGallery(),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
          ),
          const SizedBox(height: 24),
          Text(
            'Generando filtros...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Esto puede tardar unos segundos',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_currentPreviewPath == null) {
      return const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 64,
          color: Colors.white24,
        ),
      );
    }

    return Stack(
      children: [
        // Imagen con zoom/pan
        PhotoView(
          imageProvider: FileImage(File(_currentPreviewPath!)),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          initialScale: PhotoViewComputedScale.contained,
          heroAttributes: const PhotoViewHeroAttributes(tag: 'document_preview'),
        ),
        
        // Nombre del filtro actual (overlay superior)
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.secondary.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _selectedFilter.icon,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedFilter.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Hint de zoom (overlay inferior)
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.zoom_in,
                    color: Colors.white.withOpacity(0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pellizca para hacer zoom',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterGallery() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: DocumentFilter.values.length,
      itemBuilder: (context, index) {
        final filter = DocumentFilter.values[index];
        final previewPath = _filterPreviews[filter];
        final isSelected = filter == _selectedFilter;
        
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _buildFilterOption(filter, previewPath, isSelected),
        );
      },
    );
  }

  Widget _buildFilterOption(DocumentFilter filter, String? previewPath, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectFilter(filter),
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppColors.secondary 
                : Colors.white.withOpacity(0.2),
            width: isSelected ? 3 : 1,
          ),
          color: const Color(0xFF0F172A),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: previewPath != null
                    ? Image.file(
                        File(previewPath),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.secondary,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            
            // Nombre del filtro
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.secondary.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              child: Column(
                children: [
                  Icon(
                    filter.icon,
                    color: isSelected ? AppColors.secondary : Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    filter.displayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? AppColors.secondary : Colors.white70,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

  void _selectFilter(DocumentFilter filter) {
    setState(() {
      _selectedFilter = filter;
      _currentPreviewPath = _filterPreviews[filter];
    });
    
    // Feedback háptico (opcional)
    debugPrint('🎨 Filtro seleccionado: ${filter.displayName}');
  }

  Future<void> _applyFilterAndContinue() async {
    if (_currentPreviewPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay preview disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isApplying = true);

    try {
      debugPrint('✅ Aplicando filtro: ${_selectedFilter.displayName}');
      
      // El filtro ya está aplicado en _currentPreviewPath
      final filteredFile = File(_currentPreviewPath!);
      
      if (!await filteredFile.exists()) {
        throw Exception('Archivo filtrado no existe');
      }
      
      // Devolver archivo con filtro aplicado
      if (mounted) {
        Navigator.pop(context, filteredFile);
      }
      
    } catch (e) {
      debugPrint('❌ Error aplicando filtro: $e');
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
        setState(() => _isApplying = false);
      }
    }
  }

  @override
  void dispose() {
    // Limpiar archivos temporales de previews (opcional)
    // En una app real, podrías querer conservarlos en caché
    super.dispose();
  }
}

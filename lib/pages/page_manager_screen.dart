import 'dart:io';

import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../services/document_scanner_service_pro.dart';
import 'document_capture_screen.dart';
import 'filter_preview_screen.dart';

/// Modelo para página escaneada
class ScannedPage {
  final File file;
  final int pageNumber;
  String? filterApplied;
  
  ScannedPage({
    required this.file,
    required this.pageNumber,
    this.filterApplied,
  });
}

/// Pantalla para gestionar múltiples páginas escaneadas
/// Estilo CamScanner con grid reordenable
class PageManagerScreen extends StatefulWidget {
  final List<File> initialPages;

  const PageManagerScreen({
    super.key,
    required this.initialPages,
  });

  @override
  State<PageManagerScreen> createState() => _PageManagerScreenState();
}

class _PageManagerScreenState extends State<PageManagerScreen> {
  late List<ScannedPage> _pages;
  bool _isReorderMode = false;

  @override
  void initState() {
    super.initState();
    _pages = widget.initialPages.asMap().entries.map((entry) {
      return ScannedPage(
        file: entry.value,
        pageNumber: entry.key + 1,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.secondary,
        title: Text(
          '${_pages.length} página${_pages.length != 1 ? 's' : ''}',
          style: const TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Modo reordenar
          IconButton(
            icon: Icon(
              _isReorderMode ? Icons.check : Icons.reorder,
              color: AppColors.secondary,
            ),
            onPressed: () {
              setState(() => _isReorderMode = !_isReorderMode);
            },
            tooltip: _isReorderMode ? 'Finalizar' : 'Reordenar',
          ),
          
          // Botón continuar
          if (_pages.isNotEmpty)
            TextButton.icon(
              onPressed: _continueToOCR,
              icon: const Icon(Icons.arrow_forward, color: AppColors.secondary),
              label: const Text(
                'Continuar',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _pages.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Banner informativo
                if (!_isReorderMode)
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: AppColors.primary.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary.withOpacity(0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Mantén presionado una página para ver más opciones',
                            style: TextStyle(
                              color: AppColors.primary.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Grid de páginas
                Expanded(
                  child: _isReorderMode
                      ? _buildReorderableGrid()
                      : _buildNormalGrid(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewPage,
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text(
          'Agregar Página',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.document_scanner_outlined,
            size: 100,
            color: AppColors.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No hay páginas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para capturar una página',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: _pages.length,
      itemBuilder: (context, index) {
        return _buildPageCard(_pages[index], index);
      },
    );
  }

  Widget _buildReorderableGrid() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pages.length,
      onReorder: _reorderPages,
      itemBuilder: (context, index) {
        return _buildReorderablePageCard(_pages[index], index);
      },
    );
  }

  Widget _buildPageCard(ScannedPage page, int index) {
    return GestureDetector(
      onTap: () => _viewPage(page, index),
      onLongPress: () => _showPageOptions(page, index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.secondary.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen de la página
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: Image.file(
                  page.file,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            // Footer con número de página
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.description,
                    color: AppColors.secondary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Página ${page.pageNumber}',
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

  Widget _buildReorderablePageCard(ScannedPage page, int index) {
    return Container(
      key: ValueKey(page.file.path),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            page.file,
            width: 60,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          'Página ${page.pageNumber}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        subtitle: Text(
          page.filterApplied ?? 'Sin filtro',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.primary.withOpacity(0.6),
          ),
        ),
        trailing: const Icon(
          Icons.drag_handle,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  void _reorderPages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final page = _pages.removeAt(oldIndex);
      _pages.insert(newIndex, page);
      
      // Actualizar números de página
      for (int i = 0; i < _pages.length; i++) {
        _pages[i] = ScannedPage(
          file: _pages[i].file,
          pageNumber: i + 1,
          filterApplied: _pages[i].filterApplied,
        );
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Orden actualizado'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _addNewPage() async {
    final result = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (context) => const DocumentCaptureScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _pages.add(ScannedPage(
          file: result,
          pageNumber: _pages.length + 1,
        ));
      });
    }
  }

  void _viewPage(ScannedPage page, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text('Página ${page.pageNumber}'),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(page.file),
            ),
          ),
        ),
      ),
    );
  }

  void _showPageOptions(ScannedPage page, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Página ${page.pageNumber}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Opciones
            _buildOptionTile(
              icon: Icons.filter,
              title: 'Aplicar otro filtro',
              onTap: () {
                Navigator.pop(context);
                _reapplyFilter(page, index);
              },
            ),
            _buildOptionTile(
              icon: Icons.rotate_right,
              title: 'Rotar 90°',
              onTap: () {
                Navigator.pop(context);
                _rotatePage(page, index);
              },
            ),
            _buildOptionTile(
              icon: Icons.delete,
              title: 'Eliminar página',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _deletePage(index);
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _reapplyFilter(ScannedPage page, int index) async {
    final result = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (context) => FilterPreviewScreen(imagePath: page.file.path),
      ),
    );

    if (result != null) {
      setState(() {
        _pages[index] = ScannedPage(
          file: result,
          pageNumber: page.pageNumber,
          filterApplied: 'Filtro actualizado',
        );
      });
    }
  }

  Future<void> _rotatePage(ScannedPage page, int index) async {
    try {
      final rotatedPath = await DocumentScannerServicePro.rotateImage(
        page.file.path,
        degrees: 90,
      );

      if (rotatedPath != null) {
        setState(() {
          _pages[index] = ScannedPage(
            file: File(rotatedPath),
            pageNumber: page.pageNumber,
            filterApplied: page.filterApplied,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Página rotada')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rotando: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deletePage(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar página'),
        content: Text('¿Eliminar la página ${_pages[index].pageNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _pages.removeAt(index);
                
                // Renumerar páginas
                for (int i = 0; i < _pages.length; i++) {
                  _pages[i] = ScannedPage(
                    file: _pages[i].file,
                    pageNumber: i + 1,
                    filterApplied: _pages[i].filterApplied,
                  );
                }
              });
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ Página eliminada')),
              );
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _continueToOCR() {
    // Devolver lista de archivos procesados
    final files = _pages.map((p) => p.file).toList();
    Navigator.pop(context, files);
  }
}

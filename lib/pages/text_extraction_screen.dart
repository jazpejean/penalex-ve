import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_colors.dart';
import '../services/ocr_service.dart';

/// Pantalla para ver y editar texto extraído por OCR
/// Estilo CamScanner con tabs por página
class TextExtractionScreen extends StatefulWidget {
  final List<File> pages;

  const TextExtractionScreen({
    super.key,
    required this.pages,
  });

  @override
  State<TextExtractionScreen> createState() => _TextExtractionScreenState();
}

class _TextExtractionScreenState extends State<TextExtractionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<int, String> _extractedTexts = {};
  Map<int, TextEditingController> _controllers = {};
  bool _isExtracting = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.pages.length, vsync: this);
    _extractTextFromAllPages();
  }

  Future<void> _extractTextFromAllPages() async {
    setState(() {
      _isExtracting = true;
      _hasError = false;
    });

    try {
      debugPrint('🔍 Iniciando OCR de ${widget.pages.length} páginas...');
      
      final results = await OCRService.extractTextFromPages(widget.pages);
      
      setState(() {
        _extractedTexts = results;
        
        // Crear controladores para cada página
        for (var entry in results.entries) {
          _controllers[entry.key] = TextEditingController(
            text: OCRService.cleanText(entry.value),
          );
        }
        
        _isExtracting = false;
      });
      
      debugPrint('✅ OCR completado para todas las páginas');
      
    } catch (e) {
      debugPrint('❌ Error en OCR: $e');
      setState(() {
        _isExtracting = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.secondary,
        title: const Text(
          'Texto Extraído',
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: widget.pages.length > 1
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppColors.secondary,
                labelColor: AppColors.secondary,
                unselectedLabelColor: Colors.white70,
                tabs: List.generate(
                  widget.pages.length,
                  (index) => Tab(
                    icon: const Icon(Icons.description),
                    text: 'Página ${index + 1}',
                  ),
                ),
              )
            : null,
        actions: [
          if (!_isExtracting && !_hasError)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.secondary),
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'copy_all',
                  child: Row(
                    children: [
                      Icon(Icons.copy, color: AppColors.primary),
                      SizedBox(width: 12),
                      Text('Copiar todo'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, color: AppColors.primary),
                      SizedBox(width: 12),
                      Text('Compartir'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'retry',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: AppColors.primary),
                      SizedBox(width: 12),
                      Text('Reextraer texto'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: !_isExtracting && !_hasError
          ? FloatingActionButton.extended(
              onPressed: _saveAndContinue,
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.primary,
              icon: const Icon(Icons.check),
              label: const Text(
                'Finalizar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isExtracting) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_extractedTexts.isEmpty) {
      return _buildEmptyState();
    }

    if (widget.pages.length == 1) {
      return _buildSinglePageView(1);
    }

    return TabBarView(
      controller: _tabController,
      children: List.generate(
        widget.pages.length,
        (index) => _buildSinglePageView(index + 1),
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
            'Extrayendo texto...',
            style: TextStyle(
              color: AppColors.primary.withOpacity(0.8),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Procesando ${widget.pages.length} página${widget.pages.length != 1 ? 's' : ''}',
            style: TextStyle(
              color: AppColors.primary.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary.withOpacity(0.6),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Esto puede tardar unos segundos dependiendo de la calidad y cantidad de texto',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primary.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            const Text(
              'Error al extraer texto',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _extractTextFromAllPages,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Reintentar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.text_fields,
              size: 80,
              color: AppColors.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No se detectó texto',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Las imágenes no contienen texto legible o la calidad es muy baja',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _extractTextFromAllPages,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Reintentar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinglePageView(int pageNumber) {
    final controller = _controllers[pageNumber];
    final text = controller?.text ?? '';

    return Column(
      children: [
        // Header con stats
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.primary.withOpacity(0.05),
          child: Row(
            children: [
              Icon(
                Icons.description,
                color: AppColors.primary.withOpacity(0.6),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Página $pageNumber',
                style: TextStyle(
                  color: AppColors.primary.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              _buildStatChip(
                icon: Icons.text_fields,
                label: '${text.split(' ').where((w) => w.isNotEmpty).length} palabras',
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                icon: Icons.format_size,
                label: '${text.length} caracteres',
              ),
            ],
          ),
        ),

        // Text editor
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Toolbar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Edita el texto según necesites',
                        style: TextStyle(
                          color: AppColors.primary.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.copy,
                          color: AppColors.primary.withOpacity(0.6),
                          size: 20,
                        ),
                        onPressed: () => _copyPageText(pageNumber),
                        tooltip: 'Copiar',
                      ),
                    ],
                  ),
                ),

                // Text field
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.primary,
                    ),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(16),
                      border: InputBorder.none,
                      hintText: 'El texto aparecerá aquí...',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary.withOpacity(0.6)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _copyPageText(int pageNumber) {
    final text = _controllers[pageNumber]?.text ?? '';
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay texto para copiar')),
      );
      return;
    }

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('Texto de página $pageNumber copiado'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'copy_all':
        _copyAllText();
        break;
      case 'share':
        _shareText();
        break;
      case 'retry':
        _extractTextFromAllPages();
        break;
    }
  }

  void _copyAllText() {
    final allText = _controllers.entries
        .map((e) => '=== Página ${e.key} ===\n${e.value.text}')
        .join('\n\n');

    if (allText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay texto para copiar')),
      );
      return;
    }

    Clipboard.setData(ClipboardData(text: allText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('Todo el texto copiado (${_controllers.length} páginas)'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareText() async {
    final allText = _controllers.entries
        .map((e) => '=== Página ${e.key} ===\n${e.value.text}')
        .join('\n\n');

    if (allText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay texto para compartir')),
      );
      return;
    }

    try {
      await Share.share(
        allText,
        subject: 'Texto extraído - ${_controllers.length} página${_controllers.length != 1 ? 's' : ''}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error compartiendo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveAndContinue() {
    // Recopilar todo el texto editado
    final Map<int, String> finalTexts = {};
    for (var entry in _controllers.entries) {
      finalTexts[entry.key] = entry.value.text;
    }

    // Devolver resultados
    Navigator.pop(context, {
      'pages': widget.pages,
      'texts': finalTexts,
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

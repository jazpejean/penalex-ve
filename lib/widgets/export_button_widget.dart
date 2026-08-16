import 'dart:io';
import 'package:flutter/material.dart';

import '../services/document_export_service.dart';

/// Widget reutilizable para botón de exportación
class ExportButtonWidget extends StatelessWidget {
  final VoidCallback onExport;
  final String label;
  final IconData icon;
  final Color? color;
  final bool isLoading;
  
  const ExportButtonWidget({
    super.key,
    required this.onExport,
    this.label = 'Exportar DOCX',
    this.icon = Icons.file_download,
    this.color,
    this.isLoading = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onExport,
      icon: isLoading 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Diálogo de opciones de exportación
class ExportOptionsDialog extends StatefulWidget {
  final Future<File> Function(Map<String, String> options) onExport;
  final bool mostrarMembretePersonalizado;
  
  const ExportOptionsDialog({
    super.key,
    required this.onExport,
    this.mostrarMembretePersonalizado = false,
  });
  
  @override
  State<ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<ExportOptionsDialog> {
  final _nombreAbogadoController = TextEditingController();
  final _bufeteController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _numeroCasoController = TextEditingController();
  final _nombreCasoController = TextEditingController();
  
  bool _isExporting = false;
  
  @override
  void dispose() {
    _nombreAbogadoController.dispose();
    _bufeteController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _numeroCasoController.dispose();
    _nombreCasoController.dispose();
    super.dispose();
  }
  
  Future<void> _exportar() async {
    setState(() => _isExporting = true);
    
    try {
      final options = {
        'nombreAbogado': _nombreAbogadoController.text,
        'bufete': _bufeteController.text,
        'direccion': _direccionController.text,
        'telefono': _telefonoController.text,
        'email': _emailController.text,
        'numeroCaso': _numeroCasoController.text,
        'nombreCaso': _nombreCasoController.text,
      };
      
      final file = await widget.onExport(options);
      
      if (mounted) {
        Navigator.pop(context);
        
        // Mostrar diálogo de éxito con opciones
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('✅ Exportado'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Documento exportado exitosamente.'),
                const SizedBox(height: 8),
                Text(
                  'Guardado en:\n${file.path}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await DocumentExportService.compartirDocx(file);
                },
                icon: const Icon(Icons.share),
                label: const Text('Compartir'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isExporting = false);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Error'),
              ],
            ),
            content: Text('No se pudo exportar el documento:\n\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Opciones de Exportación'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Profesional',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nombreAbogadoController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Abogado',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bufeteController,
              decoration: const InputDecoration(
                labelText: 'Bufete / Firma',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
            
            if (widget.mostrarMembretePersonalizado) ...[
              const SizedBox(height: 16),
              const Text(
                'Membrete Personalizado (Opcional)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
            
            const SizedBox(height: 16),
            const Text(
              'Información del Documento',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nombreCasoController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Caso (Opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _numeroCasoController,
              decoration: const InputDecoration(
                labelText: 'Número de Caso (Opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _isExporting ? null : _exportar,
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.file_download),
          label: Text(_isExporting ? 'Exportando...' : 'Exportar'),
        ),
      ],
    );
  }
}

/// Bottom sheet con opciones de exportación rápida
class ExportBottomSheet extends StatelessWidget {
  final VoidCallback? onExportDocx;
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportExcel;
  final VoidCallback? onShare;
  
  const ExportBottomSheet({
    super.key,
    this.onExportDocx,
    this.onExportPdf,
    this.onExportExcel,
    this.onShare,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Exportar Documento',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (onExportDocx != null)
            ListTile(
              leading: const Icon(Icons.description, color: Color(0xFF2B579A)),
              title: const Text('Exportar como DOCX'),
              subtitle: const Text('Microsoft Word (editable)'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                onExportDocx!();
              },
            ),
          if (onExportPdf != null)
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFD32F2F)),
              title: const Text('Exportar como PDF'),
              subtitle: const Text('Documento no editable'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                onExportPdf!();
              },
            ),
          if (onExportExcel != null)
            ListTile(
              leading: const Icon(Icons.table_chart, color: Color(0xFF1D6F42)),
              title: const Text('Exportar como Excel'),
              subtitle: const Text('Hoja de cálculo'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                onExportExcel!();
              },
            ),
          if (onShare != null) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xFF0F172A)),
              title: const Text('Compartir'),
              subtitle: const Text('Email, WhatsApp, etc.'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                onShare!();
              },
            ),
          ],
        ],
      ),
    );
  }
}

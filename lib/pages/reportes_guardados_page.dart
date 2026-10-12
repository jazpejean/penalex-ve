import 'dart:io';

import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'package:path_provider/path_provider.dart';

import '../services/pdf_service.dart';
import '../widgets/app_drawer.dart';

/// Pantalla para ver reportes PDF guardados localmente
class ReportesGuardadosPage extends StatefulWidget {
  const ReportesGuardadosPage({super.key});

  @override
  State<ReportesGuardadosPage> createState() => _ReportesGuardadosPageState();
}

class _ReportesGuardadosPageState extends State<ReportesGuardadosPage> {
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static Color get fondoGris => TemaGlobal.superficie;

  List<File> _reportes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  Future<void> _cargarReportes() async {
    setState(() => _cargando = true);
    try {
      // Buscar PDFs en la carpeta de descargas de Penalex
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download/Penalex_VE');
      } else {
        final docDir = await getApplicationDocumentsDirectory();
        directory = Directory('${docDir.path}/Penalex_VE');
      }

      if (!directory.existsSync()) {
        setState(() {
          _reportes = [];
          _cargando = false;
        });
        return;
      }

      // Listar archivos PDF
      final List<FileSystemEntity> archivos = directory.listSync();
      final List<File> pdfs = archivos
          .whereType<File>()
          .where((file) => file.path.endsWith('.pdf'))
          .toList();

      // Ordenar por fecha de modificación (más recientes primero)
      pdfs.sort((a, b) {
        final statA = a.statSync();
        final statB = b.statSync();
        return statB.modified.compareTo(statA.modified);
      });

      setState(() {
        _reportes = pdfs;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar reportes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _abrirPDF(File file) async {
    try {
      await PDFService.abrirPDF(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _compartirPDF(File file) async {
    try {
      await PDFService.compartirPDF(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _eliminarReporte(File file) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar reporte'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este reporte?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await file.delete();
        await _cargarReportes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Reporte eliminado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  String _formatearTamano(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _obtenerNombreArchivo(File file) {
    return file.path.split('/').last.replaceAll('Dosimetria_', 'Reporte ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/reportes'),
      backgroundColor: fondoGris,
      appBar: AppBar(
        title: const Text(
          'REPORTES LOCALES',
          style: TextStyle(
            color: dorado,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        backgroundColor: azulMarino,
        foregroundColor: dorado,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarReportes,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _reportes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay reportes guardados',
                        style: TextStyle(fontSize: 18, color: TemaGlobal.textoSecundario),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Genera reportes PDF desde la calculadora',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reportes.length,
                  itemBuilder: (context, index) {
                    final reporte = _reportes[index];
                    final stat = reporte.statSync();
                    final nombre = _obtenerNombreArchivo(reporte);
                    final tamano = _formatearTamano(stat.size);
                    final fecha = _formatearFecha(stat.modified);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        title: Text(
                          nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              fecha,
                              style: TextStyle(
                                  fontSize: 12, color: TemaGlobal.textoSecundario),
                            ),
                            Text(
                              tamano,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.share, color: dorado),
                              onPressed: () => _compartirPDF(reporte),
                              tooltip: 'Compartir',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarReporte(reporte),
                              tooltip: 'Eliminar',
                            ),
                          ],
                        ),
                        onTap: () => _abrirPDF(reporte),
                      ),
                    );
                  },
                ),
    );
  }
}

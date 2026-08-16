import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../models/report_model.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../widgets/app_drawer.dart';

class SavedReportsScreen extends StatefulWidget {
  const SavedReportsScreen({super.key});

  @override
  State<SavedReportsScreen> createState() => _SavedReportsScreenState();
}

class _SavedReportsScreenState extends State<SavedReportsScreen> {
  List<ReportModel> _reportes = <ReportModel>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_cargarReportes());
  }

  Future<void> _cargarReportes() async {
    setState(() => _isLoading = true);
    try {
      _reportes = await ReportService.getSavedReports();
    } on Exception catch (_) {
      _reportes = <ReportModel>[];
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarContenido(ReportModel reporte) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(reporte.nombre),
        content: SingleChildScrollView(
            child: SelectableText(reporte.contenido,
                style: const TextStyle(fontFamily: 'monospace'))),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Future<void> _eliminarReporte(ReportModel reporte) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar reporte'),
        content: Text('¿Estás seguro de eliminar "${reporte.nombre}"?'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await ReportService.deleteReport(reporte.id);
        await _cargarReportes();
        if (!mounted) return;
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(
              content: Text('✅ Reporte eliminado'),
              backgroundColor: AppColors.success),
        );
      } on Exception catch (_) {
        if (!mounted) return;
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(
              content: Text('❌ No se pudo eliminar el reporte'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        drawer: const AppDrawer(currentRoute: "/reportes"),
        appBar: AppBar(
          title: const Text("Mis Reportes"),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final NavigatorState navigator = Navigator.of(context);
                await AuthService().logout();
                unawaited(navigator.pushNamedAndRemoveUntil(
                    "/", (Route<dynamic> route) => false));
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _reportes.isEmpty
                ? const Center(child: Text("No hay reportes guardados."))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _reportes.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ReportModel rep = _reportes[index];
                      final DateTime f = rep.fecha;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: const Icon(Icons.description,
                              color: AppColors.textSecondary),
                          title: Text(rep.nombre,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              "Guardado el: ${f.day}/${f.month}/${f.year}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error),
                            onPressed: () async {
                              await _eliminarReporte(rep);
                            },
                          ),
                          onTap: () => _mostrarContenido(rep),
                        ),
                      );
                    },
                  ),
      );
}

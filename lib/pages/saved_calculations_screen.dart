import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../models/calculation_model.dart';
import '../services/auth_service.dart';
import '../services/calculation_service.dart';
import '../widgets/app_drawer.dart';

class SavedCalculationsScreen extends StatefulWidget {
  const SavedCalculationsScreen({super.key});

  @override
  State<SavedCalculationsScreen> createState() =>
      _SavedCalculationsScreenState();
}

class _SavedCalculationsScreenState extends State<SavedCalculationsScreen> {
  List<CalculationModel> _calculations = <CalculationModel>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCalculations());
  }

  Future<void> _loadCalculations() async {
    setState(() => _isLoading = true);
    final List<CalculationModel> list =
        await CalculationService.getSavedCalculations();
    setState(() {
      _calculations = list;
      _isLoading = false;
    });
  }

  Future<void> _deleteCalculation(String id) async {
    final bool deleted = await CalculationService.deleteCalculation(id);
    if (!mounted) return;
    if (deleted) {
      await _loadCalculations();
      if (!mounted) return;
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Cálculo eliminado'),
            backgroundColor: AppColors.error),
      );
    } else {
      if (!mounted) return;
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
            content: Text('No se pudo eliminar el cálculo.'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _loadCalculation(CalculationModel calc) {
    Navigator.pushReplacementNamed(
      context,
      '/calculadora',
      arguments: calc,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        drawer: const AppDrawer(currentRoute: "/calculos"),
        appBar: AppBar(
          title: const Text("Cálculos Guardados"),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.secondary,
          elevation: 0,
          centerTitle: true,
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
            : _calculations.isEmpty
                ? const Center(child: Text("No hay cálculos guardados."))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _calculations.length,
                    itemBuilder: (BuildContext context, int index) {
                      final CalculationModel calc = _calculations[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.calculate,
                                color: AppColors.primary),
                          ),
                          title: Text(
                            calc.nombre.isEmpty ? "Sin Nombre" : calc.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${calc.delitos.length} delito(s) • ${calc.fecha.day}/${calc.fecha.month}/${calc.fecha.year}",
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_sweep,
                                color: AppColors.error),
                            onPressed: () async {
                              await _deleteCalculation(calc.id);
                            },
                          ),
                          onTap: () => _loadCalculation(calc),
                        ),
                      );
                    },
                  ),
      );
}

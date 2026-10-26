import 'package:flutter/material.dart';
import '../services/haptics_service.dart';
import '../pages/main_screen.dart';
import '../utils/main_tab_controller.dart';
import '../config/app_colors.dart';
import '../config/app_theme.dart';

import '../models/calculation_model.dart';
import '../utils/storage_manager.dart';
import '../widgets/app_drawer.dart';

/// Pantalla para ver y cargar cálculos guardados
class CalculosGuardadosPage extends StatefulWidget {
  const CalculosGuardadosPage({super.key});

  @override
  State<CalculosGuardadosPage> createState() => _CalculosGuardadosPageState();
}

class _CalculosGuardadosPageState extends State<CalculosGuardadosPage> {
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static Color get fondoGris => TemaGlobal.superficie;

  final StorageManager _storageManager = StorageManager();
  List<CalculationModel> _calculos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCalculos();
  }

  Future<void> _cargarCalculos() async {
    setState(() => _cargando = true);
    try {
      final calculos = await _storageManager.getSavedCalculations();
      setState(() {
        _calculos = calculos;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar cálculos: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _eliminarCalculo(String id) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cálculo'),
        content: const Text('¿Estás seguro de que quieres eliminar este cálculo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      Haptics.heavy();
      await _storageManager.deleteCalculation(id);
      await _cargarCalculos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cálculo eliminado'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/calculos'),
      backgroundColor: fondoGris,
      appBar: AppBar(
        title: const Text(
          'CÁLCULOS GUARDADOS',
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
              icon: Icon(Icons.home_outlined,
                  color: TemaGlobal.isDark ? TemaGlobal.dorado : TemaGlobal.azulMarino),
              tooltip: 'Ir al inicio',
              onPressed: () {
                mainTabIndex.value = 0;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                  (r) => false,
                );
              },
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _calculos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 80,
                        color: TemaGlobal.textoTenue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay cálculos guardados',
                        style: TextStyle(
                          fontSize: 18,
                          color: TemaGlobal.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Guarda tus cálculos desde la calculadora',
                        style: TextStyle(
                          fontSize: 14,
                          color: TemaGlobal.textoTenue,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _calculos.length,
                  itemBuilder: (context, index) {
                    final calculo = _calculos[index];
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
                            color: azulMarino.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calculate,
                            color: TemaGlobal.texto,
                          ),
                        ),
                        title: Text(
                          calculo.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Fecha: ${_formatearFecha(calculo.fecha)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: TemaGlobal.textoSecundario,
                              ),
                            ),
                            Text(
                              '${calculo.delitos.length} delito(s)',
                              style: TextStyle(
                                fontSize: 13,
                                color: TemaGlobal.textoSecundario,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              onPressed: () => _eliminarCalculo(calculo.id),
                              tooltip: 'Eliminar',
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () {
                          // TODO: Navegar a calculadora con datos precargados
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Funcionalidad en desarrollo'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

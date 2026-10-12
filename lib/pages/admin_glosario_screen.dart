import 'package:flutter/material.dart';
import '../pages/main_screen.dart';
import '../utils/main_tab_controller.dart';
import '../config/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/glosario_service.dart';

class AdminGlosarioScreen extends StatefulWidget {
  const AdminGlosarioScreen({super.key});

  @override
  State<AdminGlosarioScreen> createState() => _AdminGlosarioScreenState();
}

class _AdminGlosarioScreenState extends State<AdminGlosarioScreen> {
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static Color get fondoGris => TemaGlobal.superficie;

  final TextEditingController _terminoController = TextEditingController();
  final TextEditingController _definicionController = TextEditingController();
  final TextEditingController _busquedaController = TextEditingController();

  bool _isLoading = false;
  String _filtro = '';

  @override
  void dispose() {
    _terminoController.dispose();
    _definicionController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _agregarTermino() async {
    final termino = _terminoController.text.trim();
    final definicion = _definicionController.text.trim();

    if (termino.isEmpty || definicion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await GlosarioService.agregarTermino(termino, definicion);

      if (mounted) {
        _terminoController.clear();
        _definicionController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Término "$termino" agregado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _eliminarTermino(String docId, String termino) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar el término "$termino"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('glosario').doc(docId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Término "$termino" eliminado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestionar Glosario',
          style: TextStyle(color: dorado, fontWeight: FontWeight.bold),
        ),
        backgroundColor: azulMarino,
        foregroundColor: dorado,
        elevation: 0,
        centerTitle: true,
        actions: [
            IconButton(
              icon: const Icon(Icons.home_outlined, color: Color(0xFFC5A059)),
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
      backgroundColor: fondoGris,
      body: Column(
        children: [
          // Formulario para agregar término
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(                  'AGREGAR NUEVO TÉRMINO',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: TemaGlobal.texto,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _terminoController,
                  decoration: InputDecoration(
                    labelText: 'Término',
                    hintText: 'Ej: Acción penal',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.title),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _definicionController,
                  decoration: InputDecoration(
                    labelText: 'Definición',
                    hintText: 'Escribe la definición del término...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _agregarTermino,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add),
                    label: const Text('Agregar término'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azulMarino,
                      foregroundColor: dorado,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: dorado, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _busquedaController,
              decoration: InputDecoration(
                labelText: 'Buscar término',
                hintText: 'Filtrar por término...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _filtro.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _busquedaController.clear();
                          setState(() => _filtro = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _filtro = value.toLowerCase()),
            ),
          ),

          // Lista de términos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('glosario')
                  .orderBy('termino')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: dorado),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                // Filtrar términos
                final terminosFiltrados = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final termino = (data['termino'] as String? ?? '').toLowerCase();
                  return _filtro.isEmpty || termino.contains(_filtro);
                }).toList();

                if (terminosFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _filtro.isEmpty ? Icons.book_outlined : Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filtro.isEmpty
                              ? 'No hay términos en el glosario'
                              : 'No se encontraron términos',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: terminosFiltrados.length,
                  itemBuilder: (context, index) {
                    final doc = terminosFiltrados[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final termino = data['termino'] as String? ?? '';
                    final definicion = data['definicion'] as String? ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: dorado.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: ExpansionTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: dorado.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              termino.isNotEmpty ? termino[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: dorado,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          termino,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          definicion.length > 80
                              ? '${definicion.substring(0, 80)}...'
                              : definicion,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarTermino(doc.id, termino),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Definición:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: TemaGlobal.texto,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  definicion,
                                  style: const TextStyle(height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

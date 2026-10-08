import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/estilos_service.dart';
import 'redactor_documentos_screen.dart' show RedactorDocumentosScreen;

/// Biblioteca de Modelos de Escritos: los estilos reales (escritos y
/// sentencias) indexados por categoría, listos para copiar o para usar como
/// referencia de redacción en el Redactor.
class BibliotecaEstilosScreen extends StatefulWidget {
  const BibliotecaEstilosScreen({super.key});

  @override
  State<BibliotecaEstilosScreen> createState() => _BibliotecaEstilosScreenState();
}

class _BibliotecaEstilosScreenState extends State<BibliotecaEstilosScreen> {
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color grisOscuro = Color(0xFF1E293B);

  final EstilosService _service = EstilosService();
  List<String>? _categorias;
  String? _categoriaActiva;
  List<String> _documentos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      final categorias = await _service.obtenerCategorias();
      setState(() {
        _categorias = categorias;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      debugPrint('❌ Error cargando estilos: $e');
    }
  }

  Future<void> _seleccionarCategoria(String categoria) async {
    final docs = await _service.obtenerDocumentos(categoria);
    setState(() {
      _categoriaActiva = categoria;
      _documentos = docs;
    });
  }

  Future<void> _verDocumento(String categoria, String archivo) async {
    final texto = await _service.cargarTexto(categoria, archivo);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: grisOscuro,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _VistaDocumento(
          titulo: archivo,
          texto: texto,
          categoria: categoria,
          onCopiar: () => _copiarTexto(texto),
          onRedactar: () => _redactarConEstilo(categoria, archivo, texto),
        ),
      ),
    );
  }

  Future<void> _copiarTexto(String texto) async {
    await Clipboard.setData(ClipboardData(text: texto));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Estilo copiado'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _redactarConEstilo(String categoria, String archivo, String texto) {
    final nombreCategoria = EstilosService.nombreLegibleCategoria(categoria);
    final prompt = '''
Redacta un documento legal siguiendo el ESTILO del modelo de referencia "$archivo" (categoría: $nombreCategoria).

El usuario puede no tener un modelo para todo: si el escrito solicitado difiere del modelo, adapta la estructura conservando el estilo forense (encabezado, identificación de las partes, fundamentos legales con artículos y jurisprudencia, petitorio).

MODELO DE REFERENCIA (texto real, úsalo como guía de estilo y estructura; NO copies datos personales, nombres ni expedientes):
---
$texto
---

Escribe el documento completo, con [DATOS DEL CASO] donde falten datos, citando los artículos vigentes y, si está disponible, jurisprudencia de la Sala. No inventes leyes ni sentencias.
''';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RedactorDocumentosScreen(initialPrompt: prompt.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: azulMarino,
      appBar: AppBar(
        title: const Text(
          'Modelos de Escritos',
          style: TextStyle(color: dorado, fontWeight: FontWeight.bold),
        ),
        backgroundColor: azulMarino,
        elevation: 0,
        iconTheme: const IconThemeData(color: dorado),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: dorado),
            )
          : _categorias == null
              ? const Center(
                  child: Text(
                    'No se pudieron cargar los estilos',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : _categoriaActiva == null
                  ? _buildCategorias()
                  : _buildDocumentos(),
    );
  }

  Widget _buildCategorias() {
    final categorias = _categorias!;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categorias.length,
      itemBuilder: (context, index) {
        final cat = categorias[index];
        final esRaiz = cat == '.';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: grisOscuro,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _seleccionarCategoria(cat),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      esRaiz ? Icons.gavel : Icons.folder_copy,
                      color: dorado,
                      size: 24,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            EstilosService.nombreLegibleCategoria(cat),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            esRaiz
                                ? 'Sentencias y publicaciones'
                                : 'Escritos y formatos',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentos() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: grisOscuro,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _categoriaActiva = null),
                icon: const Icon(Icons.arrow_back, color: dorado, size: 20),
                tooltip: 'Volver a categorías',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  EstilosService.nombreLegibleCategoria(_categoriaActiva!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '${_documentos.length}',
                style: const TextStyle(color: dorado, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _documentos.isEmpty
              ? const Center(
                  child: Text(
                    'Esta categoría no tiene estilos',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _documentos.length,
                  itemBuilder: (context, index) {
                    final doc = _documentos[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: grisOscuro,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              _verDocumento(_categoriaActiva!, doc),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                const Icon(Icons.description,
                                    color: dorado, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    doc.replaceAll('.txt', ''),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _VistaDocumento extends StatelessWidget {
  const _VistaDocumento({
    required this.titulo,
    required this.texto,
    required this.categoria,
    required this.onCopiar,
    required this.onRedactar,
  });

  final String titulo;
  final String texto;
  final String categoria;
  final VoidCallback onCopiar;
  final VoidCallback onRedactar;

  static const Color dorado = Color(0xFFC5A059);
  static const Color azulMarino = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: azulMarino,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              const Icon(Icons.description, color: dorado),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo.replaceAll('.txt', ''),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopiar,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copiar texto'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: dorado,
                    side: const BorderSide(color: dorado),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRedactar,
                  icon: const Icon(Icons.edit_document, size: 18),
                  label: const Text('Redactar con este estilo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dorado,
                    foregroundColor: azulMarino,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF334155)),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              texto,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
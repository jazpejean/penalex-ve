import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/documento_legal.dart';
import '../services/documento_legal_service.dart';
import 'editor_documento_screen.dart';

class GenerarDocumentoScreen extends StatefulWidget {
  const GenerarDocumentoScreen({super.key});

  @override
  State<GenerarDocumentoScreen> createState() => _GenerarDocumentoScreenState();
}

class _GenerarDocumentoScreenState extends State<GenerarDocumentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();
  final _casoController = TextEditingController();
  final _tribunalController = TextEditingController();
  final _expedienteController = TextEditingController();
  final _partesController = TextEditingController();
  
  TipoDocumento _tipoSeleccionado = TipoDocumento.demanda;
  bool _cargando = false;
  bool _mostrarCamposAdicionales = false;
  
  // Archivos adjuntos
  final List<PlatformFile> _documentosAdjuntos = [];
  final List<XFile> _imagenesAdjuntas = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _promptController.dispose();
    _casoController.dispose();
    _tribunalController.dispose();
    _expedienteController.dispose();
    _partesController.dispose();
    super.dispose();
  }

  // Método para adjuntar documentos PDF/Word
  Future<void> _adjuntarDocumento() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _documentosAdjuntos.addAll(result.files);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result.files.length} documento(s) adjuntado(s)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al adjuntar documento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Método para adjuntar imágenes
  Future<void> _adjuntarImagenes() async {
    try {
      final List<XFile> imagenes = await _imagePicker.pickMultiImage();
      
      if (imagenes.isNotEmpty) {
        setState(() {
          _imagenesAdjuntas.addAll(imagenes);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${imagenes.length} imagen(es) adjuntada(s)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al adjuntar imágenes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Eliminar documento adjunto
  void _eliminarDocumento(int index) {
    setState(() {
      _documentosAdjuntos.removeAt(index);
    });
  }

  // Eliminar imagen adjunta
  void _eliminarImagen(int index) {
    setState(() {
      _imagenesAdjuntas.removeAt(index);
    });
  }

  Future<void> _generarDocumento() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      final documento = await DocumentoLegalService.generarDocumentoDesdePrompt(
        tipo: _tipoSeleccionado,
        prompt: _promptController.text,
        caso: _casoController.text.isNotEmpty ? _casoController.text : null,
        tribunal: _tribunalController.text.isNotEmpty ? _tribunalController.text : null,
        expediente: _expedienteController.text.isNotEmpty ? _expedienteController.text : null,
        partes: _partesController.text.isNotEmpty
            ? _partesController.text.split(',').map((e) => e.trim()).toList()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Documento generado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar al editor
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditorDocumentoScreen(documento: documento),
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
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9), // Mismo fondo que calculadora
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFC5A059),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Redactar con IA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Describe qué documento necesitas y la IA lo redactará',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Tipo de documento
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipo de Documento',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TipoDocumento>(
                      initialValue: _tipoSeleccionado,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF0F172A)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: const Color(0xFF0F172A).withValues(alpha: 0.2)),
                        ),
                      ),
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      items: TipoDocumento.values.map((tipo) {
                        return DropdownMenuItem(
                          value: tipo,
                          child: Text(tipo.nombre),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _tipoSeleccionado = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Prompt principal
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instrucciones para la IA',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Describe qué debe contener el documento',
                      style: TextStyle(
                        color: const Color(0xFF4A5568).withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _promptController,
                      maxLines: 6,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'Ejemplo: Redacta una demanda por lesiones personales culposas contra Juan Pérez. El accidente ocurrió el 15/03/2024 en Caracas. La víctima es María González. Solicitar indemnización de Bs. 50.000.',
                        hintStyle: TextStyle(color: const Color(0xFF4A5568).withValues(alpha: 0.4)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF0F172A)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: const Color(0xFF0F172A).withValues(alpha: 0.2)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor describe el documento';
                        }
                        if (value.trim().length < 20) {
                          return 'Proporciona más detalles (mínimo 20 caracteres)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Sección de adjuntos
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Adjuntar Archivos (Opcional)',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Botones para adjuntar
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _adjuntarDocumento,
                            icon: const Icon(Icons.attach_file, size: 20),
                            label: const Text('PDF/Word'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              side: const BorderSide(color: Color(0xFF0F172A)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _adjuntarImagenes,
                            icon: const Icon(Icons.image, size: 20),
                            label: const Text('Imágenes'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              side: const BorderSide(color: Color(0xFF0F172A)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Lista de documentos adjuntos
                    if (_documentosAdjuntos.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Documentos:',
                        style: TextStyle(
                          color: Color(0xFF4A5568),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._documentosAdjuntos.asMap().entries.map((entry) {
                        final index = entry.key;
                        final file = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                file.extension == 'pdf'
                                    ? Icons.picture_as_pdf
                                    : Icons.description,
                                color: const Color(0xFFC5A059),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      file.name,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${(file.size / 1024).toStringAsFixed(1)} KB',
                                      style: const TextStyle(
                                        color: Color(0xFF4A5568),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _eliminarDocumento(index),
                                icon: const Icon(Icons.close, size: 20),
                                color: Colors.red,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    
                    // Lista de imágenes adjuntas
                    if (_imagenesAdjuntas.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Imágenes:',
                        style: TextStyle(
                          color: Color(0xFF4A5568),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _imagenesAdjuntas.asMap().entries.map((entry) {
                          final index = entry.key;
                          final imagen = entry.value;
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(imagen.path),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _eliminarImagen(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Botón para mostrar campos adicionales
              TextButton.icon(
                onPressed: () {
                  setState(() => _mostrarCamposAdicionales = !_mostrarCamposAdicionales);
                },
                icon: Icon(
                  _mostrarCamposAdicionales
                      ? Icons.expand_less
                      : Icons.expand_more,
                  color: const Color(0xFFC5A059),
                ),
                label: Text(
                  _mostrarCamposAdicionales
                      ? 'Ocultar campos opcionales'
                      : 'Agregar información adicional',
                  style: const TextStyle(color: Color(0xFFC5A059)),
                ),
              ),
              
              // Campos adicionales
              if (_mostrarCamposAdicionales) ...[
                const SizedBox(height: 16),
                _buildCard(
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _casoController,
                        label: 'Nombre del Caso',
                        hint: 'Ej: González vs. Pérez',
                        icon: Icons.gavel,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _tribunalController,
                        label: 'Tribunal',
                        hint: 'Ej: Tribunal Penal de Caracas',
                        icon: Icons.account_balance,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _expedienteController,
                        label: 'N° Expediente',
                        hint: 'Ej: SP01-P-2024-000123',
                        icon: Icons.folder_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _partesController,
                        label: 'Partes (separadas por comas)',
                        hint: 'Ej: María González, Juan Pérez',
                        icon: Icons.people_outline,
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Botón generar
              ElevatedButton(
                onPressed: _cargando ? null : _generarDocumento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC5A059),
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                ),
                child: _cargando
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Generar Documento',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFC5A059).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC5A059).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFC5A059), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'La IA generará un borrador que podrás editar antes de guardar',
                        style: TextStyle(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0F172A).withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFC5A059), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: const Color(0xFF4A5568).withValues(alpha: 0.4)),
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0F172A)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFF0F172A).withValues(alpha: 0.2)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

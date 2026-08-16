import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/escrito_legal.dart';
import '../services/escritos_service.dart';

class GenerarEscritoScreen extends StatefulWidget {
  const GenerarEscritoScreen({super.key});

  @override
  State<GenerarEscritoScreen> createState() => _GenerarEscritoScreenState();
}

class _GenerarEscritoScreenState extends State<GenerarEscritoScreen> {
  TipoEscrito _tipoSeleccionado = TipoEscrito.recursoApelacion;
  final Map<String, TextEditingController> _controllers = {};
  
  bool _isGenerating = false;
  EscritoLegal? _escritoGenerado;

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color grisOscuro = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _inicializarControllers();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _inicializarControllers() {
    final campos = _obtenerCamposParaTipo(_tipoSeleccionado);
    for (final campo in campos) {
      _controllers[campo['key']] = TextEditingController();
    }
  }

  void _actualizarControllers() {
    // Limpiar controllers antiguos
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    
    // Crear nuevos
    _inicializarControllers();
    setState(() {});
  }

  List<Map<String, dynamic>> _obtenerCamposParaTipo(TipoEscrito tipo) {
    switch (tipo) {
      case TipoEscrito.recursoApelacion:
        return [
          {'key': 'numeroCaso', 'label': 'Número de Caso', 'required': true},
          {'key': 'tribunal', 'label': 'Tribunal', 'required': true},
          {'key': 'juez', 'label': 'Juez', 'required': false},
          {'key': 'imputado', 'label': 'Nombre del Imputado', 'required': true},
          {'key': 'delitos', 'label': 'Delito(s)', 'required': true, 'multiline': true},
          {'key': 'decisionApelada', 'label': 'Decisión que se Apela', 'required': true, 'multiline': true},
          {'key': 'fechaDecision', 'label': 'Fecha de la Decisión', 'required': false},
          {'key': 'motivosApelacion', 'label': 'Motivos de Apelación', 'required': true, 'multiline': true, 'maxLines': 5},
        ];
      case TipoEscrito.escritoDefensa:
        return [
          {'key': 'numeroCaso', 'label': 'Número de Causa', 'required': true},
          {'key': 'tribunal', 'label': 'Tribunal', 'required': true},
          {'key': 'juez', 'label': 'Juez', 'required': false},
          {'key': 'imputado', 'label': 'Nombre del Imputado', 'required': true},
          {'key': 'delitos', 'label': 'Delito(s) Imputado(s)', 'required': true, 'multiline': true},
          {'key': 'hechos', 'label': 'Hechos según el MP', 'required': true, 'multiline': true, 'maxLines': 5},
          {'key': 'lineaDefensa', 'label': 'Línea de Defensa', 'required': true, 'multiline': true, 'maxLines': 4},
        ];
      case TipoEscrito.solicitudLibertad:
        return [
          {'key': 'numeroCaso', 'label': 'Número de Causa', 'required': true},
          {'key': 'tribunal', 'label': 'Tribunal', 'required': true},
          {'key': 'imputado', 'label': 'Nombre del Imputado', 'required': true},
          {'key': 'delitos', 'label': 'Delito(s)', 'required': true, 'multiline': true},
          {'key': 'tiempoPrivacion', 'label': 'Tiempo Privado de Libertad', 'required': false},
          {'key': 'medidaActual', 'label': 'Medida Cautelar Actual', 'required': false},
          {'key': 'fundamentacion', 'label': 'Razones para Solicitar Libertad', 'required': true, 'multiline': true, 'maxLines': 5},
        ];
      case TipoEscrito.oposicionMedidas:
        return [
          {'key': 'numeroCaso', 'label': 'Número de Causa', 'required': true},
          {'key': 'tribunal', 'label': 'Tribunal', 'required': true},
          {'key': 'imputado', 'label': 'Nombre del Imputado', 'required': true},
          {'key': 'delitos', 'label': 'Delito(s) Imputado(s)', 'required': true, 'multiline': true},
          {'key': 'medidaSolicitada', 'label': 'Medida Solicitada por el MP', 'required': true},
          {'key': 'fundamentacionMP', 'label': 'Argumentos del Fiscal', 'required': false, 'multiline': true, 'maxLines': 4},
        ];
      default:
        return [
          {'key': 'numeroCaso', 'label': 'Número de Caso', 'required': false},
          {'key': 'tribunal', 'label': 'Tribunal', 'required': false},
          {'key': 'imputado', 'label': 'Nombre del Imputado', 'required': false},
          {'key': 'delitos', 'label': 'Delito(s)', 'required': false, 'multiline': true},
          {'key': 'descripcion', 'label': 'Descripción/Detalles', 'required': true, 'multiline': true, 'maxLines': 6},
        ];
    }
  }

  Future<void> _generarEscrito() async {
    // Validar campos requeridos
    final campos = _obtenerCamposParaTipo(_tipoSeleccionado);
    for (final campo in campos) {
      if (campo['required'] == true && _controllers[campo['key']]!.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('El campo "${campo['label']}" es requerido'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isGenerating = true);

    try {
      final datos = <String, dynamic>{};
      _controllers.forEach((key, controller) {
        if (controller.text.isNotEmpty) {
          datos[key] = controller.text;
        }
      });

      final escrito = await EscritosService.generarEscrito(
        tipo: _tipoSeleccionado,
        datos: datos,
      );

      // Guardar
      final escritoGuardado = await EscritosService.guardarEscrito(escrito);

      setState(() {
        _escritoGenerado = escritoGuardado;
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Escrito generado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      
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
      backgroundColor: azulMarino,
      appBar: AppBar(
        title: const Text(
          'Generar Escrito Legal',
          style: TextStyle(color: dorado, fontWeight: FontWeight.bold),
        ),
        backgroundColor: azulMarino,
        elevation: 0,
        iconTheme: const IconThemeData(color: dorado),
      ),
      body: _escritoGenerado != null
          ? _buildResultado()
          : _buildFormulario(),
    );
  }

  Widget _buildFormulario() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de tipo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: grisOscuro,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tipo de Escrito',
                  style: TextStyle(
                    color: dorado,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TipoEscrito>(
                  initialValue: _tipoSeleccionado,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: azulMarino,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: grisOscuro,
                  style: const TextStyle(color: Colors.white),
                  items: TipoEscrito.values.map((tipo) {
                    return DropdownMenuItem(
                      value: tipo,
                      child: Text(tipo.nombre),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _tipoSeleccionado = value;
                        _actualizarControllers();
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _tipoSeleccionado.descripcion,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Campos dinámicos
          ..._obtenerCamposParaTipo(_tipoSeleccionado).map((campo) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildCampo(campo),
            );
          }),

          const SizedBox(height: 24),

          // Botón generar
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generarEscrito,
              style: ElevatedButton.styleFrom(
                backgroundColor: dorado,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: dorado, width: 1.5),
                ),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: azulMarino,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Generar Escrito con IA',
                      style: TextStyle(
                        color: azulMarino,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampo(Map<String, dynamic> campo) {
    final controller = _controllers[campo['key']]!;
    final isMultiline = campo['multiline'] == true;
    final maxLines = campo['maxLines'] as int? ?? (isMultiline ? 3 : 1);
    final isRequired = campo['required'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              campo['label'],
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: grisOscuro,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            hintText: 'Ingresa ${campo['label'].toLowerCase()}',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultado() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: grisOscuro,
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Escrito Generado',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _escritoGenerado!.tipo.nombre,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: dorado),
                onPressed: () {
                  setState(() => _escritoGenerado = null);
                },
              ),
            ],
          ),
        ),

        // Contenido
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              _escritoGenerado!.contenido,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        ),

        // Acciones
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: grisOscuro,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _escritoGenerado!.contenido));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('📋 Copiado al portapapeles')),
                      );
                    },
                    icon: const Icon(Icons.copy, color: dorado),
                    label: const Text('Copiar', style: TextStyle(color: dorado)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: dorado, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Exportar a DOCX
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🚧 Export DOCX próximamente')),
                      );
                    },
                    icon: const Icon(Icons.file_download, color: azulMarino),
                    label: const Text('Exportar', style: TextStyle(color: azulMarino)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dorado,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/ai_service.dart';
import '../services/role_service.dart';
import '../widgets/role_guard.dart';

class AdminIAConfigScreen extends StatefulWidget {
  const AdminIAConfigScreen({super.key});

  @override
  State<AdminIAConfigScreen> createState() => _AdminIAConfigScreenState();
}

class _AdminIAConfigScreenState extends State<AdminIAConfigScreen> {
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color fondoGris = Color(0xFFF1F5F9);
  
  AIModel _modeloSeleccionado = AIService.getModeloActivo();
  
  final TextEditingController _openAIKeyController = TextEditingController();
  final TextEditingController _geminiKeyController = TextEditingController();
  final TextEditingController _claudeKeyController = TextEditingController();
  final TextEditingController _deepseekKeyController = TextEditingController();
  
  bool _showOpenAIKey = false;
  bool _showGeminiKey = false;
  bool _showClaudeKey = false;
  bool _showDeepSeekKey = false;
  
  @override
  void dispose() {
    _openAIKeyController.dispose();
    _geminiKeyController.dispose();
    _claudeKeyController.dispose();
    _deepseekKeyController.dispose();
    super.dispose();
  }
  
  Future<void> _guardarConfiguracion() async {
    // Actualizar API keys
    AIService.configurarKeys(
      openAI: _openAIKeyController.text.trim().isEmpty 
          ? null 
          : _openAIKeyController.text.trim(),
      gemini: _geminiKeyController.text.trim().isEmpty 
          ? null 
          : _geminiKeyController.text.trim(),
      claude: _claudeKeyController.text.trim().isEmpty 
          ? null 
          : _claudeKeyController.text.trim(),
      deepseek: _deepseekKeyController.text.trim().isEmpty 
          ? null 
          : _deepseekKeyController.text.trim(),
    );
    
    // Cambiar modelo activo
    await AIService.setModelo(_modeloSeleccionado);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Configuración guardada'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  Future<void> _probarModelo() async {
    if (!AIService.isModeloDisponible(_modeloSeleccionado)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ API Key no configurada para ${_modeloSeleccionado.proveedor.nombre}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(color: dorado),
            const SizedBox(width: 16),
            Text('Probando ${_modeloSeleccionado.nombre}...'),
          ],
        ),
      ),
    );
    
    try {
      final modeloAnterior = AIService.getModeloActivo();
      await AIService.setModelo(_modeloSeleccionado);
      
      final result = await AIService.interpretarLey(
        tituloLey: 'Código Penal Venezolano',
        articulo: 'Art. 406',
        textoArticulo: 'El que intencionalmente haya dado muerte a alguna persona, será penado con presidio de doce a dieciocho años.',
      );
      
      // Restaurar modelo anterior
      await AIService.setModelo(modeloAnterior);
      
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text('✅ ${_modeloSeleccionado.nombre}'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Respuesta:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: azulMarino,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(result.interpretacion),
                  const Divider(height: 24),
                  Text(
                    'Costo estimado: \$${_modeloSeleccionado.costoEstimadoPorInterpretacion.toStringAsFixed(4)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('❌ Error'),
              ],
            ),
            content: Text('Error al probar el modelo:\n\n$e'),
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
    return RoleProtectedPage(
      requiredRole: UserRole.admin,
      child: Scaffold(
        appBar: AppBar(
        title: const Text(
          'Configuración de IA',
          style: TextStyle(color: dorado, fontWeight: FontWeight.bold),
        ),
        backgroundColor: azulMarino,
        foregroundColor: dorado,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _guardarConfiguracion,
            tooltip: 'Guardar',
          ),
        ],
      ),
      backgroundColor: fondoGris,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del modelo actual
            _buildModeloActualCard(),
            
            const SizedBox(height: 24),
            
            // Selector de modelos
            const Text(
              'SELECCIONAR MODELO',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: azulMarino,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildProveedorSection(
              'OpenAI',
              Icons.smart_toy,
              [AIModel.gpt4, AIModel.gpt4Turbo, AIModel.gpt35Turbo],
              Colors.green,
            ),
            
            _buildProveedorSection(
              'Google Gemini',
              Icons.auto_awesome,
              [AIModel.geminiPro, AIModel.gemini15Pro],
              Colors.blue,
            ),
            
            _buildProveedorSection(
              'Anthropic Claude',
              Icons.psychology,
              [AIModel.claude3Opus, AIModel.claude3Sonnet, AIModel.claude3Haiku],
              Colors.purple,
            ),
            
            _buildProveedorSection(
              'DeepSeek',
              Icons.code,
              [AIModel.deepseekChat, AIModel.deepseekCoder],
              Colors.orange,
            ),
            
            const SizedBox(height: 24),
            
            // API Keys
            const Text(
              'API KEYS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: azulMarino,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildAPIKeyField(
              'OpenAI',
              _openAIKeyController,
              _showOpenAIKey,
              (value) => setState(() => _showOpenAIKey = value),
              'sk-proj-...',
            ),
            
            _buildAPIKeyField(
              'Google Gemini',
              _geminiKeyController,
              _showGeminiKey,
              (value) => setState(() => _showGeminiKey = value),
              'AIza...',
            ),
            
            _buildAPIKeyField(
              'Anthropic Claude',
              _claudeKeyController,
              _showClaudeKey,
              (value) => setState(() => _showClaudeKey = value),
              'sk-ant-...',
            ),
            
            _buildAPIKeyField(
              'DeepSeek',
              _deepseekKeyController,
              _showDeepSeekKey,
              (value) => setState(() => _showDeepSeekKey = value),
              'sk-...',
            ),
            
            const SizedBox(height: 24),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _probarModelo,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Probar modelo'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: azulMarino, width: 1.5),
                      foregroundColor: azulMarino,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _guardarConfiguracion,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azulMarino,
                      foregroundColor: dorado,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: dorado, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Información adicional
            _buildInfoCard(),
          ],
        ),
      ),
      ),
    );
  }
  
  Widget _buildModeloActualCard() {
    final modelo = AIService.getModeloActivo();
    final info = AIService.getInfoModelo();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [azulMarino, Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: dorado.withValues(alpha: 50 / 255),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: dorado),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MODELO ACTIVO',
                      style: TextStyle(
                        color: dorado,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      modelo.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip('Proveedor', info['proveedor']),
              _buildInfoChip('Calidad', info['calidad']),
              _buildInfoChip('Velocidad', info['velocidad']),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            modelo.descripcion,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'Costo: \$${modelo.costoEstimadoPorInterpretacion.toStringAsFixed(4)} por interpretación',
            style: TextStyle(color: dorado.withValues(alpha: 180 / 255), fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 25 / 255),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 150 / 255),
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProveedorSection(
    String nombre,
    IconData icon,
    List<AIModel> modelos,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 50 / 255)),
      ),
      child: Column(
        children: [
          // Header del proveedor
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 25 / 255),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Modelos
          ...modelos.map(_buildModeloTile),
        ],
      ),
    );
  }
  
  Widget _buildModeloTile(AIModel modelo) {
    final isSelected = _modeloSeleccionado == modelo;
    final isDisponible = AIService.isModeloDisponible(modelo);
    
    return InkWell(
      onTap: () => setState(() => _modeloSeleccionado = modelo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? azulMarino.withAlpha(10) : null,
          border: Border(
            bottom: BorderSide(color: Colors.grey.withAlpha(25)),
          ),
        ),
        child: Row(
          children: [
            // ignore: deprecated_member_use
            Radio<AIModel>(
              value: modelo,
              // ignore: deprecated_member_use
              groupValue: _modeloSeleccionado,
              // ignore: deprecated_member_use
              onChanged: (value) {
                if (value != null) {
                  setState(() => _modeloSeleccionado = value);
                }
              },
              activeColor: azulMarino,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        modelo.nombre,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isDisponible ? azulMarino : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isDisponible)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(50),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SIN API KEY',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    modelo.descripcion,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildChip('${modelo.velocidad.name}', Colors.blue),
                      const SizedBox(width: 4),
                      _buildChip('${modelo.calidad.name}', Colors.green),
                      const SizedBox(width: 4),
                      _buildChip(
                        '\$${modelo.costoEstimadoPorInterpretacion.toStringAsFixed(4)}',
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  Widget _buildAPIKeyField(
    String label,
    TextEditingController controller,
    bool showKey,
    ValueChanged<bool> onToggle,
    String hint,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(showKey ? Icons.visibility_off : Icons.visibility),
                onPressed: () => onToggle(!showKey),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: controller.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copiado al portapapeles')),
                    );
                  }
                },
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: !showKey,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Información',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '• Las API keys se guardan localmente en el dispositivo\n'
            '• Puedes cambiar el modelo en cualquier momento\n'
            '• Usa "Probar modelo" para verificar que funciona\n'
            '• Los modelos gratuitos tienen límites de uso\n'
            '• DeepSeek es el más económico (0.00014 USD por 1K tokens)',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

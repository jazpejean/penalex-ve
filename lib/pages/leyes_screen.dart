import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import '../widgets/sentencias_relacionadas_widget.dart';

class LeyesScreen extends StatefulWidget {
  const LeyesScreen({super.key, this.selectedLawIndex});
  final int? selectedLawIndex;

  @override
  State<LeyesScreen> createState() => _LeyesScreenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('selectedLawIndex', selectedLawIndex));
  }
}

class _LeyesScreenState extends State<LeyesScreen> {
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color tarjetaFondo = Color(0xFF111827);

  bool _detailShown = false;

  final List<Map<String, String>> _leyes = const <Map<String, String>>[
    <String, String>{
      'titulo': 'Constitución de la República Bolivariana de Venezuela',
      'descripcion': 'Marco constitucional de derechos, garantías y estructura del Estado venezolano.',
      'detalle': 'La Constitución es norma suprema y establece los derechos humanos, el debido proceso y la organización del Estado.',
    },
    <String, String>{
      'titulo': 'Código Penal Venezolano',
      'descripcion': 'Normas penales básicas que tipifican delitos y sancionan conductas criminales.',
      'detalle': 'Regula las penas, circunstancias agravantes y atenuantes, así como la aplicación de sanciones en el orden penal.',
    },
    <String, String>{
      'titulo': 'Código Orgánico Procesal Penal',
      'descripcion': 'Regula el procedimiento penal, investigación y garantías procesales.',
      'detalle': 'Establece la cadena de custodia, el juicio oral, la prueba, los recursos y la tutela judicial efectiva en materia penal.',
    },
    <String, String>{
      'titulo': 'Ley Orgánica sobre el Derecho de las Mujeres a una Vida Libre de Violencia',
      'descripcion': 'Protege a las mujeres contra la violencia en el ámbito público y privado.',
      'detalle': 'Define medidas de prevención, atención y sanción para erradicar la violencia de género y garantizar la protección integral de las víctimas.',
    },
    <String, String>{
      'titulo': 'Ley Orgánica de Drogas',
      'descripcion': 'Regula el control, fiscalización y sanciones sobre estupefacientes y sustancias psicotrópicas.',
      'detalle': 'Establece tipos penales, medidas de seguridad y políticas de prevención contra el tráfico ilícito de drogas.',
    },
    <String, String>{
      'titulo': 'Ley Orgánica contra la Delincuencia Organizada y Financiamiento al Terrorismo',
      'descripcion': 'Sanciona los delitos de crimen organizado y financiamiento terrorista.',
      'detalle': 'Define los delitos, la cooperación internacional y las medidas penales especiales contra las redes criminales y el terrorismo.',
    },
    <String, String>{
      'titulo': 'Ley contra el Secuestro y la Extorsión',
      'descripcion': 'Tipifica y sanciona los delitos de secuestro, coacción y extorsión.',
      'detalle': 'Contempla penas elevadas, protección a las víctimas y medidas para combatir la violencia económica y la coerción ilícita.',
    },
    <String, String>{
      'titulo': 'Ley sobre el Hurto y Robo de Vehículos Automotores',
      'descripcion': 'Regula los delitos contra vehículos automotores y las penas correspondientes.',
      'detalle': 'Describe el hurto, el robo, el desvalijamiento y las circunstancias agravantes relacionadas con vehículos automotores.',
    },
    <String, String>{
      'titulo': 'Ley para el Desarme y Control de Armas y Municiones',
      'descripcion': 'Regula la tenencia, porte y control de armas de fuego y municiones.',
      'detalle': 'Establece operaciones de desarme, registro de armas y sanciones para el uso indebido de armas y municiones.',
    },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_detailShown && widget.selectedLawIndex != null) {
      final int index = widget.selectedLawIndex!;
      if (index >= 0 && index < _leyes.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mostrarDetalle(context, _leyes[index]);
        });
      }
      _detailShown = true;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text("Biblioteca Legal"),
        backgroundColor: azulMarino,
      ),
      backgroundColor: azulMarino,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                itemCount: _leyes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisExtent: 120,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final Map<String, String> ley = _leyes[index];
                  return GestureDetector(
                    onTap: () => _mostrarDetalle(context, ley),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: tarjetaFondo,
                        border: Border.all(color: dorado.withValues(alpha: 0.25)),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            ley["titulo"]!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ley["descripcion"]!,
                            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.45),
                          ),
                          const Spacer(),
                          const Row(
                            children: <Widget>[
                              Icon(Icons.arrow_forward_rounded, color: dorado, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "VER FICHA",
                                style: TextStyle(
                                  color: dorado,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

  void _mostrarDetalle(BuildContext context, Map<String, String> ley) {
    // Si es el Código Penal, mostrar pantalla especial con datos JSON
    if (ley["titulo"]!.contains("Código Penal")) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => const CodigoPenalDetailScreen(),
        ),
      );
      return;
    }

    // Para otras leyes, mostrar el diálogo simple
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
          backgroundColor: azulMarino,
          title: Text(ley["titulo"]!, style: const TextStyle(color: dorado)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                ley["descripcion"]!,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 14),
              Text(
                ley["detalle"]!,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cerrar", style: TextStyle(color: dorado)),
            ),
          ],
        ),
    );
  }
}

// Pantalla detallada del Código Penal con botón flotante de IA
class CodigoPenalDetailScreen extends StatefulWidget {
  const CodigoPenalDetailScreen({super.key});

  @override
  State<CodigoPenalDetailScreen> createState() => _CodigoPenalDetailScreenState();
}

class _CodigoPenalDetailScreenState extends State<CodigoPenalDetailScreen> {
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color tarjetaFondo = Color(0xFF111827);

  Map<String, dynamic>? _codigoPenal;
  bool _isLoading = true;
  String? _error;
  
  // Control del chat de IA
  bool _showAIChat = false;
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  String? _selectedArticle;
  String _selectedArticleContenido = '';
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    _loadCodigoPenal();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _loadCodigoPenal() async {
    try {
      final String jsonString = await rootBundle.loadString('leyes_json/codigo penal.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;
      
      setState(() {
        _codigoPenal = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar el Código Penal: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleAIChat() {
    setState(() {
      _showAIChat = !_showAIChat;
    });
  }

  void _sendMessage() {
    if (_chatController.text.trim().isEmpty) return;

    final userMessage = _chatController.text;
    setState(() {
      _messages.add({
        'role': 'user',
        'content': userMessage,
      });
      _chatController.clear();
      _isThinking = true;
    });

    // Simular respuesta de IA (aquí deberías integrar tu servicio de IA real)
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': _generateAIResponse(userMessage),
        });
        _isThinking = false;
      });
    });
  }

  String _generateAIResponse(String query) {
    // Esto es una simulación. Aquí deberías llamar a tu servicio de IA real
    final lowerQuery = query.toLowerCase();
    
    if (lowerQuery.contains('artículo') || lowerQuery.contains('articulo')) {
      return '📚 Para interpretar un artículo específico, por favor indícame el número del artículo y te proporcionaré:\n\n'
          '• Interpretación clara y sencilla\n'
          '• Ejemplos prácticos de aplicación\n'
          '• Referencias cruzadas con otros artículos\n'
          '• Jurisprudencia relevante si existe\n\n'
          'Ejemplo: "Explícame el artículo 405"';
    }
    
    if (lowerQuery.contains('ejemplo')) {
      return '💡 Los ejemplos ayudan a entender mejor la ley. '
          'Dime qué artículo o tema te interesa y te daré casos prácticos de aplicación.';
    }
    
    if (lowerQuery.contains('homicidio')) {
      return '⚖️ El homicidio está regulado principalmente en los artículos 405-412 del Código Penal:\n\n'
          '• Art. 405: Homicidio simple (12-18 años de presidio)\n'
          '• Art. 406: Homicidio calificado (15-30 años)\n'
          '• Art. 409: Homicidio culposo (6 meses-5 años)\n\n'
          '¿Quieres que te explique alguno en detalle?';
    }
    
    return '🤖 Entiendo tu consulta sobre "${query}". Como asistente legal de IA, puedo ayudarte a:\n\n'
        '• Interpretar artículos del Código Penal\n'
        '• Explicar términos jurídicos complejos\n'
        '• Dar ejemplos prácticos de aplicación\n'
        '• Relacionar artículos entre sí\n\n'
        'Por favor, hazme una pregunta más específica sobre algún artículo o tema legal.';
  }

  void _showArticleIA(Map<String, dynamic> articulo) {
    setState(() {
      _selectedArticle = articulo['numero'].toString();
      _selectedArticleContenido = articulo['contenido']?.toString() ?? '';
      _showAIChat = true;
      _messages.clear();
      _messages.add({
        'role': 'assistant',
        'content': '📖 Artículo ${articulo['numero']} seleccionado.\n\n'
            '${articulo['contenido']}\n\n'
            'Puedes preguntarme:\n'
            '• ¿Qué significa este artículo?\n'
            '• Dame un ejemplo práctico\n'
            '• ¿Con qué otros artículos se relaciona?\n'
            '• ¿Cuáles son las penas?',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: azulMarino,
      appBar: AppBar(
        title: const Text('Código Penal Venezolano'),
        backgroundColor: azulMarino,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showAIChat ? Icons.close : Icons.smart_toy),
            onPressed: _toggleAIChat,
            tooltip: 'Asistente IA',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: dorado))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white)))
              : Stack(
                  children: [
                    _buildContent(),
                    if (_showAIChat) _buildAIChatPanel(),
                  ],
                ),
      floatingActionButton: !_showAIChat ? FloatingActionButton.extended(
        onPressed: _toggleAIChat,
        backgroundColor: dorado,
        foregroundColor: azulMarino,
        icon: const Icon(Icons.psychology),
        label: const Text('IA Legal', style: TextStyle(fontWeight: FontWeight.bold)),
      ) : null,
    );
  }

  Widget _buildContent() {
    if (_codigoPenal == null) return const SizedBox();

    final libros = _codigoPenal!['libros'] as List;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: libros.length,
      itemBuilder: (context, index) {
        final libro = libros[index] as Map<String, dynamic>;
        return _buildLibroCard(libro);
      },
    );
  }

  Widget _buildLibroCard(Map<String, dynamic> libro) {
    final titulos = libro['titulos'] as List;
    
    return Card(
      color: tarjetaFondo,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: dorado.withOpacity(0.3)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            'Libro ${libro['numero']}: ${libro['nombre']}',
            style: const TextStyle(
              color: dorado,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          iconColor: dorado,
          collapsedIconColor: dorado,
          children: titulos.map<Widget>((titulo) {
            return _buildTituloItem(titulo as Map<String, dynamic>);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTituloItem(Map<String, dynamic> titulo) {
    final articulos = titulo['articulos'] as List;
    final capitulos = titulo['capitulos'] as List;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: azulMarino,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          'Título ${titulo['numero']}: ${titulo['nombre']}',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        iconColor: dorado,
        collapsedIconColor: Colors.white54,
        children: [
          if (articulos.isNotEmpty)
            ...articulos.map<Widget>((art) {
              final articulo = art as Map<String, dynamic>;
              return _buildArticuloItem(articulo);
            }),
          if (capitulos.isNotEmpty)
            ...capitulos.map<Widget>((cap) {
              final capitulo = cap as Map<String, dynamic>;
              return _buildCapituloItem(capitulo);
            }),
        ],
      ),
    );
  }

  Widget _buildCapituloItem(Map<String, dynamic> capitulo) {
    final articulos = capitulo['articulos'] as List;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        title: Text(
          'Capítulo ${capitulo['numero']}: ${capitulo['nombre']}',
          style: TextStyle(color: dorado.withOpacity(0.8), fontSize: 13),
        ),
        iconColor: dorado,
        collapsedIconColor: Colors.white38,
        children: articulos.map<Widget>((art) {
          final articulo = art as Map<String, dynamic>;
          return _buildArticuloItem(articulo);
        }).toList(),
      ),
    );
  }

  Widget _buildArticuloItem(Map<String, dynamic> articulo) {
    return InkWell(
      onTap: () => _showArticleIA(articulo),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tarjetaFondo.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: dorado,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Art. ${articulo['numero']}',
                style: const TextStyle(
                  color: azulMarino,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                articulo['contenido'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.psychology_outlined, color: dorado, size: 18),
          ],
        ),
      ),
    );
  }

  /// Construye los elementos del chat: mensajes + módulo RAG de
  /// sentencias reales del TSJ relacionadas con el artículo seleccionado.
  List<Widget> _buildChatChildren() {
    final List<Widget> children = [];

    for (var i = 0; i < _messages.length + (_isThinking ? 1 : 0); i++) {
      if (i == _messages.length && _isThinking) {
        children.add(_buildThinkingBubble());
      } else {
        final message = _messages[i];
        children.add(_buildMessageBubble(
          message['content']!,
          message['role']! == 'user',
        ));
      }
    }

    // 🔍 Módulo RAG: sentencias reales del TSJ relacionadas con el artículo
    if (_selectedArticle != null) {
      children.addAll([
        const SizedBox(height: 12),
        Divider(color: dorado.withOpacity(0.3)),
        const SizedBox(height: 4),
        SentenciasRelacionadasWidget(
          contextoLegal: _selectedArticleContenido,
          darkMode: true,
        ),
        const SizedBox(height: 8),
      ]);
    }

    return children;
  }

  Widget _buildAIChatPanel() {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: MediaQuery.of(context).size.width * 0.9,
      child: Container(
        decoration: BoxDecoration(
          color: tarjetaFondo,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(24),
          ),
          border: Border.all(color: dorado.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: azulMarino,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                ),
                border: Border(bottom: BorderSide(color: dorado.withOpacity(0.3))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology, color: dorado, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Asistente Legal IA',
                          style: TextStyle(
                            color: dorado,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Interpretación y ejemplos de artículos',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.white70,
                    onPressed: _toggleAIChat,
                  ),
                ],
              ),
            ),
            
            // Messages + Sentencias relacionadas (RAG)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: _buildChatChildren(),
              ),
            ),
            
            // Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: azulMarino,
                border: Border(top: BorderSide(color: dorado.withOpacity(0.3))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Pregunta sobre un artículo...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: tarjetaFondo,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    backgroundColor: dorado,
                    mini: true,
                    child: const Icon(Icons.send, color: azulMarino),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String message, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isUser ? dorado.withOpacity(0.2) : azulMarino,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUser ? dorado.withOpacity(0.5) : Colors.white24,
          ),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: azulMarino,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: dorado,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Pensando...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
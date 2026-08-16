import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/jurisprudencia.dart';
import '../models/sentencia.dart';
import '../services/jurisprudencia_service.dart';
import '../widgets/app_drawer.dart';

class JurisprudenciaScreen extends StatefulWidget {
  const JurisprudenciaScreen({super.key});

  @override
  State<JurisprudenciaScreen> createState() => _JurisprudenciaScreenState();
}

class _JurisprudenciaScreenState extends State<JurisprudenciaScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  bool _isUsingFirebase = false;
  String? _errorMessage;
  List<Sentencia> _sentencias = [];
  List<Sentencia> _sentenciasFiltradas = [];
  
  String? _salaSeleccionada;
  int _relevanciaMinima = 1;
  
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color fondoGris = Color(0xFFF1F5F9);

  @override
  void initState() {
    super.initState();
    _cargarSentencias();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarSentencias() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<dynamic> jurisprudencias = await JurisprudenciaService.getAll();
      
      setState(() {
        // Convertir dynamic a Sentencia para compatibilidad
        _sentencias = jurisprudencias.map((j) {
          if (j is Jurisprudencia) {
            return Sentencia(
              id: j.id,
              numero: j.numero,
              fecha: j.fecha,
              tribunal: j.tribunal,
              sala: j.tribunal,
              magistradoPonente: j.magistradoPonente,
              delito: j.delito,
              resumen: j.resumen,
              doctrina: j.doctrina,
              articulosCitados: j.articulosCitados,
              relevancia: j.relevancia,
              createdAt: j.createdAt,
              tags: j.tags,
            );
          } else {
            // Si es SentenciaModel de Firebase
            return Sentencia(
              id: j.id ?? '',
              numero: j.numeroSentencia ?? '',
              fecha: DateTime.now(),
              tribunal: j.sala ?? '',
              sala: j.sala ?? '',
              magistradoPonente: j.ponente ?? '',
              delito: j.delito ?? '',
              resumen: j.resumen ?? '',
              doctrina: j.contenidoCompleto ?? '',
              articulosCitados: [],
              relevancia: 3,
              createdAt: DateTime.now(),
              tags: [],
            );
          }
        }).toList();
        _sentenciasFiltradas = _sentencias;
        _isUsingFirebase = _sentencias.isNotEmpty && _sentencias.first.id != '1';
        _isLoading = false;
        if (!_isUsingFirebase) {
          _errorMessage = 'Usando sentencias de ejemplo (Firebase vacío)';
        }
      });
    } catch (e) {
      setState(() {
        _sentencias = Sentencia.getSentenciasEjemplo();
        _sentenciasFiltradas = _sentencias;
        _isUsingFirebase = false;
        _isLoading = false;
        _errorMessage = 'Error de conexión, usando datos locales';
      });
    }
  }

  void _filtrarSentencias() {
    final String query = _searchController.text.toLowerCase();
    
    setState(() {
      _sentenciasFiltradas = _sentencias.where((sentencia) {
        // Filtro de búsqueda
        final bool matchQuery = query.isEmpty ||
            sentencia.numero.toLowerCase().contains(query) ||
            sentencia.delito.toLowerCase().contains(query) ||
            sentencia.magistradoPonente.toLowerCase().contains(query) ||
            sentencia.resumen.toLowerCase().contains(query) ||
            sentencia.tags.any((tag) => tag.toLowerCase().contains(query));
        
        // Filtro de sala
        final bool matchSala = _salaSeleccionada == null ||
            _salaSeleccionada == 'Todas' ||
            sentencia.sala == _salaSeleccionada;
        
        // Filtro de relevancia
        final bool matchRelevancia = sentencia.relevancia >= _relevanciaMinima;
        
        return matchQuery && matchSala && matchRelevancia;
      }).toList();
    });
  }

  void _mostrarDetalleSentencia(Sentencia sentencia) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetallesSentenciaSheet(sentencia: sentencia),
    );
  }

  Widget _buildEstrellas(int relevancia) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < relevancia ? Icons.star : Icons.star_border,
          color: dorado,
          size: 16,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: "/jurisprudencia"),
      appBar: AppBar(
        title: const Text("Jurisprudencia",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: azulMarino,
        foregroundColor: dorado,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Indicador Firebase/Local
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isUsingFirebase
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isUsingFirebase ? Icons.cloud_done : Icons.lightbulb_outline,
                      size: 14,
                      color: _isUsingFirebase ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isUsingFirebase ? 'Firebase' : 'Ejemplo',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _isUsingFirebase ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Filtros
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _mostrarFiltros(),
            tooltip: 'Filtros',
          ),
        ],
      ),
      backgroundColor: fondoGris,
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: dorado),
                  SizedBox(height: 16),
                  Text(
                    'Cargando jurisprudencia...',
                    style: TextStyle(color: azulMarino, fontSize: 16),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Mensaje de advertencia
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.orange, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.orange, fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: Colors.orange, size: 20),
                          onPressed: _cargarSentencias,
                          tooltip: 'Reintentar',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                
                // Barra de búsqueda
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _filtrarSentencias(),
                    decoration: InputDecoration(
                      hintText: 'Buscar por número, delito, magistrado...',
                      prefixIcon: const Icon(Icons.search, color: azulMarino),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: azulMarino.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: dorado, width: 2),
                      ),
                    ),
                  ),
                ),
                
                // Contador de resultados
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_sentenciasFiltradas.length} sentencia${_sentenciasFiltradas.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: azulMarino.withValues(alpha: 0.7),
                        ),
                      ),
                      if (_salaSeleccionada != null || _relevanciaMinima > 1)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _salaSeleccionada = null;
                              _relevanciaMinima = 1;
                            });
                            _filtrarSentencias();
                          },
                          child: const Text('Limpiar filtros'),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Lista de sentencias
                Expanded(
                  child: _sentenciasFiltradas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 64, color: azulMarino.withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              Text(
                                'No se encontraron sentencias',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: azulMarino.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _sentenciasFiltradas.length,
                          itemBuilder: (context, index) {
                            final sentencia = _sentenciasFiltradas[index];
                            return _buildSentenciaCard(sentencia);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSentenciaCard(Sentencia sentencia) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: dorado.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: () => _mostrarDetalleSentencia(sentencia),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Número y estrellas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      sentencia.numero,
                      style: const TextStyle(
                        color: azulMarino,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildEstrellas(sentencia.relevancia),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Delito
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: dorado.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sentencia.delito,
                  style: const TextStyle(
                    color: azulMarino,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Resumen
              Text(
                sentencia.resumen,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Footer: Magistrado y fecha
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      sentencia.magistradoPonente,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(sentencia.fecha),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Tags
              if (sentencia.tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: sentencia.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: azulMarino.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          color: azulMarino.withValues(alpha: 0.8),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: azulMarino,
              ),
            ),
            const SizedBox(height: 24),
            
            // Filtro de sala
            const Text(
              'Sala',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Todas', 'Sala de Casación Penal', 'Sala Constitucional']
                  .map((sala) {
                return ChoiceChip(
                  label: Text(sala),
                  selected: _salaSeleccionada == sala || (sala == 'Todas' && _salaSeleccionada == null),
                  onSelected: (selected) {
                    setState(() {
                      _salaSeleccionada = sala == 'Todas' ? null : sala;
                    });
                    _filtrarSentencias();
                    Navigator.pop(context);
                  },
                  selectedColor: dorado.withValues(alpha: 0.3),
                  labelStyle: TextStyle(
                    color: _salaSeleccionada == sala ? azulMarino : Colors.grey[700],
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Filtro de relevancia
            Text(
              'Relevancia mínima: ${_relevanciaMinima} ${_relevanciaMinima == 1 ? 'estrella' : 'estrellas'}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _relevanciaMinima.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              activeColor: dorado,
              label: _relevanciaMinima.toString(),
              onChanged: (value) {
                setState(() {
                  _relevanciaMinima = value.toInt();
                });
              },
              onChangeEnd: (value) {
                _filtrarSentencias();
              },
            ),
            
            const SizedBox(height: 16),
            
            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _salaSeleccionada = null;
                      _relevanciaMinima = 1;
                    });
                    _filtrarSentencias();
                    Navigator.pop(context);
                  },
                  child: const Text('Limpiar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azulMarino,
                    foregroundColor: dorado,
                  ),
                  child: const Text('Aplicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget de detalles de sentencia
class _DetallesSentenciaSheet extends StatelessWidget {
  final Sentencia sentencia;

  const _DetallesSentenciaSheet({required this.sentencia});

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Contenido
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Número
                      Text(
                        sentencia.numero,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: azulMarino,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Info básica
                      _buildInfoRow(Icons.gavel, 'Delito', sentencia.delito),
                      _buildInfoRow(Icons.person, 'Magistrado Ponente',
                          sentencia.magistradoPonente),
                      _buildInfoRow(Icons.account_balance, 'Tribunal',
                          sentencia.tribunal),
                      _buildInfoRow(Icons.calendar_today, 'Fecha',
                          dateFormat.format(sentencia.fecha)),
                      
                      const Divider(height: 32),
                      
                      // Artículos citados
                      const Text(
                        'Artículos Citados',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: azulMarino,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sentencia.articulosCitados.map((art) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: dorado.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: dorado.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              art,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: azulMarino,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const Divider(height: 32),
                      
                      // Resumen
                      const Text(
                        'Resumen',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: azulMarino,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sentencia.resumen,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.grey[800],
                        ),
                      ),
                      
                      const Divider(height: 32),
                      
                      // Doctrina
                      const Text(
                        'Doctrina',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: azulMarino,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: azulMarino.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: azulMarino.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          sentencia.doctrina,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Tags
                      if (sentencia.tags.isNotEmpty) ...[
                        const Text(
                          'Etiquetas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: azulMarino,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: sentencia.tags.map((tag) {
                            return Chip(
                              label: Text(tag),
                              backgroundColor: azulMarino.withValues(alpha: 0.1),
                              labelStyle: const TextStyle(fontSize: 12),
                            );
                          }).toList(),
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      // Botones
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Compartir sentencia
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Función de compartir próximamente')),
                                );
                              },
                              icon: const Icon(Icons.share),
                              label: const Text('Compartir'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: azulMarino,
                                side: const BorderSide(color: azulMarino),
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                          if (sentencia.urlPDF != null) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // TODO: Abrir PDF
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Abriendo PDF...')),
                                  );
                                },
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('Ver PDF'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: azulMarino,
                                  foregroundColor: dorado,
                                  padding: const EdgeInsets.all(16),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: dorado),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: azulMarino,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/documento_legal.dart';
import '../services/documento_legal_service.dart';
import 'editor_documento_screen.dart';

class MisDocumentosScreen extends StatefulWidget {
  const MisDocumentosScreen({super.key});

  @override
  State<MisDocumentosScreen> createState() => _MisDocumentosScreenState();
}

class _MisDocumentosScreenState extends State<MisDocumentosScreen> {
  TipoDocumento? _filtroTipo;
  EstadoDocumento? _filtroEstado;
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      child: Column(
        children: [
          // Filtros y búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Barra de búsqueda
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar documentos...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFC5A059)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _busqueda = value);
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Filtros
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: _filtroTipo?.nombre ?? 'Tipo',
                        icon: Icons.description,
                        selected: _filtroTipo != null,
                        onTap: () => _mostrarFiltroTipo(),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: _filtroEstado?.nombre ?? 'Estado',
                        icon: Icons.flag,
                        selected: _filtroEstado != null,
                        onTap: () => _mostrarFiltroEstado(),
                      ),
                      const SizedBox(width: 8),
                      if (_filtroTipo != null || _filtroEstado != null)
                        _buildFilterChip(
                          label: 'Limpiar',
                          icon: Icons.clear,
                          selected: false,
                          onTap: () {
                            setState(() {
                              _filtroTipo = null;
                              _filtroEstado = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de documentos
          Expanded(
            child: StreamBuilder<List<DocumentoLegal>>(
              stream: DocumentoLegalService.streamDocumentos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC5A059)),
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                }
                
                List<DocumentoLegal> documentos = snapshot.data ?? [];
                
                // Aplicar filtros
                if (_filtroTipo != null) {
                  documentos = documentos.where((d) => d.tipo == _filtroTipo).toList();
                }
                if (_filtroEstado != null) {
                  documentos = documentos.where((d) => d.estado == _filtroEstado).toList();
                }
                if (_busqueda.isNotEmpty) {
                  documentos = documentos.where((d) =>
                    d.titulo.toLowerCase().contains(_busqueda.toLowerCase()) ||
                    d.contenido.toLowerCase().contains(_busqueda.toLowerCase())
                  ).toList();
                }
                
                if (documentos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay documentos',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea tu primer documento legal',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: documentos.length,
                  itemBuilder: (context, index) {
                    return _buildDocumentoCard(documentos[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentoCard(DocumentoLegal documento) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditorDocumentoScreen(documento: documento),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Icono tipo
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getTipoColor(documento.tipo).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getTipoIcon(documento.tipo),
                        color: _getTipoColor(documento.tipo),
                        size: 24,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Título y tipo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            documento.titulo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            documento.tipo.nombre,
                            style: TextStyle(
                              color: _getTipoColor(documento.tipo),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Badge estado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(documento.estado).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getEstadoColor(documento.estado).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        documento.estado.nombre,
                        style: TextStyle(
                          color: _getEstadoColor(documento.estado),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Contenido preview
                Text(
                  documento.contenido,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Metadatos
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (documento.generadoPorIA)
                      _buildMetaBadge(
                        Icons.auto_awesome,
                        'IA: ${documento.modeloIA}',
                        Colors.purple,
                      ),
                    if (documento.creadoDesdeImagen)
                      _buildMetaBadge(
                        Icons.document_scanner,
                        'Escaneado',
                        Colors.blue,
                      ),
                    if (documento.caso != null)
                      _buildMetaBadge(
                        Icons.gavel,
                        documento.caso!,
                        const Color(0xFFC5A059),
                      ),
                    _buildMetaBadge(
                      Icons.calendar_today,
                      DateFormat('dd/MM/yyyy').format(documento.createdAt),
                      Colors.grey,
                    ),
                  ],
                ),
                
                // Botón eliminar
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red.withValues(alpha: 0.7),
                    onPressed: () => _confirmarEliminar(documento),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected 
              ? const Color(0xFFC5A059).withValues(alpha: 0.2)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected 
                ? const Color(0xFFC5A059)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? const Color(0xFFC5A059) : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFFC5A059) : Colors.white70,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFiltroTipo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Filtrar por tipo',
              style: TextStyle(
                color: Color(0xFFC5A059),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...TipoDocumento.values.map((tipo) {
              return ListTile(
                leading: Icon(
                  _getTipoIcon(tipo),
                  color: _getTipoColor(tipo),
                ),
                title: Text(
                  tipo.nombre,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  setState(() => _filtroTipo = tipo);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _mostrarFiltroEstado() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Filtrar por estado',
              style: TextStyle(
                color: Color(0xFFC5A059),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...EstadoDocumento.values.map((estado) {
              return ListTile(
                leading: Icon(
                  Icons.flag,
                  color: _getEstadoColor(estado),
                ),
                title: Text(
                  estado.nombre,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  setState(() => _filtroEstado = estado);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminar(DocumentoLegal documento) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          '¿Eliminar documento?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Se eliminará "${documento.titulo}" permanentemente.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await DocumentoLegalService.eliminarDocumento(documento.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Documento eliminado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTipoColor(TipoDocumento tipo) {
    switch (tipo) {
      case TipoDocumento.demanda:
        return Colors.red;
      case TipoDocumento.contestacion:
        return Colors.orange;
      case TipoDocumento.recurso:
        return Colors.purple;
      case TipoDocumento.escrito:
        return Colors.blue;
      case TipoDocumento.memorial:
        return Colors.indigo;
      case TipoDocumento.solicitud:
        return Colors.green;
      case TipoDocumento.poder:
        return Colors.teal;
      case TipoDocumento.contrato:
        return Colors.cyan;
      case TipoDocumento.sentencia:
        return const Color(0xFFC5A059);
      case TipoDocumento.auto:
        return Colors.amber;
      case TipoDocumento.providencia:
        return Colors.lime;
      case TipoDocumento.acta:
        return Colors.lightGreen;
      case TipoDocumento.otro:
        return Colors.grey;
    }
  }

  IconData _getTipoIcon(TipoDocumento tipo) {
    switch (tipo) {
      case TipoDocumento.demanda:
        return Icons.gavel;
      case TipoDocumento.contestacion:
        return Icons.reply;
      case TipoDocumento.recurso:
        return Icons.arrow_upward;
      case TipoDocumento.escrito:
        return Icons.description;
      case TipoDocumento.memorial:
        return Icons.article;
      case TipoDocumento.solicitud:
        return Icons.request_page;
      case TipoDocumento.poder:
        return Icons.verified_user;
      case TipoDocumento.contrato:
        return Icons.handshake;
      case TipoDocumento.sentencia:
        return Icons.balance;
      case TipoDocumento.auto:
        return Icons.assignment;
      case TipoDocumento.providencia:
        return Icons.assignment_turned_in;
      case TipoDocumento.acta:
        return Icons.event_note;
      case TipoDocumento.otro:
        return Icons.insert_drive_file;
    }
  }

  Color _getEstadoColor(EstadoDocumento estado) {
    switch (estado) {
      case EstadoDocumento.borrador:
        return Colors.grey;
      case EstadoDocumento.revision:
        return Colors.orange;
      case EstadoDocumento.finalizado:
        return Colors.green;
      case EstadoDocumento.enviado:
        return Colors.blue;
    }
  }
}

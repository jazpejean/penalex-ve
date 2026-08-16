import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LegislationDetailScreen extends StatefulWidget {
  final String legislationId;

  const LegislationDetailScreen({
    super.key,
    required this.legislationId,
  });

  @override
  State<LegislationDetailScreen> createState() => _LegislationDetailScreenState();
}

class _LegislationDetailScreenState extends State<LegislationDetailScreen> {
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color tarjetaFondo = Color(0xFF1E293B);

  bool _isLoading = true;
  Map<String, dynamic>? _legislation;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLegislation();
  }

  Future<void> _loadLegislation() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('legislacion')
          .doc(widget.legislationId)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'Legislación no encontrada';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _legislation = doc.data();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar la legislación: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: azulMarino,
      appBar: AppBar(
        title: const Text('Detalle de Legislación'),
        backgroundColor: azulMarino,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: dorado),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = null;
                            });
                            _loadLegislation();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: dorado,
                            foregroundColor: azulMarino,
                          ),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _legislation == null
                  ? const Center(
                      child: Text(
                        'No hay datos disponibles',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadLegislation,
      color: dorado,
      backgroundColor: tarjetaFondo,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildPublicationCard(),
            const SizedBox(height: 16),
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildDescriptionCard(),
            const SizedBox(height: 16),
            _buildMetadataCard(),
            const SizedBox(height: 16),
            _buildAdditionalInfoCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final String titulo = _legislation?['titulo_oficial'] ?? 'Sin título';
    final String? acronimo = _legislation?['acronimo'];
    final String? tituloCorto = _legislation?['titulo_corto'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            dorado.withOpacity(0.2),
            dorado.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dorado.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (acronimo != null && acronimo.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: dorado,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                acronimo,
                style: const TextStyle(
                  color: azulMarino,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          if (acronimo != null && acronimo.isNotEmpty) const SizedBox(height: 12),
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          if (tituloCorto != null && tituloCorto.isNotEmpty && tituloCorto != titulo) ...[
            const SizedBox(height: 8),
            Text(
              tituloCorto,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final String? tipoInstrumento = _legislation?['tipo_instrumento'];
    final String? numeroLey = _legislation?['numero_ley'];

    return _buildCard(
      title: 'Información General',
      icon: Icons.info_outline,
      children: [
        if (tipoInstrumento != null && tipoInstrumento.isNotEmpty)
          _buildInfoRow('Tipo de Instrumento', tipoInstrumento),
        if (numeroLey != null && numeroLey.isNotEmpty)
          _buildInfoRow('Número de Ley', numeroLey),
      ],
    );
  }

  Widget _buildPublicationCard() {
    final String? fechaPromulgacion = _legislation?['fecha_promulgacion'];
    final String? fechaPublicacion = _legislation?['fecha_publicacion_gaceta'];
    final String? numeroGaceta = _legislation?['numero_gaceta'];
    final String? fechaVigencia = _legislation?['fecha_entrada_vigencia'];

    return _buildCard(
      title: 'Datos de Publicación',
      icon: Icons.calendar_today,
      children: [
        if (fechaPromulgacion != null && fechaPromulgacion.isNotEmpty)
          _buildInfoRow('Fecha de Promulgación', _formatDate(fechaPromulgacion)),
        if (fechaPublicacion != null && fechaPublicacion.isNotEmpty)
          _buildInfoRow('Fecha de Publicación (Gaceta)', _formatDate(fechaPublicacion)),
        if (numeroGaceta != null && numeroGaceta.isNotEmpty)
          _buildInfoRow('Número de Gaceta', numeroGaceta),
        if (fechaVigencia != null && fechaVigencia.isNotEmpty)
          _buildInfoRow('Fecha de Entrada en Vigencia', _formatDate(fechaVigencia)),
      ],
    );
  }

  Widget _buildStatusCard() {
    final String? estado = _legislation?['estado'];
    final String? fechaReforma = _legislation?['fecha_ultima_reforma'];
    final String? gacetaReforma = _legislation?['numero_gaceta_reforma'];
    final String? fechaDerogacion = _legislation?['fecha_derogacion'];
    final String? derogadaPor = _legislation?['derogada_por'];

    final bool hasContent = (estado != null && estado.isNotEmpty) ||
        (fechaReforma != null && fechaReforma.isNotEmpty) ||
        (gacetaReforma != null && gacetaReforma.isNotEmpty) ||
        (fechaDerogacion != null && fechaDerogacion.isNotEmpty) ||
        (derogadaPor != null && derogadaPor.isNotEmpty);

    if (!hasContent) return const SizedBox.shrink();

    Color statusColor = Colors.green;
    if (estado == 'DEROGADO' || estado == 'DEROGADA') {
      statusColor = Colors.red;
    } else if (estado == 'REFORMADO' || estado == 'REFORMADA') {
      statusColor = Colors.orange;
    }

    return _buildCard(
      title: 'Estado y Reformas',
      icon: Icons.update,
      children: [
        if (estado != null && estado.isNotEmpty)
          _buildStatusBadge(estado, statusColor),
        if (fechaReforma != null && fechaReforma.isNotEmpty)
          _buildInfoRow('Fecha de Última Reforma', _formatDate(fechaReforma)),
        if (gacetaReforma != null && gacetaReforma.isNotEmpty)
          _buildInfoRow('Gaceta de Reforma', gacetaReforma),
        if (fechaDerogacion != null && fechaDerogacion.isNotEmpty)
          _buildInfoRow('Fecha de Derogación', _formatDate(fechaDerogacion)),
        if (derogadaPor != null && derogadaPor.isNotEmpty)
          _buildInfoRow('Derogada Por', derogadaPor),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    final String? descripcion = _legislation?['descripcion'];
    final String? objetoLey = _legislation?['objeto_ley'];
    final String? materiaRegulada = _legislation?['materia_regulada'];

    return _buildCard(
      title: 'Descripción',
      icon: Icons.description,
      children: [
        if (descripcion != null && descripcion.isNotEmpty)
          _buildTextSection('Descripción General', descripcion),
        if (objetoLey != null && objetoLey.isNotEmpty)
          _buildTextSection('Objeto de la Ley', objetoLey),
        if (materiaRegulada != null && materiaRegulada.isNotEmpty)
          _buildTextSection('Materia Regulada', materiaRegulada),
      ],
    );
  }

  Widget _buildMetadataCard() {
    final String? autoridad = _legislation?['autoridad_emisora'];
    final String? rango = _legislation?['rango_legal'];
    final String? ambito = _legislation?['ambito_aplicacion'];

    final bool hasContent = (autoridad != null && autoridad.isNotEmpty) ||
        (rango != null && rango.isNotEmpty) ||
        (ambito != null && ambito.isNotEmpty);

    if (!hasContent) return const SizedBox.shrink();

    return _buildCard(
      title: 'Información Legal',
      icon: Icons.gavel,
      children: [
        if (autoridad != null && autoridad.isNotEmpty)
          _buildInfoRow('Autoridad Emisora', autoridad),
        if (rango != null && rango.isNotEmpty)
          _buildInfoRow('Rango Legal', rango),
        if (ambito != null && ambito.isNotEmpty)
          _buildInfoRow('Ámbito de Aplicación', ambito),
      ],
    );
  }

  Widget _buildAdditionalInfoCard() {
    final String? tags = _legislation?['tags'];
    final String? urlOficial = _legislation?['url_oficial'];
    final String? urlPdf = _legislation?['url_pdf'];
    final String? observaciones = _legislation?['observaciones'];

    final bool hasContent = (tags != null && tags.isNotEmpty) ||
        (urlOficial != null && urlOficial.isNotEmpty) ||
        (urlPdf != null && urlPdf.isNotEmpty) ||
        (observaciones != null && observaciones.isNotEmpty);

    if (!hasContent) return const SizedBox.shrink();

    return _buildCard(
      title: 'Información Adicional',
      icon: Icons.more_horiz,
      children: [
        if (tags != null && tags.isNotEmpty) _buildTagsSection(tags),
        if (urlOficial != null && urlOficial.isNotEmpty)
          _buildLinkRow('URL Oficial', urlOficial, Icons.link),
        if (urlPdf != null && urlPdf.isNotEmpty)
          _buildLinkRow('Documento PDF', urlPdf, Icons.picture_as_pdf),
        if (observaciones != null && observaciones.isNotEmpty)
          _buildTextSection('Observaciones', observaciones),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: tarjetaFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dorado.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: dorado, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: dorado,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSection(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              color: color,
              size: 12,
            ),
            const SizedBox(width: 8),
            Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection(String tagsString) {
    final tags = tagsString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Etiquetas',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: azulMarino,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: dorado.withOpacity(0.3)),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: dorado.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkRow(String label, String url, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Open URL in browser
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Abrir: $url'),
              backgroundColor: tarjetaFondo,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: azulMarino,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: dorado.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: dorado, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      url,
                      style: const TextStyle(
                        color: dorado,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, color: dorado, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
        'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
      ];
      return '${date.day} de ${months[date.month - 1]} de ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

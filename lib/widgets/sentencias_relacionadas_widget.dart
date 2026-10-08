/// Widget de "Sentencias Relacionadas" para la pantalla de detalle de leyes.
///
/// Usa RAG ([RAGService]) para recuperar jurisprudencia REAL del TSJ desde
/// Supabase según el texto de la ley (o el artículo consultado), mostrando
/// hasta 3 sentencias como tarjetas clicables que abren [DetalleSentenciaScreen].
library;

import 'package:flutter/material.dart';

import '../models/sentencia_model.dart';
import '../pages/repositorio_jurisprudencia_screen.dart';
import '../services/rag_service.dart';

class SentenciasRelacionadasWidget extends StatefulWidget {
  /// Texto (ley/artículo) que se usa como consulta para recuperar sentencias.
  final String contextoLegal;

  /// Si `true`, usa estilos para fondos oscuros (chat IA de leyes).
  final bool darkMode;

  const SentenciasRelacionadasWidget({
    super.key,
    required this.contextoLegal,
    this.darkMode = false,
  });

  @override
  State<SentenciasRelacionadasWidget> createState() =>
      _SentenciasRelacionadasWidgetState();
}

class _SentenciasRelacionadasWidgetState
    extends State<SentenciasRelacionadasWidget> {
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);

  List<SentenciaModel> _sentencias = [];
  bool _cargando = false;
  bool _cargado = false;

  Future<void> _buscarRelacionadas() async {
    if (widget.contextoLegal.trim().isEmpty) return;

    setState(() {
      _cargando = true;
      _cargado = false;
    });

    try {
      final sentencias = await RAGService.buscarJurisprudenciaRelevante(
        consulta: widget.contextoLegal.trim(),
        limit: 3,
      );

      if (mounted) {
        setState(() {
          _sentencias = sentencias;
          _cargando = false;
          _cargado = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Error buscando sentencias relacionadas: $e');
      if (mounted) {
        setState(() {
          _cargando = false;
          _cargado = true;
          _sentencias = [];
        });
      }
    }
  }

  void _verDetalle(SentenciaModel sentencia) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleSentenciaScreen(sentencia: sentencia),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: dorado.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.account_balance, color: dorado, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '⚖️ Sentencias relacionadas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.darkMode ? Colors.white : azulMarino,
                ),
              ),
            ),
            // Botón para buscar / actualizar
            if (!_cargando)
              TextButton.icon(
                onPressed: _buscarRelacionadas,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Buscar'),
                style: TextButton.styleFrom(
                  foregroundColor: widget.darkMode ? dorado : azulMarino,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Estado
        if (_cargando)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: dorado,
                      strokeWidth: 2.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Buscando jurisprudencia del TSJ...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else if (!_cargado)
          // Estado inicial: sugerencia
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.darkMode
                  ? Colors.white.withValues(alpha: 0.06)
                  : azulMarino.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.darkMode
                    ? dorado.withValues(alpha: 0.3)
                    : azulMarino.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 20,
                  color: widget.darkMode ? dorado : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Busca sentencias reales del TSJ relacionadas con ${widget.contextoLegal.trim().isEmpty ? 'esta ley' : 'este artículo'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.darkMode ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (_sentencias.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: widget.darkMode ? Colors.white54 : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No se encontraron sentencias relacionadas. Prueba con otra sección del artículo.',
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.darkMode ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: _sentencias.map((s) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildSentenciaCard(s),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSentenciaCard(SentenciaModel sentencia) {
    final bool oscuro = widget.darkMode;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: oscuro ? const Color(0xFF111827) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: oscuro
              ? dorado.withValues(alpha: 0.35)
              : azulMarino.withValues(alpha: 0.12),
        ),
      ),
      child: InkWell(
        onTap: () => _verDetalle(sentencia),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: azulMarino,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sentencia.sala,
                      style: const TextStyle(
                        color: dorado,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nº ${sentencia.numeroSentencia}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: oscuro ? Colors.white : azulMarino,
                      ),
                    ),
                  ),
                  if (sentencia.fechaSentencia.isNotEmpty &&
                      sentencia.fechaSentencia != 'null')
                    Text(
                      sentencia.fechaSentencia,
                      style: TextStyle(
                        color: oscuro ? Colors.white54 : Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              if (sentencia.delito.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.gavel,
                      size: 14,
                      color: oscuro ? dorado : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        sentencia.delito,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: oscuro ? Colors.white : const Color(0xFF334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (sentencia.resumen.isNotEmpty &&
                  sentencia.resumen != 'null') ...[
                const SizedBox(height: 8),
                Text(
                  sentencia.resumen,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: oscuro ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Ver detalles →',
                  style: TextStyle(
                    color: oscuro ? dorado : azulMarino,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../services/leyes_repositorio_service.dart';
import 'tabla_anexo.dart';

/// Muestra un artículo en una ventana flotante (bottom sheet), sin salir de la
/// pantalla actual. Reutilizable desde la calculadora, el chat, etc.
Future<void> mostrarArticuloLey(
  BuildContext context,
  ResultadoLey resultado,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ArticuloLeySheet(resultado: resultado),
  );
}

class _ArticuloLeySheet extends StatelessWidget {
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color grisOscuro = Color(0xFF1E293B);

  final ResultadoLey resultado;

  const _ArticuloLeySheet({required this.resultado});

  @override
  Widget build(BuildContext context) {
    final reg = resultado.registro;
    final esArticulo = reg.tipoNorma == 'Artículo';
    final titulo = esArticulo ? 'Artículo ${reg.identificador}' : reg.tipoNorma;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: grisOscuro,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: dorado,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      color: azulMarino,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    reg.leyNombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (reg.titulo != null && reg.titulo!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        reg.titulo!,
                        style: TextStyle(
                          color: dorado.withOpacity(0.8),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  if (reg.encabezado != null && reg.encabezado!.isNotEmpty)
                    Text(
                      reg.encabezado!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    reg.texto,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  if (reg.numeralesLiterales.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _subtitulo('Numerales'),
                    ...reg.numeralesLiterales.map((n) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            n,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        )),
                  ],
                  if (reg.tablas.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ...reg.tablas.map((t) => TablaAnexoView(tabla: t)),
                  ],
                  if (reg.paragrafos.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _subtitulo('Parágrafos'),
                    ...reg.paragrafos.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            p,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subtitulo(String texto) => Text(
        texto,
        style: const TextStyle(
          color: Color(0xFFC5A059),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
}

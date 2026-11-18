import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/expediente.dart';
import '../providers/expediente_activo_provider.dart';

/// Selector de expediente reutilizable ("case-first").
///
/// Se muestra al abrir cualquier herramienta (detector de vicios, redactor,
/// escáner, chat) para que el abogado trabaje SIEMPRE sobre un expediente:
/// - Seleccionar una causa existente
/// - Crear un expediente nuevo
/// - Continuar en "consulta aislada" (sin contexto de causa)
///
/// Uso:
/// ```dart
/// final exp = await SelectorExpedienteSheet.mostrar(context);
/// if (exp != null) { ... }
/// ```
class SelectorExpedienteSheet extends StatefulWidget {
  /// Si es true, permite elegir "consulta aislada" como opción explícita.
  final bool permitirAislada;

  const SelectorExpedienteSheet({super.key, this.permitirAislada = true});

  /// Abre el selector y devuelve el expediente elegido (o null si aislada).
  static Future<Expediente?> mostrar(
    BuildContext context, {
    bool permitirAislada = true,
  }) {
    return showModalBottomSheet<Expediente?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TemaGlobal.tarjeta,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SelectorExpedienteSheet(permitirAislada: permitirAislada),
    );
  }

  @override
  State<SelectorExpedienteSheet> createState() => _SelectorExpedienteSheetState();
}

class _SelectorExpedienteSheetState extends State<SelectorExpedienteSheet> {
  final _busqueda = TextEditingController();
  bool _cargado = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final prov = context.read<ExpedienteActivoProvider>();
    await prov.cargarExpedientes();
    if (mounted) setState(() => _cargado = true);
  }

  Future<void> _nuevoExpediente() async {
    final numero = TextEditingController();
    final imputado = TextEditingController();
    final delitos = TextEditingController();
    final creado = await showDialog<Expediente?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TemaGlobal.tarjeta,
        title: Text('Nuevo expediente', style: TextStyle(color: TemaGlobal.texto)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numero,
                autofocus: true,
                style: TextStyle(color: TemaGlobal.texto),
                decoration: const InputDecoration(
                  labelText: 'Número de expediente *',
                  hintText: 'Ej.: 1U-1337-26',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: imputado,
                style: TextStyle(color: TemaGlobal.texto),
                decoration: const InputDecoration(
                  labelText: 'Imputado *',
                  hintText: 'Nombre y apellido',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: delitos,
                style: TextStyle(color: TemaGlobal.texto),
                decoration: const InputDecoration(
                  labelText: 'Delitos (opcional)',
                  hintText: 'Ej.: Homicidio intencional',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (numero.text.trim().isEmpty || imputado.text.trim().isEmpty) {
                return;
              }
              final p = context.read<ExpedienteActivoProvider>();
              final e = await p.crearYNuevo(
                numeroExpediente: numero.text.trim(),
                imputado: imputado.text.trim(),
                delitos: delitos.text.trim().isEmpty ? null : delitos.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx, e);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (creado != null) {
      Navigator.pop(context, creado);
    }
  }

  void _aislada() {
    context.read<ExpedienteActivoProvider>().limpiar();
    Navigator.pop(context, null);
  }

  void _elegir(Expediente e) {
    context.read<ExpedienteActivoProvider>().seleccionar(e);
    Navigator.pop(context, e);
  }

  List<Expediente> _filtrados(List<Expediente> todos) {
    final q = _busqueda.text.trim().toLowerCase();
    if (q.isEmpty) return todos;
    return todos
        .where((e) =>
            e.numeroExpediente.toLowerCase().contains(q) ||
            e.imputado.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExpedienteActivoProvider>();
    final lista = _filtrados(prov.expedientes);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabecera
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_special,
                      color: TemaGlobal.isDark
                          ? TemaGlobal.dorado
                          : TemaGlobal.azulMarino,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¿En qué expediente trabajas?',
                            style: TextStyle(
                              color: TemaGlobal.texto,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'La IA recibirá el contexto de la causa',
                            style: TextStyle(
                              color: TemaGlobal.textoTenue,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Buscador
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _busqueda,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: TemaGlobal.texto, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Buscar por número o imputado…',
                    hintStyle:
                        TextStyle(color: TemaGlobal.textoTenue, fontSize: 12.5),
                    prefixIcon: Icon(Icons.search,
                        size: 18, color: TemaGlobal.textoTenue),
                    isDense: true,
                    filled: true,
                    fillColor: TemaGlobal.campoTexto,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: TemaGlobal.textoTenue.withValues(alpha: 0.25),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: TemaGlobal.textoTenue.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Lista
              Flexible(
                child: !_cargado
                    ? const Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(),
                      )
                    : lista.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(26),
                            child: Text(
                              prov.expedientes.isEmpty
                                  ? 'Aún no tienes expedientes. Crea el primero al agendar una audiencia o aquí abajo.'
                                  : 'Sin resultados para la búsqueda.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: TemaGlobal.textoTenue,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: lista.length,
                            itemBuilder: (context, i) {
                              final e = lista[i];
                              final activo = prov.expediente?.id == e.id;
                              return ListTile(
                                onTap: () => _elegir(e),
                                leading: Icon(
                                  activo ? Icons.check_circle : Icons.folder_open,
                                  color: activo
                                      ? (TemaGlobal.isDark
                                          ? TemaGlobal.dorado
                                          : TemaGlobal.azulMarino)
                                      : TemaGlobal.textoTenue,
                                  size: 22,
                                ),
                                title: Text(
                                  e.numeroExpediente,
                                  style: TextStyle(
                                    color: TemaGlobal.texto,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  [
                                    e.imputado,
                                    if (e.delitos != null && e.delitos!.isNotEmpty)
                                      e.delitos!,
                                    if (e.tribunalNombre != null)
                                      e.tribunalNombre!,
                                  ].join(' · '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: TemaGlobal.textoSecundario,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: TemaGlobal.textoTenue,
                                  size: 20,
                                ),
                              );
                            },
                          ),
              ),
              // Acciones
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _nuevoExpediente,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Nuevo expediente'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TemaGlobal.isDark
                              ? TemaGlobal.dorado
                              : TemaGlobal.azulMarino,
                          side: BorderSide(
                            color: (TemaGlobal.isDark
                                    ? TemaGlobal.dorado
                                    : TemaGlobal.azulMarino)
                                .withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    if (widget.permitirAislada) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _aislada,
                          icon: const Icon(Icons.person_search, size: 18),
                          label: const Text('Consulta aislada'),
                          style: TextButton.styleFrom(
                            foregroundColor: TemaGlobal.textoSecundario,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

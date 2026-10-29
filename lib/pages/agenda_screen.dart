import 'dart:async';
import '../services/haptics_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';

import '../config/app_colors.dart';
import '../models/audiencia.dart';
import '../config/app_theme.dart';
import '../services/agenda_service.dart';
import '../services/non_working_day_service.dart';
import '../services/notification_service.dart';
import '../services/tribunales_service.dart';
import '../utils/date_utils.dart';
import '../utils/non_working_days.dart';
import 'calendario_judicial_screen.dart';
import 'tribunal_detail_screen.dart';
import '../widgets/app_snackbar.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Audiencia>> _audienciasPorDia = <DateTime, List<Audiencia>>{};
  List<Audiencia> _audienciasDelDia = <Audiencia>[];
  List<NonWorkingDay> _userNonWorkingDays = <NonWorkingDay>[];
  bool _isLoading = false;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    unawaited(_cargarAudiencias());
    unawaited(_loadNonWorkingDays());
  }

  Future<void> _loadNonWorkingDays() async {
    setState(() => _isLoading = true);
    try {
      final List<NonWorkingDay> loadedDays =
          await NonWorkingDayService.loadUserNonWorkingDays()
              .timeout(const Duration(seconds: 4));
      setState(() {
        _userNonWorkingDays = loadedDays;
      });
    } catch (e) {
      debugPrint('⚠️ Error cargando días sin despacho: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  DateTime _normalizeDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<void> _cargarAudiencias() async {
    setState(() => _isLoading = true);
    try {
      final List<Audiencia> audiencias =
          await AgendaService.cargarAudiencias(_focusedDay)
              .timeout(const Duration(seconds: 4));
      final Map<DateTime, List<Audiencia>> tempMap =
          <DateTime, List<Audiencia>>{};
      for (final Audiencia aud in audiencias) {
        final DateTime fechaSinHora = _normalizeDay(aud.fecha);
        tempMap.putIfAbsent(fechaSinHora, () => <Audiencia>[]);
        tempMap[fechaSinHora]!.add(aud);
      }
      setState(() {
        _audienciasPorDia = tempMap;
        _audienciasDelDia =
            _audienciasPorDia[_normalizeDay(_selectedDay!)] ?? <Audiencia>[];
      });
    } catch (e) {
      debugPrint('⚠️ Error cargando audiencias: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarAudiencia(Audiencia audiencia) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Eliminar audiencia'),
        content: Text(
            '¿Estás seguro de que deseas eliminar la audiencia con expediente "${audiencia.expediente}"?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    Haptics.heavy();
    setState(() => _isLoading = true);
    final bool exito = await AgendaService.eliminarAudiencia(audiencia.id);
    if (exito) {
      await _cargarAudiencias();
      if (mounted) {
        AppSnackBar.success(context, 'Audiencia eliminada');
      }
    } else {
      if (mounted) {
        AppSnackBar.error(context, 'Error al eliminar la audiencia');
      }
    }
    setState(() => _isLoading = false);
  }

  void _mostrarFormularioNuevaAudiencia() {
    final TextEditingController expedienteCtrl = TextEditingController();
    final TextEditingController tribunalCtrl = TextEditingController();
    final TextEditingController imputadoCtrl = TextEditingController();
    final TextEditingController cedulaCtrl = TextEditingController();
    final TextEditingController fiscaliaCtrl = TextEditingController();
    final TextEditingController delitosCtrl = TextEditingController();
    final TextEditingController fechaCtrl = TextEditingController();
    final TextEditingController horaCtrl = TextEditingController();
    final TextEditingController tipoCtrl = TextEditingController();
    final TextEditingController notasCtrl = TextEditingController();
    // Tribunal del catálogo seleccionado (se guarda como tribunal_id).
    Tribunal? tribunalSel;

    if (_selectedDay != null) {
      fechaCtrl.text =
          "${_selectedDay!.day.toString().padLeft(2, '0')}/${_selectedDay!.month.toString().padLeft(2, '0')}/${_selectedDay!.year}";
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TemaGlobal.dorado.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.gavel, color: AppColors.acento, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Nueva Audiencia',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.95,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildModernField(expedienteCtrl, 'Expediente', Icons.folder_open, esObligatorio: true),
                _buildModernField(imputadoCtrl, 'Imputado / Acusado', Icons.person, esObligatorio: true),
                _buildModernField(cedulaCtrl, 'Cédula de Identidad', Icons.badge_outlined, numeric: true),
                _buildModernField(fechaCtrl, 'Fecha de Audiencia (DD/MM/AAAA)', Icons.calendar_today, isDate: true, hint: 'Ej: 24/12/2026', esObligatorio: true),
                _buildModernField(horaCtrl, 'Hora (HH:MM)', Icons.access_time, isTime: true, hint: 'Ej: 0230 (Aplica PM automáticamente)', esObligatorio: true),
                _buildModernField(tribunalCtrl, 'Tribunal competente', Icons.account_balance,
                    onTap: () async {
                      final Tribunal? elegido = await _seleccionarTribunal(
                          context, tribunalCtrl.text);
                      if (elegido != null && context.mounted) {
                        tribunalSel = elegido;
                        tribunalCtrl.text = elegido.nombreLimpio;
                      }
                    }),
                _buildModernField(fiscaliaCtrl, 'Fiscalía', Icons.shield),
                _buildModernField(delitosCtrl, 'Delitos imputados', Icons.gavel, maxLines: 2),
                _buildModernField(tipoCtrl, 'Tipo de Audiencia', Icons.merge_type),
                _buildModernField(notasCtrl, 'Notas adicionales', Icons.note_alt_outlined, maxLines: 2),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: TemaGlobal.textoSecundario,
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulMarino,
              foregroundColor: AppColors.onAzulMarino,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Haptics.light();
              if (expedienteCtrl.text.isEmpty || imputadoCtrl.text.isEmpty || fechaCtrl.text.isEmpty || horaCtrl.text.isEmpty) {
                Haptics.error();
                AppSnackBar.error(context, 'Expediente, Imputado, Fecha y Hora son obligatorios');
                return;
              }
              final DateTime? fecha = parseFecha(fechaCtrl.text);
              if (fecha == null) {
                AppSnackBar.error(context, 'Fecha inválida. Use DD/MM/AAAA');
                return;
              }
              final Audiencia nueva = Audiencia(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                expediente: expedienteCtrl.text,
                tribunal: tribunalCtrl.text.isNotEmpty ? tribunalCtrl.text : null,
                tribunalId: tribunalSel?.id,
                imputado: imputadoCtrl.text,
                cedula: cedulaCtrl.text.isNotEmpty ? cedulaCtrl.text : null,
                fiscalia: fiscaliaCtrl.text.isNotEmpty ? fiscaliaCtrl.text : null,
                delitos: delitosCtrl.text.isNotEmpty ? delitosCtrl.text : null,
                fecha: fecha,
                hora: horaCtrl.text,
                tipo: tipoCtrl.text.isNotEmpty ? tipoCtrl.text : null,
                notas: notasCtrl.text.isNotEmpty ? notasCtrl.text : null,
              );
              final bool exito = await AgendaService.crearAudiencia(nueva);
              if (exito) {
                final TimeOfDay? horaAudiencia = parseHora(horaCtrl.text);
                if (horaAudiencia != null) {
                  final DateTime fechaHoraAudiencia = DateTime(
                    fecha.year,
                    fecha.month,
                    fecha.day,
                    horaAudiencia.hour,
                    horaAudiencia.minute,
                  );
                  final DateTime fechaHoraNotificacion = fechaHoraAudiencia.subtract(const Duration(hours: 1));
                  if (fechaHoraNotificacion.isAfter(DateTime.now())) {
                    unawaited(_notificationService.scheduleAudienceReminder(
                      audienceId: nueva.id,
                      title: 'Audiencia: ${nueva.expediente} - ${nueva.imputado}',
                      dateTime: fechaHoraNotificacion,
                    ));
                  }
                }
                if (context.mounted) Navigator.pop(context);
                unawaited(_cargarAudiencias());
              } else {
                if (context.mounted) {
                  AppSnackBar.error(context, 'Error al guardar la audiencia');
                }
              }
            },
            label: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  /// Abre la ficha del tribunal (foto, mapa, ruta) desde una audiencia.
  void _abrirTribunal(String tribunalId) async {
    final List<Tribunal> todos = await TribunalesService.listar();
    final Tribunal t = todos.firstWhere(
      (x) => x.id == tribunalId,
      orElse: () => Tribunal(
        id: tribunalId,
        codigo: '',
        nombre: tribunalId,
        estado: '',
        instancia: '',
        despacho: '',
      ),
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TribunalDetailScreen(tribunal: t),
      ),
    );
  }

  /// Abre los LAPSOS del expediente agendado: línea de tiempo guiada
  /// Abre el Workspace del Expediente (portafolio de la causa).
  void _abrirExpediente(Audiencia aud) {
    Haptics.tap();
    Navigator.of(context).pushNamed('/expediente', arguments: aud);
  }

  /// Abre el Calendario Judicial de lapsos del expediente (se calcula
  /// desde la fecha de la audiencia (la presentación es la primera que
  /// se agenda). El motor calcula vencimientos/hitos según la vía.
  void _abrirLapsosExpediente(Audiencia aud) {
    Haptics.tap();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CalendarioJudicialScreen(
          expediente: aud.expediente,
          imputado: aud.imputado,
          fechaBase: aud.fecha,
          tribunalId: aud.tribunalId,
        ),
      ),
    );
  }

  /// Selector de tribunal (catálogo oficial de tribunales penales).
  /// La búsqueda es por TEXTO local sobre el catálogo completo: lista
  /// TODOS los tribunales que coinciden (buscar "Los Teques" muestra los
  /// ~20 de esa sede). La semántica (pgvector) solo se usa como refuerzo
  /// cuando el texto no encuentra nada.
  Future<Tribunal?> _seleccionarTribunal(
      BuildContext context, String inicial) async {
    final TextEditingController buscadorCtrl =
        TextEditingController(text: inicial);
    List<Tribunal> resultados = <Tribunal>[];
    bool buscando = true;
    bool cacheLista = false;
    String? filtroEstado; // null = todos los estados

    // Asegura el catálogo en caché (una sola carga; luego filtro local).
    Future<void> asegurarCache() async {
      if (cacheLista) return;
      await TribunalesService.listar();
      cacheLista = true;
    }

    // La caché del catálogo debe estar lista ANTES del primer filtro por
    // texto; si no, el filtro local no encuentra nada y se cae a la
    // semántica (que devuelve solo 1-2 resultados "relevantes").
    await asegurarCache();

    Future<void> buscar() async {
      final q = buscadorCtrl.text.trim();
      if (q.isEmpty) {
        // Sin texto: mostrar el catálogo completo (directorio), no un
        // spinner infinito.
        final todos = TribunalesService.listarEnCache();
        resultados = todos == null ? <Tribunal>[] : List.of(todos);
        buscando = false;
        return;
      }
      buscando = true;
      // 1) Filtro local por texto: TODOS los que coinciden.
      final locales = TribunalesService.filtrarPorTexto(q);
      if (locales.isNotEmpty) {
        resultados = locales;
        buscando = false;
        return;
      }
      // 2) Refuerzo semántico solo si el texto no dio coincidencias.
      final sem = await TribunalesService.buscarSemantico(q, limite: 20);
      if (sem == null || sem.isEmpty) {
        resultados = sem ?? <Tribunal>[];
        buscando = false;
        return;
      }
      const umbral = 0.52;
      final relevantes = sem
          .where((t) => t.distancia != null && t.distancia! < umbral)
          .toList();
      resultados = relevantes.isNotEmpty ? relevantes : sem;
      buscando = false;
    }

    // Lista de estados disponibles (para el filtro desplegable).
    final todosEstados = <String>{
      ...?TribunalesService.listarEnCache()?.map((t) => t.estado),
    }.toList()..sort();

    await buscar();

    return showDialog<Tribunal>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TemaGlobal.dorado.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.account_balance,
                  color: AppColors.acento, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Buscar tribunal',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          width: MediaQuery.of(dialogContext).size.width * 0.92,
          height: 460,
          child: Column(
            children: <Widget>[
              TextField(
                controller: buscadorCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Ej: Los Teques, juicio de Maracaibo...',
                  prefixIcon: Icon(Icons.search,
                      color: TemaGlobal.textoSecundario),
                  filled: true,
                  fillColor: TemaGlobal.superficie,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
                onChanged: (_) => buscar(),
              ),
              const SizedBox(height: 10),
              // Filtro por estado / circunscripción judicial.
              DropdownButtonFormField<String>(
                initialValue: filtroEstado,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Estado (circunscripción judicial)',
                  prefixIcon: Icon(Icons.public,
                      color: TemaGlobal.textoSecundario, size: 20),
                  filled: true,
                  fillColor: TemaGlobal.superficie,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                items: <DropdownMenuItem<String>>[
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Todos los estados'),
                  ),
                  ...todosEstados.map((e) => DropdownMenuItem<String>(
                        value: e,
                        child: Text(e, overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (v) {
                  filtroEstado = v;
                  buscar();
                },
              ),
              const SizedBox(height: 10),
              Expanded(
                child: buscando
                    ? const Center(child: CircularProgressIndicator())
                    : resultados.isEmpty
                        ? Center(
                            child: Text(
                              'No se encontraron tribunales con esos criterios',
                              style: TextStyle(color: TemaGlobal.textoTenue),
                              textAlign: TextAlign.center,
                            ))
                        : _listaTribunalesAgrupada(
                            dialogContext, resultados, filtroEstado),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  /// Lista de tribunales agrupada por estado y circunscripción judicial.
  /// Lista de tribunales clasificada por ESTADO y CIRCUNSCRIPCIÓN JUDICIAL:
  /// sin filtro se agrupa en dos niveles (estado → circuito judicial → lista);
  /// con [filtroEstado] se muestran solo los de ese estado, con un
  /// encabezado por circuito (ej. "CIRCUITO JUDICIAL PENAL DEL ESTADO ...").
  Widget _listaTribunalesAgrupada(BuildContext dialogContext,
      List<Tribunal> lista, String? filtroEstado) {
    final filas = <Widget>[];
    // Primer nivel: estado.
    final porEstado = <String, List<Tribunal>>{};
    for (final t in lista) {
      if (filtroEstado != null && t.estado != filtroEstado) continue;
      porEstado.putIfAbsent(t.estado, () => <Tribunal>[]).add(t);
    }
    final estados = porEstado.keys.toList()..sort();
    for (final estado in estados) {
      final tribunalesEstado = porEstado[estado]!;
      if (filtroEstado == null) {
        filas.add(_encabezadoGrupo(estado, tribunalesEstado.length, nivel: 0));
      }
      // Segundo nivel: circunscripción judicial (circuito).
      final porCircuito = <String, List<Tribunal>>{};
      for (final t in tribunalesEstado) {
        porCircuito
            .putIfAbsent(t.circunscripcionJudicial, () => <Tribunal>[])
            .add(t);
      }
      final circuitos = porCircuito.keys.toList()..sort();
      for (final circuito in circuitos) {
        final tribunales = porCircuito[circuito]!..sort((a, b) {
          final f = a.etiquetaFuncion.compareTo(b.etiquetaFuncion);
          if (f != 0) return f;
          return a.nombreLimpio.compareTo(b.nombreLimpio);
        });
        if (filtroEstado != null || circuitos.length > 1) {
          filas.add(
              _encabezadoGrupo(circuito, tribunales.length, nivel: 1));
        }
        for (final t in tribunales) {
          filas.add(ListTile(
            dense: true,
            title: Text(t.nombreLimpio,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${t.etiquetaFuncion}${t.municipio != null ? ' · ${t.municipio}' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5),
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => Navigator.pop(dialogContext, t),
          ));
        }
      }
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: filas,
    );
  }

  Widget _encabezadoGrupo(String titulo, int cantidad, {int nivel = 0}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, nivel == 0 ? 12 : 8, 4, 4),
      child: Row(
        children: <Widget>[
          Container(
            width: 3,
            height: nivel == 0 ? 18 : 14,
            decoration: BoxDecoration(
              color: nivel == 0
                  ? AppColors.acento
                  : AppColors.acento.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: nivel == 0 ? 13 : 12,
                  color: TemaGlobal.textoSecundario),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$cantidad',
            style: TextStyle(
                fontSize: 11.5,
                color: TemaGlobal.textoTenue,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _mostrarFormularioNuevoDiaSinDespacho() {
    final TextEditingController fechaCtrl = TextEditingController();
    final TextEditingController motivoCtrl = TextEditingController();
    final TextEditingController tribunalCtrl = TextEditingController();
    // Tribunal del catálogo asociado (opcional; null = toda la agenda).
    Tribunal? tribunalSel;

    if (_selectedDay != null) {
      fechaCtrl.text =
          "${_selectedDay!.day.toString().padLeft(2, '0')}/${_selectedDay!.month.toString().padLeft(2, '0')}/${_selectedDay!.year}";
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TemaGlobal.dorado.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.block, color: AppColors.acento, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Nuevo día sin despacho',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.95,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildModernField(fechaCtrl, 'Fecha (DD/MM/AAAA)', Icons.calendar_today, isDate: true, hint: 'Ej: 24/12/2026', esObligatorio: true),
                _buildModernField(motivoCtrl, 'Motivo', Icons.description, maxLines: 2, hint: 'Ej: falla eléctrica, salud, etc.', esObligatorio: true),
                _buildModernField(tribunalCtrl, 'Tribunal (opcional)', Icons.account_balance,
                    onTap: () async {
                      final Tribunal? elegido = await _seleccionarTribunal(
                          context, tribunalCtrl.text);
                      if (elegido != null && context.mounted) {
                        tribunalSel = elegido;
                        tribunalCtrl.text = elegido.nombreLimpio;
                      }
                    }),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sin tribunal: aplica a toda la agenda personal. Con tribunal: solo excluye los lapsos de ese tribunal.',
                          style: TextStyle(fontSize: 12, color: TemaGlobal.textoSecundario, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: TemaGlobal.textoSecundario,
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulMarino,
              foregroundColor: AppColors.onAzulMarino,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (fechaCtrl.text.isEmpty || motivoCtrl.text.isEmpty) {
                AppSnackBar.error(context, 'Fecha y Motivo son obligatorios');
                return;
              }
              final DateTime? fecha = parseFecha(fechaCtrl.text);
              if (fecha == null) {
                AppSnackBar.error(context, 'Fecha inválida. Use DD/MM/AAAA');
                return;
              }
              final NonWorkingDay newNonWorkingDay = NonWorkingDay(
                date: fecha,
                reason: motivoCtrl.text,
                tribunalId: tribunalSel?.id,
                tribunalNombre: tribunalSel?.nombreLimpio,
              );
              final bool success = await NonWorkingDayService.saveNonWorkingDay(newNonWorkingDay);
              if (success) {
                if (context.mounted) {
                  AppSnackBar.success(context, 'Día sin despacho guardado');
                }
                if (context.mounted) Navigator.pop(context);
                unawaited(_loadNonWorkingDays());
              } else {
                if (context.mounted) {
                  AppSnackBar.error(context, 'No se pudo guardar el día sin despacho. Verifique su sesión y conexión.');
                }
              }
            },
            label: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  List<NonWorkingDay> _getNonWorkingDaysForDay(DateTime day) {
    final List<NonWorkingDay> allNonWorkingDays = <NonWorkingDay>[...nonWorkingDays2026, ..._userNonWorkingDays];
    return allNonWorkingDays.where((NonWorkingDay nwd) => isSameDay(nwd.date, day)).toList();
  }

  Widget _buildModernField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool numeric = false,
    bool isDate = false,
    bool isTime = false,
    int maxLines = 1,
    String? hint,
    VoidCallback? onTap,
    bool esObligatorio = false,
  }) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: onTap != null,
        onTap: onTap,
        keyboardType: (numeric || isDate || isTime) ? TextInputType.number : TextInputType.text,
        inputFormatters: <TextInputFormatter>[
          if (isDate) DateMaskFormatter(),
          if (isTime) TimeMaskFormatter(),
          if (numeric && !isDate && !isTime) FilteringTextInputFormatter.digitsOnly,
        ],
        style: TextStyle(fontSize: 15, color: TemaGlobal.texto),
        decoration: InputDecoration(
          labelText: esObligatorio ? '$label *' : label,
          hintText: hint,
          hintStyle: TextStyle(color: TemaGlobal.textoTenue, fontSize: 13),
          labelStyle: TextStyle(
              color: TemaGlobal.textoSecundario, fontSize: 13.5),
          prefixIcon: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: TemaGlobal.dorado.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.acento, size: 20),
          ),
          filled: true,
          fillColor: TemaGlobal.superficie,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: TemaGlobal.textoTenue.withValues(alpha: 0.25)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.acento, width: 1.4),
          ),
        ),
      ),
    );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: TemaGlobal.superficie,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Header de la pestaña
                      Text(
                        'Agenda',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: TemaGlobal.texto,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Calendario + leyenda
                      Container(
                        decoration: BoxDecoration(
                          color: TemaGlobal.tarjeta,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: TemaGlobal.capa),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: <Widget>[
                            TableCalendar(
                              locale: "es_VE",
                              firstDay: DateTime.utc(2020),
                              lastDay: DateTime.utc(2030, 12, 31),
                              focusedDay: _focusedDay,
                              selectedDayPredicate: (DateTime day) =>
                                  isSameDay(_selectedDay, day),
                              onDaySelected:
                                  (DateTime selectedDay, DateTime focusedDay) {
                                setState(() {
                                  _selectedDay = selectedDay;
                                  _focusedDay = focusedDay;
                                  _audienciasDelDia =
                                      _audienciasPorDia[_normalizeDay(
                                              selectedDay)] ??
                                          <Audiencia>[];
                                });
                              },
                              eventLoader: (DateTime day) =>
                                  _audienciasPorDia[_normalizeDay(day)] ??
                                  <dynamic>[],
                              headerStyle: HeaderStyle(
                                formatButtonVisible: false,
                                formatButtonShowsNext: false,
                                titleCentered: true,
                                titleTextStyle: TextStyle(
                                    color: TemaGlobal.texto,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16),
                                leftChevronIcon: Icon(Icons.chevron_left,
                                    color: TemaGlobal.texto),
                                rightChevronIcon: Icon(Icons.chevron_right,
                                    color: TemaGlobal.texto),
                              ),
                              daysOfWeekStyle: DaysOfWeekStyle(
                                weekdayStyle:
                                    TextStyle(color: TemaGlobal.texto),
                                weekendStyle:
                                    TextStyle(color: TemaGlobal.texto),
                              ),
                              calendarStyle: CalendarStyle(
                                selectedDecoration: BoxDecoration(
                                    color: AppColors.acento,
                                    borderRadius: BorderRadius.circular(10)),
                                todayDecoration: BoxDecoration(
                                    color: AppColors.dorado.withValues(
                                        alpha: AppColors.a12),
                                    borderRadius: BorderRadius.circular(10)),
                                selectedTextStyle: const TextStyle(
                                    color: AppColors.onDorado,
                                    fontWeight: FontWeight.bold),
                                todayTextStyle: TextStyle(
                                    color: TemaGlobal.texto,
                                    fontWeight: FontWeight.w700),
                                markerDecoration: const BoxDecoration(
                                    color: AppColors.dorado,
                                    shape: BoxShape.circle),
                              ),
                              calendarBuilders: CalendarBuilders(
                                defaultBuilder: (BuildContext context,
                                    DateTime day,
                                    DateTime focusedDay) {
                                  final bool isNonWorkingDay =
                                      _getNonWorkingDaysForDay(day).isNotEmpty;
                                  if (isNonWorkingDay) {
                                    return Container(
                                      margin: const EdgeInsets.all(6),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(
                                            alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                            color: AppColors.error
                                                .withValues(alpha: 0.35)),
                                      ),
                                      child: Text(
                                        "${day.day}",
                                        style: TextStyle(
                                            color: AppColors.error,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    );
                                  }
                                  return null;
                                },
                                todayBuilder: (BuildContext context,
                                        DateTime day,
                                        DateTime focusedDay) =>
                                    Container(
                                  margin: const EdgeInsets.all(6),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.dorado.withValues(
                                        alpha: AppColors.a12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                        color: TemaGlobal.texto,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                selectedBuilder: (BuildContext context,
                                        DateTime day,
                                        DateTime focusedDay) =>
                                    Container(
                                  margin: const EdgeInsets.all(6),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: AppColors.acento,
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  child: Text(
                                    '${day.day}',
                                    style: const TextStyle(
                                        color: AppColors.onDorado,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Leyenda
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                _buildLegendItem(
                                    AppColors.dorado, 'Audiencia'),
                                const SizedBox(width: 16),
                                _buildLegendItem(
                                    AppColors.error, 'Sin despacho'),
                                const SizedBox(width: 16),
                                _buildLegendItem(
                                    AppColors.dorado.withValues(alpha: 0.3),
                                    'Hoy'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Acciones rápidas
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _mostrarFormularioNuevaAudiencia,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Nueva Audiencia'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.acento,
                                foregroundColor: AppColors.acento ==
                                        AppColors.dorado
                                    ? AppColors.onDorado
                                    : AppColors.onAzulMarino,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _mostrarFormularioNuevoDiaSinDespacho,
                              icon: const Icon(Icons.block, size: 18),
                              label: const Text('Día sin Despacho'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: TemaGlobal.texto,
                                side: BorderSide(
                                    color: TemaGlobal.capa, width: 1.5),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Timeline de audiencias
                      Expanded(child: _buildTimeline(context)),
                    ],
                  ),
                ),
        ),
      );

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: TemaGlobal.textoSecundario,
          ),
        ),
      ],
    );
  }

  /// Timeline del día seleccionado: tarjetas de día sin despacho primero
  /// (borde rojo) y luego las audiencias ordenadas por hora, con badge
  /// AUDIENCIA, hora, expediente, imputado y tribunal.
  Widget _buildTimeline(BuildContext context) {
    final List<NonWorkingDay> nonWorkingDays =
        _getNonWorkingDaysForDay(_selectedDay!);
    final List<Audiencia> audiencias = <Audiencia>[..._audienciasDelDia]
      ..sort((a, b) => a.hora.compareTo(b.hora));

    if (nonWorkingDays.isEmpty && audiencias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.calendar_month,
                color: TemaGlobal.textoSecundario, size: 48),
            const SizedBox(height: 12),
            Text(
              'No hay audiencias fijadas.',
              style: TextStyle(
                fontSize: 14,
                color: TemaGlobal.textoSecundario,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: <Widget>[
        for (final NonWorkingDay nwd in nonWorkingDays)
          _buildNonWorkingCard(context, nwd),
        for (final Audiencia aud in audiencias)
          _buildAudienciaCard(context, aud),
      ],
    );
  }

  Widget _buildNonWorkingCard(BuildContext context, NonWorkingDay nwd) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaGlobal.tarjeta,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaGlobal.capa),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Borde rojo izquierdo (marca de día sin despacho)
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.error
                              .withValues(alpha: AppColors.a12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'DÍA SIN DESPACHO',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    nwd.reason,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: TemaGlobal.texto,
                    ),
                  ),
                  if (nwd.tribunalNombre?.isNotEmpty == true) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      nwd.tribunalNombre!,
                      style: TextStyle(
                        fontSize: 12,
                        color: TemaGlobal.textoSecundario,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Icon(Icons.info_outline,
                          size: 14, color: TemaGlobal.textoTenue),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'El cómputo de lapsos depende del procedimiento '
                          '(continuo, hábil o de despacho). Verifica tus '
                          'lapsos en el Calendario Judicial.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: TemaGlobal.textoSecundario,
                          ),
                        ),
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

  Widget _buildAudienciaCard(BuildContext context, Audiencia aud) {
    final ({String hora, String periodo}) h = _dividirHora(aud.hora);
    final bool esHoy = isSameDay(aud.fecha, DateTime.now());
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Columna de hora
        SizedBox(
          width: 54,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                h.hora,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: esHoy ? AppColors.acento : TemaGlobal.texto,
                ),
              ),
              if (h.periodo.isNotEmpty)
                Text(
                  h.periodo,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: TemaGlobal.textoSecundario,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Línea vertical
        Container(
          width: 2,
          margin: const EdgeInsets.only(top: 14),
          height: 40,
          decoration: BoxDecoration(
            color: esHoy ? AppColors.dorado : TemaGlobal.capa,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        // Tarjeta del evento
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TemaGlobal.tarjeta,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TemaGlobal.capa),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:
                            AppColors.dorado.withValues(alpha: AppColors.a12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'AUDIENCIA',
                        style: TextStyle(
                          color: AppColors.acento,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          tooltip: 'Portafolio del expediente',
                          icon: Icon(Icons.folder_open,
                              color: AppColors.dorado, size: 20),
                          onPressed: () => _abrirExpediente(aud),
                        ),
                        IconButton(
                          tooltip: 'Lapsos del expediente',
                          icon: Icon(Icons.timeline,
                              color: AppColors.acento, size: 20),
                          onPressed: () => _abrirLapsosExpediente(aud),
                        ),
                        IconButton(
                          tooltip: 'Eliminar audiencia',
                          icon: Icon(Icons.delete_outline,
                              color: AppColors.error, size: 20),
                          onPressed: () => unawaited(_eliminarAudiencia(aud)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: aud.tribunalId != null
                      ? () => _abrirTribunal(aud.tribunalId!)
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        aud.expediente,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: TemaGlobal.texto,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        aud.imputado,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TemaGlobal.textoSecundario,
                        ),
                      ),
                      if ((aud.tribunal ?? '').isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Icon(Icons.account_balance,
                                size: 14, color: TemaGlobal.textoTenue),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                aud.tribunal!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: TemaGlobal.textoSecundario,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Separa una hora "HH:MM AM/PM" en su hora y su periodo.
  /// Si no trae periodo explícito, lo infiere (12:00 = PM, 1-6 = PM,
  /// resto AM, igual que el campo de la agenda).
  ({String hora, String periodo}) _dividirHora(String raw) {
    final String texto = raw.trim().toUpperCase();
    final RegExp regex = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$');
    final RegExpMatch? m = regex.firstMatch(texto);
    if (m == null) return (hora: raw.trim(), periodo: '');
    final int hour = int.parse(m.group(1)!);
    final String minutos = m.group(2)!;
    String? periodo = m.group(3);
    periodo ??= (hour == 12 || (hour >= 1 && hour <= 6)) ? 'PM' : 'AM';
    return (hora: '$hour:$minutos', periodo: periodo);
  }
}

class DateMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    if (text.length > 8) text = text.substring(0, 8);
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i == 1 || i == 3) && i != text.length - 1) buffer.write('/');
    }
    return TextEditingValue(text: buffer.toString(), selection: TextSelection.collapsed(offset: buffer.toString().length));
  }
}

class TimeMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    String digits = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    if (digits.isEmpty) return TextEditingValue.empty;
    String formatted = '';
    if (digits.isNotEmpty) formatted += digits[0];
    if (digits.length >= 2) formatted += digits[1];
    String period = '';
    if (digits.length >= 2) {
      final int hour = int.tryParse(digits.substring(0, 2)) ?? 0;
      if (hour >= 7 && hour <= 11) {
        period = ' AM';
      } else if (hour == 12 || (hour >= 1 && hour <= 6)) {
        period = ' PM';
      } else {
        period = ' AM';
      }
    }
    if (digits.length >= 3) formatted += ':${digits[2]}';
    if (digits.length >= 4) formatted += digits[3];
    return TextEditingValue(text: formatted + period, selection: TextSelection.collapsed(offset: formatted.length));
  }
}
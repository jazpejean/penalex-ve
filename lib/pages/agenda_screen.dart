import 'dart:async';
import '../services/haptics_service.dart';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../config/app_colors.dart';
import '../models/audiencia.dart';
import '../config/app_theme.dart';
import '../services/agenda_service.dart';
import '../services/non_working_day_service.dart';
import '../services/tribunales_service.dart';
import '../utils/non_working_days.dart';
import 'calendario_judicial_screen.dart';
import 'formulario_audiencia_screen.dart';
import 'formulario_dia_sin_despacho_screen.dart';
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
    Haptics.tap();
    Navigator.of(context)
        .push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FormularioAudienciaScreen(fechaInicial: _selectedDay),
      ),
    )
        .then((bool? guardado) {
      if (guardado == true && mounted) {
        unawaited(_cargarAudiencias());
      }
    });
  }

  void _mostrarFormularioNuevoDiaSinDespacho() {
    Haptics.tap();
    Navigator.of(context)
        .push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            FormularioDiaSinDespachoScreen(fechaInicial: _selectedDay),
      ),
    )
        .then((bool? guardado) {
      if (guardado == true && mounted) {
        unawaited(_loadNonWorkingDays());
      }
    });
  }

  /// Días sin despacho de un día: feriados judiciales de TODOS los años
  /// (el generador calcula Semana Santa y Carnaval por año) + días sin
  /// despacho que el usuario registró.
  List<NonWorkingDay> _getNonWorkingDaysForDay(DateTime day) {
    final List<NonWorkingDay> allNonWorkingDays = <NonWorkingDay>[
      ...getNonWorkingDaysForYear(day.year),
      ..._userNonWorkingDays,
    ];
    return allNonWorkingDays
        .where((NonWorkingDay nwd) => isSameDay(nwd.date, day))
        .toList();
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
                      // Calendario + leyenda (sin título: la pestaña ya se
                      // identifica en la barra inferior).
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
                                // Texto del día seleccionado: contraste según
                                // el modo (navy en claro → blanco; dorado en
                                // oscuro → navy). Nunca navy sobre navy.
                                selectedTextStyle: TextStyle(
                                    color: AppColors.acento ==
                                            AppColors.dorado
                                        ? AppColors.onDorado
                                        : AppColors.onAzulMarino,
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
                                    style: TextStyle(
                                        color: AppColors.acento ==
                                                AppColors.dorado
                                            ? AppColors.onDorado
                                            : AppColors.onAzulMarino,
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


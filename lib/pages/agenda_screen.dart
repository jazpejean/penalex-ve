import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';

import '../config/app_colors.dart';
import '../models/audiencia.dart';
import '../config/app_theme.dart';
import '../services/agenda_service.dart';
import '../services/non_working_day_service.dart';
import '../services/notification_service.dart';
import '../utils/date_utils.dart';
import '../utils/non_working_days.dart';
import '../widgets/app_drawer.dart';

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
          await NonWorkingDayService.loadUserNonWorkingDays();
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
          await AgendaService.cargarAudiencias(_focusedDay);
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    final bool exito = await AgendaService.eliminarAudiencia(audiencia.id);
    if (exito) {
      await _cargarAudiencias();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audiencia eliminada'), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar la audiencia'), backgroundColor: Colors.red),
        );
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

    if (_selectedDay != null) {
      fechaCtrl.text =
          "${_selectedDay!.day.toString().padLeft(2, '0')}/${_selectedDay!.month.toString().padLeft(2, '0')}/${_selectedDay!.year}";
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Nueva Audiencia', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.95,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildModernField(expedienteCtrl, 'Expediente *', Icons.folder_open),
                _buildModernField(imputadoCtrl, 'Imputado / Acusado *', Icons.person),
                _buildModernField(cedulaCtrl, 'Cédula de Identidad', Icons.badge_outlined, numeric: true),
                _buildModernField(fechaCtrl, 'Fecha de Audiencia (DD/MM/AAAA) *', Icons.calendar_today, isDate: true, hint: 'Ej: 24/12/2026'),
                _buildModernField(horaCtrl, 'Hora (HH:MM) *', Icons.access_time, isTime: true, hint: 'Ej: 0230 (Aplica PM automáticamente)'),
                _buildModernField(tribunalCtrl, 'Tribunal competente', Icons.account_balance),
                _buildModernField(fiscaliaCtrl, 'Fiscalía', Icons.shield),
                _buildModernField(delitosCtrl, 'Delitos imputados', Icons.gavel, maxLines: 2),
                _buildModernField(tipoCtrl, 'Tipo de Audiencia', Icons.merge_type),
                _buildModernField(notasCtrl, 'Notas adicionales', Icons.note_alt_outlined, maxLines: 2),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              if (expedienteCtrl.text.isEmpty || imputadoCtrl.text.isEmpty || fechaCtrl.text.isEmpty || horaCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Expediente, Imputado, Fecha y Hora son obligatorios'),
                  backgroundColor: Colors.red,
                ));
                return;
              }
              final DateTime? fecha = parseFecha(fechaCtrl.text);
              if (fecha == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Fecha inválida. Use DD/MM/AAAA'),
                  backgroundColor: Colors.red,
                ));
                return;
              }
              final Audiencia nueva = Audiencia(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                expediente: expedienteCtrl.text,
                tribunal: tribunalCtrl.text.isNotEmpty ? tribunalCtrl.text : null,
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Error al guardar la audiencia'),
                    backgroundColor: Colors.red,
                  ));
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _mostrarFormularioNuevoDiaSinDespacho() {
    final TextEditingController fechaCtrl = TextEditingController();
    final TextEditingController motivoCtrl = TextEditingController();

    if (_selectedDay != null) {
      fechaCtrl.text =
          "${_selectedDay!.day.toString().padLeft(2, '0')}/${_selectedDay!.month.toString().padLeft(2, '0')}/${_selectedDay!.year}";
    }

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Nuevo día sin despacho', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.95,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildModernField(fechaCtrl, 'Fecha (DD/MM/AAAA) *', Icons.calendar_today, isDate: true, hint: 'Ej: 24/12/2026'),
                _buildModernField(motivoCtrl, 'Motivo (ej: falla eléctrica, salud, etc.) *', Icons.description, maxLines: 2),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Este día se marcará como inhábil en toda la agenda personal, sin distinguir tribunales.',
                          style: TextStyle(fontSize: 12, color: AppColors.primary.withValues(alpha: 0.8)),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              if (fechaCtrl.text.isEmpty || motivoCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Fecha y Motivo son obligatorios'),
                  backgroundColor: Colors.red,
                ));
                return;
              }
              final DateTime? fecha = parseFecha(fechaCtrl.text);
              if (fecha == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Fecha inválida. Use DD/MM/AAAA'),
                  backgroundColor: Colors.red,
                ));
                return;
              }
              final NonWorkingDay newNonWorkingDay = NonWorkingDay(date: fecha, reason: motivoCtrl.text);
              final bool success = await NonWorkingDayService.saveNonWorkingDay(newNonWorkingDay);
              if (success) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Día sin despacho guardado'),
                    backgroundColor: Colors.green,
                  ));
                }
                if (context.mounted) Navigator.pop(context);
                unawaited(_loadNonWorkingDays());
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('No se pudo guardar el día sin despacho. Verifique su sesión y conexión.'),
                    backgroundColor: Colors.red,
                  ));
                }
              }
            },
            child: const Text('Guardar'),
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
  }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: (numeric || isDate || isTime) ? TextInputType.number : TextInputType.text,
        inputFormatters: <TextInputFormatter>[
          if (isDate) DateMaskFormatter(),
          if (isTime) TimeMaskFormatter(),
          if (numeric && !isDate && !isTime) FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: TemaGlobal.textoTenue, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
      ),
    );

  @override
  Widget build(BuildContext context) => Scaffold(
      drawer: const AppDrawer(currentRoute: "/agenda"),
      appBar: AppBar(title: const Text("Agenda Judicial")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    "Agenda Judicial",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: TemaGlobal.texto,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TableCalendar(
                        locale: "es_VE",
                        firstDay: DateTime.utc(2020),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (DateTime day) => isSameDay(_selectedDay, day),
                        onDaySelected: (DateTime selectedDay, DateTime focusedDay) {
                          final List<NonWorkingDay> nonWorkingDays = _getNonWorkingDaysForDay(selectedDay);
                          if (nonWorkingDays.isNotEmpty) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                title: const Text("Día sin despacho"),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: nonWorkingDays
                                      .map((NonWorkingDay nwd) => Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Text("• ${nwd.reason}"),
                                          ))
                                      .toList(),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Entendido"),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                            _audienciasDelDia = _audienciasPorDia[_normalizeDay(selectedDay)] ?? <Audiencia>[];
                          });
                        },
                        eventLoader: (DateTime day) => _audienciasPorDia[_normalizeDay(day)] ?? <dynamic>[],
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          formatButtonShowsNext: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(color: TemaGlobal.texto, fontWeight: FontWeight.w700),
                          leftChevronIcon: Icon(Icons.chevron_left, color: TemaGlobal.texto),
                          rightChevronIcon: Icon(Icons.chevron_right, color: TemaGlobal.texto),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(color: TemaGlobal.texto),
                          weekendStyle: TextStyle(color: TemaGlobal.texto),
                        ),
                        calendarStyle: CalendarStyle(
                          selectedDecoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                          todayDecoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                          selectedTextStyle: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                          todayTextStyle: TextStyle(color: TemaGlobal.texto, fontWeight: FontWeight.w700),
                          markerDecoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                        ),
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (BuildContext context, DateTime day, DateTime focusedDay) {
                            final bool isNonWorkingDay = _getNonWorkingDaysForDay(day).isNotEmpty;
                            if (isNonWorkingDay) {
                              return Container(
                                margin: const EdgeInsets.all(6),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
                                ),
                                child: Text(
                                  "${day.day}",
                                  style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                                ),
                              );
                            }
                            return null;
                          },
                          todayBuilder: (BuildContext context, DateTime day, DateTime focusedDay) => Container(
                              margin: const EdgeInsets.all(6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${day.day}', style: TextStyle(color: TemaGlobal.texto, fontWeight: FontWeight.w700)),
                            ),
                          selectedBuilder: (BuildContext context, DateTime day, DateTime focusedDay) => Container(
                              margin: const EdgeInsets.all(6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                              child: Text('${day.day}', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                            ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _audienciasDelDia.isEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(Icons.calendar_month, color: TemaGlobal.texto, size: 48),
                                  const SizedBox(height: 12),
                                  const Text("No hay audiencias fijadas.", textAlign: TextAlign.center),
                                ],
                              )
                            : ListView.builder(
                                itemCount: _audienciasDelDia.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final Audiencia aud = _audienciasDelDia[index];
                                  return Dismissible(
                                    key: Key(aud.id),
                                    background: Container(
                                      color: AppColors.error,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      child: const Icon(Icons.delete, color: Colors.white),
                                    ),
                                    direction: DismissDirection.endToStart,
                                    confirmDismiss: (DismissDirection direction) async => showDialog(
                                        context: context,
                                        builder: (BuildContext context) => AlertDialog(
                                          title: const Text('Eliminar audiencia'),
                                          content: Text('¿Eliminar audiencia con expediente "${aud.expediente}"?'),
                                          actions: <Widget>[
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: AppColors.error))),
                                          ],
                                        )),
                                    onDismissed: (DismissDirection direction) => unawaited(_eliminarAudiencia(aud)),
                                    child: ListTile(
                                      title: Text(aud.expediente, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text("${aud.imputado} - ${aud.hora}"),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => unawaited(_eliminarAudiencia(aud)),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: _mostrarFormularioNuevoDiaSinDespacho,
              icon: const Icon(Icons.block, size: 20),
              label: const Text("Día sin despacho"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _mostrarFormularioNuevaAudiencia,
              icon: const Icon(Icons.add, size: 20),
              label: const Text("Nueva audiencia"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
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
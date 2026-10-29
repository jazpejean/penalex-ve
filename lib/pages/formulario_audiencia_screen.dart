import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../models/audiencia.dart';
import '../services/agenda_service.dart';
import '../services/expediente_service.dart';
import '../services/haptics_service.dart';
import '../services/notification_service.dart';
import '../services/tribunales_service.dart';
import '../utils/date_utils.dart';
import '../widgets/app_bar_institucional.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/campo_moderno.dart';
import 'selector_tribunal_screen.dart';

/// Formulario de Nueva Audiencia a pantalla completa.
///
/// Al guardar crea la audiencia en `agenda_eventos` (con recordatorio) y
/// **asegura el portafolio** en `expedientes` (el expediente se crea o
/// actualiza automáticamente con los datos de la causa). Devuelve `true`
/// con `Navigator.pop` si se guardó.
class FormularioAudienciaScreen extends StatefulWidget {
  const FormularioAudienciaScreen({super.key, this.fechaInicial});

  /// Fecha preseleccionada (el día seleccionado en el calendario).
  final DateTime? fechaInicial;

  @override
  State<FormularioAudienciaScreen> createState() =>
      _FormularioAudienciaScreenState();
}

class _FormularioAudienciaScreenState extends State<FormularioAudienciaScreen> {
  final TextEditingController _expedienteCtrl = TextEditingController();
  final TextEditingController _tribunalCtrl = TextEditingController();
  final TextEditingController _imputadoCtrl = TextEditingController();
  final TextEditingController _cedulaCtrl = TextEditingController();
  final TextEditingController _fiscaliaCtrl = TextEditingController();
  final TextEditingController _delitosCtrl = TextEditingController();
  final TextEditingController _fechaCtrl = TextEditingController();
  final TextEditingController _horaCtrl = TextEditingController();
  final TextEditingController _tipoCtrl = TextEditingController();
  final TextEditingController _notasCtrl = TextEditingController();
  final NotificationService _notificationService = NotificationService();
  // Tribunal del catálogo seleccionado (se guarda como tribunal_id).
  Tribunal? _tribunalSel;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final DateTime? inicial = widget.fechaInicial;
    if (inicial != null) {
      _fechaCtrl.text = "${inicial.day.toString().padLeft(2, '0')}/"
          "${inicial.month.toString().padLeft(2, '0')}/${inicial.year}";
    }
  }

  @override
  void dispose() {
    _expedienteCtrl.dispose();
    _tribunalCtrl.dispose();
    _imputadoCtrl.dispose();
    _cedulaCtrl.dispose();
    _fiscaliaCtrl.dispose();
    _delitosCtrl.dispose();
    _fechaCtrl.dispose();
    _horaCtrl.dispose();
    _tipoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarTribunal() async {
    final Tribunal? elegido = await Navigator.of(context).push<Tribunal>(
      MaterialPageRoute<Tribunal>(
        builder: (_) => SelectorTribunalScreen(inicial: _tribunalCtrl.text),
      ),
    );
    if (elegido != null && mounted) {
      setState(() {
        _tribunalSel = elegido;
        _tribunalCtrl.text = elegido.nombreLimpio;
      });
    }
  }

  Future<void> _guardar() async {
    Haptics.light();
    if (_expedienteCtrl.text.isEmpty ||
        _imputadoCtrl.text.isEmpty ||
        _fechaCtrl.text.isEmpty ||
        _horaCtrl.text.isEmpty) {
      Haptics.error();
      AppSnackBar.error(
          context, 'Expediente, Imputado, Fecha y Hora son obligatorios');
      return;
    }
    final DateTime? fecha = parseFecha(_fechaCtrl.text);
    if (fecha == null) {
      AppSnackBar.error(context, 'Fecha inválida. Use DD/MM/AAAA');
      return;
    }
    setState(() => _guardando = true);
    final Audiencia nueva = Audiencia(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      expediente: _expedienteCtrl.text.trim(),
      tribunal: _tribunalCtrl.text.isNotEmpty ? _tribunalCtrl.text : null,
      tribunalId: _tribunalSel?.id,
      imputado: _imputadoCtrl.text.trim(),
      cedula: _cedulaCtrl.text.isNotEmpty ? _cedulaCtrl.text.trim() : null,
      fiscalia:
          _fiscaliaCtrl.text.isNotEmpty ? _fiscaliaCtrl.text.trim() : null,
      delitos: _delitosCtrl.text.isNotEmpty ? _delitosCtrl.text.trim() : null,
      fecha: fecha,
      hora: _horaCtrl.text.trim(),
      tipo: _tipoCtrl.text.isNotEmpty ? _tipoCtrl.text.trim() : null,
      notas: _notasCtrl.text.isNotEmpty ? _notasCtrl.text.trim() : null,
    );
    final bool exito = await AgendaService.crearAudiencia(nueva);
    if (exito) {
      // Cierra el ciclo del portafolio: el expediente se crea/actualiza
      // automáticamente al agendar la audiencia.
      await ExpedienteService.asegurarExpediente(
        numeroExpediente: nueva.expediente,
        imputado: nueva.imputado,
        cedula: nueva.cedula,
        delitos: nueva.delitos,
        tribunalId: nueva.tribunalId,
        tribunalNombre: nueva.tribunal,
        fechaAudiencia: nueva.fecha,
      );
      final TimeOfDay? horaAudiencia = parseHora(_horaCtrl.text);
      if (horaAudiencia != null) {
        final DateTime fechaHoraAudiencia = DateTime(
          fecha.year,
          fecha.month,
          fecha.day,
          horaAudiencia.hour,
          horaAudiencia.minute,
        );
        final DateTime fechaHoraNotificacion =
            fechaHoraAudiencia.subtract(const Duration(hours: 1));
        if (fechaHoraNotificacion.isAfter(DateTime.now())) {
          unawaited(_notificationService.scheduleAudienceReminder(
            audienceId: nueva.id,
            title:
                'Audiencia: ${nueva.expediente} - ${nueva.imputado}',
            dateTime: fechaHoraNotificacion,
          ));
        }
      }
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() => _guardando = false);
      AppSnackBar.error(context, 'Error al guardar la audiencia');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
      appBar: AppBarInstitucional(
        title: 'Nueva Audiencia',
        mostrarBack: true,
        mostrarHome: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CampoModerno(_expedienteCtrl, 'Expediente',
                  Icons.folder_open,
                  esObligatorio: true),
              CampoModerno(_imputadoCtrl, 'Imputado / Acusado',
                  Icons.person,
                  esObligatorio: true),
              CampoModerno(_cedulaCtrl, 'Cédula de Identidad',
                  Icons.badge_outlined,
                  numeric: true),
              CampoModerno(_fechaCtrl, 'Fecha de Audiencia (DD/MM/AAAA)',
                  Icons.calendar_today,
                  isDate: true,
                  hint: 'Ej: 24/12/2026',
                  esObligatorio: true),
              CampoModerno(_horaCtrl, 'Hora (HH:MM)', Icons.access_time,
                  isTime: true,
                  hint: 'Ej: 0230 (Aplica PM automáticamente)',
                  esObligatorio: true),
              CampoModerno(
                _tribunalCtrl,
                'Tribunal competente',
                Icons.account_balance,
                onTap: _seleccionarTribunal,
              ),
              CampoModerno(_fiscaliaCtrl, 'Fiscalía', Icons.shield),
              CampoModerno(_delitosCtrl, 'Delitos imputados', Icons.gavel,
                  maxLines: 2),
              CampoModerno(_tipoCtrl, 'Tipo de Audiencia', Icons.merge_type),
              CampoModerno(_notasCtrl, 'Notas adicionales',
                  Icons.note_alt_outlined,
                  maxLines: 2),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: Text(_guardando ? 'Guardando…' : 'Guardar'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.acento,
                  foregroundColor: AppColors.acento == AppColors.dorado
                      ? AppColors.onDorado
                      : AppColors.onAzulMarino,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
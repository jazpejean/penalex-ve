import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../services/haptics_service.dart';
import '../services/non_working_day_service.dart';
import '../services/tribunales_service.dart';
import '../utils/date_utils.dart';
import '../utils/non_working_days.dart';
import '../widgets/app_bar_institucional.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/campo_moderno.dart';
import 'selector_tribunal_screen.dart';

/// Formulario de Día sin Despacho a pantalla completa.
///
/// El tribunal es OBLIGATORIO: un día sin despacho siempre se registra
/// para un tribunal concreto del catálogo (excluye los lapsos de ese
/// tribunal en el Calendario Judicial). Devuelve `true` con
/// `Navigator.pop` si se guardó.
class FormularioDiaSinDespachoScreen extends StatefulWidget {
  const FormularioDiaSinDespachoScreen({super.key, this.fechaInicial});

  /// Fecha preseleccionada (el día seleccionado en el calendario).
  final DateTime? fechaInicial;

  @override
  State<FormularioDiaSinDespachoScreen> createState() =>
      _FormularioDiaSinDespachoScreenState();
}

class _FormularioDiaSinDespachoScreenState
    extends State<FormularioDiaSinDespachoScreen> {
  final TextEditingController _fechaCtrl = TextEditingController();
  final TextEditingController _motivoCtrl = TextEditingController();
  final TextEditingController _tribunalCtrl = TextEditingController();
  // Tribunal del catálogo asociado — OBLIGATORIO.
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
    _fechaCtrl.dispose();
    _motivoCtrl.dispose();
    _tribunalCtrl.dispose();
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
    if (_fechaCtrl.text.isEmpty || _motivoCtrl.text.isEmpty) {
      Haptics.error();
      AppSnackBar.error(context, 'Fecha y Motivo son obligatorios');
      return;
    }
    if (_tribunalSel == null) {
      Haptics.error();
      AppSnackBar.error(context, 'Debe seleccionar el tribunal');
      return;
    }
    final DateTime? fecha = parseFecha(_fechaCtrl.text);
    if (fecha == null) {
      AppSnackBar.error(context, 'Fecha inválida. Use DD/MM/AAAA');
      return;
    }
    setState(() => _guardando = true);
    final NonWorkingDay newNonWorkingDay = NonWorkingDay(
      date: fecha,
      reason: _motivoCtrl.text.trim(),
      tribunalId: _tribunalSel!.id,
      tribunalNombre: _tribunalSel!.nombreLimpio,
    );
    final bool success =
        await NonWorkingDayService.saveNonWorkingDay(newNonWorkingDay);
    if (!mounted) return;
    setState(() => _guardando = false);
    if (success) {
      AppSnackBar.success(context, 'Día sin despacho guardado');
      Navigator.pop(context, true);
    } else {
      AppSnackBar.error(context,
          'No se pudo guardar el día sin despacho. Verifique su sesión y conexión.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
      appBar: AppBarInstitucional(
        title: 'Día sin Despacho',
        mostrarBack: true,

      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CampoModerno(_fechaCtrl, 'Fecha (DD/MM/AAAA)',
                  Icons.calendar_today,
                  isDate: true,
                  hint: 'Ej: 24/12/2026',
                  esObligatorio: true),
              CampoModerno(_motivoCtrl, 'Motivo', Icons.description,
                  maxLines: 2,
                  hint: 'Ej: falla eléctrica, salud, etc.',
                  esObligatorio: true),
              CampoModerno(
                _tribunalCtrl,
                'Tribunal',
                Icons.account_balance,
                onTap: _seleccionarTribunal,
                esObligatorio: true,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.info_outline,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El día sin despacho excluye los lapsos de ese '
                        'tribunal en el Calendario Judicial. El cómputo '
                        'depende del procedimiento (continuo, hábil o de '
                        'despacho).',
                        style: TextStyle(
                          fontSize: 12,
                          color: TemaGlobal.textoSecundario,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
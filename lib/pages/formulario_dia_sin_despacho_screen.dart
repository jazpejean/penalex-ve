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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ── Sección: Datos del día ───────────────────────────────
              const _TituloSeccion('Datos del día'),
              CampoModerno(_fechaCtrl, 'Fecha',
                  Icons.calendar_today,
                  isDate: true,
                  hint: 'Ej: 24/12/2026',
                  esObligatorio: true),
              CampoModerno(_motivoCtrl, 'Motivo', Icons.description,
                  maxLines: 2,
                  hint: 'Ej: falla eléctrica, salud, etc.',
                  esObligatorio: true),
              const SizedBox(height: 8),
              // ── Sección: Tribunal ────────────────────────────────────
              const _TituloSeccion('Tribunal'),
              CampoModerno(
                _tribunalCtrl,
                'Tribunal competente',
                Icons.account_balance,
                onTap: _seleccionarTribunal,
                hint: 'Toca para buscar por estado',
                esObligatorio: true,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.info_outline,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'El día sin despacho excluye los lapsos de ese '
                        'tribunal en el Calendario Judicial. El cómputo '
                        'depende del procedimiento (continuo, hábil o de '
                        'despacho).',
                        style: TextStyle(
                          fontSize: 13,
                          color: TemaGlobal.textoSecundario,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: Text(_guardando ? 'Guardando…' : 'Guardar'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.acento,
                  foregroundColor: AppColors.acento == AppColors.dorado
                      ? AppColors.onDorado
                      : AppColors.onAzulMarino,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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

/// Título de sección del formulario (guía 3.6: 15px w800, como expediente).
class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion(this.titulo);

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        titulo,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: TemaGlobal.texto,
        ),
      ),
    );
  }
}
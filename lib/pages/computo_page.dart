import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/report_generator.dart';
import '../models/calculation_model.dart';
import '../models/delito.dart';
import '../services/calculation_service.dart';
import '../services/pdf_service.dart';
import '../services/report_service.dart';
import '../widgets/app_drawer.dart';
import 'dosimetria_page.dart';

class ComputoPage extends StatefulWidget {
  const ComputoPage({
    required this.delitos,
    required this.concurso,
    required this.admisionHechos,
    required this.fraccionAdmision,
    required this.penaTotal,
    super.key,
  });
  final List<Delito> delitos;
  final TipoConcurso concurso;
  final bool admisionHechos;
  final double fraccionAdmision;
  final double penaTotal;

  @override
  State<ComputoPage> createState() => _ComputoPageState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<Delito>('delitos', delitos));
    properties.add(EnumProperty<TipoConcurso>('concurso', concurso));
    properties.add(DiagnosticsProperty<bool>('admisionHechos', admisionHechos));
    properties.add(DoubleProperty('fraccionAdmision', fraccionAdmision));
    properties.add(DoubleProperty('penaTotal', penaTotal));
  }
}

class _ComputoPageState extends State<ComputoPage> {
  bool _sinDetenido = false;
  DateTime? _fechaDetencion;
  DateTime? _fechaCondena;
  bool _usarFechaActual = true;
  DateTime _fechaCumplimiento = DateTime.now();
  String _tiempoDetenido = '';
  String _tiempoRestante = '';

  final TextEditingController _fechaDetencionController = TextEditingController();
  final TextEditingController _fechaCondenaController = TextEditingController();
  bool _fechaDetencionValida = true;
  bool _fechaCondenaValida = true;

  static const Color fondoPantalla = Color(0xFFF1F5F9);
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);

  @override
  void initState() {
    super.initState();
    _fechaCumplimiento = DateTime.now();
    _tiempoDetenido = '0 años, 0 meses, 0 días';
    _tiempoRestante = '0 años, 0 meses, 0 días';
  }

  void _calcularTodo() {
    if (_sinDetenido || _fechaDetencion == null) {
      setState(() {
        _tiempoDetenido = 'No aplica';
        _tiempoRestante = 'No aplica';
        _fechaCumplimiento = DateTime.now();
      });
      return;
    }

    DateTime hasta;
    if (_fechaCondena != null) {
      hasta = _fechaCondena!;
    } else if (_usarFechaActual) {
      hasta = DateTime.now();
    } else {
      hasta = DateTime.now();
    }

    final List<int> diferencia = _diferenciaComercial(_fechaDetencion!, hasta);
    _tiempoDetenido = _formatearDuracion(diferencia[0], diferencia[1], diferencia[2]);

    _fechaCumplimiento = _sumarPena(_fechaDetencion!, widget.penaTotal);

    final List<int> diferenciaRestante = _diferenciaComercial(hasta, _fechaCumplimiento);
    if (hasta.isAfter(_fechaCumplimiento)) {
      _tiempoRestante = '0 años, 0 meses, 0 días';
    } else {
      _tiempoRestante = _formatearDuracion(diferenciaRestante[0], diferenciaRestante[1], diferenciaRestante[2]);
    }
    setState(() {});
  }

  List<int> _diferenciaComercial(DateTime desde, DateTime hasta) {
    int years = hasta.year - desde.year;
    int months = hasta.month - desde.month;
    int days = hasta.day - desde.day;
    if (days < 0) {
      months--;
      days += 30;
    }
    if (months < 0) {
      years--;
      months += 12;
    }
    return <int>[years, months, days];
  }

  String _formatearDuracion(int years, int months, int days) {
    final String y = years == 1 ? 'año' : 'años';
    final String m = months == 1 ? 'mes' : 'meses';
    final String d = days == 1 ? 'día' : 'días';
    return '$years $y, $months $m, $days $d';
  }

  DateTime _sumarPena(DateTime desde, double penaEnAnios) {
    final int totalDias = (penaEnAnios * 360).round();
    final int anios = totalDias ~/ 360;
    final int resto = totalDias % 360;
    final int meses = resto ~/ 30;
    final int dias = resto % 30;
    DateTime fecha = desde;
    fecha = DateTime(fecha.year + anios, fecha.month, fecha.day);
    fecha = DateTime(fecha.year, fecha.month + meses, fecha.day);
    fecha = fecha.add(Duration(days: dias));
    return fecha;
  }

  String _formatearFecha(DateTime fecha) => '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  DateTime? _parsearFecha(String texto) {
    try {
      final List<String> partes = texto.split('/');
      if (partes.length != 3) return null;
      final int? dia = int.tryParse(partes[0]);
      final int? mes = int.tryParse(partes[1]);
      final int? anio = int.tryParse(partes[2]);
      if (dia == null || mes == null || anio == null) return null;
      return DateTime(anio, mes, dia);
    } on Exception catch (_) {
      return null;
    }
  }

  void _validarFecha(String texto, bool esDetencion) {
    if (_sinDetenido && esDetencion) return;
    if (texto.isEmpty) {
      if (esDetencion) {
        _fechaDetencion = null;
        _fechaDetencionValida = true;
      } else {
        _fechaCondena = null;
        _fechaCondenaValida = true;
      }
      _calcularTodo();
      return;
    }
    final DateTime? fecha = _parsearFecha(texto);
    if (fecha == null) {
      if (esDetencion) {
        _fechaDetencionValida = false;
        _fechaDetencion = null;
      } else {
        _fechaCondenaValida = false;
        _fechaCondena = null;
      }
      setState(() {});
      return;
    }
    if (fecha.isAfter(DateTime.now())) {
      if (esDetencion) {
        _fechaDetencionValida = false;
        _fechaDetencion = null;
      } else {
        _fechaCondenaValida = false;
        _fechaCondena = null;
      }
      setState(() {});
      return;
    }
    if (esDetencion) {
      _fechaDetencion = fecha;
      _fechaDetencionValida = true;
    } else {
      _fechaCondena = fecha;
      _fechaCondenaValida = true;
    }
    _calcularTodo();
  }

  void _aplicarMascara(TextEditingController controller, String texto) {
    final String limpio = texto.replaceAll(RegExp('[^0-9]'), '');
    if (limpio.isEmpty) {
      controller.text = '';
      return;
    }
    String formateado = '';
    for (int i = 0; i < limpio.length; i++) {
      if (i == 2 || i == 4) formateado += '/';
      formateado += limpio[i];
    }
    if (formateado.length > 10) formateado = formateado.substring(0, 10);
    controller.text = formateado;
    controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esDetencion) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: azulMarino),
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      if (esDetencion) {
        _fechaDetencion = picked;
        _fechaDetencionController.text = _formatearFecha(picked);
        _fechaDetencionValida = true;
      } else {
        _fechaCondena = picked;
        _fechaCondenaController.text = _formatearFecha(picked);
        _fechaCondenaValida = true;
      }
      _calcularTodo();
    }
  }

  String _generarReporte() {
    ComputoData? computoData;
    if (!_sinDetenido && _fechaDetencion != null) {
      computoData = ComputoData(
        fechaDetencion: _fechaDetencion!,
        tiempoDetenidoTexto: _tiempoDetenido,
        tiempoRestanteTexto: _tiempoRestante,
        fechaCumplimiento: _fechaCumplimiento,
        fechaCondena: _usarFechaActual ? DateTime.now() : _fechaCondena,
      );
    }
    return ReportGenerator.generarReporteCompleto(
      delitos: widget.delitos,
      concurso: widget.concurso,
      admisionHechos: widget.admisionHechos,
      fraccionAdmision: widget.fraccionAdmision,
      computo: computoData,
    );
  }

  Future<void> _guardarCalculo() async {
    final String? nombre = await _mostrarDialogoNombre('Guardar cálculo', 'Nombre del cálculo');
    if (nombre == null || nombre.isEmpty) return;
    final CalculationModel calculation = CalculationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: nombre,
      fecha: DateTime.now(),
      delitos: widget.delitos.map((Delito d) => Delito.fromMap(d.toMap())).toList(),
      concurso: widget.concurso,
      admisionHechos: widget.admisionHechos,
      fraccionAdmision: widget.fraccionAdmision,
    );
    await CalculationService.saveCalculation(calculation);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Cálculo "$nombre" guardado'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _guardarReporte() async {
    final String? nombre = await _mostrarDialogoNombre('Guardar reporte', 'Nombre del archivo (sin extensión)');
    if (nombre == null || nombre.isEmpty) return;
    final String reporte = _generarReporte();
    try {
      await ReportService.saveReport(nombre, reporte);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Reporte guardado como "$nombre" en Firebase'), backgroundColor: Colors.green),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _descargarPDF() async {
    final String reporte = _generarReporte();
    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    ));
    try {
      final File? archivo = await PDFService.generarPDF(reporte, 'computo_${DateTime.now().millisecondsSinceEpoch}');
      if (mounted) Navigator.pop(context);
      if (archivo != null) {
        await PDFService.abrirPDF(archivo);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ PDF guardado en: ${archivo.path}'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al generar PDF'), backgroundColor: Colors.red),
          );
        }
      }
    } on Exception catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _compartirPDF() async {
    final String reporte = _generarReporte();
    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    ));
    try {
      final File? archivo = await PDFService.generarPDF(reporte, 'computo_${DateTime.now().millisecondsSinceEpoch}_share');
      if (mounted) Navigator.pop(context);
      if (archivo != null) {
        await PDFService.compartirPDF(archivo);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Reporte PDF compartido'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Error al generar PDF para compartir'), backgroundColor: Colors.red),
          );
        }
      }
    } on Exception catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al compartir PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _copiarReporte() async {
    final String reporte = _generarReporte();
    try {
      await Clipboard.setData(ClipboardData(text: reporte));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Reporte copiado al portapapeles'), backgroundColor: Colors.green),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al copiar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String?> _mostrarDialogoNombre(String titulo, String hint) async {
    final TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Guardar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      drawer: const AppDrawer(currentRoute: "/computo"),
      backgroundColor: fondoPantalla,
      appBar: AppBar(
        title: const Text("CÓMPUTO", style: TextStyle(color: dorado, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
        backgroundColor: azulMarino,
        foregroundColor: dorado,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: double.infinity,
              margin: EdgeInsets.zero,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: azulMarino,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: dorado, width: 1.5),
                ),
                child: Column(
                  children: <Widget>[
                    const Text(
                      "FECHA CUMPLIMIENTO EST.",
                      style: TextStyle(color: dorado, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _sinDetenido || _fechaDetencion == null ? "Sin detención" : _formatearFecha(_fechaCumplimiento),
                      style: const TextStyle(color: dorado, fontSize: 28, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "TIEMPO DETENIDO",
                      style: TextStyle(color: dorado, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _sinDetenido || _fechaDetencion == null ? "No aplica" : _tiempoDetenido,
                      style: TextStyle(color: dorado.withValues(alpha: 0.85), fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "POR CUMPLIR",
                      style: TextStyle(color: dorado, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _sinDetenido || _fechaDetencion == null ? "No aplica" : _tiempoRestante,
                      style: TextStyle(color: dorado.withValues(alpha: 0.85), fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: dorado),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "FECHA DE DETENCIÓN",
                      style: TextStyle(color: azulMarino.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: CheckboxListTile(
                            title: Text("Sin detenido", style: TextStyle(color: azulMarino.withValues(alpha: 0.86))),
                            value: _sinDetenido,
                            onChanged: (bool? value) {
                              setState(() {
                                _sinDetenido = value ?? false;
                                if (_sinDetenido) {
                                  _fechaDetencion = null;
                                  _fechaDetencionController.clear();
                                  _calcularTodo();
                                } else {
                                  _calcularTodo();
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: dorado,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    if (!_sinDetenido) ...<Widget>[
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: GestureDetector(
                              onTap: () => unawaited(_seleccionarFecha(context, true)),
                              child: AbsorbPointer(
                                child: TextField(
                                  controller: _fechaDetencionController,
                                  decoration: InputDecoration(
                                    hintText: "DD/MM/AAAA",
                                    filled: true,
                                    fillColor: fondoPantalla,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: azulMarino.withValues(alpha: 0.18)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: azulMarino.withValues(alpha: 0.12)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: azulMarino.withValues(alpha: 0.35), width: 1.2),
                                    ),
                                    errorText: _fechaDetencionValida ? null : "Fecha inválida",
                                    suffixIcon: Icon(Icons.calendar_today_rounded, color: azulMarino.withValues(alpha: 0.70)),
                                  ),
                                  style: const TextStyle(color: azulMarino),
                                  onChanged: (String value) {
                                    _aplicarMascara(_fechaDetencionController, value);
                                    _validarFecha(_fechaDetencionController.text, true);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: dorado),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "FECHA DE CONDENA",
                      style: TextStyle(color: azulMarino.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: Text("Usar fecha actual", style: TextStyle(color: azulMarino.withValues(alpha: 0.86))),
                      value: _usarFechaActual,
                      onChanged: (bool value) {
                        setState(() {
                          _usarFechaActual = value;
                          if (_usarFechaActual) {
                            _fechaCondena = null;
                            _fechaCondenaController.clear();
                          }
                          _calcularTodo();
                        });
                      },
                      activeThumbColor: dorado,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (!_usarFechaActual) ...<Widget>[
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: GestureDetector(
                              onTap: () => unawaited(_seleccionarFecha(context, false)),
                              child: AbsorbPointer(
                                child: TextField(
                                  controller: _fechaCondenaController,
                                  decoration: InputDecoration(
                                    hintText: "DD/MM/AAAA",
                                    filled: true,
                                    fillColor: fondoPantalla,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: azulMarino.withValues(alpha: 0.18)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: azulMarino.withValues(alpha: 0.12)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: azulMarino.withValues(alpha: 0.35), width: 1.2),
                                    ),
                                    errorText: _fechaCondenaValida ? null : "Fecha inválida",
                                    suffixIcon: Icon(Icons.calendar_today_rounded, color: azulMarino.withValues(alpha: 0.70)),
                                  ),
                                  style: const TextStyle(color: azulMarino),
                                  onChanged: (String value) {
                                    _aplicarMascara(_fechaCondenaController, value);
                                    _validarFecha(_fechaCondenaController.text, false);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _buildActionChip(icon: Icons.save_rounded, label: "Guardar Datos", onPressed: _guardarCalculo),
                _buildActionChip(icon: Icons.description_rounded, label: "Guardar Reporte", onPressed: _guardarReporte),
                _buildActionChip(icon: Icons.picture_as_pdf_rounded, label: "PDF Descargar", onPressed: _descargarPDF),
                _buildActionChip(icon: Icons.share_rounded, label: "PDF Compartir", onPressed: _compartirPDF),
                _buildActionChip(icon: Icons.copy_rounded, label: "Copiar", onPressed: _copiarReporte),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("REGRESAR"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: azulMarino,
                      side: const BorderSide(color: dorado),
                      fixedSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (BuildContext context) => const DosimetriaPage()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    icon: const Icon(Icons.home),
                    label: const Text("INICIO"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azulMarino,
                      foregroundColor: dorado,
                      side: const BorderSide(color: dorado),
                      fixedSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) => ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 152),
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: azulMarino.withValues(alpha: 0.08),
          foregroundColor: azulMarino,
          side: const BorderSide(color: dorado),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
      ),
    );
}
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../logic/report_generator.dart';
import '../models/calculation_model.dart';
import '../models/delito.dart';
import '../services/pdf_service.dart';
import '../utils/storage_manager.dart';
import '../widgets/app_drawer.dart';
import 'dosimetria_page.dart';

class ComputoPage extends StatefulWidget {

  const ComputoPage({
    required this.delitos, required this.concurso, required this.admisionHechos, required this.fraccionAdmision, required this.penaTotal, this.articuloConcurso = '', super.key,
  });
  final List<Delito> delitos;
  final TipoConcurso concurso;
  final bool admisionHechos;
  final double fraccionAdmision;
  final double penaTotal;
  final String articuloConcurso;

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
  // Datos del caso
  final TextEditingController _expedienteController = TextEditingController();
  final TextEditingController _acusadoController = TextEditingController();

  // Fechas
  bool _sinDetenido = false;
  DateTime? _fechaDetencion;
  DateTime? _fechaCondena;
  bool _usarFechaActual = true;
  DateTime _fechaCumplimiento = DateTime.now();
  String _tiempoDetenido = '';
  String _tiempoRestante = '';

  // Controladores y validación
  final TextEditingController _fechaDetencionController = TextEditingController();
  final TextEditingController _fechaCondenaController = TextEditingController();
  bool _fechaDetencionValida = true;
  bool _fechaCondenaValida = true;

  // Colores
  static const Color fondoPantalla = Color(0xFFF1F5F9);
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color grisTexto = Color(0xFF4A5568);
  static const Color borde = Color(0x1A0F172A); // azul marino con baja opacidad

  final StorageManager _storageManager = StorageManager();

  @override
  void initState() {
    super.initState();
    // Inicializamos todas las variables de fecha para evitar LateInitializationError
    _fechaCumplimiento = DateTime.now();
    _tiempoDetenido = '0 años, 0 meses, 0 días';
    _tiempoRestante = '0 años, 0 meses, 0 días';
    // Si hay fecha de detención previa, se podría cargar, pero no es el caso.
  }

  @override
  void dispose() {
    _expedienteController.dispose();
    _acusadoController.dispose();
    _fechaDetencionController.dispose();
    _fechaCondenaController.dispose();
    super.dispose();
  }

  // ==================== MÉTODOS DE CÁLCULO ====================

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

    final diferencia = _diferenciaComercial(_fechaDetencion!, hasta);
    _tiempoDetenido = _formatearDuracion(diferencia[0], diferencia[1], diferencia[2]);

    _fechaCumplimiento = _sumarPena(_fechaDetencion!, widget.penaTotal);

    final diferenciaRestante = _diferenciaComercial(hasta, _fechaCumplimiento);
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
    return [years, months, days];
  }

  String _formatearDuracion(int years, int months, int days) {
    return '$years años, $months meses, $days días';
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

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  DateTime? _parsearFecha(String texto) {
    try {
      final partes = texto.split('/');
      if (partes.length != 3) return null;
      final dia = int.tryParse(partes[0]);
      final mes = int.tryParse(partes[1]);
      final anio = int.tryParse(partes[2]);
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

    final fecha = _parsearFecha(texto);
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
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < limpio.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(limpio[i]);
    }
    String formateado = buffer.toString();
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
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: azulMarino), dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
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

  // ==================== MÉTODOS DE ACCIÓN ====================

  Future<pw.Document> _generarReportePDF() async {
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
    
    final expediente = _expedienteController.text.trim().isEmpty 
        ? 'S/N' 
        : _expedienteController.text.trim();
    final acusado = _acusadoController.text.trim().isEmpty 
        ? 'No especificado' 
        : _acusadoController.text.trim();
    
    return await ReportGenerator.generarReportePDF(
      delitos: widget.delitos,
      concurso: widget.concurso,
      admisionHechos: widget.admisionHechos,
      fraccionAdmision: widget.fraccionAdmision,
      computo: computoData,
      expediente: expediente,
      acusado: acusado,
      articuloConcurso: widget.articuloConcurso, // Pasar el artículo desde ConcursoPage
    );
  }

  String _generarReporte() {
    // Generar reporte en texto para guardar/copiar
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('INFORME TÉCNICO DE DOSIMETRÍA JURÍDICA');
    buffer.writeln('=====================================\n');
    
    buffer.writeln('Expediente: ${_expedienteController.text.trim().isEmpty ? "S/N" : _expedienteController.text.trim()}');
    buffer.writeln('Acusado(s): ${_acusadoController.text.trim().isEmpty ? "No especificado" : _acusadoController.text.trim()}\n');
    
    buffer.writeln('FECHA CUMPLIMIENTO ESTIMADA:');
    buffer.writeln(_sinDetenido || _fechaDetencion == null 
        ? 'Sin detención registrada' 
        : _formatearFecha(_fechaCumplimiento));
    buffer.writeln();
    
    buffer.writeln('TIEMPO DETENIDO: ${_sinDetenido || _fechaDetencion == null ? "No aplica" : _tiempoDetenido}');
    buffer.writeln('TIEMPO POR CUMPLIR: ${_sinDetenido || _fechaDetencion == null ? "No aplica" : _tiempoRestante}');
    
    return buffer.toString();
  }

  Future<void> _guardarCalculo() async {
    final nombre = await _mostrarDialogoNombre('Guardar cálculo', 'Nombre del cálculo');
    if (nombre == null || nombre.isEmpty) return;
    final calculation = CalculationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: nombre,
      fecha: DateTime.now(),
      delitos: widget.delitos.map((d) => Delito.fromMap(d.toMap())).toList(),
      concurso: widget.concurso,
      admisionHechos: widget.admisionHechos,
      fraccionAdmision: widget.fraccionAdmision,
    );
    await _storageManager.saveCalculation(calculation);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Cálculo "$nombre" guardado'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _descargarPDF() async {
    final pdfDoc = await _generarReportePDF();
    
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    ));
    try {
      // Guardar el PDF localmente
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download/Penalex_VE');
      } else {
        final docDir = await getApplicationDocumentsDirectory();
        directory = Directory('${docDir.path}/Penalex_VE');
      }
      
      if (!directory.existsSync()) await directory.create(recursive: true);
      final fileName = 'Dosimetria_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdfDoc.save());
      
      if (mounted) Navigator.pop(context);
      
      // Abrir PDF
      await PDFService.abrirPDF(file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF guardado en: ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
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
    final pdfDoc = await _generarReportePDF();
    
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    ));
    try {
      // Guardar temporalmente para compartir
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/computo_share.pdf');
      await file.writeAsBytes(await pdfDoc.save());
      
      if (mounted) Navigator.pop(context);
      await PDFService.compartirPDF(file);
    } on Exception catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _copiarReporte() async {
    final reporte = _generarReporte();
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
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Guardar')),
        ],
      ),
    );
  }

  // ==================== WIDGETS UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/computo'),
      backgroundColor: fondoPantalla,
      appBar: AppBar(
        title: const Text('CÓMPUTO', style: TextStyle(color: dorado, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
        backgroundColor: azulMarino,
        foregroundColor: dorado,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== 0. DATOS DEL CASO ====================
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: borde),
              ),
              color: Colors.white,
              surfaceTintColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.folder_outlined, color: azulMarino.withValues(alpha: 0.7), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'DATOS DEL CASO',
                          style: TextStyle(
                            color: azulMarino.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo Expediente
                    TextField(
                      controller: _expedienteController,
                      decoration: InputDecoration(
                        labelText: 'Nº de Expediente',
                        hintText: 'Ej: 123-2024',
                        prefixIcon: const Icon(Icons.numbers_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: azulMarino.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: azulMarino, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo Acusado
                    TextField(
                      controller: _acusadoController,
                      decoration: InputDecoration(
                        labelText: 'Acusado(s) / Justiciable(s)',
                        hintText: 'Nombre completo del acusado',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: azulMarino.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: azulMarino, width: 2),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Estos datos aparecerán en el informe PDF',
                      style: TextStyle(
                        color: grisTexto.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // ==================== 1. TARJETA DE RESULTADOS ====================
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    azulMarino,
                    azulMarino.withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: azulMarino.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Icono decorativo
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: dorado.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: dorado, width: 2),
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        color: dorado,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Título
                    Text(
                      'FECHA CUMPLIMIENTO ESTIMADA',
                      style: TextStyle(
                        color: dorado.withValues(alpha: 0.95),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    
                    // Fecha principal
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: dorado.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _sinDetenido || _fechaDetencion == null
                            ? 'Sin detención registrada'
                            : _formatearFecha(_fechaCumplimiento),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Divider decorativo
                    Row(
                      children: [
                        Expanded(child: Divider(color: dorado.withValues(alpha: 0.3), thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.timer_outlined, color: dorado.withValues(alpha: 0.7), size: 18),
                        ),
                        Expanded(child: Divider(color: dorado.withValues(alpha: 0.3), thickness: 1)),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Tiempo detenido
                    _buildInfoRow(
                      icon: Icons.lock_clock_rounded,
                      label: 'TIEMPO DETENIDO',
                      value: _sinDetenido || _fechaDetencion == null ? 'No aplica' : _tiempoDetenido,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Tiempo por cumplir
                    _buildInfoRow(
                      icon: Icons.hourglass_bottom_rounded,
                      label: 'TIEMPO POR CUMPLIR',
                      value: _sinDetenido || _fechaDetencion == null ? 'No aplica' : _tiempoRestante,
                      isHighlight: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ==================== 2. SECCIÓN DE FECHAS ====================
            // Bloque A: FECHA DE DETENCIÓN
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: borde),
              ),
              color: Colors.white,
              surfaceTintColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FECHA DE DETENCIÓN',
                      style: TextStyle(
                        color: azulMarino.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: Text('Sin detenido', style: TextStyle(color: azulMarino.withValues(alpha: 0.86))),
                            value: _sinDetenido,
                            onChanged: (value) {
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
                    if (!_sinDetenido) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _seleccionarFecha(context, true),
                              child: AbsorbPointer(
                                child: TextField(
                                  controller: _fechaDetencionController,
                                  decoration: InputDecoration(
                                    hintText: 'DD/MM/AAAA',
                                    filled: true,
                                    fillColor: fondoPantalla,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: azulMarino.withValues(alpha: 0.18))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: azulMarino.withValues(alpha: 0.12))),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: azulMarino.withValues(alpha: 0.35), width: 1.2)),
                                    errorText: _fechaDetencionValida ? null : 'Fecha inválida',
                                    suffixIcon: Icon(Icons.calendar_today_rounded, color: azulMarino.withValues(alpha: 0.70)),
                                  ),
                                  style: const TextStyle(color: azulMarino),
                                  onChanged: (value) {
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

            // Bloque B: FECHA DE CONDENA
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: borde),
              ),
              color: Colors.white,
              surfaceTintColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FECHA DE CONDENA',
                      style: TextStyle(
                        color: azulMarino.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: Text('Usar fecha actual', style: TextStyle(color: azulMarino.withValues(alpha: 0.86))),
                      value: _usarFechaActual,
                      onChanged: (value) {
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
                    if (!_usarFechaActual) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _seleccionarFecha(context, false),
                              child: AbsorbPointer(
                                child: TextField(
                                  controller: _fechaCondenaController,
                                  decoration: InputDecoration(
                                    hintText: 'DD/MM/AAAA',
                                    filled: true,
                                    fillColor: fondoPantalla,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: azulMarino.withValues(alpha: 0.18))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: azulMarino.withValues(alpha: 0.12))),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: azulMarino.withValues(alpha: 0.35), width: 1.2)),
                                    errorText: _fechaCondenaValida ? null : 'Fecha inválida',
                                    suffixIcon: Icon(Icons.calendar_today_rounded, color: azulMarino.withValues(alpha: 0.70)),
                                  ),
                                  style: const TextStyle(color: azulMarino),
                                  onChanged: (value) {
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

            // ==================== 3. FILA DE ACCIONES (4 BOTONES) ====================
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildActionChip(
                  icon: Icons.save_rounded,
                  label: 'Guardar Datos',
                  onPressed: _guardarCalculo,
                ),
                _buildActionChip(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'PDF Descargar',
                  onPressed: _descargarPDF,
                ),
                _buildActionChip(
                  icon: Icons.share_rounded,
                  label: 'PDF Compartir',
                  onPressed: _compartirPDF,
                ),
                _buildActionChip(
                  icon: Icons.copy_rounded,
                  label: 'Copiar',
                  onPressed: _copiarReporte,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ==================== 4. FOOTER (BOTONES GEMELOS) ====================
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('REGRESAR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: azulMarino,
                      fixedSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: azulMarino.withValues(alpha: 0.18)),
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
                        MaterialPageRoute(builder: (context) => const DosimetriaPage()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('INICIO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azulMarino,
                      foregroundColor: dorado,
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
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 152),
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: azulMarino.withValues(alpha: 0.08),
          foregroundColor: azulMarino,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlight 
            ? dorado.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight 
              ? dorado.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isHighlight ? dorado : Colors.white.withValues(alpha: 0.85),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isHighlight 
                        ? dorado.withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.70),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isHighlight ? 16 : 15,
                    fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
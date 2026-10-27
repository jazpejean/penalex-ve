import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/prescripcion_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/main_bottom_bar.dart';
import 'redactor_documentos_screen.dart';

/// Calculadora de Prescripción Penal (arts. 108 y 112 CP).
///
/// Cálculo determinístico: la IA no interviene en términos ni fechas.
class CalculadoraPrescripcionScreen extends StatefulWidget {
  const CalculadoraPrescripcionScreen({super.key});

  @override
  State<CalculadoraPrescripcionScreen> createState() =>
      _CalculadoraPrescripcionScreenState();
}

class _CalculadoraPrescripcionScreenState
    extends State<CalculadoraPrescripcionScreen> {
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color grisOscuro = Color(0xFF1E293B);

  bool _modoPena = false; // false = acción penal (art. 108), true = pena (art. 112)
  TipoPenaPrescripcion _tipo = TipoPenaPrescripcion.prision;

  final TextEditingController _penaController = TextEditingController();
  final TextEditingController _arrestoController = TextEditingController();
  final TextEditingController _multaController = TextEditingController();

  DateTime _fechaBase = DateTime.now();
  TerminoPrescripcion? _termino;
  DateTime? _fechaPrescripcion;
  int? _diasRestantes;

  @override
  void dispose() {
    _penaController.dispose();
    _arrestoController.dispose();
    _multaController.dispose();
    super.dispose();
  }

  void _calcular() {
    final TerminoPrescripcion termino;
    if (_modoPena) {
      final pena = double.tryParse(
              _penaController.text.trim().replaceAll(',', '.')) ??
          0;
      if (pena <= 0) {
        _mostrarAviso('Ingresa la pena impuesta en años (ej. 12.5).');
        return;
      }
      termino = PrescripcionService.terminoPenaArt112(penaAnios: pena);
    } else {
      switch (_tipo) {
        case TipoPenaPrescripcion.prision:
          final pena = double.tryParse(
                  _penaController.text.trim().replaceAll(',', '.')) ??
              0;
          if (pena <= 0) {
            _mostrarAviso(
                'Ingresa la pena máxima del delito en años (ej. 12.5).');
            return;
          }
          termino = PrescripcionService.terminoAccionPenal(
              tipo: _tipo, penaMaxAnios: pena);
        case TipoPenaPrescripcion.arresto:
          final meses = double.tryParse(
                  _arrestoController.text.trim().replaceAll(',', '.')) ??
              0;
          if (meses <= 0) {
            _mostrarAviso('Ingresa la duración del arresto en meses.');
            return;
          }
          termino = PrescripcionService.terminoAccionPenal(
              tipo: _tipo, arrestoMeses: meses);
        case TipoPenaPrescripcion.multa:
          final ut = double.tryParse(
                  _multaController.text.trim().replaceAll(',', '.')) ??
              0;
          if (ut <= 0) {
            _mostrarAviso('Ingresa el monto de la multa en U.T.');
            return;
          }
          termino = PrescripcionService.terminoAccionPenal(
              tipo: _tipo, multaUt: ut);
      }
    }

    final fecha = PrescripcionService.fechaPrescripcion(_fechaBase, termino);
    final dias = PrescripcionService.diasRestantes(fecha, DateTime.now());
    setState(() {
      _termino = termino;
      _fechaPrescripcion = fecha;
      _diasRestantes = dias;
    });
  }

  void _mostrarAviso(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('⚠️ $mensaje')),
    );
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaBase,
      firstDate: DateTime(hoy.year - 30),
      lastDate: hoy,
      helpText: 'Fecha del hecho / última actuación',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: dorado,
            surface: grisOscuro,
          ),
        ),
        child: child!,
      ),
    );
    if (seleccionada != null) {
      setState(() => _fechaBase = seleccionada);
    }
  }

  void _redactarSolicitud() {
    if (_termino == null || _fechaPrescripcion == null) return;
    final contexto = '''
Redacta una solicitud de prescripción de la acción penal conforme al Código Penal venezolano.

Contexto del caso:
- Término de prescripción aplicable: ${_termino!.tituloLargo} (${_termino!.fundamento}).
- Fecha de inicio del cómputo (art. 109 CP): ${DateFormat('dd/MM/yyyy').format(_fechaBase)}.
- Fecha en que se completa el término: ${DateFormat('dd/MM/yyyy').format(_fechaPrescripcion!)}.
- ${_termino!.textoOrdinal != null ? 'Texto del numeral: ${_termino!.textoOrdinal}' : ''}

Estructura: identificación de la causa y las partes, fundamentos de hecho (fecha del hecho y tiempo transcurrido), fundamentos de derecho (art. 108 CP, numeral aplicable, con jurisprudencia de la Sala de Casación Penal si está disponible), y petitorio de declaratoria de prescripción. Deja [DATOS DEL CASO] donde falten datos. No inventes jurisprudencia.
''';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RedactorDocumentosScreen(initialPrompt: contexto.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/calculadora_prescripcion'),
      backgroundColor: azulMarino,
      bottomNavigationBar: const MainBottomBar(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            color: dorado,
            tooltip: 'Menú',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Calculadora de Prescripción',
          style: TextStyle(color: dorado, fontWeight: FontWeight.bold),
        ),
        backgroundColor: azulMarino,
        elevation: 0,
        iconTheme: const IconThemeData(color: dorado),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModoSelector(),
            const SizedBox(height: 20),
            _buildInputs(),
            const SizedBox(height: 24),
            _buildCalcularButton(),
            if (_termino != null) ...[
              const SizedBox(height: 28),
              _buildResultado(),
            ],
            const SizedBox(height: 28),
            _buildReglas(),
          ],
        ),
      ),
    );
  }

  Widget _buildModoSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: grisOscuro,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Qué prescripción calculas?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildModoButton(
                  'Acción penal (art. 108)',
                  !_modoPena,
                  () => setState(() => _modoPena = false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildModoButton(
                  'Pena (art. 112)',
                  _modoPena,
                  () => setState(() => _modoPena = true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModoButton(String label, bool activo, VoidCallback onTap) {
    return Material(
      color: activo ? dorado : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: dorado.withValues(alpha: 0.4)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: activo ? azulMarino : Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputs() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: grisOscuro,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_modoPena && _tipo != TipoPenaPrescripcion.prision) ...[
            Text(
              'Tipo de pena',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            _buildTipoSelector(),
            const SizedBox(height: 16),
          ],
          if (_modoPena || _tipo == TipoPenaPrescripcion.prision) ...[
            Text(
              _modoPena
                  ? 'Pena impuesta (años, ej. 12.5)'
                  : 'Pena máxima del delito (años, ej. 12.5)',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _penaController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Ej. 12.5'),
            ),
            const SizedBox(height: 16),
          ],
          if (!_modoPena && _tipo == TipoPenaPrescripcion.arresto) ...[
            Text(
              'Duración del arresto (meses)',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _arrestoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Ej. 3'),
            ),
            const SizedBox(height: 16),
          ],
          if (!_modoPena && _tipo == TipoPenaPrescripcion.multa) ...[
            Text(
              'Monto de la multa (U.T.)',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _multaController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Ej. 200'),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Fecha del hecho / última actuación (art. 109 CP)',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Material(
            color: azulMarino,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _elegirFecha,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dorado.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: dorado, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('dd/MM/yyyy').format(_fechaBase),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
      filled: true,
      fillColor: azulMarino,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dorado.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dorado.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildTipoSelector() {
    final opciones = [
      (TipoPenaPrescripcion.prision, 'Prisión'),
      (TipoPenaPrescripcion.arresto, 'Arresto'),
      (TipoPenaPrescripcion.multa, 'Multa'),
    ];
    return Row(
      children: opciones.map((o) {
        final activo = _tipo == o.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: activo ? dorado : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _tipo = o.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: dorado.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    o.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: activo ? azulMarino : Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalcularButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _calcular,
        icon: const Icon(Icons.calculate),
        label: const Text('Calcular prescripción'),
        style: ElevatedButton.styleFrom(
          backgroundColor: dorado,
          foregroundColor: azulMarino,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildResultado() {
    final termino = _termino!;
    final fecha = _fechaPrescripcion!;
    final dias = _diasRestantes ?? 0;
    final prescrita = dias <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resultado',
          style: TextStyle(
            color: dorado,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: prescrita
                ? const Color(0xFFB91C1C).withValues(alpha: 0.85)
                : grisOscuro,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: prescrita ? const Color(0xFFEF4444) : dorado,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Término: ${termino.tituloLargo}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                termino.fundamento,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildFilaResultado(
                'Fecha de prescripción',
                DateFormat('dd/MM/yyyy').format(fecha),
                Icons.event_available,
              ),
              const SizedBox(height: 8),
              _buildFilaResultado(
                prescrita
                    ? 'Estado'
                    : 'Días restantes',
                prescrita
                    ? '¡PRESCRITA!'
                    : '$dias días',
                prescrita ? Icons.verified : Icons.timer,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (termino.textoOrdinal != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: azulMarino,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: dorado.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fundamento textual',
                  style: TextStyle(
                    color: dorado,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  termino.textoOrdinal!,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _redactarSolicitud,
            icon: const Icon(Icons.edit_document),
            label: const Text('Redactar solicitud de prescripción'),
            style: OutlinedButton.styleFrom(
              foregroundColor: dorado,
              side: BorderSide(color: dorado.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilaResultado(String label, String valor, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: dorado, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
        ),
        const Spacer(),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildReglas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reglas del cómputo',
          style: TextStyle(
            color: dorado,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildReglaCard(
          Icons.play_circle_outline,
          'Inicio del cómputo',
          PrescripcionService.reglaInicio109,
        ),
        const SizedBox(height: 10),
        _buildReglaCard(
          Icons.refresh,
          'Interrupción',
          PrescripcionService.reglaInterrupcion110,
        ),
        const SizedBox(height: 12),
        Text(
          'Cálculo orientativo: verifica el numeral aplicable y las causales '
          'de interrupción/suspensión de tu causa antes de invocarla.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildReglaCard(IconData icon, String titulo, String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: grisOscuro,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: dorado, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  texto,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12.5,
                    height: 1.4,
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
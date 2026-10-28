/// Calendario Judicial — línea de tiempo guiada de lapsos procesales
/// DE UN EXPEDIENTE AGENDADO (se abre desde la Agenda, en la tarjeta de
/// la audiencia). Decisión del usuario: los lapsos se muestran en cada
/// expediente agendado; no hay pestañas ni pantalla global.
///
/// Flujo dirigido por el usuario (decisión de diseño confirmada):
///  - Paso 1: elegir la vía (ordinario / violencia / menos graves).
///  - Paso 2: la fecha base viene precargada con la fecha de la audiencia
///    agendada (la de presentación, la primera que se agenda); el abogado
///    puede corregirla si es necesario.
///  - Paso 3: el abogado marca cada acto posterior (acusación, preliminar,
///    recepción del expediente en el tribunal de juicio, sentencia…) y el
///    motor calcula los lapsos que corren desde esa fecha real.
///
/// Reglas: cómputo continuo / hábil / despacho (Art. 156 COPP), con
/// recálculo automático al marcar días sin despacho (feriados judiciales
/// + días sin despacho del usuario en Supabase). EXCLUYE ejecución de la
/// pena (sección 9 de la Guía de Lapsos), por decisión del usuario.
library;

import 'package:flutter/material.dart';
import '../widgets/app_bar_institucional.dart';

import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../logic/lapsos_engine.dart';
import '../logic/secuencia_procesal.dart';
import '../models/audiencia.dart';
import '../models/lapso_procesal.dart';
import '../services/agenda_service.dart';
import '../services/haptics_service.dart';
import '../services/non_working_day_service.dart';
import '../utils/non_working_days.dart';

/// Lapsos de UN expediente agendado. Se abre desde la tarjeta de la
/// audiencia en la Agenda; `fechaBase` es la fecha de esa audiencia
/// (la presentación es la primera que se agenda).
class CalendarioJudicialScreen extends StatefulWidget {
  const CalendarioJudicialScreen({
    super.key,
    required this.expediente,
    required this.imputado,
    this.fechaBase,
    this.tribunalId,
    this.viaInicial = ViaProcesal.ordinario,
  });

  /// Número de expediente agendado (se usa al agendar hitos).
  final String expediente;

  /// Nombre del imputado/acusado.
  final String imputado;

  /// Fecha de la audiencia agendada (base del cómputo). Si es null,
  /// el abogado la indica al abrir.
  final DateTime? fechaBase;

  /// Tribunal del expediente: los días sin despacho asociados a OTRO
  /// tribunal no se excluyen del cómputo (solo los globales y los de
  /// este tribunal).
  final String? tribunalId;

  /// Vía procesal con la que inicia (por defecto ordinario).
  final ViaProcesal viaInicial;

  @override
  State<CalendarioJudicialScreen> createState() =>
      _CalendarioJudicialScreenState();
}

class _CalendarioJudicialScreenState extends State<CalendarioJudicialScreen> {
  
  late ViaProcesal _via = widget.viaInicial;

  /// Fecha de la audiencia de presentación (fecha base del calendario).
  DateTime? _fechaPresentacion;

  /// Fechas reales marcadas por el abogado para cada gatillo
  /// (clave = Gatillos.*). El motor calcula los lapsos que dependen de
  /// ellas SOLO cuando existen.
  final Map<String, DateTime> _fechasGatillo = <String, DateTime>{};

  /// Días excluidos del cómputo hábil/despacho: feriados judiciales
  /// nacionales + días sin despacho del usuario (Supabase).
  Set<DateTime> _excluidos = <DateTime>{};

  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // La fecha base viene de la audiencia agendada (presentación).
    _fechaPresentacion = widget.fechaBase != null
        ? fechaPura(widget.fechaBase!)
        : null;
    _cargarDiasExcluidos();
  }

  Future<void> _cargarDiasExcluidos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final List<NonWorkingDay> feriados = getAllNonWorkingDays();
      final List<NonWorkingDay> usuario =
          await NonWorkingDayService.loadUserNonWorkingDays();
      // Días sin despacho del usuario: aplican SOLO si son globales
      // (sin tribunal) o pertenecen al tribunal de este expediente.
      final List<NonWorkingDay> aplicables = usuario.where((n) =>
          n.tribunalId == null ||
          (widget.tribunalId != null && n.tribunalId == widget.tribunalId)).toList();
      final List<DateTime> fechas = <DateTime>[
        ...feriados.map((n) => n.date),
        ...aplicables.map((n) => n.date),
      ];
      setState(() {
        _excluidos = fechasExcluidasDe(fechas);
        _cargando = false;
      });
    } on Exception catch (e) {
      setState(() {
        _error = 'No se pudieron cargar los días sin despacho: $e';
        _cargando = false;
      });
    }
  }

  /// Recalcula con los días sin despacho más recientes (se llama al
  /// volver de marcar un día sin despacho en la agenda o manualmente).
  Future<void> _recargarExcluidos() => _cargarDiasExcluidos();

  // ─────────────────────────── cálculo ──────────────────────────────

  List<HitoCalculado> _hitos() {
    if (_fechaPresentacion == null) {
      return <HitoCalculado>[];
    }
    final List<HitoCalculado> base = generarHitosIniciales(
      via: _via,
      fechaBase: _fechaPresentacion!,
      excluidos: _excluidos,
    );
    // Reemplaza los hitos pendientes cuyos gatillos ya tienen fecha real.
    final List<HitoCalculado> result = <HitoCalculado>[];
    for (final HitoCalculado h in base) {
      final String? gatillo = h.lapso.gatillo;
      if (gatillo != null && _fechasGatillo.containsKey(gatillo)) {
        result.add(calcularHito(
          lapso: h.lapso as LapsoCatalogo,
          fechaBase: _fechasGatillo[gatillo]!,
          excluidos: _excluidos,
        ));
      } else {
        result.add(h);
      }
    }
    return result;
  }

  // ─────────────────────────── UI helpers ───────────────────────────

  String _nombreGatillo(String gatillo) {
    switch (gatillo) {
      case Gatillos.acusacion:
        return 'acusación presentada';
      case Gatillos.preliminar:
        return 'audiencia preliminar fijada';
      case Gatillos.autoApertura:
        return 'auto de apertura';
      case Gatillos.recepcionExpediente:
        return 'recepción del expediente en el tribunal de juicio';
      case Gatillos.juicioInicio:
        return 'inicio del juicio oral';
      case Gatillos.sentencia:
        return 'sentencia dictada';
      case Gatillos.decisionInterlocutoria:
        return 'decisión interlocutoria';
      case Gatillos.interposicionApelacionAutos:
        return 'interposición de la apelación de autos';
      default:
        return gatillo;
    }
  }

  String _labelUnidad(UnidadLapso u, int cantidad) {
    switch (u) {
      case UnidadLapso.horas:
        return cantidad == 1 ? 'hora' : 'horas';
      case UnidadLapso.dias:
        return cantidad == 1 ? 'día' : 'días';
      case UnidadLapso.meses:
        return cantidad == 1 ? 'mes' : 'meses';
      case UnidadLapso.anos:
        return cantidad == 1 ? 'año' : 'años';
    }
  }

  String _labelComputo(TipoComputo c) {
    switch (c) {
      case TipoComputo.continuo:
        return 'continuo';
      case TipoComputo.habiles:
        return 'días hábiles';
      case TipoComputo.despacho:
        return 'días de despacho';
    }
  }

  String _textoLapso(LapsoProcesal l) {
    final String unidad = _labelUnidad(l.unidad, l.cantidadMin ?? 1);
    final String computo = _labelComputo(l.computo);
    final String rango = l.cantidadMax != null && l.cantidadMax != l.cantidadMin
        ? '${l.cantidadMin}–${l.cantidadMax} $unidad'
        : '${l.cantidadMin ?? ''} $unidad'.trim();
    final String antelacion = l.antelacion ? ' (hasta ANTES del acto)' : '';
    return '$rango $computo$antelacion';
  }

  String _fechasHito(HitoCalculado h) {
    if (h.pendienteDe != null) {
      return 'Pendiente: ${_nombreGatillo(h.pendienteDe!)}';
    }
    final String fMin =
        _fmt(h.fechaMin ?? h.fechaBase);
    if (h.fechaMax != null && h.fechaMax != h.fechaMin) {
      return 'Entre $fMin y ${_fmt(h.fechaMax!)}';
    }
    return 'Límite: $fMin';
  }

  String _fmt(DateTime d) {
    final String dia = d.day.toString().padLeft(2, '0');
    final String mes = d.month.toString().padLeft(2, '0');
    return '$dia/$mes/${d.year}';
  }

  Future<void> _marcarGatillo(LapsoProcesal lapso) async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: _fechaPresentacion ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Fecha real del acto: ${_nombreGatillo(lapso.gatillo!)}',
    );
    if (fecha == null || !mounted) return;
    setState(() {
      _fechasGatillo[lapso.gatillo!] = fecha;
    });
    Haptics.tap();
  }

  Future<void> _agendarHito(HitoCalculado h) async {
    if (h.fechaMin == null) return;
    final bool ok = await AgendaService.crearAudiencia(Audiencia(
      id: '',
      expediente: widget.expediente,
      tribunal: 'Calendario Judicial',
      imputado: '${widget.imputado} — ${h.lapso.acto}',
      cedula: null,
      fiscalia: null,
      delitos: h.lapso.baseLegal,
      fecha: h.fechaMin!,
      hora: '00:00',
      tipo: 'Lapso procesal',
      notas: '${_textoLapso(h.lapso)} — ${h.lapso.descripcion ?? ''}',
      recordatorioMinutos: 0,
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Hito agendado: ${_fmt(h.fechaMin!)}'
          : 'No se pudo agendar (sesión o conexión)'),
      backgroundColor: ok ? TemaGlobal.dorado : AppColors.error,
    ));
  }

  // ─────────────────────────── build ────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final List<HitoCalculado> hitos = _hitos();
    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
            appBar: AppBarInstitucional(
        title: 'Lapsos del expediente',
        mostrarBack: true,
        mostrarHome: true,
      ),
      body: RefreshIndicator(
        onRefresh: _recargarExcluidos,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            // Cabecera del expediente agendado.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TemaGlobal.tarjeta,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: TemaGlobal.capa, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.expediente.isEmpty
                        ? 'Expediente sin número'
                        : 'Expediente ${widget.expediente}',
                    style: TextStyle(
                      color: TemaGlobal.texto,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.imputado.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      widget.imputado,
                      style: TextStyle(
                        color: TemaGlobal.textoSecundario,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Lapsos procesales',
              style: TextStyle(
                color: AppColors.acento,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Desde la audiencia de presentación (${_fechaPresentacion != null ? _fmt(_fechaPresentacion!) : 'sin fecha aún'}). '
              'Excluye la fase de ejecución de la pena.',
              style: TextStyle(
                color: TemaGlobal.textoSecundario,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            _buildViaSelector(),
            const SizedBox(height: 12),
          _buildFechaPresentacion(),
          if (_cargando)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _buildError()
          else if (_fechaPresentacion == null)
            _buildIntro()
          else
            ..._buildHitos(hitos),
        ],
        ),
      ),
    );
  }

  Widget _buildViaSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Procedimiento (vía)',
          style: TextStyle(
              color: TemaGlobal.textoSecundario,
              fontSize: 13,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: <Widget>[
            _chipVia(ViaProcesal.ordinario, 'Ordinario'),
            _chipVia(ViaProcesal.violencia, 'Violencia'),
            _chipVia(ViaProcesal.menosGraves, 'Menos graves'),
          ],
        ),
      ],
    );
  }

  Widget _chipVia(ViaProcesal via, String label) {
    final bool activo = _via == via;
    return ChoiceChip(
      label: Text(label),
      selected: activo,
      selectedColor: TemaGlobal.dorado,
      backgroundColor: TemaGlobal.tarjeta,
      labelStyle: TextStyle(
        color: activo ? TemaGlobal.azulMarino : TemaGlobal.texto,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (_) {
        setState(() => _via = via);
        Haptics.tap();
      },
    );
  }

  Widget _buildFechaPresentacion() {
    return Card(
      color: TemaGlobal.tarjeta,
      child: ListTile(
        leading: Icon(Icons.event, color: TemaGlobal.azulMarino),
        title: Text('Audiencia de Presentación',
            style: TextStyle(color: TemaGlobal.texto, fontWeight: FontWeight.bold)),
        subtitle: Text(
          _fechaPresentacion == null
              ? 'Toca para fijar la fecha base'
              : 'Fecha base (agendada): ${_fmt(_fechaPresentacion!)} — toca para corregir',
          style: TextStyle(color: TemaGlobal.textoSecundario),
        ),
        trailing: Icon(Icons.edit_calendar, color: TemaGlobal.textoSecundario),
        onTap: _seleccionarFechaPresentacion,
      ),
    );
  }

  Future<void> _seleccionarFechaPresentacion() async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: _fechaPresentacion ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Fecha de la audiencia de presentación',
    );
    if (fecha == null || !mounted) return;
    setState(() {
      _fechaPresentacion = fecha;
      _fechasGatillo.clear();
    });
    Haptics.tap();
  }

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 8),
      child: Column(
        children: <Widget>[
          Icon(Icons.timeline, size: 64, color: TemaGlobal.azulMarino),
          const SizedBox(height: 16),
          Text(
            'El calendario parte de la audiencia de presentación.\n'
            'Fija esa fecha y el motor calculará los lapsos '
            'hacia adelante (excluye ejecución de la pena).',
            textAlign: TextAlign.center,
            style: TextStyle(color: TemaGlobal.textoSecundario, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          Icon(Icons.cloud_off, size: 48, color: TemaGlobal.textoSecundario),
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: TemaGlobal.textoSecundario)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargarDiasExcluidos,
            style: ElevatedButton.styleFrom(
              backgroundColor: TemaGlobal.azulMarino,
              foregroundColor: TemaGlobal.dorado,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHitos(List<HitoCalculado> hitos) {
    final List<Widget> widgets = <Widget>[];
    String? faseActual;
    for (final HitoCalculado h in hitos) {
      if (h.lapso.fase != faseActual) {
        faseActual = h.lapso.fase;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(
            faseActual,
            style: TextStyle(
              color: AppColors.acento,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ));
      }
      widgets.add(_buildHitoCard(h));
    }
    widgets.add(Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextButton.icon(
        onPressed: () {
          // Recalcula con los días sin despacho actualizados de la agenda.
          _recargarExcluidos();
        },
        icon: Icon(Icons.refresh, color: TemaGlobal.azulMarino),
        label: Text('Recalcular (días sin despacho)',
            style: TextStyle(color: TemaGlobal.azulMarino)),
      ),
    ));
    return widgets;
  }

  Widget _buildHitoCard(HitoCalculado h) {
    final LapsoProcesal l = h.lapso;
    final bool pendiente = h.pendienteDe != null;
    final bool esGatillo = l.gatillo != null;
    return Card(
      color: TemaGlobal.tarjeta,
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        leading: Icon(
          pendiente ? Icons.schedule : Icons.check_circle_outline,
          color: pendiente ? TemaGlobal.textoSecundario : TemaGlobal.azulMarino,
        ),
        title: Text(l.acto,
            style: TextStyle(
                color: TemaGlobal.texto, fontWeight: FontWeight.w600)),
        subtitle: Text(
          _fechasHito(h),
          style: TextStyle(
              color: pendiente
                  ? TemaGlobal.textoSecundario
                  : TemaGlobal.azulMarino),
        ),
        children: <Widget>[
          _fila('Lapso legal', _textoLapso(l)),
          _fila('Base legal', l.baseLegal),
          if (l.descripcion != null) _fila('Detalle', l.descripcion!),
          if (l.consecuencia != null) _fila('Consecuencia', l.consecuencia!),
          if (h.lapso is LapsoCatalogo &&
              (h.lapso as LapsoCatalogo).pendienteVerificacion)
            _fila('Verificación', 'Dato del usuario — pendiente de cotejo con la ley.'),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              if (esGatillo && pendiente)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _marcarGatillo(l),
                    style: FilledButton.styleFrom(
                      backgroundColor: TemaGlobal.dorado,
                      foregroundColor: TemaGlobal.azulMarino,
                    ),
                    icon: const Icon(Icons.event_available),
                    label: Text('Marcar ${_nombreGatillo(l.gatillo!)}'),
                  ),
                )
              else if (h.fechaMin != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _agendarHito(h),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.acento),
                      foregroundColor: AppColors.acento,
                    ),
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Agendar este hito'),
                  ),
                ),
              const SizedBox(width: 8),
              if (esGatillo && _fechasGatillo.containsKey(l.gatillo))
                IconButton(
                  tooltip: 'Quitar fecha marcada',
                  onPressed: () {
                    setState(() => _fechasGatillo.remove(l.gatillo));
                  },
                  icon: Icon(Icons.undo, color: TemaGlobal.textoSecundario),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fila(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(etiqueta,
                style: TextStyle(
                    color: TemaGlobal.textoSecundario, fontSize: 12.5)),
          ),
          Expanded(
            child: Text(valor,
                style: TextStyle(color: TemaGlobal.texto, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
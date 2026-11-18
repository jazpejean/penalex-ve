import 'package:flutter/foundation.dart';
import '../models/expediente.dart';
import '../services/expediente_service.dart';

/// Estado global del expediente ACTIVO ("causa en la que estoy trabajando").
///
/// Mecánica case-first: al abrir cualquier herramienta (detector de vicios,
/// redactor, escáner, chat/RAG) el abogado selecciona el expediente donde va
/// a trabajar, y la IA recibe ese contexto de forma persistente.
class ExpedienteActivoProvider extends ChangeNotifier {
  Expediente? _expediente;
  List<Expediente> _expedientes = const [];
  bool _cargando = false;

  Expediente? get expediente => _expediente;
  List<Expediente> get expedientes => _expedientes;
  bool get cargando => _cargando;
  bool get tieneExpediente => _expediente != null;

  /// Número de expediente legible para mostrar en UI.
  String get etiqueta {
    final e = _expediente;
    if (e == null) return 'Consulta aislada';
    return 'Exp. ${e.numeroExpediente} · ${e.imputado}';
  }

  Future<void> cargarExpedientes() async {
    _cargando = true;
    notifyListeners();
    try {
      _expedientes = await ExpedienteService.listarExpedientes();
    } catch (e) {
      debugPrint('⚠️ No se pudieron listar expedientes: $e');
      _expedientes = const [];
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void seleccionar(Expediente? e) {
    _expediente = e;
    notifyListeners();
  }

  /// Limpia el contexto (consulta aislada, sin expediente).
  void limpiar() {
    _expediente = null;
    notifyListeners();
  }

  /// Crea un expediente nuevo y lo deja activo.
  Future<Expediente?> crearYNuevo({
    required String numeroExpediente,
    required String imputado,
    String? delitos,
    String? tribunalNombre,
  }) async {
    final creado = await ExpedienteService.crear(
      numeroExpediente: numeroExpediente,
      imputado: imputado,
      delitos: delitos,
      tribunalNombre: tribunalNombre,
    );
    if (creado != null) {
      _expediente = creado;
      if (!_expedientes.any((e) => e.id == creado.id)) {
        _expedientes = [creado, ..._expedientes];
      }
      notifyListeners();
    }
    return creado;
  }
}

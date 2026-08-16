/// Modelo de suscripción y planes
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de planes disponibles
enum TipoPlan {
  free,
  pro,
  teams;

  String get nombre {
    switch (this) {
      case TipoPlan.free:
        return 'Free';
      case TipoPlan.pro:
        return 'Pro';
      case TipoPlan.teams:
        return 'Teams';
    }
  }

  String get descripcion {
    switch (this) {
      case TipoPlan.free:
        return 'Plan gratuito con funciones básicas';
      case TipoPlan.pro:
        return 'Plan profesional para abogados independientes';
      case TipoPlan.teams:
        return 'Plan empresarial para bufetes y equipos';
    }
  }

  double get precioMensual {
    switch (this) {
      case TipoPlan.free:
        return 0.0;
      case TipoPlan.pro:
        return 29.99;
      case TipoPlan.teams:
        return 99.99; // por equipo de hasta 10 usuarios
    }
  }
}

/// Estado de una suscripción
enum EstadoSuscripcion {
  activa,
  cancelada,
  expirada,
  trial;

  String get nombre {
    switch (this) {
      case EstadoSuscripcion.activa:
        return 'Activa';
      case EstadoSuscripcion.cancelada:
        return 'Cancelada';
      case EstadoSuscripcion.expirada:
        return 'Expirada';
      case EstadoSuscripcion.trial:
        return 'Período de Prueba';
    }
  }
}

/// Límites y características de cada plan
class LimitesPlan {
  final int maxCasos;
  final int maxDocumentosPorMes;
  final int maxConsultasIA;
  final bool exportarDOCX;
  final bool exportarPDF;
  final bool comparadorEstrategias;
  final bool busquedaSemantica;
  final bool chatLegal;
  final bool sincronizacionNube;
  final bool colaboracionEquipo;
  final bool soportePrioritario;
  final bool historicoCompleto;

  const LimitesPlan({
    required this.maxCasos,
    required this.maxDocumentosPorMes,
    required this.maxConsultasIA,
    required this.exportarDOCX,
    required this.exportarPDF,
    required this.comparadorEstrategias,
    required this.busquedaSemantica,
    required this.chatLegal,
    required this.sincronizacionNube,
    required this.colaboracionEquipo,
    required this.soportePrioritario,
    required this.historicoCompleto,
  });

  static LimitesPlan paraPlan(TipoPlan plan) {
    switch (plan) {
      case TipoPlan.free:
        return const LimitesPlan(
          maxCasos: 5,
          maxDocumentosPorMes: 10,
          maxConsultasIA: 50,
          exportarDOCX: false,
          exportarPDF: true,
          comparadorEstrategias: false,
          busquedaSemantica: false,
          chatLegal: true,
          sincronizacionNube: true,
          colaboracionEquipo: false,
          soportePrioritario: false,
          historicoCompleto: false,
        );

      case TipoPlan.pro:
        return const LimitesPlan(
          maxCasos: -1, // ilimitado
          maxDocumentosPorMes: 200,
          maxConsultasIA: 1000,
          exportarDOCX: true,
          exportarPDF: true,
          comparadorEstrategias: true,
          busquedaSemantica: true,
          chatLegal: true,
          sincronizacionNube: true,
          colaboracionEquipo: false,
          soportePrioritario: true,
          historicoCompleto: true,
        );

      case TipoPlan.teams:
        return const LimitesPlan(
          maxCasos: -1, // ilimitado
          maxDocumentosPorMes: -1, // ilimitado
          maxConsultasIA: -1, // ilimitado
          exportarDOCX: true,
          exportarPDF: true,
          comparadorEstrategias: true,
          busquedaSemantica: true,
          chatLegal: true,
          sincronizacionNube: true,
          colaboracionEquipo: true,
          soportePrioritario: true,
          historicoCompleto: true,
        );
    }
  }

  bool esIlimitado(int valor) => valor == -1;
}

/// Modelo de suscripción del usuario
class Suscripcion {
  final String id;
  final String userId;
  final TipoPlan plan;
  final EstadoSuscripcion estado;
  final DateTime fechaInicio;
  final DateTime fechaExpiracion;
  final bool renovacionAutomatica;
  final String? metodoPagoId;
  final Map<String, int> usoMensual; // 'documentos', 'consultasIA', etc.

  const Suscripcion({
    required this.id,
    required this.userId,
    required this.plan,
    required this.estado,
    required this.fechaInicio,
    required this.fechaExpiracion,
    this.renovacionAutomatica = false,
    this.metodoPagoId,
    this.usoMensual = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'plan': plan.name,
      'estado': estado.name,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaExpiracion': Timestamp.fromDate(fechaExpiracion),
      'renovacionAutomatica': renovacionAutomatica,
      'metodoPagoId': metodoPagoId,
      'usoMensual': usoMensual,
    };
  }

  factory Suscripcion.fromMap(Map<String, dynamic> map) {
    return Suscripcion(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      plan: TipoPlan.values.firstWhere(
        (e) => e.name == map['plan'],
        orElse: () => TipoPlan.free,
      ),
      estado: EstadoSuscripcion.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoSuscripcion.activa,
      ),
      fechaInicio: (map['fechaInicio'] as Timestamp).toDate(),
      fechaExpiracion: (map['fechaExpiracion'] as Timestamp).toDate(),
      renovacionAutomatica: map['renovacionAutomatica'] ?? false,
      metodoPagoId: map['metodoPagoId'],
      usoMensual: Map<String, int>.from(map['usoMensual'] ?? {}),
    );
  }

  /// Verifica si la suscripción está activa
  bool get estaActiva =>
      estado == EstadoSuscripcion.activa ||
      estado == EstadoSuscripcion.trial;

  /// Verifica si está en período de prueba
  bool get esTrial => estado == EstadoSuscripcion.trial;

  /// Días restantes de suscripción
  int get diasRestantes {
    if (!estaActiva) return 0;
    final diferencia = fechaExpiracion.difference(DateTime.now());
    return diferencia.inDays;
  }

  /// Verifica si está por vencer (menos de 7 días)
  bool get porVencer => estaActiva && diasRestantes <= 7;

  /// Obtiene los límites del plan actual
  LimitesPlan get limites => LimitesPlan.paraPlan(plan);

  /// Verifica si puede usar una feature específica
  bool puedeUsar(String feature) {
    final limites = this.limites;
    switch (feature) {
      case 'exportar_docx':
        return limites.exportarDOCX;
      case 'comparador_estrategias':
        return limites.comparadorEstrategias;
      case 'busqueda_semantica':
        return limites.busquedaSemantica;
      case 'colaboracion_equipo':
        return limites.colaboracionEquipo;
      case 'soporte_prioritario':
        return limites.soportePrioritario;
      case 'historico_completo':
        return limites.historicoCompleto;
      default:
        return false;
    }
  }

  /// Verifica si alcanzó el límite de un recurso
  bool alcanzeLimite(String recurso) {
    final limites = this.limites;
    final uso = usoMensual[recurso] ?? 0;

    switch (recurso) {
      case 'documentos':
        if (limites.maxDocumentosPorMes == -1) return false;
        return uso >= limites.maxDocumentosPorMes;
      case 'consultasIA':
        if (limites.maxConsultasIA == -1) return false;
        return uso >= limites.maxConsultasIA;
      default:
        return false;
    }
  }

  /// Incrementa el uso de un recurso
  Suscripcion incrementarUso(String recurso) {
    final nuevoUso = Map<String, int>.from(usoMensual);
    nuevoUso[recurso] = (nuevoUso[recurso] ?? 0) + 1;

    return Suscripcion(
      id: id,
      userId: userId,
      plan: plan,
      estado: estado,
      fechaInicio: fechaInicio,
      fechaExpiracion: fechaExpiracion,
      renovacionAutomatica: renovacionAutomatica,
      metodoPagoId: metodoPagoId,
      usoMensual: nuevoUso,
    );
  }
}

/// Transacción de pago
class TransaccionPago {
  final String id;
  final String userId;
  final TipoPlan plan;
  final double monto;
  final String moneda;
  final DateTime fecha;
  final String estado; // 'exitoso', 'fallido', 'pendiente'
  final String? numeroRecibo;
  final String metodoPago; // 'tarjeta', 'paypal', etc.

  const TransaccionPago({
    required this.id,
    required this.userId,
    required this.plan,
    required this.monto,
    required this.moneda,
    required this.fecha,
    required this.estado,
    this.numeroRecibo,
    required this.metodoPago,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'plan': plan.name,
      'monto': monto,
      'moneda': moneda,
      'fecha': Timestamp.fromDate(fecha),
      'estado': estado,
      'numeroRecibo': numeroRecibo,
      'metodoPago': metodoPago,
    };
  }

  factory TransaccionPago.fromMap(Map<String, dynamic> map) {
    return TransaccionPago(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      plan: TipoPlan.values.firstWhere(
        (e) => e.name == map['plan'],
        orElse: () => TipoPlan.free,
      ),
      monto: (map['monto'] ?? 0.0).toDouble(),
      moneda: map['moneda'] ?? 'USD',
      fecha: (map['fecha'] as Timestamp).toDate(),
      estado: map['estado'] ?? 'pendiente',
      numeroRecibo: map['numeroRecibo'],
      metodoPago: map['metodoPago'] ?? 'tarjeta',
    );
  }
}

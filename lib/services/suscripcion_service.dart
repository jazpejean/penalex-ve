/// Servicio de gestión de suscripciones
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/suscripcion.dart';
import 'auth_service.dart';

class SuscripcionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Obtiene la suscripción actual del usuario
  Future<Suscripcion?> obtenerSuscripcionActual() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return null;

    try {
      final doc = await _firestore
          .collection('suscripciones')
          .doc(userId)
          .get();

      if (!doc.exists) {
        // Crear suscripción FREE por defecto
        return await _crearSuscripcionInicial(userId);
      }

      return Suscripcion.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Error obteniendo suscripción: $e');
      return null;
    }
  }

  /// Stream de la suscripción actual
  Stream<Suscripcion?> streamSuscripcion() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return Stream.value(null);

    return _firestore
        .collection('suscripciones')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? Suscripcion.fromMap(doc.data()!) : null);
  }

  /// Crea suscripción inicial FREE
  Future<Suscripcion> _crearSuscripcionInicial(String userId) async {
    final suscripcion = Suscripcion(
      id: userId,
      userId: userId,
      plan: TipoPlan.free,
      estado: EstadoSuscripcion.trial,
      fechaInicio: DateTime.now(),
      fechaExpiracion: DateTime.now().add(const Duration(days: 14)), // 14 días trial
      renovacionAutomatica: false,
    );

    await _firestore
        .collection('suscripciones')
        .doc(userId)
        .set(suscripcion.toMap());

    return suscripcion;
  }

  /// Actualiza el plan de suscripción
  Future<void> actualizarPlan(TipoPlan nuevoPlan) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    final fechaInicio = DateTime.now();
    final fechaExpiracion = DateTime.now().add(const Duration(days: 30));

    await _firestore.collection('suscripciones').doc(userId).update({
      'plan': nuevoPlan.name,
      'estado': EstadoSuscripcion.activa.name,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaExpiracion': Timestamp.fromDate(fechaExpiracion),
      'renovacionAutomatica': true,
    });
  }

  /// Cancela la suscripción
  Future<void> cancelarSuscripcion() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('suscripciones').doc(userId).update({
      'estado': EstadoSuscripcion.cancelada.name,
      'renovacionAutomatica': false,
    });
  }

  /// Incrementa el uso de un recurso
  Future<void> incrementarUso(String recurso) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('suscripciones').doc(userId).update({
      'usoMensual.$recurso': FieldValue.increment(1),
    });
  }

  /// Verifica si puede usar una feature
  Future<bool> puedeUsarFeature(String feature) async {
    final suscripcion = await obtenerSuscripcionActual();
    if (suscripcion == null) return false;
    return suscripcion.puedeUsar(feature);
  }

  /// Verifica si alcanzó un límite
  Future<bool> alcanzeLimite(String recurso) async {
    final suscripcion = await obtenerSuscripcionActual();
    if (suscripcion == null) return true;
    return suscripcion.alcanzeLimite(recurso);
  }

  /// Registra una transacción
  Future<void> registrarTransaccion(TransaccionPago transaccion) async {
    await _firestore
        .collection('transacciones')
        .doc(transaccion.id)
        .set(transaccion.toMap());
  }

  /// Obtiene historial de transacciones
  Future<List<TransaccionPago>> obtenerTransacciones() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return [];

    final snapshot = await _firestore
        .collection('transacciones')
        .where('userId', isEqualTo: userId)
        .orderBy('fecha', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TransaccionPago.fromMap(doc.data()))
        .toList();
  }
}

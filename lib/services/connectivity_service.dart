import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  static final ConnectivityService _instance = ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  /// Verifica si hay conexión a internet (con un pequeño timeout)
  Future<bool> hasInternetConnection() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      final bool hasConnection =
          results.any((ConnectivityResult r) => r != ConnectivityResult.none);

      if (!hasConnection) return false;

      // Verificación adicional con un lookup DNS simple
      try {
        final List<InternetAddress> result =
            await InternetAddress.lookup('google.com')
                .timeout(const Duration(seconds: 3));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException {
        return false;
      } on TimeoutException {
        return false;
      }
    } on Exception catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  /// Stream para escuchar cambios de conectividad en tiempo real
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(
      (List<ConnectivityResult> results) =>
          results.any((ConnectivityResult r) => r != ConnectivityResult.none),
    );
  }
}

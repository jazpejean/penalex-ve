import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Implementación para **Android / iOS / Desktop** (usa `dart:io`).
Future<String?> obtenerDeviceId(DeviceInfoPlugin deviceInfo) async {
  if (Platform.isAndroid) {
    final build = await deviceInfo.androidInfo;
    return build.id;
  }
  if (Platform.isIOS) {
    final data = await deviceInfo.iosInfo;
    return data.identifierForVendor;
  }
  // Otros (desktop) — fingerprint básico
  final info = await deviceInfo.deviceInfo;
  return info.data.values.join('_').hashCode.toString();
}

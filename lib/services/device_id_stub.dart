import 'package:device_info_plus/device_info_plus.dart';

/// Implementación para **Web** (no hay `dart:io` ni `Platform`).
Future<String?> obtenerDeviceId(DeviceInfoPlugin deviceInfo) async {
  final webInfo = await deviceInfo.webBrowserInfo;
  return '${webInfo.vendor}_${webInfo.userAgent}_${webInfo.browserName}'
      .hashCode
      .toString();
}

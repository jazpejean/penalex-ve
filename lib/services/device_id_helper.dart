import 'package:device_info_plus/device_info_plus.dart';

import 'device_id_stub.dart'
    if (dart.library.io) 'device_id_io.dart' as device_id_impl;

/// Obtiene un identificador del dispositivo actual.
///
/// - **Web**: combinación de propiedades del navegador (device_info_plus).
/// - **Android/iOS**: `build.id` / `identifierForVendor`.
///
/// Esta separación con imports condicionales es necesaria porque
/// `dart:io` (Platform) no existe en Web, pero sí en móvil/desktop.
Future<String?> obtenerDeviceId(DeviceInfoPlugin deviceInfo) =>
    device_id_impl.obtenerDeviceId(deviceInfo);

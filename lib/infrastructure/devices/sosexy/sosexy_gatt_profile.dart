import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Centralized GATT profile for SOSEXY devices.
///
/// NOTE:
/// UUIDs below follow the public tutorial-derived official adapter config.
/// Keep them centralized so future HCI adjustments only touch one place.
class SosexyGattProfile {
  const SosexyGattProfile._();

  static final Guid serviceUuid = Guid('0000ee01-0000-1000-8000-00805f9b34fb');

  static final Guid writeCharacteristicUuid = Guid(
    '0000ee03-0000-1000-8000-00805f9b34fb',
  );

  static final Guid notifyCharacteristicUuid = Guid(
    '0000ee02-0000-1000-8000-00805f9b34fb',
  );

  static const bool writeWithoutResponse = false;
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration writeTimeout = Duration(milliseconds: 600);
  static const int retryCount = 1;
  static const int requestMtu = 185;
}

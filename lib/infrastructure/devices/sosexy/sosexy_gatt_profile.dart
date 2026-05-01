import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Centralized GATT profile for SOSEXY devices.
///
/// NOTE:
/// UUIDs below are placeholders until we verify the exact values from
/// hardware capture. Keeping them centralized avoids protocol leakage.
class SosexyGattProfile {
  const SosexyGattProfile._();

  // inferred
  static final Guid serviceUuid = Guid('0000fff0-0000-1000-8000-00805f9b34fb');

  // inferred
  static final Guid writeCharacteristicUuid = Guid(
    '0000fff3-0000-1000-8000-00805f9b34fb',
  );

  // inferred
  static final Guid notifyCharacteristicUuid = Guid(
    '0000fff4-0000-1000-8000-00805f9b34fb',
  );

  static const bool writeWithoutResponse = true;
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration writeTimeout = Duration(milliseconds: 600);
  static const int retryCount = 1;
  static const int requestMtu = 185;
}

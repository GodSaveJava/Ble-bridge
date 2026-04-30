import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../entities/device_status.dart';
import '../entities/safety_policy.dart';

enum DeviceConnectionState { disconnected, connecting, connected }

enum ToyFeature { suck, vibe, ems }

abstract class ToyDevice {
  String get id;
  String get name;
  String get bleNamePrefix;
  Set<ToyFeature> get supportedFeatures;
  Map<ToyFeature, ({int min, int max})> get intensityRangeByChannel;
  SafetyPolicy get safetyPolicy;
  DeviceConnectionState get connectionState;
  Stream<DeviceStatus> get statusStream;

  Future<bool> connect(BluetoothDevice device);
  Future<void> disconnect();

  Future<void> setSuck(int intensity, {int mode = 1});
  Future<void> setVibe(int intensity, {int mode = 1});
  Future<void> setEms(int intensity, {int mode = 1});
  Future<void> setAll({
    int suck = 0,
    int vibe = 0,
    int ems = 0,
    int suckMode = 1,
    int vibeMode = 1,
    int emsMode = 1,
  });
  Future<void> stopAll();
  Future<DeviceStatus> getStatus();

  Future<void> sendRawCommand(List<int> bytes);
}

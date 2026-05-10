import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../domain/devices/toy_device.dart';
import '../../domain/entities/device_status.dart';
import '../../domain/entities/safety_policy.dart';

class MockToyDevice implements ToyDevice {
  MockToyDevice({
    required this.id,
    this.name = 'Mock SOSEXY Device',
    this.bleNamePrefix = 'SOSEXY',
  }) : _status = DeviceStatus.disconnected(deviceId: id);

  @override
  final String id;

  @override
  final String name;

  @override
  final String bleNamePrefix;

  DeviceStatus _status;

  final StreamController<DeviceStatus> _statusController =
      StreamController<DeviceStatus>.broadcast();

  @override
  Set<ToyFeature> get supportedFeatures => <ToyFeature>{
    ToyFeature.suck,
    ToyFeature.vibe,
    ToyFeature.ems,
  };

  @override
  Map<ToyFeature, ({int min, int max})> get intensityRangeByChannel =>
      <ToyFeature, ({int min, int max})>{
        ToyFeature.suck: (min: 0, max: 100),
        ToyFeature.vibe: (min: 0, max: 100),
        ToyFeature.ems: (min: 0, max: 20),
      };

  @override
  SafetyPolicy get safetyPolicy => const SafetyPolicy();

  @override
  DeviceConnectionState get connectionState => _status.isConnected
      ? DeviceConnectionState.connected
      : DeviceConnectionState.disconnected;

  @override
  Stream<DeviceStatus> get statusStream => _statusController.stream;

  @override
  Future<String> getGattFingerprint() async {
    return 'mock-gatt:$bleNamePrefix:$id';
  }

  @override
  Future<bool> connect(BluetoothDevice device) async {
    _status = _status.copyWith(isConnected: true);
    _statusController.add(_status);
    return true;
  }

  Future<bool> connectMock() async {
    _status = _status.copyWith(isConnected: true);
    _statusController.add(_status);
    return true;
  }

  @override
  Future<void> disconnect() async {
    _status = _status.copyWith(
      isConnected: false,
      suckIntensity: 0,
      vibeIntensity: 0,
      emsIntensity: 0,
    );
    _statusController.add(_status);
  }

  @override
  Future<void> setSuck(int intensity, {int mode = 1}) async {
    _status = _status.copyWith(
      suckIntensity: intensity,
      suckMode: mode,
      isConnected: true,
    );
    _statusController.add(_status);
  }

  @override
  Future<void> setVibe(int intensity, {int mode = 1}) async {
    _status = _status.copyWith(
      vibeIntensity: intensity,
      vibeMode: mode,
      isConnected: true,
    );
    _statusController.add(_status);
  }

  @override
  Future<void> setEms(int intensity, {int mode = 1}) async {
    _status = _status.copyWith(
      emsIntensity: intensity,
      emsMode: mode,
      isConnected: true,
    );
    _statusController.add(_status);
  }

  @override
  Future<void> setAll({
    int suck = 0,
    int vibe = 0,
    int ems = 0,
    int suckMode = 1,
    int vibeMode = 1,
    int emsMode = 1,
  }) async {
    _status = _status.copyWith(
      suckIntensity: suck,
      vibeIntensity: vibe,
      emsIntensity: ems,
      suckMode: suckMode,
      vibeMode: vibeMode,
      emsMode: emsMode,
      isConnected: true,
    );
    _statusController.add(_status);
  }

  @override
  Future<void> stopAll() async {
    _status = _status.copyWith(
      suckIntensity: 0,
      vibeIntensity: 0,
      emsIntensity: 0,
      isConnected: true,
    );
    _statusController.add(_status);
  }

  @override
  Future<DeviceStatus> getStatus() async => _status;

  @override
  Future<void> sendRawCommand(List<int> bytes) async {}

  Future<void> dispose() async {
    await _statusController.close();
  }
}

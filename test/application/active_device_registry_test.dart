import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/application/registry/active_device_registry.dart';
import 'package:toylink_ai/core/error/failure.dart';
import 'package:toylink_ai/domain/devices/toy_device.dart';
import 'package:toylink_ai/domain/entities/device_status.dart';
import 'package:toylink_ai/domain/entities/safety_policy.dart';
import 'package:toylink_ai/domain/entities/toy_device_info.dart';
import 'package:toylink_ai/domain/repositories/hardware_repository.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  group('ActiveDeviceRegistry', () {
    late _FakeHardwareRepository repository;
    late ActiveDeviceRegistry registry;

    setUp(() {
      repository = _FakeHardwareRepository();
      registry = ActiveDeviceRegistry(hardwareRepository: repository);
    });

    tearDown(() async {
      await registry.dispose();
      await repository.dispose();
    });

    test('throws noActiveDevice when no device is active', () {
      expect(
        registry.requireActiveDevice,
        throwsA(
          isA<Failure>().having(
            (Failure failure) => failure.code,
            'code',
            FailureCode.noActiveDevice,
          ),
        ),
      );
    });

    test('returns active device when present', () {
      final _FakeToyDevice fakeDevice = _FakeToyDevice(id: 'dev-1');
      repository.activeDevice = fakeDevice;

      final ToyDevice result = registry.requireActiveDevice();
      expect(result.id, 'dev-1');
    });

    test('forwards status stream from repository', () async {
      final DeviceStatus status = DeviceStatus(
        deviceId: 'dev-1',
        isConnected: true,
        suckIntensity: 10,
        vibeIntensity: 20,
        emsIntensity: 0,
        suckMode: 1,
        vibeMode: 1,
        emsMode: 1,
        lastUpdatedAt: DateTime(2026),
      );

      final Future<DeviceStatus> future = registry.statusStream.first;
      repository.emitStatus(status);

      expect(await future, status);
    });
  });
}

class _FakeHardwareRepository implements HardwareRepository {
  final StreamController<List<ToyDeviceInfo>> _scanController =
      StreamController<List<ToyDeviceInfo>>.broadcast();
  final StreamController<DeviceStatus> _statusController =
      StreamController<DeviceStatus>.broadcast();

  ToyDevice? activeDevice;

  @override
  Future<void> connectActiveDevice(ToyDeviceInfo info) async {}

  @override
  Future<void> disconnectActiveDevice() async {
    activeDevice = null;
  }

  @override
  ToyDevice? getActiveDevice() => activeDevice;

  @override
  Future<void> startScan() async {}

  @override
  Future<void> stopScan() async {}

  @override
  Stream<DeviceStatus> watchActiveStatus() => _statusController.stream;

  @override
  Stream<List<ToyDeviceInfo>> watchDiscoveredDevices() =>
      _scanController.stream;

  void emitStatus(DeviceStatus status) {
    _statusController.add(status);
  }

  Future<void> dispose() async {
    await _scanController.close();
    await _statusController.close();
  }
}

class _FakeToyDevice implements ToyDevice {
  _FakeToyDevice({required this.id});

  @override
  final String id;

  @override
  String get bleNamePrefix => 'SOSEXY';

  @override
  DeviceConnectionState get connectionState => DeviceConnectionState.connected;

  @override
  Map<ToyFeature, ({int min, int max})> get intensityRangeByChannel =>
      <ToyFeature, ({int min, int max})>{ToyFeature.suck: (min: 0, max: 100)};

  @override
  String get name => 'Fake';

  @override
  SafetyPolicy get safetyPolicy => const SafetyPolicy();

  @override
  Stream<DeviceStatus> get statusStream => const Stream<DeviceStatus>.empty();

  @override
  Future<String> getGattFingerprint() async => 'fake-gatt:$id';

  @override
  Set<ToyFeature> get supportedFeatures => <ToyFeature>{ToyFeature.suck};

  @override
  Future<bool> connect(BluetoothDevice device) async => true;

  @override
  Future<void> disconnect() async {}

  @override
  Future<DeviceStatus> getStatus() async =>
      DeviceStatus.disconnected(deviceId: id);

  @override
  Future<void> sendRawCommand(List<int> bytes) async {}

  @override
  Future<void> setAll({
    int suck = 0,
    int vibe = 0,
    int ems = 0,
    int suckMode = 1,
    int vibeMode = 1,
    int emsMode = 1,
  }) async {}

  @override
  Future<void> setEms(int intensity, {int mode = 1}) async {}

  @override
  Future<void> setSuck(int intensity, {int mode = 1}) async {}

  @override
  Future<void> setVibe(int intensity, {int mode = 1}) async {}

  @override
  Future<void> stopAll() async {}
}

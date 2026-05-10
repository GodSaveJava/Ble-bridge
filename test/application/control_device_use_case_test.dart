import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/application/registry/active_device_registry.dart';
import 'package:toylink_ai/application/safety/safety_guard.dart';
import 'package:toylink_ai/application/use_cases/control_device_use_case.dart';
import 'package:toylink_ai/core/error/failure.dart';
import 'package:toylink_ai/domain/devices/toy_device.dart';
import 'package:toylink_ai/domain/entities/device_status.dart';
import 'package:toylink_ai/domain/entities/safety_policy.dart';
import 'package:toylink_ai/domain/entities/toy_device_info.dart';
import 'package:toylink_ai/domain/repositories/hardware_repository.dart';

void main() {
  group('ControlDeviceUseCase', () {
    late _FakeHardwareRepository repository;
    late ActiveDeviceRegistry registry;
    late ControlDeviceUseCase useCase;
    late _RecordingToyDevice device;

    setUp(() {
      repository = _FakeHardwareRepository();
      registry = ActiveDeviceRegistry(hardwareRepository: repository);
      useCase = ControlDeviceUseCase(
        activeDeviceRegistry: registry,
        safetyGuard: const SafetyGuard(),
      );
      device = _RecordingToyDevice(id: 'device-1');
      repository.activeDevice = device;
    });

    tearDown(() async {
      await registry.dispose();
      await repository.dispose();
    });

    test('setSuck writes to active device', () async {
      await useCase.setSuck(intensity: 30, mode: 2);
      expect(device.lastAction, 'setSuck:30:2');
    });

    test('setEms > soft limit requires confirmation', () async {
      expect(
        () => useCase.setEms(intensity: 9, mode: 1),
        throwsA(
          isA<Failure>().having(
            (Failure failure) => failure.code,
            'code',
            FailureCode.validation,
          ),
        ),
      );
    });

    test('setEms > hard limit is rejected', () async {
      expect(
        () => useCase.setEms(intensity: 21, mode: 1),
        throwsA(
          isA<Failure>().having(
            (Failure failure) => failure.code,
            'code',
            FailureCode.validation,
          ),
        ),
      );
    });

    test('setAll delegates to device and returns status', () async {
      final status = await useCase.setAll(
        suck: 10,
        vibe: 20,
        ems: 0,
        suckMode: 1,
        vibeMode: 2,
        emsMode: 3,
      );

      expect(device.lastAction, 'setAll:10:20:0:1:2:3');
      expect(status.deviceId, 'device-1');
    });

    test('throws noActiveDevice when device missing', () async {
      repository.activeDevice = null;

      expect(
        () => useCase.getStatus(),
        throwsA(
          isA<Failure>().having(
            (Failure failure) => failure.code,
            'code',
            FailureCode.noActiveDevice,
          ),
        ),
      );
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

  Future<void> dispose() async {
    await _scanController.close();
    await _statusController.close();
  }
}

class _RecordingToyDevice implements ToyDevice {
  _RecordingToyDevice({required this.id});

  String? lastAction;

  @override
  final String id;

  @override
  String get bleNamePrefix => 'SOSEXY';

  @override
  DeviceConnectionState get connectionState => DeviceConnectionState.connected;

  @override
  Map<ToyFeature, ({int min, int max})> get intensityRangeByChannel =>
      <ToyFeature, ({int min, int max})>{
        ToyFeature.suck: (min: 0, max: 100),
        ToyFeature.vibe: (min: 0, max: 100),
        ToyFeature.ems: (min: 0, max: 20),
      };

  @override
  String get name => 'Recorder';

  @override
  SafetyPolicy get safetyPolicy => const SafetyPolicy();

  @override
  Stream<DeviceStatus> get statusStream => const Stream<DeviceStatus>.empty();

  @override
  Future<String> getGattFingerprint() async => 'recording-gatt:$id';

  @override
  Set<ToyFeature> get supportedFeatures => <ToyFeature>{
    ToyFeature.suck,
    ToyFeature.vibe,
    ToyFeature.ems,
  };

  @override
  Future<bool> connect(BluetoothDevice device) async => true;

  @override
  Future<void> disconnect() async {}

  @override
  Future<DeviceStatus> getStatus() async => DeviceStatus(
    deviceId: id,
    isConnected: true,
    suckIntensity: 0,
    vibeIntensity: 0,
    emsIntensity: 0,
    suckMode: 1,
    vibeMode: 1,
    emsMode: 1,
    lastUpdatedAt: DateTime.now(),
  );

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
  }) async {
    lastAction = 'setAll:$suck:$vibe:$ems:$suckMode:$vibeMode:$emsMode';
  }

  @override
  Future<void> setEms(int intensity, {int mode = 1}) async {
    lastAction = 'setEms:$intensity:$mode';
  }

  @override
  Future<void> setSuck(int intensity, {int mode = 1}) async {
    lastAction = 'setSuck:$intensity:$mode';
  }

  @override
  Future<void> setVibe(int intensity, {int mode = 1}) async {
    lastAction = 'setVibe:$intensity:$mode';
  }

  @override
  Future<void> stopAll() async {
    lastAction = 'stopAll';
  }
}

import 'dart:async';

import '../../domain/devices/toy_device.dart';
import '../../domain/entities/device_status.dart';
import '../../domain/entities/toy_device_info.dart';
import '../../domain/repositories/hardware_repository.dart';
import 'mock_toy_device.dart';

class MockHardwareRepository implements HardwareRepository {
  MockHardwareRepository({MockToyDevice? toyDevice})
    : _toyDevice = toyDevice ?? MockToyDevice(id: 'mock-sosexy-001') {
    _activeDevice = _toyDevice;
    _statusSubscription = _toyDevice.statusStream.listen(_statusController.add);
    unawaited(_toyDevice.connectMock());
  }

  final MockToyDevice _toyDevice;
  ToyDevice? _activeDevice;
  bool _isScanning = false;

  final StreamController<List<ToyDeviceInfo>> _scanController =
      StreamController<List<ToyDeviceInfo>>.broadcast();
  final StreamController<DeviceStatus> _statusController =
      StreamController<DeviceStatus>.broadcast();
  late final StreamSubscription<DeviceStatus> _statusSubscription;

  @override
  Stream<List<ToyDeviceInfo>> watchDiscoveredDevices() =>
      _scanController.stream;

  @override
  Future<void> startScan() async {
    _isScanning = true;
    _scanController.add(<ToyDeviceInfo>[
      ToyDeviceInfo(
        id: _toyDevice.id,
        displayName: _toyDevice.name,
        bleNamePrefix: _toyDevice.bleNamePrefix,
        protocolKey: 'sosexy',
        isKnownTemplate: true,
        rssi: -42,
      ),
    ]);
  }

  @override
  Future<void> stopScan() async {
    _isScanning = false;
  }

  @override
  Future<void> connectActiveDevice(ToyDeviceInfo info) async {
    if (_isScanning) {
      await stopScan();
    }
    _activeDevice = _toyDevice;
    await _toyDevice.connectMock();
    _statusController.add(await _toyDevice.getStatus());
  }

  @override
  Future<void> disconnectActiveDevice() async {
    final ToyDevice? device = _activeDevice;
    if (device == null) {
      return;
    }
    await device.disconnect();
    _activeDevice = null;
    _statusController.add(await device.getStatus());
  }

  @override
  ToyDevice? getActiveDevice() => _activeDevice;

  @override
  Stream<DeviceStatus> watchActiveStatus() => _statusController.stream;

  Future<void> dispose() async {
    await _statusSubscription.cancel();
    await _scanController.close();
    await _statusController.close();
    await _toyDevice.dispose();
  }
}

import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../domain/devices/toy_device.dart';
import '../../domain/entities/device_status.dart';
import '../../domain/entities/toy_device_info.dart';
import '../../domain/repositories/hardware_repository.dart';
import '../devices/sosexy/sosexy_device.dart';

class SosexyHardwareRepository implements HardwareRepository {
  SosexyHardwareRepository({this.namePrefixes = const <String>['SOSEXY']}) {
    _scanSub = FlutterBluePlus.scanResults.listen(_onScanResults);
  }

  final List<String> namePrefixes;
  final StreamController<List<ToyDeviceInfo>> _scanController =
      StreamController<List<ToyDeviceInfo>>.broadcast();
  final StreamController<DeviceStatus> _statusController =
      StreamController<DeviceStatus>.broadcast();

  final Map<String, ScanResult> _scanCache = <String, ScanResult>{};
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<DeviceStatus>? _deviceStatusSub;
  ToyDevice? _activeDevice;
  bool _isScanning = false;

  @override
  Stream<List<ToyDeviceInfo>> watchDiscoveredDevices() =>
      _scanController.stream;

  @override
  Future<void> startScan() async {
    _scanCache.clear();
    _isScanning = true;
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
  }

  @override
  Future<void> stopScan() async {
    _isScanning = false;
    await FlutterBluePlus.stopScan();
  }

  @override
  Future<void> connectActiveDevice(ToyDeviceInfo info) async {
    final ScanResult? result = _scanCache[info.id];
    if (result == null) {
      throw StateError('Selected device not found in scan cache: ${info.id}');
    }

    if (_isScanning) {
      await stopScan();
    }

    final existing = _activeDevice;
    if (existing is SosexyDevice) {
      await existing.disconnect();
      await existing.dispose();
    }

    final device = SosexyDevice(id: info.id, name: info.displayName);
    await device.connect(result.device);
    await _deviceStatusSub?.cancel();
    _deviceStatusSub = device.statusStream.listen(_statusController.add);
    _activeDevice = device;
    _statusController.add(await device.getStatus());
  }

  @override
  Future<void> disconnectActiveDevice() async {
    final device = _activeDevice;
    if (device == null) {
      return;
    }
    await device.disconnect();
    if (device is SosexyDevice) {
      await device.dispose();
    }
    _activeDevice = null;
    _statusController.add(await device.getStatus());
  }

  @override
  ToyDevice? getActiveDevice() => _activeDevice;

  @override
  Stream<DeviceStatus> watchActiveStatus() => _statusController.stream;

  void _onScanResults(List<ScanResult> results) {
    if (!_isScanning) {
      return;
    }
    for (final result in results) {
      final String name = result.device.platformName;
      if (_matchesPrefix(name)) {
        _scanCache[result.device.remoteId.str] = result;
      }
    }
    _scanController.add(_scanCache.values.map(_toInfo).toList(growable: false));
  }

  bool _matchesPrefix(String name) {
    final upper = name.toUpperCase();
    for (final p in namePrefixes) {
      if (upper.contains(p.toUpperCase())) {
        return true;
      }
    }
    return false;
  }

  ToyDeviceInfo _toInfo(ScanResult result) {
    return ToyDeviceInfo(
      id: result.device.remoteId.str,
      displayName: result.device.platformName.isEmpty
          ? 'SOSEXY'
          : result.device.platformName,
      bleNamePrefix: 'SOSEXY',
      protocolKey: 'sosexy',
      isKnownTemplate: true,
      rssi: result.rssi,
    );
  }

  Future<void> dispose() async {
    await _scanSub?.cancel();
    await _deviceStatusSub?.cancel();
    await _scanController.close();
    await _statusController.close();
    final device = _activeDevice;
    if (device is SosexyDevice) {
      await device.dispose();
    }
  }
}

import '../../domain/entities/toy_device_info.dart';
import '../../domain/repositories/hardware_repository.dart';

/// Coordinates scan/connect/disconnect actions for the currently active device.
///
/// This use case keeps feature pages away from infrastructure implementations
/// and preserves clean boundaries for future BLE/back-end swaps.
class ManageActiveDeviceUseCase {
  ManageActiveDeviceUseCase({required HardwareRepository hardwareRepository})
    : _hardwareRepository = hardwareRepository;

  final HardwareRepository _hardwareRepository;

  Stream<List<ToyDeviceInfo>> watchDiscoveredDevices() {
    return _hardwareRepository.watchDiscoveredDevices();
  }

  Future<void> startScan() {
    return _hardwareRepository.startScan();
  }

  Future<void> stopScan() {
    return _hardwareRepository.stopScan();
  }

  Future<void> connect(ToyDeviceInfo info) {
    return _hardwareRepository.connectActiveDevice(info);
  }

  Future<void> disconnect() {
    return _hardwareRepository.disconnectActiveDevice();
  }
}

import 'dart:async';

import '../../core/error/failure.dart';
import '../../domain/devices/toy_device.dart';
import '../../domain/entities/device_status.dart';
import '../../domain/repositories/hardware_repository.dart';

class ActiveDeviceRegistry {
  ActiveDeviceRegistry({required HardwareRepository hardwareRepository})
    : _hardwareRepository = hardwareRepository {
    _statusSubscription = _hardwareRepository.watchActiveStatus().listen(
      _statusController.add,
      onError: _statusController.addError,
    );
  }

  final HardwareRepository _hardwareRepository;
  final StreamController<DeviceStatus> _statusController =
      StreamController<DeviceStatus>.broadcast();
  late final StreamSubscription<DeviceStatus> _statusSubscription;

  Stream<DeviceStatus> get statusStream => _statusController.stream;

  ToyDevice requireActiveDevice() {
    final ToyDevice? device = _hardwareRepository.getActiveDevice();
    if (device == null) {
      throw const Failure.noActiveDevice();
    }
    return device;
  }

  ToyDevice? getActiveDeviceOrNull() => _hardwareRepository.getActiveDevice();

  Future<void> dispose() async {
    await _statusSubscription.cancel();
    await _statusController.close();
  }
}

import '../devices/toy_device.dart';
import '../entities/device_status.dart';
import '../entities/toy_device_info.dart';

abstract class HardwareRepository {
  Stream<List<ToyDeviceInfo>> watchDiscoveredDevices();
  Future<void> startScan();
  Future<void> stopScan();
  Future<void> connectActiveDevice(ToyDeviceInfo info);
  Future<void> disconnectActiveDevice();
  ToyDevice? getActiveDevice();
  Stream<DeviceStatus> watchActiveStatus();
}

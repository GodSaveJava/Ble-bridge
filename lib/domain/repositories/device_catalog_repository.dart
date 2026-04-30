import '../entities/toy_device_info.dart';

abstract class DeviceCatalogRepository {
  Future<List<String>> getScanPrefixes();
  Future<List<ToyDeviceInfo>> getSavedDevices();
}

import '../entities/active_adapter_binding.dart';

abstract class ActiveAdapterBindingRepository {
  Stream<List<ActiveAdapterBinding>> watchAll();
  Future<void> save(ActiveAdapterBinding binding);
  Future<ActiveAdapterBinding?> findByDeviceFingerprint(
    String deviceFingerprint,
  );
  Future<void> removeByDeviceFingerprint(String deviceFingerprint);
}

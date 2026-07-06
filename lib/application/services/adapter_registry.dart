import '../../domain/entities/active_adapter_binding.dart';
import '../../core/error/failure.dart';
import '../../domain/entities/adapter_manifest.dart';
import '../../domain/entities/verified_adapter_record.dart';
import '../../domain/repositories/active_adapter_binding_repository.dart';
import '../../domain/repositories/adapter_manifest_repository.dart';
import '../../domain/repositories/verified_adapter_repository.dart';

class AdapterRegistry {
  AdapterRegistry({
    required AdapterManifestRepository adapterManifestRepository,
    required VerifiedAdapterRepository verifiedAdapterRepository,
    required ActiveAdapterBindingRepository activeAdapterBindingRepository,
  }) : _adapterManifestRepository = adapterManifestRepository,
       _verifiedAdapterRepository = verifiedAdapterRepository,
       _activeAdapterBindingRepository = activeAdapterBindingRepository;

  final AdapterManifestRepository _adapterManifestRepository;
  final VerifiedAdapterRepository _verifiedAdapterRepository;
  final ActiveAdapterBindingRepository _activeAdapterBindingRepository;

  Stream<List<AdapterManifest>> watchAvailableManifests() {
    return _adapterManifestRepository.watchAll();
  }

  Future<void> importManifestJson(Map<String, Object?> json) async {
    final AdapterManifest manifest = AdapterManifest.fromJson(json);
    await _adapterManifestRepository.save(manifest);
  }

  Future<AdapterManifest> requireManifest(String adapterId) async {
    final AdapterManifest? manifest = await _adapterManifestRepository.findById(
      adapterId,
    );
    if (manifest == null) {
      throw Failure.adapterSchemaInvalid(
        message: 'Adapter "$adapterId" not found.',
      );
    }
    return manifest;
  }

  Future<void> removeManifest(String adapterId) {
    return _adapterManifestRepository.remove(adapterId);
  }

  Future<VerifiedAdapterRecord?> getVerificationRecord({
    required String adapterId,
    required String deviceFingerprint,
  }) {
    return _verifiedAdapterRepository.find(
      adapterId: adapterId,
      deviceFingerprint: deviceFingerprint,
    );
  }

  Future<bool> isVerified({
    required String adapterId,
    required String deviceFingerprint,
  }) async {
    final VerifiedAdapterRecord? record = await getVerificationRecord(
      adapterId: adapterId,
      deviceFingerprint: deviceFingerprint,
    );
    return record?.isVerified ?? false;
  }

  Future<void> bindAdapterToDevice({
    required String adapterId,
    required String deviceFingerprint,
  }) {
    return _activeAdapterBindingRepository.save(
      ActiveAdapterBinding(
        deviceFingerprint: deviceFingerprint,
        adapterId: adapterId,
        boundAt: DateTime.now(),
      ),
    );
  }

  Future<ActiveAdapterBinding?> getBindingForDevice(String deviceFingerprint) {
    return _activeAdapterBindingRepository.findByDeviceFingerprint(
      deviceFingerprint,
    );
  }

  Future<void> clearBindingForDevice(String deviceFingerprint) {
    return _activeAdapterBindingRepository.removeByDeviceFingerprint(
      deviceFingerprint,
    );
  }

  Stream<List<ActiveAdapterBinding>> watchBindings() {
    return _activeAdapterBindingRepository.watchAll();
  }

  Future<List<VerifiedAdapterRecord>> getVerificationRecordsForDevice(
    String deviceFingerprint,
  ) async {
    final List<VerifiedAdapterRecord> records = await _verifiedAdapterRepository
        .watchAll()
        .first;
    return records
        .where(
          (VerifiedAdapterRecord record) =>
              record.target.deviceFingerprint == deviceFingerprint,
        )
        .toList();
  }
}

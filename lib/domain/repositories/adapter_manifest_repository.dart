import '../entities/adapter_manifest.dart';

abstract class AdapterManifestRepository {
  Stream<List<AdapterManifest>> watchAll();
  Future<void> save(AdapterManifest manifest);
  Future<void> remove(String adapterId);
  Future<AdapterManifest?> findById(String adapterId);
}

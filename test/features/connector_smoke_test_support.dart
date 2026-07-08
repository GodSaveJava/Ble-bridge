import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/domain/entities/active_adapter_binding.dart';
import 'package:toylink_ai/domain/entities/adapter_manifest.dart';
import 'package:toylink_ai/domain/entities/verified_adapter_record.dart';
import 'package:toylink_ai/domain/repositories/active_adapter_binding_repository.dart';
import 'package:toylink_ai/domain/repositories/adapter_manifest_repository.dart';
import 'package:toylink_ai/domain/repositories/verified_adapter_repository.dart';
import 'package:toylink_ai/infrastructure/mock/mock_hardware_repository.dart';

ProviderContainer buildConnectorSmokeTestContainer() {
  return ProviderContainer(
    overrides: [
      hardwareRepositoryProvider.overrideWith((_) => MockHardwareRepository()),
      adapterManifestRepositoryProvider.overrideWith(
        (_) => _UnusedAdapterManifestRepository(),
      ),
      verifiedAdapterRepositoryProvider.overrideWith(
        (_) => _UnusedVerifiedAdapterRepository(),
      ),
      activeAdapterBindingRepositoryProvider.overrideWith(
        (_) => _UnusedActiveAdapterBindingRepository(),
      ),
    ],
  );
}

class _UnusedAdapterManifestRepository implements AdapterManifestRepository {
  @override
  Future<AdapterManifest?> findById(String adapterId) async => null;

  @override
  Future<void> remove(String adapterId) async {}

  @override
  Future<void> save(AdapterManifest manifest) async {}

  @override
  Stream<List<AdapterManifest>> watchAll() async* {
    yield const <AdapterManifest>[];
  }
}

class _UnusedVerifiedAdapterRepository implements VerifiedAdapterRepository {
  @override
  Future<VerifiedAdapterRecord?> find({
    required String adapterId,
    required String deviceFingerprint,
  }) async {
    return null;
  }

  @override
  Future<void> remove({
    required String adapterId,
    required String deviceFingerprint,
  }) async {}

  @override
  Future<void> save(VerifiedAdapterRecord record) async {}

  @override
  Stream<List<VerifiedAdapterRecord>> watchAll() async* {
    yield const <VerifiedAdapterRecord>[];
  }
}

class _UnusedActiveAdapterBindingRepository
    implements ActiveAdapterBindingRepository {
  @override
  Future<ActiveAdapterBinding?> findByDeviceFingerprint(
    String deviceFingerprint,
  ) async {
    return null;
  }

  @override
  Future<void> removeByDeviceFingerprint(String deviceFingerprint) async {}

  @override
  Future<void> save(ActiveAdapterBinding binding) async {}

  @override
  Stream<List<ActiveAdapterBinding>> watchAll() async* {
    yield const <ActiveAdapterBinding>[];
  }
}

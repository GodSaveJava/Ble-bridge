import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/application/services/adapter_registry.dart';
import 'package:toylink_ai/application/services/adapter_validator.dart';
import 'package:toylink_ai/application/use_cases/manage_adapter_use_case.dart';
import 'package:toylink_ai/domain/entities/adapter_manifest.dart';
import 'package:toylink_ai/domain/entities/verified_adapter_record.dart';
import 'package:toylink_ai/domain/repositories/adapter_manifest_repository.dart';
import 'package:toylink_ai/domain/repositories/verified_adapter_repository.dart';
import 'package:toylink_ai/features/device_manager/presentation/controllers/device_manager_controller.dart';

void main() {
  test('importJsonText sets importedAdapterId on success', () async {
    final _InMemoryManifestRepository manifestRepository =
        _InMemoryManifestRepository();
    final _InMemoryVerifiedRepository verifiedRepository =
        _InMemoryVerifiedRepository();
    final AdapterRegistry registry = AdapterRegistry(
      adapterManifestRepository: manifestRepository,
      verifiedAdapterRepository: verifiedRepository,
    );
    final AdapterValidator validator = AdapterValidator(
      verifiedAdapterRepository: verifiedRepository,
    );
    final ManageAdapterUseCase useCase = ManageAdapterUseCase(
      adapterRegistry: registry,
      adapterValidator: validator,
    );

    final ProviderContainer container = ProviderContainer(
      overrides: [
        manageAdapterUseCaseProvider.overrideWithValue(useCase),
      ],
    );
    addTearDown(container.dispose);

    final DeviceManagerController notifier = container.read(
      deviceManagerControllerProvider.notifier,
    );
    await notifier.importJsonText(_manifestJsonText());

    final DeviceManagerState state = container.read(deviceManagerControllerProvider);
    expect(state.importedAdapterId, 'generic.triple_channel.v1');
    expect(state.errorMessage, isNull);
  });
}

class _InMemoryManifestRepository implements AdapterManifestRepository {
  final StreamController<List<AdapterManifest>> _controller =
      StreamController<List<AdapterManifest>>.broadcast();
  final List<AdapterManifest> _manifests = <AdapterManifest>[];

  @override
  Future<AdapterManifest?> findById(String adapterId) async {
    for (final AdapterManifest manifest in _manifests) {
      if (manifest.adapterId == adapterId) {
        return manifest;
      }
    }
    return null;
  }

  @override
  Future<void> remove(String adapterId) async {
    _manifests.removeWhere((AdapterManifest e) => e.adapterId == adapterId);
    _controller.add(List<AdapterManifest>.from(_manifests));
  }

  @override
  Future<void> save(AdapterManifest manifest) async {
    final int index = _manifests.indexWhere(
      (AdapterManifest e) => e.adapterId == manifest.adapterId,
    );
    if (index >= 0) {
      _manifests[index] = manifest;
    } else {
      _manifests.add(manifest);
    }
    _controller.add(List<AdapterManifest>.from(_manifests));
  }

  @override
  Stream<List<AdapterManifest>> watchAll() async* {
    yield List<AdapterManifest>.from(_manifests);
    yield* _controller.stream;
  }
}

class _InMemoryVerifiedRepository implements VerifiedAdapterRepository {
  final Map<String, VerifiedAdapterRecord> _records =
      <String, VerifiedAdapterRecord>{};
  final StreamController<List<VerifiedAdapterRecord>> _controller =
      StreamController<List<VerifiedAdapterRecord>>.broadcast();

  @override
  Future<VerifiedAdapterRecord?> find({
    required String adapterId,
    required String deviceFingerprint,
  }) async {
    return _records['$adapterId::$deviceFingerprint'];
  }

  @override
  Future<void> remove({
    required String adapterId,
    required String deviceFingerprint,
  }) async {
    _records.remove('$adapterId::$deviceFingerprint');
    _controller.add(_records.values.toList());
  }

  @override
  Future<void> save(VerifiedAdapterRecord record) async {
    _records['${record.adapterId}::${record.target.deviceFingerprint}'] =
        record;
    _controller.add(_records.values.toList());
  }

  @override
  Stream<List<VerifiedAdapterRecord>> watchAll() async* {
    yield _records.values.toList();
    yield* _controller.stream;
  }
}

String _manifestJsonText() {
  return '''
{
  "schemaVersion": 1,
  "adapterId": "generic.triple_channel.v1",
  "displayName": "Generic Triple Channel",
  "protocolKey": "generic_triple_channel",
  "version": "1.0.0",
  "minAppVersion": "1.0.0",
  "adapterKind": "codecBacked",
  "codecKey": "generic_triple_channel_v1",
  "bleNamePrefixes": ["SOSEXY"],
  "matching": {
    "serviceUuids": ["0000fff0-0000-1000-8000-00805f9b34fb"],
    "manufacturerDataPattern": null,
    "priority": 100
  },
  "gatt": {
    "serviceUuid": "0000fff0-0000-1000-8000-00805f9b34fb",
    "writeCharacteristicUuid": "0000fff3-0000-1000-8000-00805f9b34fb",
    "notifyCharacteristicUuid": "0000fff4-0000-1000-8000-00805f9b34fb",
    "writeWithoutResponse": true
  },
  "connection": {
    "requiresBonding": false,
    "requestMtu": 185,
    "notifyRequired": false
  },
  "capabilities": {
    "supportsSuck": true,
    "supportsVibe": true,
    "supportsEms": true,
    "supportsSetAll": true,
    "supportsStopAll": true
  },
  "ranges": {
    "suckIntensity": {"min": 0, "max": 100},
    "vibeIntensity": {"min": 0, "max": 100},
    "emsIntensity": {"min": 0, "max": 20},
    "mode": {"min": 1, "max": 4}
  }
}
''';
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/application/services/adapter_registry.dart';
import 'package:toylink_ai/application/services/adapter_validator.dart';
import 'package:toylink_ai/application/use_cases/manage_adapter_use_case.dart';
import 'package:toylink_ai/core/error/failure.dart';
import 'package:toylink_ai/domain/entities/adapter_manifest.dart';
import 'package:toylink_ai/domain/entities/verified_adapter_record.dart';
import 'package:toylink_ai/domain/repositories/adapter_manifest_repository.dart';
import 'package:toylink_ai/domain/repositories/verified_adapter_repository.dart';

void main() {
  group('ManageAdapterUseCase', () {
    late _InMemoryManifestRepository manifestRepository;
    late _InMemoryVerifiedRepository verifiedRepository;
    late ManageAdapterUseCase useCase;

    setUp(() {
      manifestRepository = _InMemoryManifestRepository();
      verifiedRepository = _InMemoryVerifiedRepository();
      final AdapterRegistry registry = AdapterRegistry(
        adapterManifestRepository: manifestRepository,
        verifiedAdapterRepository: verifiedRepository,
      );
      final AdapterValidator validator = AdapterValidator(
        verifiedAdapterRepository: verifiedRepository,
      );
      useCase = ManageAdapterUseCase(
        adapterRegistry: registry,
        adapterValidator: validator,
      );
    });

    test('imports manifest and returns from stream', () async {
      await useCase.importManifestJson(_manifestJson());

      final List<AdapterManifest> manifests = await useCase
          .watchAvailableAdapters()
          .first;
      expect(manifests, hasLength(1));
      expect(manifests.first.adapterId, 'generic.triple_channel.v1');
    });

    test('markVerificationPassed requires stop_all step', () async {
      await useCase.importManifestJson(_manifestJson());

      await expectLater(
        () => useCase.markVerificationPassed(
          const AdapterVerificationInput(
            adapterId: 'generic.triple_channel.v1',
            deviceFingerprint: 'device-a',
            gattFingerprint: 'gatt-a',
            appVersion: '1.0.0',
            stepResults: <VerificationStepResult>[
              VerificationStepResult(stepKey: 'set_suck', passed: true),
            ],
          ),
        ),
        throwsA(
          isA<Failure>().having(
            (Failure failure) => failure.code,
            'code',
            FailureCode.adapterVerificationFailed,
          ),
        ),
      );
    });
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

Map<String, Object?> _manifestJson() {
  return <String, Object?>{
    'schemaVersion': 1,
    'adapterId': 'generic.triple_channel.v1',
    'displayName': 'Generic Triple Channel',
    'protocolKey': 'generic_triple_channel',
    'version': '1.0.0',
    'minAppVersion': '1.0.0',
    'adapterKind': 'codecBacked',
    'codecKey': 'generic_triple_channel_v1',
    'bleNamePrefixes': <String>['SOSEXY'],
    'matching': <String, Object?>{
      'serviceUuids': <String>['0000fff0-0000-1000-8000-00805f9b34fb'],
      'manufacturerDataPattern': null,
      'priority': 100,
    },
    'gatt': <String, Object?>{
      'serviceUuid': '0000fff0-0000-1000-8000-00805f9b34fb',
      'writeCharacteristicUuid': '0000fff3-0000-1000-8000-00805f9b34fb',
      'notifyCharacteristicUuid': '0000fff4-0000-1000-8000-00805f9b34fb',
      'writeWithoutResponse': true,
    },
    'connection': <String, Object?>{
      'requiresBonding': false,
      'requestMtu': 185,
      'notifyRequired': false,
    },
    'capabilities': <String, Object?>{
      'supportsSuck': true,
      'supportsVibe': true,
      'supportsEms': true,
      'supportsSetAll': true,
      'supportsStopAll': true,
    },
    'ranges': <String, Object?>{
      'suckIntensity': <String, Object?>{'min': 0, 'max': 100},
      'vibeIntensity': <String, Object?>{'min': 0, 'max': 100},
      'emsIntensity': <String, Object?>{'min': 0, 'max': 20},
      'mode': <String, Object?>{'min': 1, 'max': 4},
    },
  };
}

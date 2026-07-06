import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/application/services/adapter_validator.dart';
import 'package:toylink_ai/core/error/failure.dart';
import 'package:toylink_ai/domain/entities/adapter_manifest.dart';
import 'package:toylink_ai/domain/entities/verified_adapter_record.dart';
import 'package:toylink_ai/domain/repositories/verified_adapter_repository.dart';

void main() {
  group('AdapterValidator', () {
    late _FakeVerifiedAdapterRepository repository;
    late AdapterValidator validator;

    setUp(() {
      repository = _FakeVerifiedAdapterRepository();
      validator = AdapterValidator(verifiedAdapterRepository: repository);
    });

    test('saves verified record when all steps pass', () async {
      final AdapterManifest manifest = _manifest();
      final VerifiedAdapterRecord record = await validator.markVerified(
        manifest: manifest,
        manifestHash: 'hash-1',
        appVersion: '1.0.0',
        target: const VerifiedTarget(
          deviceFingerprint: 'device-a',
          gattFingerprint: 'gatt-a',
        ),
        stepResults: const <VerificationStepResult>[
          VerificationStepResult(stepKey: 'set_suck', passed: true),
          VerificationStepResult(stepKey: 'stop_all', passed: true),
        ],
      );

      expect(record.status, AdapterVerificationStatus.verified);
      expect(repository.lastSaved?.isVerified, isTrue);
    });

    test('rejects verified status when a step failed', () async {
      final AdapterManifest manifest = _manifest();

      await expectLater(
        () => validator.markVerified(
          manifest: manifest,
          manifestHash: 'hash-1',
          appVersion: '1.0.0',
          target: const VerifiedTarget(
            deviceFingerprint: 'device-a',
            gattFingerprint: 'gatt-a',
          ),
          stepResults: const <VerificationStepResult>[
            VerificationStepResult(stepKey: 'set_suck', passed: false),
          ],
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

class _FakeVerifiedAdapterRepository implements VerifiedAdapterRepository {
  final StreamController<List<VerifiedAdapterRecord>> _controller =
      StreamController<List<VerifiedAdapterRecord>>.broadcast();
  final Map<String, VerifiedAdapterRecord> _records =
      <String, VerifiedAdapterRecord>{};

  VerifiedAdapterRecord? lastSaved;

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
  }

  @override
  Future<void> save(VerifiedAdapterRecord record) async {
    _records['${record.adapterId}::${record.target.deviceFingerprint}'] =
        record;
    lastSaved = record;
    _controller.add(_records.values.toList());
  }

  @override
  Stream<List<VerifiedAdapterRecord>> watchAll() => _controller.stream;
}

AdapterManifest _manifest() {
  return AdapterManifest.fromJson(<String, Object?>{
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
  });
}

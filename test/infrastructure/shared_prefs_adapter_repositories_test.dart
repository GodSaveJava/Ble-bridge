import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toylink_ai/domain/entities/adapter_manifest.dart';
import 'package:toylink_ai/domain/entities/verified_adapter_record.dart';
import 'package:toylink_ai/infrastructure/storage/shared_prefs_adapter_manifest_repository.dart';
import 'package:toylink_ai/infrastructure/storage/shared_prefs_verified_adapter_repository.dart';

void main() {
  group('SharedPrefsAdapterManifestRepository', () {
    late SharedPrefsAdapterManifestRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = SharedPrefsAdapterManifestRepository();
    });

    tearDown(() async {
      await repository.dispose();
    });

    test('saves and finds manifest', () async {
      final AdapterManifest manifest = _manifest(adapterId: 'a1');
      await repository.save(manifest);

      final AdapterManifest? loaded = await repository.findById('a1');
      expect(loaded, isNotNull);
      expect(loaded!.adapterId, 'a1');
    });

    test('loads built-in template on first launch', () async {
      final List<AdapterManifest> manifests = await repository.watchAll().first;
      expect(manifests.isNotEmpty, isTrue);
      expect(
        manifests.any(
          (AdapterManifest e) => e.adapterId == 'generic.triple_channel.v1',
        ),
        isTrue,
      );
    });
  });

  group('SharedPrefsVerifiedAdapterRepository', () {
    late SharedPrefsVerifiedAdapterRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = SharedPrefsVerifiedAdapterRepository();
    });

    tearDown(() async {
      await repository.dispose();
    });

    test('saves and retrieves verified record', () async {
      final VerifiedAdapterRecord record = VerifiedAdapterRecord(
        manifestHash: 'h1',
        adapterId: 'a1',
        adapterVersion: '1.0.0',
        status: AdapterVerificationStatus.verified,
        updatedAt: DateTime(2026, 1, 1),
        verifiedByAppVersion: '1.0.0',
        target: VerifiedTarget(
          deviceFingerprint: 'device-1',
          gattFingerprint: 'gatt-1',
        ),
        stepResults: <VerificationStepResult>[
          VerificationStepResult(stepKey: 'stop_all', passed: true),
        ],
      );

      await repository.save(record);
      final VerifiedAdapterRecord? loaded = await repository.find(
        adapterId: 'a1',
        deviceFingerprint: 'device-1',
      );

      expect(loaded, isNotNull);
      expect(loaded!.status, AdapterVerificationStatus.verified);
    });
  });
}

AdapterManifest _manifest({required String adapterId}) {
  return AdapterManifest.fromJson(<String, Object?>{
    'schemaVersion': 1,
    'adapterId': adapterId,
    'displayName': 'Generic',
    'protocolKey': 'generic',
    'version': '1.0.0',
    'minAppVersion': '1.0.0',
    'adapterKind': 'codecBacked',
    'codecKey': 'generic_v1',
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

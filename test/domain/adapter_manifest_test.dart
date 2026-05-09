import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/core/error/failure.dart';
import 'package:toylink_ai/domain/entities/adapter_manifest.dart';

void main() {
  group('AdapterManifest', () {
    test('parses valid manifest', () {
      final AdapterManifest manifest = AdapterManifest.fromJson(
        <String, Object?>{
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
          'notes': 'template',
        },
      );

      expect(manifest.adapterId, 'generic.triple_channel.v1');
      expect(manifest.adapterKind, AdapterKind.codecBacked);
      expect(manifest.bleNamePrefixes, contains('SOSEXY'));
    });

    test('rejects unsupported adapter kind', () {
      expect(
        () => AdapterManifest.fromJson(<String, Object?>{
          'schemaVersion': 1,
          'adapterId': 'test',
          'displayName': 'Test',
          'protocolKey': 'test',
          'version': '1.0.0',
          'minAppVersion': '1.0.0',
          'adapterKind': 'executable',
          'codecKey': 'x',
          'bleNamePrefixes': <String>['A'],
          'matching': <String, Object?>{
            'serviceUuids': <String>['fff0'],
            'manufacturerDataPattern': null,
            'priority': 1,
          },
          'gatt': <String, Object?>{
            'serviceUuid': 'fff0',
            'writeCharacteristicUuid': 'fff3',
            'notifyCharacteristicUuid': 'fff4',
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
        }),
        throwsA(
          isA<Failure>().having(
            (Failure failure) => failure.code,
            'code',
            FailureCode.adapterSchemaInvalid,
          ),
        ),
      );
    });
  });
}

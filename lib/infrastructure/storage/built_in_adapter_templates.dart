import '../../domain/entities/adapter_manifest.dart';

class BuiltInAdapterTemplates {
  const BuiltInAdapterTemplates._();

  static List<AdapterManifest> defaults() {
    return <AdapterManifest>[
      AdapterManifest.fromJson(<String, Object?>{
        'schemaVersion': 1,
        'adapterId': 'generic.triple_channel.v1',
        'displayName': '通用三通道模板',
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
        'notes': '内置起步模板，可复制后按设备协议修改。',
      }),
    ];
  }
}

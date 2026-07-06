import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/domain/entities/adapter_manifest.dart';
import 'package:toylink_ai/infrastructure/storage/built_in_adapter_templates.dart';

void main() {
  test('defaults include the SOSEXY official template', () {
    final List<AdapterManifest> defaults = BuiltInAdapterTemplates.defaults();

    final AdapterManifest sosexy = defaults.firstWhere(
      (AdapterManifest manifest) => manifest.adapterId == 'sosexy.official.v1',
    );

    expect(sosexy.source, AdapterSource.official);
    expect(sosexy.protocolKey, 'sosexy_verified_v1');
    expect(sosexy.gatt.serviceUuid, '0000ee01-0000-1000-8000-00805f9b34fb');
    expect(
      sosexy.gatt.writeCharacteristicUuid,
      '0000ee03-0000-1000-8000-00805f9b34fb',
    );
    expect(
      sosexy.gatt.notifyCharacteristicUuid,
      '0000ee02-0000-1000-8000-00805f9b34fb',
    );
    expect(sosexy.gatt.writeWithoutResponse, isFalse);
    expect(sosexy.connection.notifyRequired, isTrue);
    expect(sosexy.bleNamePrefixes, contains('SOSEXY'));
  });
}

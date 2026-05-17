import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/application/models/active_device_adapter_readiness.dart';
import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/domain/entities/active_adapter_binding.dart';
import 'package:toylink_ai/domain/entities/adapter_manifest.dart';
import 'package:toylink_ai/domain/entities/device_status.dart';
import 'package:toylink_ai/domain/entities/verified_adapter_record.dart';

void main() {
  test(
    'readiness becomes verified when device binding and record match',
    () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          activeDeviceStatusStreamProvider.overrideWith(
            (_) => Stream<DeviceStatus>.value(_connectedStatus()),
          ),
          availableAdapterManifestsStreamProvider.overrideWith(
            (_) => Stream<List<AdapterManifest>>.value(<AdapterManifest>[
              _manifest(),
            ]),
          ),
          activeAdapterBindingsStreamProvider.overrideWith(
            (_) =>
                Stream<List<ActiveAdapterBinding>>.value(<ActiveAdapterBinding>[
                  ActiveAdapterBinding(
                    adapterId: 'generic.triple_channel.v1',
                    deviceFingerprint: 'device-a',
                    boundAt: DateTime(2026, 1, 1),
                  ),
                ]),
          ),
          verifiedAdapterRecordsStreamProvider.overrideWith(
            (_) => Stream<List<VerifiedAdapterRecord>>.value(
              <VerifiedAdapterRecord>[
                _record(status: AdapterVerificationStatus.verified),
              ],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await _settle(container);

      final ActiveDeviceAdapterReadiness readiness = container
          .read(activeDeviceAdapterReadinessProvider)
          .requireValue;
      expect(readiness.state, ActiveDeviceAdapterReadinessState.verified);
      expect(readiness.canControlViaMcp, isTrue);
      expect(readiness.adapterDisplayName, 'Generic Triple Channel');
    },
  );

  test(
    'readiness becomes noBinding when active device has no adapter binding',
    () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          activeDeviceStatusStreamProvider.overrideWith(
            (_) => Stream<DeviceStatus>.value(_connectedStatus()),
          ),
          availableAdapterManifestsStreamProvider.overrideWith(
            (_) => Stream<List<AdapterManifest>>.value(<AdapterManifest>[
              _manifest(),
            ]),
          ),
          activeAdapterBindingsStreamProvider.overrideWith(
            (_) => Stream<List<ActiveAdapterBinding>>.value(
              const <ActiveAdapterBinding>[],
            ),
          ),
          verifiedAdapterRecordsStreamProvider.overrideWith(
            (_) => Stream<List<VerifiedAdapterRecord>>.value(
              const <VerifiedAdapterRecord>[],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await _settle(container);

      final ActiveDeviceAdapterReadiness readiness = container
          .read(activeDeviceAdapterReadinessProvider)
          .requireValue;
      expect(readiness.state, ActiveDeviceAdapterReadinessState.noBinding);
      expect(readiness.canControlViaMcp, isFalse);
    },
  );

  test(
    'readiness becomes needsReverify when record requires revalidation',
    () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          activeDeviceStatusStreamProvider.overrideWith(
            (_) => Stream<DeviceStatus>.value(_connectedStatus()),
          ),
          availableAdapterManifestsStreamProvider.overrideWith(
            (_) => Stream<List<AdapterManifest>>.value(<AdapterManifest>[
              _manifest(),
            ]),
          ),
          activeAdapterBindingsStreamProvider.overrideWith(
            (_) =>
                Stream<List<ActiveAdapterBinding>>.value(<ActiveAdapterBinding>[
                  ActiveAdapterBinding(
                    adapterId: 'generic.triple_channel.v1',
                    deviceFingerprint: 'device-a',
                    boundAt: DateTime(2026, 1, 1),
                  ),
                ]),
          ),
          verifiedAdapterRecordsStreamProvider.overrideWith(
            (_) => Stream<List<VerifiedAdapterRecord>>.value(
              <VerifiedAdapterRecord>[
                _record(status: AdapterVerificationStatus.needsReverify),
              ],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await _settle(container);

      final ActiveDeviceAdapterReadiness readiness = container
          .read(activeDeviceAdapterReadinessProvider)
          .requireValue;
      expect(readiness.state, ActiveDeviceAdapterReadinessState.needsReverify);
      expect(readiness.canControlViaMcp, isFalse);
    },
  );
}

Future<void> _settle(ProviderContainer container) async {
  final ProviderSubscription<AsyncValue<ActiveDeviceAdapterReadiness>>
  subscription = container.listen(
    activeDeviceAdapterReadinessProvider,
    (_, _) {},
    fireImmediately: true,
  );
  await container.read(activeDeviceStatusStreamProvider.future);
  await container.read(availableAdapterManifestsStreamProvider.future);
  await container.read(activeAdapterBindingsStreamProvider.future);
  await container.read(verifiedAdapterRecordsStreamProvider.future);
  await Future<void>.delayed(Duration.zero);
  subscription.close();
}

DeviceStatus _connectedStatus() => DeviceStatus(
  deviceId: 'device-a',
  isConnected: true,
  suckIntensity: 0,
  vibeIntensity: 0,
  emsIntensity: 0,
  suckMode: 1,
  vibeMode: 1,
  emsMode: 1,
  lastUpdatedAt: DateTime(2026),
);

AdapterManifest _manifest() {
  return AdapterManifest.fromJson(const <String, Object?>{
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

VerifiedAdapterRecord _record({required AdapterVerificationStatus status}) {
  return VerifiedAdapterRecord(
    manifestHash: 'hash-v1',
    adapterId: 'generic.triple_channel.v1',
    adapterVersion: '1.0.0',
    status: status,
    updatedAt: DateTime(2026, 1, 1),
    verifiedByAppVersion: '1.0.0',
    target: const VerifiedTarget(
      deviceFingerprint: 'device-a',
      gattFingerprint: 'gatt-a',
    ),
    stepResults: const <VerificationStepResult>[
      VerificationStepResult(stepKey: 'set_suck', passed: true),
      VerificationStepResult(stepKey: 'stop_all', passed: true),
    ],
  );
}

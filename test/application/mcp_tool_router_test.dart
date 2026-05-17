import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/domain/devices/toy_device.dart';
import 'package:toylink_ai/domain/entities/active_adapter_binding.dart';
import 'package:toylink_ai/domain/entities/adapter_manifest.dart';
import 'package:toylink_ai/domain/entities/verified_adapter_record.dart';
import 'package:toylink_ai/domain/entities/device_status.dart';
import 'package:toylink_ai/domain/entities/toy_device_info.dart';
import 'package:toylink_ai/domain/repositories/active_adapter_binding_repository.dart';
import 'package:toylink_ai/domain/repositories/adapter_manifest_repository.dart';
import 'package:toylink_ai/domain/repositories/hardware_repository.dart';
import 'package:toylink_ai/domain/repositories/verified_adapter_repository.dart';
import 'package:toylink_ai/infrastructure/mock/mock_hardware_repository.dart';

void main() {
  group('McpToolRouter', () {
    test('returns status on set_suck', () async {
      final container = ProviderContainer(
        overrides: [
          hardwareRepositoryProvider.overrideWith(
            (_) => MockHardwareRepository(),
          ),
          adapterManifestRepositoryProvider.overrideWith(
            (_) => _InMemoryManifestRepository(),
          ),
          verifiedAdapterRepositoryProvider.overrideWith(
            (_) => _InMemoryVerifiedRepository(
              records: <VerifiedAdapterRecord>[
                _record(status: AdapterVerificationStatus.verified),
              ],
            ),
          ),
          activeAdapterBindingRepositoryProvider.overrideWith(
            (_) => _InMemoryActiveBindingRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(mcpToolRouterProvider);
      final result = await router.callTool(
        'set_suck',
        arguments: <String, Object?>{'intensity': 30, 'mode': 2},
      );

      expect(result.ok, isTrue);
      expect(result.data?['suckIntensity'], 30);
    });

    test(
      'blocks control tools when device has no verified adapter record',
      () async {
        final container = ProviderContainer(
          overrides: [
            hardwareRepositoryProvider.overrideWith(
              (_) => MockHardwareRepository(),
            ),
            adapterManifestRepositoryProvider.overrideWith(
              (_) => _InMemoryManifestRepository(),
            ),
            verifiedAdapterRepositoryProvider.overrideWith(
              (_) => _InMemoryVerifiedRepository(),
            ),
            activeAdapterBindingRepositoryProvider.overrideWith(
              (_) => _InMemoryActiveBindingRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final router = container.read(mcpToolRouterProvider);
        final result = await router.callTool(
          'set_suck',
          arguments: <String, Object?>{'intensity': 20, 'mode': 1},
        );

        expect(result.ok, isFalse);
        expect(result.errorCode, 'adapter_not_verified');
      },
    );

    test('blocks control tools when verification was revoked', () async {
      final container = ProviderContainer(
        overrides: [
          hardwareRepositoryProvider.overrideWith(
            (_) => MockHardwareRepository(),
          ),
          adapterManifestRepositoryProvider.overrideWith(
            (_) => _InMemoryManifestRepository(),
          ),
          verifiedAdapterRepositoryProvider.overrideWith(
            (_) => _InMemoryVerifiedRepository(
              records: <VerifiedAdapterRecord>[
                _record(status: AdapterVerificationStatus.revoked),
                _record(
                  adapterId: 'adapter.sosexy.verified',
                  status: AdapterVerificationStatus.verified,
                ),
              ],
            ),
          ),
          activeAdapterBindingRepositoryProvider.overrideWith(
            (_) => _InMemoryActiveBindingRepository(
              bindings: <ActiveAdapterBinding>[
                ActiveAdapterBinding(
                  deviceFingerprint: 'mock-sosexy-001',
                  adapterId: 'adapter.sosexy.demo',
                  boundAt: _boundAt,
                ),
              ],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(mcpToolRouterProvider);
      final result = await router.callTool(
        'set_vibe',
        arguments: <String, Object?>{'intensity': 20, 'mode': 1},
      );

      expect(result.ok, isFalse);
      expect(result.errorCode, 'adapter_revoked');
    });

    test(
      'falls back to legacy verified record when no binding exists',
      () async {
        final container = ProviderContainer(
          overrides: [
            hardwareRepositoryProvider.overrideWith(
              (_) => MockHardwareRepository(),
            ),
            adapterManifestRepositoryProvider.overrideWith(
              (_) => _InMemoryManifestRepository(),
            ),
            verifiedAdapterRepositoryProvider.overrideWith(
              (_) => _InMemoryVerifiedRepository(
                records: <VerifiedAdapterRecord>[
                  _record(
                    adapterId: 'adapter.sosexy.verified',
                    status: AdapterVerificationStatus.verified,
                  ),
                  _record(status: AdapterVerificationStatus.revoked),
                ],
              ),
            ),
            activeAdapterBindingRepositoryProvider.overrideWith(
              (_) => _InMemoryActiveBindingRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final router = container.read(mcpToolRouterProvider);
        final result = await router.callTool(
          'set_vibe',
          arguments: <String, Object?>{'intensity': 20, 'mode': 1},
        );

        expect(result.ok, isTrue);
        expect(result.data?['vibeIntensity'], 20);
      },
    );

    test('allows stop_all without verified adapter record', () async {
      final container = ProviderContainer(
        overrides: [
          hardwareRepositoryProvider.overrideWith(
            (_) => MockHardwareRepository(),
          ),
          adapterManifestRepositoryProvider.overrideWith(
            (_) => _InMemoryManifestRepository(),
          ),
          verifiedAdapterRepositoryProvider.overrideWith(
            (_) => _InMemoryVerifiedRepository(),
          ),
          activeAdapterBindingRepositoryProvider.overrideWith(
            (_) => _InMemoryActiveBindingRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(mcpToolRouterProvider);
      final result = await router.callTool('stop_all');

      expect(result.ok, isTrue);
      expect(result.data?['suckIntensity'], 0);
      expect(result.data?['vibeIntensity'], 0);
      expect(result.data?['emsIntensity'], 0);
    });

    test(
      'maps safety confirmation to validation error for set_ems(9)',
      () async {
        final container = ProviderContainer(
          overrides: [
            hardwareRepositoryProvider.overrideWith(
              (_) => MockHardwareRepository(),
            ),
            adapterManifestRepositoryProvider.overrideWith(
              (_) => _InMemoryManifestRepository(),
            ),
            verifiedAdapterRepositoryProvider.overrideWith(
              (_) => _InMemoryVerifiedRepository(
                records: <VerifiedAdapterRecord>[
                  _record(status: AdapterVerificationStatus.verified),
                ],
              ),
            ),
            activeAdapterBindingRepositoryProvider.overrideWith(
              (_) => _InMemoryActiveBindingRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final router = container.read(mcpToolRouterProvider);
        final result = await router.callTool(
          'set_ems',
          arguments: <String, Object?>{'intensity': 9, 'mode': 1},
        );

        expect(result.ok, isFalse);
        expect(result.errorCode, 'validation_error');
      },
    );

    test(
      'returns no_active_device when repository has no active device',
      () async {
        final container = ProviderContainer(
          overrides: [
            hardwareRepositoryProvider.overrideWith(
              (_) => _NoActiveHardwareRepo(),
            ),
            adapterManifestRepositoryProvider.overrideWith(
              (_) => _InMemoryManifestRepository(),
            ),
            verifiedAdapterRepositoryProvider.overrideWith(
              (_) => _InMemoryVerifiedRepository(),
            ),
            activeAdapterBindingRepositoryProvider.overrideWith(
              (_) => _InMemoryActiveBindingRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final router = container.read(mcpToolRouterProvider);
        final result = await router.callTool('get_status');

        expect(result.ok, isFalse);
        expect(result.errorCode, 'no_active_device');
      },
    );
  });
}

class _NoActiveHardwareRepo implements HardwareRepository {
  final _statusController = StreamController<DeviceStatus>.broadcast();
  final _scanController = StreamController<List<ToyDeviceInfo>>.broadcast();

  @override
  Future<void> connectActiveDevice(ToyDeviceInfo info) async {}

  @override
  Future<void> disconnectActiveDevice() async {}

  @override
  ToyDevice? getActiveDevice() => null;

  @override
  Future<void> startScan() async {}

  @override
  Future<void> stopScan() async {}

  @override
  Stream<DeviceStatus> watchActiveStatus() => _statusController.stream;

  @override
  Stream<List<ToyDeviceInfo>> watchDiscoveredDevices() =>
      _scanController.stream;
}

class _InMemoryManifestRepository implements AdapterManifestRepository {
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

class _InMemoryVerifiedRepository implements VerifiedAdapterRepository {
  _InMemoryVerifiedRepository({
    List<VerifiedAdapterRecord> records = const <VerifiedAdapterRecord>[],
  }) : _records = List<VerifiedAdapterRecord>.from(records);

  final List<VerifiedAdapterRecord> _records;

  @override
  Stream<List<VerifiedAdapterRecord>> watchAll() async* {
    yield List<VerifiedAdapterRecord>.from(_records);
  }

  @override
  Future<VerifiedAdapterRecord?> find({
    required String adapterId,
    required String deviceFingerprint,
  }) async {
    for (final VerifiedAdapterRecord record in _records) {
      if (record.adapterId == adapterId &&
          record.target.deviceFingerprint == deviceFingerprint) {
        return record;
      }
    }
    return null;
  }

  @override
  Future<void> remove({
    required String adapterId,
    required String deviceFingerprint,
  }) async {
    _records.removeWhere(
      (VerifiedAdapterRecord record) =>
          record.adapterId == adapterId &&
          record.target.deviceFingerprint == deviceFingerprint,
    );
  }

  @override
  Future<void> save(VerifiedAdapterRecord record) async {
    _records.removeWhere(
      (VerifiedAdapterRecord existing) =>
          existing.adapterId == record.adapterId &&
          existing.target.deviceFingerprint == record.target.deviceFingerprint,
    );
    _records.add(record);
  }
}

class _InMemoryActiveBindingRepository
    implements ActiveAdapterBindingRepository {
  _InMemoryActiveBindingRepository({
    List<ActiveAdapterBinding> bindings = const <ActiveAdapterBinding>[],
  }) : _bindings = <String, ActiveAdapterBinding>{
         for (final ActiveAdapterBinding binding in bindings)
           binding.deviceFingerprint: binding,
       };

  final Map<String, ActiveAdapterBinding> _bindings;

  @override
  Future<ActiveAdapterBinding?> findByDeviceFingerprint(
    String deviceFingerprint,
  ) async {
    return _bindings[deviceFingerprint];
  }

  @override
  Future<void> removeByDeviceFingerprint(String deviceFingerprint) async {
    _bindings.remove(deviceFingerprint);
  }

  @override
  Future<void> save(ActiveAdapterBinding binding) async {
    _bindings[binding.deviceFingerprint] = binding;
  }

  @override
  Stream<List<ActiveAdapterBinding>> watchAll() async* {
    yield _bindings.values.toList();
  }
}

final DateTime _boundAt = DateTime(2026, 5, 18, 15);

VerifiedAdapterRecord _record({
  required AdapterVerificationStatus status,
  String adapterId = 'adapter.sosexy.demo',
}) {
  return VerifiedAdapterRecord(
    manifestHash: 'hash-1',
    adapterId: adapterId,
    adapterVersion: '1.0.0',
    status: status,
    updatedAt: DateTime(2026, 5, 18, 12),
    verifiedByAppVersion: '1.0.0',
    target: const VerifiedTarget(
      deviceFingerprint: 'mock-sosexy-001',
      gattFingerprint: 'gatt:demo',
    ),
    stepResults: const <VerificationStepResult>[
      VerificationStepResult(stepKey: 'stop_all', passed: true),
    ],
    revokedReason: status == AdapterVerificationStatus.revoked
        ? 'revoked for test'
        : null,
  );
}

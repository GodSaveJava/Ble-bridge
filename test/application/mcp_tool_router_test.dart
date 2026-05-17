import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/domain/devices/toy_device.dart';
import 'package:toylink_ai/domain/entities/verified_adapter_record.dart';
import 'package:toylink_ai/domain/entities/device_status.dart';
import 'package:toylink_ai/domain/entities/toy_device_info.dart';
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
          verifiedAdapterRepositoryProvider.overrideWith(
            (_) => _InMemoryVerifiedRepository(
              records: <VerifiedAdapterRecord>[
                _record(status: AdapterVerificationStatus.verified),
              ],
            ),
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
            verifiedAdapterRepositoryProvider.overrideWith(
              (_) => _InMemoryVerifiedRepository(),
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
          verifiedAdapterRepositoryProvider.overrideWith(
            (_) => _InMemoryVerifiedRepository(
              records: <VerifiedAdapterRecord>[
                _record(status: AdapterVerificationStatus.revoked),
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

    test('allows stop_all without verified adapter record', () async {
      final container = ProviderContainer(
        overrides: [
          hardwareRepositoryProvider.overrideWith(
            (_) => MockHardwareRepository(),
          ),
          verifiedAdapterRepositoryProvider.overrideWith(
            (_) => _InMemoryVerifiedRepository(),
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
            verifiedAdapterRepositoryProvider.overrideWith(
              (_) => _InMemoryVerifiedRepository(
                records: <VerifiedAdapterRecord>[
                  _record(status: AdapterVerificationStatus.verified),
                ],
              ),
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
            verifiedAdapterRepositoryProvider.overrideWith(
              (_) => _InMemoryVerifiedRepository(),
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

VerifiedAdapterRecord _record({required AdapterVerificationStatus status}) {
  return VerifiedAdapterRecord(
    manifestHash: 'hash-1',
    adapterId: 'adapter.sosexy.demo',
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

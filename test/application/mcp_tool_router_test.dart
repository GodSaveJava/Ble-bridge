import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/domain/devices/toy_device.dart';
import 'package:toylink_ai/domain/entities/device_status.dart';
import 'package:toylink_ai/domain/entities/toy_device_info.dart';
import 'package:toylink_ai/domain/repositories/hardware_repository.dart';
import 'package:toylink_ai/infrastructure/mock/mock_hardware_repository.dart';

void main() {
  group('McpToolRouter', () {
    test('returns status on set_suck', () async {
      final container = ProviderContainer(
        overrides: [
          hardwareRepositoryProvider.overrideWith(
            (_) => MockHardwareRepository(),
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
      'maps safety confirmation to validation error for set_ems(9)',
      () async {
        final container = ProviderContainer(
          overrides: [
            hardwareRepositoryProvider.overrideWith(
              (_) => MockHardwareRepository(),
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

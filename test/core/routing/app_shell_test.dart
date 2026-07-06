import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/application/registry/active_device_registry.dart';
import 'package:toylink_ai/application/safety/safety_guard.dart';
import 'package:toylink_ai/application/use_cases/control_device_use_case.dart';
import 'package:toylink_ai/core/routing/app_shell.dart';
import 'package:toylink_ai/domain/devices/toy_device.dart';
import 'package:toylink_ai/domain/entities/device_status.dart';
import 'package:toylink_ai/domain/entities/toy_device_info.dart';
import 'package:toylink_ai/domain/repositories/hardware_repository.dart';
import 'package:toylink_ai/infrastructure/mock/mock_hardware_repository.dart';
import 'package:toylink_ai/infrastructure/mock/mock_toy_device.dart';

void main() {
  testWidgets('global emergency stop bar reserves space below shell content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AppShell(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FilledButton(
                onPressed: null,
                child: Text('Bottom page action'),
              ),
            ),
          ),
        ),
      ),
    );

    final Rect actionRect = tester.getRect(find.text('Bottom page action'));
    final Rect stopRect = tester.getRect(find.text('EMERGENCY STOP ALL'));

    expect(actionRect.bottom, lessThanOrEqualTo(stopRect.top));
  });

  testWidgets('global emergency stop stops the active device', (
    WidgetTester tester,
  ) async {
    final MockToyDevice toyDevice = MockToyDevice(id: 'mock-device-1');
    await toyDevice.connectMock();
    await toyDevice.setAll(suck: 40, vibe: 50, ems: 3);

    final MockHardwareRepository hardwareRepository = MockHardwareRepository(
      toyDevice: toyDevice,
    );
    final ActiveDeviceRegistry activeDeviceRegistry = ActiveDeviceRegistry(
      hardwareRepository: hardwareRepository,
    );
    final ControlDeviceUseCase controlDeviceUseCase = ControlDeviceUseCase(
      activeDeviceRegistry: activeDeviceRegistry,
      safetyGuard: const SafetyGuard(),
    );

    addTearDown(() async {
      await activeDeviceRegistry.dispose();
      await hardwareRepository.dispose();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          controlDeviceUseCaseProvider.overrideWithValue(controlDeviceUseCase),
        ],
        child: const MaterialApp(home: AppShell(child: Text('Shell body'))),
      ),
    );

    await tester.tap(find.text('EMERGENCY STOP ALL'));
    await tester.pump();

    final status = await toyDevice.getStatus();
    expect(status.suckIntensity, 0);
    expect(status.vibeIntensity, 0);
    expect(status.emsIntensity, 0);
    expect(find.text('All device output stopped'), findsOneWidget);
  });

  testWidgets(
    'global emergency stop reports failure when no device is active',
    (WidgetTester tester) async {
      final ActiveDeviceRegistry activeDeviceRegistry = ActiveDeviceRegistry(
        hardwareRepository: _NoActiveHardwareRepository(),
      );
      final ControlDeviceUseCase controlDeviceUseCase = ControlDeviceUseCase(
        activeDeviceRegistry: activeDeviceRegistry,
        safetyGuard: const SafetyGuard(),
      );

      addTearDown(() async {
        await activeDeviceRegistry.dispose();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            controlDeviceUseCaseProvider.overrideWithValue(
              controlDeviceUseCase,
            ),
          ],
          child: const MaterialApp(home: AppShell(child: Text('Shell body'))),
        ),
      );

      await tester.tap(find.text('EMERGENCY STOP ALL'));
      await tester.pump();

      expect(find.textContaining('Stop failed:'), findsOneWidget);
    },
  );
}

class _NoActiveHardwareRepository implements HardwareRepository {
  final _scanController = StreamController<List<ToyDeviceInfo>>.broadcast();
  final _statusController = StreamController<DeviceStatus>.broadcast();

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
  Stream<List<ToyDeviceInfo>> watchDiscoveredDevices() =>
      _scanController.stream;

  @override
  Stream<DeviceStatus> watchActiveStatus() => _statusController.stream;
}

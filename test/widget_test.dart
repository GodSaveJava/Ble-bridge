import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/application/models/active_device_adapter_readiness.dart';
import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/app.dart';
import 'package:toylink_ai/domain/entities/active_adapter_binding.dart';
import 'package:toylink_ai/domain/entities/adapter_manifest.dart';
import 'package:toylink_ai/domain/entities/device_status.dart';
import 'package:toylink_ai/domain/entities/verified_adapter_record.dart';
import 'package:toylink_ai/features/device_manager/presentation/controllers/device_manager_controller.dart';
import 'package:toylink_ai/features/device_manager/presentation/pages/adapter_verification_page.dart';
import 'package:toylink_ai/features/device_manager/presentation/pages/device_manager_page.dart';
import 'package:toylink_ai/features/home/presentation/pages/home_page.dart';
import 'package:toylink_ai/features/mcp_server/presentation/pages/mcp_page.dart';
import 'package:toylink_ai/infrastructure/providers/infrastructure_providers.dart';

void main() {
  testWidgets('renders home shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hardwareRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultHardwareRepositoryProvider);
          }),
          mcpServiceProvider.overrideWith((ref) {
            return ref.watch(defaultMcpServiceProvider);
          }),
          adapterManifestRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterManifestRepositoryProvider);
          }),
          activeAdapterBindingRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultActiveAdapterBindingRepositoryProvider);
          }),
          verifiedAdapterRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultVerifiedAdapterRepositoryProvider);
          }),
        ],
        child: const ToyLinkApp(),
      ),
    );

    expect(find.text('ToyLink AI'), findsOneWidget);
    expect(find.text(_kDeviceStatus), findsOneWidget);
    expect(find.text(_kMcpService), findsOneWidget);
    expect(find.text(_kViewAdapterStatus), findsOneWidget);
  });

  testWidgets('home page shows binding action when adapter is not bound', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hardwareRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultHardwareRepositoryProvider);
          }),
          mcpServiceProvider.overrideWith((ref) {
            return ref.watch(defaultMcpServiceProvider);
          }),
          adapterManifestRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterManifestRepositoryProvider);
          }),
          activeAdapterBindingRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultActiveAdapterBindingRepositoryProvider);
          }),
          verifiedAdapterRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultVerifiedAdapterRepositoryProvider);
          }),
          activeDeviceAdapterReadinessProvider.overrideWith(
            (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
              ActiveDeviceAdapterReadiness(
                state: ActiveDeviceAdapterReadinessState.noBinding,
                deviceId: 'device-a',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );

    expect(find.text(_kGoBindAdapter), findsOneWidget);
  });

  testWidgets('mcp page shows reverify action when adapter needs reverify', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hardwareRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultHardwareRepositoryProvider);
          }),
          mcpServiceProvider.overrideWith((ref) {
            return ref.watch(defaultMcpServiceProvider);
          }),
          adapterManifestRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterManifestRepositoryProvider);
          }),
          activeAdapterBindingRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultActiveAdapterBindingRepositoryProvider);
          }),
          verifiedAdapterRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultVerifiedAdapterRepositoryProvider);
          }),
          activeDeviceAdapterReadinessProvider.overrideWith(
            (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
              ActiveDeviceAdapterReadiness(
                state: ActiveDeviceAdapterReadinessState.needsReverify,
                deviceId: 'device-a',
                adapterId: 'generic.triple_channel.v1',
                adapterDisplayName: 'Generic Triple Channel',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: McpPage()),
      ),
    );

    expect(find.text(_kGoReverify), findsOneWidget);
  });

  testWidgets('verification page shows beginner guidance and locked submit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeDeviceStatusStreamProvider.overrideWith(
            (_) => Stream<DeviceStatus>.value(
              _deviceStatus(deviceId: 'device-a', isConnected: true),
            ),
          ),
        ],
        child: const MaterialApp(
          home: AdapterVerificationPage(adapterId: 'generic.triple_channel.v1'),
        ),
      ),
    );

    expect(find.text(_kVerificationGuide), findsOneWidget);
    expect(find.text(_kVerificationLockedHint), findsOneWidget);
  });

  testWidgets('device manager page shows recommended template guidance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hardwareRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultHardwareRepositoryProvider);
          }),
          mcpServiceProvider.overrideWith((ref) {
            return ref.watch(defaultMcpServiceProvider);
          }),
          adapterManifestRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterManifestRepositoryProvider);
          }),
          activeAdapterBindingRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultActiveAdapterBindingRepositoryProvider);
          }),
          verifiedAdapterRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultVerifiedAdapterRepositoryProvider);
          }),
          adapterExportServiceProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterExportServiceProvider);
          }),
          adapterImportServiceProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterImportServiceProvider);
          }),
          activeAdapterRecommendationsProvider.overrideWith(
            (_) => AsyncData<List<AdapterRecommendation>>(
              <AdapterRecommendation>[_demoRecommendation()],
            ),
          ),
          verifiedAdapterRecordsProvider.overrideWith(
            (_) => Stream<List<VerifiedAdapterRecord>>.value(
              const <VerifiedAdapterRecord>[],
            ),
          ),
          activeAdapterBindingsProvider.overrideWith(
            (_) => Stream<List<ActiveAdapterBinding>>.value(
              const <ActiveAdapterBinding>[],
            ),
          ),
          activeDeviceStatusStreamProvider.overrideWith(
            (_) => Stream<DeviceStatus>.value(
              _deviceStatus(deviceId: 'mock-sosexy-001', isConnected: true),
            ),
          ),
        ],
        child: const MaterialApp(home: DeviceManagerPage()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text(_kSystemRecommendedTemplate), findsOneWidget);
    expect(find.text(_kPreferThisTemplate), findsOneWidget);
    expect(find.text(_kBindRecommendedTemplate), findsOneWidget);
  });

  testWidgets('device manager page guides users to connect a device first', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hardwareRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultHardwareRepositoryProvider);
          }),
          mcpServiceProvider.overrideWith((ref) {
            return ref.watch(defaultMcpServiceProvider);
          }),
          adapterManifestRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterManifestRepositoryProvider);
          }),
          activeAdapterBindingRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultActiveAdapterBindingRepositoryProvider);
          }),
          verifiedAdapterRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultVerifiedAdapterRepositoryProvider);
          }),
          adapterExportServiceProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterExportServiceProvider);
          }),
          adapterImportServiceProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterImportServiceProvider);
          }),
          activeAdapterRecommendationsProvider.overrideWith(
            (_) => AsyncData<List<AdapterRecommendation>>(
              <AdapterRecommendation>[_demoRecommendation()],
            ),
          ),
          verifiedAdapterRecordsProvider.overrideWith(
            (_) => Stream<List<VerifiedAdapterRecord>>.value(
              const <VerifiedAdapterRecord>[],
            ),
          ),
          activeAdapterBindingsProvider.overrideWith(
            (_) => Stream<List<ActiveAdapterBinding>>.value(
              const <ActiveAdapterBinding>[],
            ),
          ),
          activeDeviceStatusStreamProvider.overrideWith(
            (_) => Stream<DeviceStatus>.value(
              _deviceStatus(deviceId: '', isConnected: false),
            ),
          ),
        ],
        child: const MaterialApp(home: DeviceManagerPage()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text(_kNextStepSuggestion), findsOneWidget);
    expect(find.text(_kGoConnectDevice), findsOneWidget);
  });

  testWidgets('device manager page guides reverify and template switch', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hardwareRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultHardwareRepositoryProvider);
          }),
          mcpServiceProvider.overrideWith((ref) {
            return ref.watch(defaultMcpServiceProvider);
          }),
          adapterManifestRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterManifestRepositoryProvider);
          }),
          activeAdapterBindingRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultActiveAdapterBindingRepositoryProvider);
          }),
          verifiedAdapterRepositoryProvider.overrideWith((ref) {
            return ref.watch(defaultVerifiedAdapterRepositoryProvider);
          }),
          adapterExportServiceProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterExportServiceProvider);
          }),
          adapterImportServiceProvider.overrideWith((ref) {
            return ref.watch(defaultAdapterImportServiceProvider);
          }),
          activeAdapterRecommendationsProvider.overrideWith(
            (_) => AsyncData<List<AdapterRecommendation>>(
              <AdapterRecommendation>[_demoRecommendation()],
            ),
          ),
          activeAdapterBindingsProvider.overrideWith(
            (_) =>
                Stream<List<ActiveAdapterBinding>>.value(<ActiveAdapterBinding>[
                  ActiveAdapterBinding(
                    deviceFingerprint: 'mock-sosexy-001',
                    adapterId: 'generic.triple_channel.v1',
                    boundAt: DateTime(2026),
                  ),
                ]),
          ),
          verifiedAdapterRecordsProvider.overrideWith(
            (_) => Stream<List<VerifiedAdapterRecord>>.value(
              <VerifiedAdapterRecord>[
                VerifiedAdapterRecord(
                  manifestHash: 'manifest-hash-1',
                  adapterId: 'generic.triple_channel.v1',
                  adapterVersion: '1.0.0',
                  status: AdapterVerificationStatus.needsReverify,
                  updatedAt: DateTime(2026),
                  verifiedByAppVersion: '1.0.0',
                  target: const VerifiedTarget(
                    deviceFingerprint: 'mock-sosexy-001',
                    gattFingerprint: 'fff0/fff3/fff4',
                  ),
                  stepResults: const <VerificationStepResult>[
                    VerificationStepResult(stepKey: 'suck', passed: true),
                  ],
                  revokedReason: 'manifest changed',
                ),
              ],
            ),
          ),
          activeDeviceStatusStreamProvider.overrideWith(
            (_) => Stream<DeviceStatus>.value(
              _deviceStatus(deviceId: 'mock-sosexy-001', isConnected: true),
            ),
          ),
        ],
        child: const MaterialApp(home: DeviceManagerPage()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text(_kReverifyCurrentTemplate), findsOneWidget);
    expect(find.text(_kSwitchToRecommendedTemplate), findsOneWidget);
  });
}

DeviceStatus _deviceStatus({
  required String deviceId,
  required bool isConnected,
}) {
  return DeviceStatus(
    deviceId: deviceId,
    isConnected: isConnected,
    suckIntensity: 0,
    vibeIntensity: 0,
    emsIntensity: 0,
    suckMode: 1,
    vibeMode: 1,
    emsMode: 1,
    lastUpdatedAt: DateTime(2026),
  );
}

AdapterRecommendation _demoRecommendation() {
  return AdapterRecommendation(
    manifest: const AdapterManifest(
      schemaVersion: 1,
      adapterId: 'generic.triple_channel.v1',
      displayName: '\u901a\u7528\u4e09\u901a\u9053\u6a21\u677f',
      protocolKey: 'generic_triple_channel',
      version: '1.0.0',
      minAppVersion: '1.0.0',
      adapterKind: AdapterKind.codecBacked,
      codecKey: 'generic_triple_channel_v1',
      bleNamePrefixes: <String>['SOSEXY'],
      matching: AdapterMatching(
        serviceUuids: <String>['0000fff0-0000-1000-8000-00805f9b34fb'],
        priority: 100,
      ),
      gatt: AdapterGattProfile(
        serviceUuid: '0000fff0-0000-1000-8000-00805f9b34fb',
        writeCharacteristicUuid: '0000fff3-0000-1000-8000-00805f9b34fb',
        notifyCharacteristicUuid: '0000fff4-0000-1000-8000-00805f9b34fb',
        writeWithoutResponse: true,
      ),
      connection: AdapterConnectionHints(
        requiresBonding: false,
        requestMtu: 185,
        notifyRequired: false,
      ),
      capabilities: AdapterCapabilities(
        supportsSuck: true,
        supportsVibe: true,
        supportsEms: true,
        supportsSetAll: true,
        supportsStopAll: true,
      ),
      ranges: AdapterRanges(
        suckIntensity: IntRange(min: 0, max: 100),
        vibeIntensity: IntRange(min: 0, max: 100),
        emsIntensity: IntRange(min: 0, max: 20),
        mode: IntRange(min: 1, max: 4),
      ),
    ),
    reasons: const <String>[
      '\u8bbe\u5907\u524d\u7f00\u4e0e\u6a21\u677f\u5339\u914d\uff1aSOSEXY',
      '\u5bfc\u5165\u540e\u4ecd\u9700\u5728\u672c\u673a\u5b8c\u6210\u4f4e\u5f3a\u5ea6\u9a8c\u8bc1',
    ],
    score: 999,
    isCurrentBinding: false,
    verificationStatus: AdapterVerificationStatus.unverified,
  );
}

const String _kDeviceStatus = '\u8bbe\u5907\u72b6\u6001';
const String _kMcpService = 'MCP \u670d\u52a1';
const String _kViewAdapterStatus = '\u67e5\u770b\u9002\u914d\u5668\u72b6\u6001';
const String _kGoBindAdapter = '\u53bb\u7ed1\u5b9a\u9002\u914d\u5668';
const String _kGoReverify = '\u53bb\u91cd\u65b0\u9a8c\u8bc1';
const String _kVerificationGuide = '\u9a8c\u8bc1\u8bf4\u660e';
const String _kVerificationLockedHint =
    '\u5168\u90e8\u6b65\u9aa4\u90fd\u786e\u8ba4\u901a\u8fc7\u540e\uff0c\u624d\u80fd\u542f\u7528 AI \u63a7\u5236\u3002';
const String _kSystemRecommendedTemplate =
    '\u7cfb\u7edf\u63a8\u8350\u6a21\u677f';
const String _kPreferThisTemplate =
    '\u4f18\u5148\u4f7f\u7528\u8fd9\u4efd\u6a21\u677f';
const String _kBindRecommendedTemplate = '\u7ed1\u5b9a\u63a8\u8350\u6a21\u677f';
const String _kNextStepSuggestion = '\u4e0b\u4e00\u6b65\u5efa\u8bae';
const String _kGoConnectDevice = '\u53bb\u8fde\u63a5\u8bbe\u5907';
const String _kReverifyCurrentTemplate =
    '\u91cd\u65b0\u9a8c\u8bc1\u5f53\u524d\u6a21\u677f';
const String _kSwitchToRecommendedTemplate =
    '\u6539\u7528\u63a8\u8350\u6a21\u677f';

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
import 'package:toylink_ai/features/device_manager/presentation/controllers/adapter_verification_controller.dart';
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
    expect(find.text(_kStopAllFirstStep), findsOneWidget);
    expect(find.text(_kStartLowIntensityTest), findsAtLeastNWidgets(1));
    expect(find.text(_kVerificationLockedHint), findsOneWidget);
  });

  testWidgets(
    'verification page shows next actions after verification passes',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeDeviceStatusStreamProvider.overrideWith(
              (_) => Stream<DeviceStatus>.value(
                _deviceStatus(deviceId: 'device-a', isConnected: true),
              ),
            ),
            adapterVerificationControllerProvider.overrideWith(
              _VerifiedAdapterVerificationController.new,
            ),
          ],
          child: const MaterialApp(
            home: AdapterVerificationPage(
              adapterId: 'generic.triple_channel.v1',
            ),
          ),
        ),
      );

      expect(find.text(_kGoStartMcp), findsOneWidget);
      expect(find.text(_kConfirmInManualControl), findsOneWidget);
    },
  );

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
    await tester.scrollUntilVisible(
      find.text(_kAdapterWizardTitle),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(_kAdapterWizardTitle), findsOneWidget);
    expect(find.text(_kWizardVerifyStep), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(_kSystemRecommendedTemplate),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text(_kSystemRecommendedTemplate), findsOneWidget);
    expect(find.text(_kOfficialTemplate), findsAtLeastNWidgets(1));
    expect(find.text(_kPreferThisTemplate), findsOneWidget);
    expect(find.text(_kBindRecommendedTemplate), findsOneWidget);
    expect(find.text(_kPendingVerificationExplanation), findsOneWidget);
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
    expect(find.text(_kConnectThenBindHint), findsOneWidget);
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
    expect(find.text(_kNeedsReverifyExplanation), findsOneWidget);
    expect(find.text(_kNeedsReverifyHint), findsOneWidget);
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
      source: AdapterSource.official,
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

class _VerifiedAdapterVerificationController
    extends AdapterVerificationController {
  @override
  AdapterVerificationState build() {
    const AdapterVerificationState base = AdapterVerificationState(
      successMessage: '验证已通过，可以启用 AI 控制。',
    );
    return base.copyWith(
      steps: base.steps
          .map((VerificationStepDraft step) => step.copyWith(passed: true))
          .toList(),
    );
  }
}

const String _kDeviceStatus = '\u8bbe\u5907\u72b6\u6001';
const String _kMcpService = 'MCP \u670d\u52a1';
const String _kViewAdapterStatus = '\u67e5\u770b\u9002\u914d\u5668\u72b6\u6001';
const String _kGoBindAdapter = '\u53bb\u7ed1\u5b9a\u9002\u914d\u5668';
const String _kGoReverify = '\u53bb\u91cd\u65b0\u9a8c\u8bc1';
const String _kVerificationGuide = '\u9a8c\u8bc1\u8bf4\u660e';
const String _kStopAllFirstStep =
    '\u5148\u786e\u8ba4\u4e00\u952e\u505c\u6b62\u6b63\u5e38';
const String _kStartLowIntensityTest =
    '\u5f00\u59cb\u4f4e\u5f3a\u5ea6\u6d4b\u8bd5';
const String _kGoStartMcp = '\u53bb\u542f\u52a8 MCP';
const String _kConfirmInManualControl =
    '\u5148\u8fdb\u5165\u624b\u52a8\u63a7\u5236\u786e\u8ba4';
const String _kVerificationLockedHint =
    '\u5168\u90e8\u6b65\u9aa4\u90fd\u786e\u8ba4\u901a\u8fc7\u540e\uff0c\u624d\u80fd\u542f\u7528 AI \u63a7\u5236\u3002';
const String _kSystemRecommendedTemplate =
    '\u7cfb\u7edf\u63a8\u8350\u6a21\u677f';
const String _kAdapterWizardTitle = '\u9002\u914d\u5411\u5bfc';
const String _kWizardVerifyStep =
    '\u7b2c 3 \u6b65\uff1a\u4f4e\u5f3a\u5ea6\u9a8c\u8bc1';
const String _kOfficialTemplate = '\u5b98\u65b9\u6a21\u677f';
const String _kPreferThisTemplate =
    '\u4f18\u5148\u4f7f\u7528\u8fd9\u4efd\u6a21\u677f';
const String _kBindRecommendedTemplate =
    '\u7ed1\u5b9a\u63a8\u8350\u6a21\u677f\uff1a\u901a\u7528\u4e09\u901a\u9053\u6a21\u677f';
const String _kNextStepSuggestion = '\u4e0b\u4e00\u6b65\u5efa\u8bae';
const String _kGoConnectDevice = '\u53bb\u8fde\u63a5\u8bbe\u5907';
const String _kReverifyCurrentTemplate =
    '\u91cd\u65b0\u9a8c\u8bc1\u5f53\u524d\u6a21\u677f';
const String _kSwitchToRecommendedTemplate =
    '\u6539\u7528\u63a8\u8350\u6a21\u677f\uff1a\u901a\u7528\u4e09\u901a\u9053\u6a21\u677f';
const String _kPendingVerificationExplanation =
    '\u8fd9\u4efd\u9002\u914d\u5668\u8fd8\u6ca1\u5728\u5f53\u524d\u8bbe\u5907\u4e0a\u505a\u8fc7\u672c\u673a\u9a8c\u8bc1\u3002';
const String _kConnectThenBindHint =
    '\u5148\u8fde\u63a5\u8bbe\u5907\uff0c\u518d\u7ed1\u5b9a\u6216\u9a8c\u8bc1\u9002\u914d\u5668\u3002';
const String _kNeedsReverifyExplanation =
    '\u8fd9\u4efd\u9002\u914d\u5668\u4e4b\u524d\u53ef\u7528\uff0c\u4f46\u56e0\u4e3a\u6a21\u677f\u5185\u5bb9\u6216\u9a8c\u8bc1\u6761\u4ef6\u53d8\u5316\uff0c\u73b0\u5728\u9700\u8981\u91cd\u65b0\u786e\u8ba4\u4e00\u6b21\u3002\u539f\u56e0\uff1a\u9002\u914d\u5668\u5185\u5bb9\u53d1\u751f\u53d8\u5316\u3002';
const String _kNeedsReverifyHint =
    '\u5148\u91cd\u65b0\u9a8c\u8bc1\uff1b\u5982\u679c\u53cd\u5e94\u548c\u4e4b\u524d\u4e0d\u4e00\u81f4\uff0c\u518d\u6539\u7528\u63a8\u8350\u6a21\u677f\u3002';

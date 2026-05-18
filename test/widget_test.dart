import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/application/models/active_device_adapter_readiness.dart';
import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/app.dart';
import 'package:toylink_ai/domain/entities/device_status.dart';
import 'package:toylink_ai/features/device_manager/presentation/pages/adapter_verification_page.dart';
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
    expect(find.text('设备状态'), findsOneWidget);
    expect(find.text('MCP 服务'), findsOneWidget);
    expect(find.text('查看适配器状态'), findsOneWidget);
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

    expect(find.text('去绑定适配器'), findsOneWidget);
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

    expect(find.text('去重新验证'), findsOneWidget);
  });

  testWidgets('verification page shows beginner guidance and locked submit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeDeviceStatusStreamProvider.overrideWith(
            (_) => Stream<DeviceStatus>.value(
              DeviceStatus(
                deviceId: 'device-a',
                isConnected: true,
                suckIntensity: 0,
                vibeIntensity: 0,
                emsIntensity: 0,
                suckMode: 1,
                vibeMode: 1,
                emsMode: 1,
                lastUpdatedAt: DateTime(2026),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: AdapterVerificationPage(adapterId: 'generic.triple_channel.v1'),
        ),
      ),
    );

    expect(find.text('验证说明'), findsOneWidget);
    expect(find.text('全部步骤都确认通过后，才能启用 AI 控制。'), findsOneWidget);
  });
}

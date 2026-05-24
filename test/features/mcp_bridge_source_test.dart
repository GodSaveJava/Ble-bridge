import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/application/models/active_device_adapter_readiness.dart';
import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/domain/entities/claude_connector_onboarding_record.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_session.dart';
import 'package:toylink_ai/domain/repositories/claude_connector_onboarding_repository.dart';
import 'package:toylink_ai/domain/services/mcp_service.dart';
import 'package:toylink_ai/domain/services/remote_bridge_service.dart';
import 'package:toylink_ai/features/mcp_server/presentation/pages/mcp_page.dart';

void main() {
  testWidgets('mcp page renders bridge source details for mock mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mcpServiceProvider.overrideWith((_) => _StoppedMcpService()),
          remoteBridgeServiceProvider.overrideWith(
            (_) => _FakeBridgeService(RemoteBridgeRuntimeSource.mock),
          ),
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => _InMemoryClaudeConnectorOnboardingRepository(),
          ),
          activeDeviceAdapterReadinessProvider.overrideWith(
            (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
              ActiveDeviceAdapterReadiness(
                state: ActiveDeviceAdapterReadinessState.verified,
                deviceId: 'device-a',
                adapterId: 'generic.triple_channel.v1',
                adapterDisplayName: '通用三通道模板',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: McpPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Claude'), findsWidgets);
    expect(find.textContaining('mock'), findsWidgets);
  });

  testWidgets('mcp page renders recovery actions for saved bridge source', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mcpServiceProvider.overrideWith((_) => _StoppedMcpService()),
          remoteBridgeServiceProvider.overrideWith(
            (_) => _FakeBridgeService(RemoteBridgeRuntimeSource.savedConfig),
          ),
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => _InMemoryClaudeConnectorOnboardingRepository(),
          ),
          activeDeviceAdapterReadinessProvider.overrideWith(
            (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
              ActiveDeviceAdapterReadiness(
                state: ActiveDeviceAdapterReadinessState.verified,
                deviceId: 'device-a',
                adapterId: 'generic.triple_channel.v1',
                adapterDisplayName: '通用三通道模板',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: McpPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Bridge'), findsWidgets);
    expect(find.byType(OutlinedButton), findsWidgets);
  });

  testWidgets('mcp page shows last sync diagnostics when bridge is ready', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mcpServiceProvider.overrideWith((_) => _StoppedMcpService()),
          remoteBridgeServiceProvider.overrideWith(
            (_) => _FakeBridgeService(
              RemoteBridgeRuntimeSource.savedConfig,
              session: RemoteBridgeSession(
                status: RemoteBridgeSessionStatus.ready,
                bridgeSessionId: 'bridge-session-1',
                connectorInfo: const RemoteBridgeConnectorInfo(
                  connectorUrl: 'https://bridge.toylink.local/mcp/claude',
                  connectorToken: 'bridge_token_1',
                  toolNames: <String>['get_status'],
                ),
                lastUpdatedAt: DateTime(2026, 5, 24, 16, 9),
              ),
            ),
          ),
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => _InMemoryClaudeConnectorOnboardingRepository(),
          ),
          activeDeviceAdapterReadinessProvider.overrideWith(
            (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
              ActiveDeviceAdapterReadiness(
                state: ActiveDeviceAdapterReadinessState.verified,
                deviceId: 'device-a',
                adapterId: 'generic.triple_channel.v1',
                adapterDisplayName: '通用三通道模板',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: McpPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('最近同步：2026-05-24 16:09'), findsOneWidget);
  });

  testWidgets('mcp page shows keepalive recovery guidance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mcpServiceProvider.overrideWith((_) => _StoppedMcpService()),
          remoteBridgeServiceProvider.overrideWith(
            (_) => _FakeBridgeService(
              RemoteBridgeRuntimeSource.savedConfig,
              session: RemoteBridgeSession(
                status: RemoteBridgeSessionStatus.error,
                bridgeSessionId: 'bridge-session-1',
                lastErrorCode: 'bridge_keepalive_failed',
                lastErrorMessage: 'keepalive failed',
                lastUpdatedAt: DateTime(2026, 5, 24, 16, 10),
              ),
            ),
          ),
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => _InMemoryClaudeConnectorOnboardingRepository(),
          ),
          activeDeviceAdapterReadinessProvider.overrideWith(
            (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
              ActiveDeviceAdapterReadiness(
                state: ActiveDeviceAdapterReadinessState.verified,
                deviceId: 'device-a',
                adapterId: 'generic.triple_channel.v1',
                adapterDisplayName: '通用三通道模板',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: McpPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('桥接保活失败'), findsOneWidget);
    expect(find.textContaining('后续保活刷新失败'), findsOneWidget);
    expect(find.textContaining('最近同步：2026-05-24 16:10'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, '重新启动桥接会话'),
      findsOneWidget,
    );
  });
}

class _StoppedMcpService implements McpService {
  @override
  McpEndpointInfo? get endpointInfo => null;

  @override
  bool get isRunning => false;

  @override
  Future<void> registerToolsForActiveDevice() async {}

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

class _FakeBridgeService
    implements RemoteBridgeService, RemoteBridgeServiceDiagnostics {
  _FakeBridgeService(this.runtimeSource, {RemoteBridgeSession? session})
    : _session =
          session ??
          const RemoteBridgeSession(status: RemoteBridgeSessionStatus.offline);

  @override
  final RemoteBridgeRuntimeSource runtimeSource;

  final RemoteBridgeSession _session;

  @override
  RemoteBridgeSession get currentSession => _session;

  @override
  void dispose() {}

  @override
  Future<void> refreshConnector() async {}

  @override
  Future<void> startSession() async {}

  @override
  Future<void> stopSession() async {}

  @override
  Stream<RemoteBridgeSession> watchSession() async* {
    yield currentSession;
  }
}

class _InMemoryClaudeConnectorOnboardingRepository
    implements ClaudeConnectorOnboardingRepository {
  ClaudeConnectorOnboardingRecord? _record;

  @override
  Future<ClaudeConnectorOnboardingRecord?> load() async => _record;

  @override
  Future<void> reset() async {
    _record = null;
  }

  @override
  Future<void> save(ClaudeConnectorOnboardingRecord record) async {
    _record = record;
  }
}

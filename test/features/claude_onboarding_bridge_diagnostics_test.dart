import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toylink_ai/application/models/active_device_adapter_readiness.dart';
import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_session.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_assignment.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_result.dart';
import 'package:toylink_ai/domain/entities/claude_connector_onboarding_record.dart';
import 'package:toylink_ai/domain/repositories/claude_connector_onboarding_repository.dart';
import 'package:toylink_ai/domain/services/remote_bridge_service.dart';
import 'package:toylink_ai/features/mcp_server/presentation/controllers/remote_bridge_diagnostics_controller.dart';
import 'package:toylink_ai/features/mcp_server/presentation/pages/claude_onboarding_page.dart';

void main() {
  testWidgets('Claude onboarding bridge diagnostics action navigates to scan', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remoteBridgeServiceProvider.overrideWith(
            (_) => _ReadyRemoteBridgeService(),
          ),
          remoteBridgeDiagnosticsProvider.overrideWith(
            (_) => const RemoteBridgeDiagnostics(
              title: '玩具连接已断开',
              summary: '远程桥接仍在线，但当前手机没有连着可控制的玩具。',
              isWarning: true,
              lastSyncLabel: '最近同步：2026-06-02 10:00',
              action: RemoteBridgeDiagnosticsAction.openDeviceScan,
              actionLabel: '去重新连接设备',
              actionRoute: '/scan',
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
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: <RouteBase>[
              GoRoute(
                path: '/',
                builder: (BuildContext context, GoRouterState state) {
                  return const ClaudeOnboardingPage();
                },
              ),
              GoRoute(
                path: '/scan',
                builder: (BuildContext context, GoRouterState state) {
                  return const Scaffold(body: Text('scan target'));
                },
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('玩具连接已断开'), findsOneWidget);
    expect(find.text('去重新连接设备'), findsOneWidget);

    await tester.tap(find.text('去重新连接设备'));
    await tester.pumpAndSettle();

    expect(find.text('scan target'), findsOneWidget);
  });
}

class _ReadyRemoteBridgeService
    implements RemoteBridgeService, RemoteBridgeServiceDiagnostics {
  @override
  RemoteBridgeSession get currentSession => const RemoteBridgeSession(
    status: RemoteBridgeSessionStatus.ready,
    bridgeSessionId: 'bridge-session-ready',
    connectorInfo: RemoteBridgeConnectorInfo(
      connectorUrl: 'https://bridge.toylink.local/mcp/claude',
      connectorToken: 'toy_bridge_token_ready',
      toolNames: <String>['get_status', 'stop_all'],
    ),
  );

  @override
  RemoteBridgeRuntimeSource get runtimeSource => RemoteBridgeRuntimeSource.mock;

  @override
  Future<void> dispose() async {}

  @override
  Future<RemoteBridgeTaskAssignment?> fetchNextTask() async => null;

  @override
  Future<void> refreshConnector() async {}

  @override
  Future<void> reportTaskResult(RemoteBridgeTaskResult result) async {}

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
  _InMemoryClaudeConnectorOnboardingRepository();

  ClaudeConnectorOnboardingRecord? _record;

  @override
  Future<void> reset() async {
    _record = null;
  }

  @override
  Future<ClaudeConnectorOnboardingRecord?> load() async => _record;

  @override
  Future<void> save(ClaudeConnectorOnboardingRecord record) async {
    _record = record;
  }
}

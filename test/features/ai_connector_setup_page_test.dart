import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/application/models/active_device_adapter_readiness.dart';
import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_session.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_assignment.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_result.dart';
import 'package:toylink_ai/domain/services/remote_bridge_service.dart';
import 'package:toylink_ai/features/mcp_server/presentation/pages/ai_connector_setup_page.dart';

void main() {
  testWidgets('AI connector setup page shows platform templates', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remoteBridgeServiceProvider.overrideWith(
            (_) => _ReadyRemoteBridgeService(),
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
        child: const MaterialApp(home: AiConnectorSetupPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('AI Connector Setup'), findsOneWidget);
    expect(find.text('连接你的原有 AI'), findsOneWidget);
    expect(find.text('Safety V0'), findsOneWidget);
    expect(find.text('set_* 未开放'), findsOneWidget);
    expect(find.text('复制连接卡片'), findsOneWidget);
    expect(find.text('复制 Deep link'), findsOneWidget);
    expect(find.text('Claude Remote MCP'), findsAtLeastNWidgets(1));
    expect(find.text('ChatGPT / GPT Actions'), findsAtLeastNWidgets(1));
    expect(find.text('OpenAPI / REST Tool'), findsAtLeastNWidgets(1));
    expect(find.text('Webhook'), findsAtLeastNWidgets(1));
    expect(find.textContaining('get_status'), findsAtLeastNWidgets(1));
    expect(find.textContaining('stop_all'), findsAtLeastNWidgets(1));
  });

  testWidgets('AI connector setup page blocks before local readiness', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remoteBridgeServiceProvider.overrideWith(
            (_) => _ReadyRemoteBridgeService(),
          ),
          activeDeviceAdapterReadinessProvider.overrideWith(
            (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
              ActiveDeviceAdapterReadiness(
                state: ActiveDeviceAdapterReadinessState.noDevice,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: AiConnectorSetupPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('还不能开始 AI 接入'), findsOneWidget);
    expect(find.text('去设备管理'), findsOneWidget);
    expect(find.text('去连接设备'), findsOneWidget);
  });
}

class _ReadyRemoteBridgeService implements RemoteBridgeService {
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
  void dispose() {}

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

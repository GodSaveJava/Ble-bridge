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
  testWidgets('mcp page shows mock bridge source label', (
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

    expect(find.text('来源：本地 mock'), findsOneWidget);
    expect(find.textContaining('当前仍在使用本地 mock 桥接'), findsOneWidget);
  });

  testWidgets('mcp page guides users back to saved bridge config when offline', (
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

    expect(find.text('来源：真实 Bridge'), findsOneWidget);
    expect(find.text('去检查远程桥接配置'), findsOneWidget);
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
  _FakeBridgeService(this.runtimeSource);

  @override
  final RemoteBridgeRuntimeSource runtimeSource;

  @override
  RemoteBridgeSession get currentSession => const RemoteBridgeSession(
    status: RemoteBridgeSessionStatus.offline,
  );

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

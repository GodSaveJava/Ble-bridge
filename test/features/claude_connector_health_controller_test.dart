import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/application/models/active_device_adapter_readiness.dart';
import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/domain/entities/claude_connector_onboarding_record.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_session.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_assignment.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_result.dart';
import 'package:toylink_ai/domain/repositories/claude_connector_onboarding_repository.dart';
import 'package:toylink_ai/domain/services/remote_bridge_service.dart';
import 'package:toylink_ai/features/mcp_server/presentation/controllers/claude_connector_onboarding_controller.dart';
import 'package:toylink_ai/features/mcp_server/presentation/controllers/claude_connector_health_controller.dart';

void main() {
  test('reports pending when Claude connector is not configured yet', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
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
        remoteBridgeServiceProvider.overrideWith((_) => _ReadyBridgeService()),
        claudeConnectorOnboardingRepositoryProvider.overrideWith(
          (_) => _InMemoryClaudeConnectorOnboardingRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(claudeConnectorOnboardingControllerProvider.notifier)
        .load();

    final AsyncValue<ClaudeConnectorHealthCheck> healthAsync = container.read(
      claudeConnectorHealthCheckProvider,
    );
    final ClaudeConnectorHealthCheck health = healthAsync.requireValue;

    expect(health.status, ClaudeConnectorHealthStatus.pending);
    expect(health.onboardingCompleted, isFalse);
    expect(health.summary, contains('Claude'));
  });

  test(
    'reports ready when device bridge and Claude onboarding are complete',
    () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
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
          remoteBridgeServiceProvider.overrideWith(
            (_) => _ReadyBridgeService(),
          ),
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => _InMemoryClaudeConnectorOnboardingRepository(
              record: ClaudeConnectorOnboardingRecord(
                deviceId: 'device-a',
                adapterId: 'generic.triple_channel.v1',
                completedAt: DateTime(2026),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(claudeConnectorOnboardingControllerProvider.notifier)
          .load();

      final AsyncValue<ClaudeConnectorHealthCheck> healthAsync = container.read(
        claudeConnectorHealthCheckProvider,
      );
      final ClaudeConnectorHealthCheck health = healthAsync.requireValue;

      expect(health.status, ClaudeConnectorHealthStatus.ready);
      expect(health.isHealthy, isTrue);
      expect(health.summary, contains('Claude 原对话'));
    },
  );
}

class _ReadyBridgeService implements RemoteBridgeService {
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
  Future<void> reportTaskResult(RemoteBridgeTaskResult result) async {}

  @override
  Future<RemoteBridgeTaskAssignment?> fetchNextTask() async => null;

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
  _InMemoryClaudeConnectorOnboardingRepository({this.record});

  ClaudeConnectorOnboardingRecord? record;

  @override
  Future<ClaudeConnectorOnboardingRecord?> load() async => record;

  @override
  Future<void> reset() async {
    record = null;
  }

  @override
  Future<void> save(ClaudeConnectorOnboardingRecord next) async {
    record = next;
  }
}

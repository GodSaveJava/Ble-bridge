import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/application/models/active_device_adapter_readiness.dart';
import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_session.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_assignment.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_result.dart';
import 'package:toylink_ai/domain/services/remote_bridge_service.dart';
import 'package:toylink_ai/features/mcp_server/presentation/controllers/remote_bridge_diagnostics_controller.dart';

void main() {
  test('reports keepalive failure with restart guidance', () {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        remoteBridgeServiceProvider.overrideWith(
          (_) => _FakeBridgeService(
            RemoteBridgeSession(
              status: RemoteBridgeSessionStatus.error,
              bridgeSessionId: 'bridge-session-1',
              lastErrorCode: 'bridge_keepalive_failed',
              lastErrorMessage: 'keepalive failed',
              lastUpdatedAt: DateTime(2026, 5, 25, 10, 8),
            ),
          ),
        ),
        activeDeviceAdapterReadinessProvider.overrideWith(
          (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
            ActiveDeviceAdapterReadiness(
              state: ActiveDeviceAdapterReadinessState.verified,
              deviceId: 'device-a',
              adapterId: 'generic.triple_channel.v1',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final RemoteBridgeDiagnostics diagnostics = container.read(
      remoteBridgeDiagnosticsProvider,
    );

    expect(diagnostics.title, '桥接保活失败');
    expect(diagnostics.summary, contains('重新启动桥接会话'));
    expect(diagnostics.lastSyncLabel, '最近同步：2026-05-25 10:08');
    expect(diagnostics.actionLabel, '重新启动桥接会话');
    expect(
      diagnostics.action,
      RemoteBridgeDiagnosticsAction.restartBridgeSession,
    );
    expect(diagnostics.actionRoute, isNull);
  });

  test('reports device disconnected when bridge is still ready', () {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        remoteBridgeServiceProvider.overrideWith(
          (_) => _FakeBridgeService(
            RemoteBridgeSession(
              status: RemoteBridgeSessionStatus.ready,
              bridgeSessionId: 'bridge-session-1',
              connectorInfo: const RemoteBridgeConnectorInfo(
                connectorUrl: 'https://bridge.toylink.local/mcp/claude',
                connectorToken: 'bridge_token_1',
                toolNames: <String>['get_status'],
              ),
              lastUpdatedAt: DateTime(2026, 5, 25, 10, 9),
            ),
          ),
        ),
        activeDeviceAdapterReadinessProvider.overrideWith(
          (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
            ActiveDeviceAdapterReadiness(
              state: ActiveDeviceAdapterReadinessState.noDevice,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final RemoteBridgeDiagnostics diagnostics = container.read(
      remoteBridgeDiagnosticsProvider,
    );

    expect(diagnostics.title, '玩具连接已断开');
    expect(diagnostics.summary, contains('重新连接设备'));
    expect(diagnostics.lastSyncLabel, '最近同步：2026-05-25 10:09');
    expect(diagnostics.actionLabel, '去重新连接设备');
    expect(
      diagnostics.action,
      RemoteBridgeDiagnosticsAction.openDeviceScan,
    );
    expect(diagnostics.actionRoute, '/scan');
  });

  test('reports ready session with last sync label', () {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        remoteBridgeServiceProvider.overrideWith(
          (_) => _FakeBridgeService(
            RemoteBridgeSession(
              status: RemoteBridgeSessionStatus.ready,
              bridgeSessionId: 'bridge-session-1',
              connectorInfo: const RemoteBridgeConnectorInfo(
                connectorUrl: 'https://bridge.toylink.local/mcp/claude',
                connectorToken: 'bridge_token_1',
                toolNames: <String>['get_status'],
              ),
              lastUpdatedAt: DateTime(2026, 5, 25, 10, 10),
            ),
          ),
        ),
        activeDeviceAdapterReadinessProvider.overrideWith(
          (_) => const AsyncData<ActiveDeviceAdapterReadiness>(
            ActiveDeviceAdapterReadiness(
              state: ActiveDeviceAdapterReadinessState.verified,
              deviceId: 'device-a',
              adapterId: 'generic.triple_channel.v1',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final RemoteBridgeDiagnostics diagnostics = container.read(
      remoteBridgeDiagnosticsProvider,
    );

    expect(diagnostics.title, '桥接连接正常');
    expect(diagnostics.lastSyncLabel, '最近同步：2026-05-25 10:10');
    expect(diagnostics.actionLabel, isNull);
  });
}

class _FakeBridgeService implements RemoteBridgeService {
  _FakeBridgeService(this._session);

  final RemoteBridgeSession _session;

  @override
  RemoteBridgeSession get currentSession => _session;

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
    yield _session;
  }
}

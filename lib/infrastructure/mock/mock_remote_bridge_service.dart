import 'dart:async';

import '../../domain/entities/remote_bridge_session.dart';
import '../../domain/services/remote_bridge_service.dart';

class MockRemoteBridgeService
    implements RemoteBridgeService, RemoteBridgeServiceDiagnostics {
  MockRemoteBridgeService()
    : _session = const RemoteBridgeSession(
        status: RemoteBridgeSessionStatus.offline,
      );

  RemoteBridgeSession _session;

  final _controller = StreamController<RemoteBridgeSession>.broadcast();

  int _connectorRevision = 0;

  @override
  RemoteBridgeSession get currentSession => _session;

  @override
  RemoteBridgeRuntimeSource get runtimeSource => RemoteBridgeRuntimeSource.mock;

  @override
  void dispose() {
    _controller.close();
  }

  @override
  Future<void> refreshConnector() async {
    final String? bridgeSessionId = _session.bridgeSessionId;
    if (bridgeSessionId == null || bridgeSessionId.isEmpty) {
      _emit(
        _session.copyWith(
          status: RemoteBridgeSessionStatus.error,
          lastErrorCode: 'bridge_session_missing',
          lastErrorMessage: '当前还没有可刷新的桥接会话。',
          lastUpdatedAt: DateTime.now(),
        ),
      );
      return;
    }

    _emit(
      _session.copyWith(
        status: RemoteBridgeSessionStatus.busy,
        clearError: true,
        lastUpdatedAt: DateTime.now(),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    _connectorRevision += 1;
    _emit(
      RemoteBridgeSession(
        status: RemoteBridgeSessionStatus.ready,
        bridgeSessionId: bridgeSessionId,
        connectorInfo: _buildConnectorInfo(revision: _connectorRevision),
        lastUpdatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> startSession() async {
    _emit(
      _session.copyWith(
        status: RemoteBridgeSessionStatus.connecting,
        clearError: true,
        lastUpdatedAt: DateTime.now(),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    _connectorRevision += 1;
    _emit(
      RemoteBridgeSession(
        status: RemoteBridgeSessionStatus.ready,
        bridgeSessionId: 'bridge-session-$_connectorRevision',
        connectorInfo: _buildConnectorInfo(revision: _connectorRevision),
        lastUpdatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> stopSession() async {
    _emit(
      RemoteBridgeSession(
        status: RemoteBridgeSessionStatus.offline,
        lastUpdatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Stream<RemoteBridgeSession> watchSession() async* {
    yield _session;
    yield* _controller.stream;
  }

  RemoteBridgeConnectorInfo _buildConnectorInfo({required int revision}) {
    return RemoteBridgeConnectorInfo(
      connectorUrl: 'https://bridge.toylink.local/mcp/claude',
      connectorToken: 'toy_bridge_token_$revision',
      toolNames: const <String>[
        'set_suck',
        'set_vibe',
        'set_ems',
        'set_all',
        'stop_all',
        'get_status',
      ],
    );
  }

  void _emit(RemoteBridgeSession next) {
    _session = next;
    _controller.add(next);
  }
}

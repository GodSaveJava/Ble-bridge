import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_session.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_assignment.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_result.dart';
import 'package:toylink_ai/infrastructure/bridge/remote_bridge_protocol.dart';

void main() {
  test('remote bridge protocol builds stable session paths', () {
    expect(
      RemoteBridgeProtocol.sessionStartPath,
      '/mobile-bridge/session/start',
    );
    expect(
      RemoteBridgeProtocol.sessionRefreshPath('bridge-session-1'),
      '/mobile-bridge/session/bridge-session-1/refresh',
    );
    expect(
      RemoteBridgeProtocol.sessionNextTaskPath('bridge-session-1'),
      '/mobile-bridge/session/bridge-session-1/next-task',
    );
    expect(
      RemoteBridgeProtocol.sessionTaskResultPath('bridge-session-1'),
      '/mobile-bridge/session/bridge-session-1/task-result',
    );
    expect(
      RemoteBridgeProtocol.sessionStopPath('bridge-session-1'),
      '/mobile-bridge/session/bridge-session-1/stop',
    );
  });

  test('remote bridge protocol builds stable request payloads', () {
    expect(
      RemoteBridgeProtocol.sessionRequestBody('client-1'),
      <String, Object?>{'clientId': 'client-1'},
    );

    expect(
      RemoteBridgeProtocol.taskResultRequestBody(
        'client-1',
        const RemoteBridgeTaskResult(
          ok: true,
          requestId: 'task-1',
          tool: 'get_status',
          result: <String, dynamic>{
            'deviceId': 'mock-sosexy-001',
            'status': 'ready',
          },
        ),
      ),
      <String, Object?>{
        'clientId': 'client-1',
        'requestId': 'task-1',
        'tool': 'get_status',
        'ok': true,
        'result': <String, dynamic>{'status': 'ready'},
        'errorCode': null,
        'errorMessage': null,
      },
    );
  });

  test('remote bridge protocol parses session response payload', () {
    final RemoteBridgeSession session =
        RemoteBridgeProtocol.parseSessionResponse(
          <String, dynamic>{
            'bridgeSessionId': 'bridge-session-1',
            'connectorUrl': 'https://bridge.toylink.local/mcp/claude',
            'connectorToken': 'token-1',
            'toolNames': <String>['get_status', 'stop_all'],
          },
          fallback: const RemoteBridgeSession(
            status: RemoteBridgeSessionStatus.offline,
            bridgeSessionId: 'fallback-session',
          ),
        );

    expect(session.status, RemoteBridgeSessionStatus.ready);
    expect(session.bridgeSessionId, 'bridge-session-1');
    expect(
      session.connectorInfo?.connectorUrl,
      'https://bridge.toylink.local/mcp/claude',
    );
    expect(session.connectorInfo?.connectorToken, 'token-1');
    expect(session.connectorInfo?.toolNames, <String>[
      'get_status',
      'stop_all',
    ]);
  });

  test('remote bridge protocol parses task assignment payload', () {
    final RemoteBridgeTaskAssignment? assignment =
        RemoteBridgeProtocol.parseTaskAssignmentResponse(<String, dynamic>{
          'requestId': 'task-1',
          'tool': 'get_status',
          'input': <String, Object?>{'source': 'bridge'},
        });

    expect(assignment, isNotNull);
    expect(assignment?.requestId, 'task-1');
    expect(assignment?.tool, 'get_status');
    expect(assignment?.input, <String, Object?>{'source': 'bridge'});
  });
}

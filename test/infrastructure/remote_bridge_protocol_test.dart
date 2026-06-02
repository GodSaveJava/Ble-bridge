import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_result.dart';
import 'package:toylink_ai/infrastructure/bridge/remote_bridge_protocol.dart';

void main() {
  test('remote bridge protocol builds stable session paths', () {
    expect(RemoteBridgeProtocol.sessionStartPath, '/mobile-bridge/session/start');
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
          result: <String, dynamic>{'status': 'ready'},
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
}

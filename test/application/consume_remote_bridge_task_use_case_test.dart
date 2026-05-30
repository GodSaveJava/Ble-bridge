import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/application/use_cases/consume_remote_bridge_task_use_case.dart';
import 'package:toylink_ai/application/use_cases/execute_remote_bridge_task_use_case.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_session.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_assignment.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_result.dart';
import 'package:toylink_ai/domain/services/remote_bridge_service.dart';
import 'package:toylink_ai/domain/services/remote_bridge_task_executor.dart';

void main() {
  group('ConsumeRemoteBridgeTaskUseCase', () {
    test('executes task and reports success result back to bridge', () async {
      final _RecordingBridgeService bridgeService = _RecordingBridgeService(
        toolNames: const <String>['get_status', 'stop_all'],
      );
      final ConsumeRemoteBridgeTaskUseCase useCase =
          ConsumeRemoteBridgeTaskUseCase(
            remoteBridgeService: bridgeService,
            executeRemoteBridgeTaskUseCase: ExecuteRemoteBridgeTaskUseCase(
              remoteBridgeService: bridgeService,
              remoteBridgeTaskExecutor: const _FakeTaskExecutor(
                result: RemoteBridgeTaskResult(
                  ok: true,
                  requestId: 'bridge-task-1',
                  tool: 'get_status',
                  result: <String, dynamic>{'deviceId': 'mock-sosexy-001'},
                ),
              ),
            ),
          );

      final RemoteBridgeTaskResult result = await useCase.consume(
        requestId: 'bridge-task-1',
        tool: 'get_status',
      );

      expect(result.ok, isTrue);
      expect(bridgeService.reportedResults, hasLength(1));
      expect(bridgeService.reportedResults.single.requestId, 'bridge-task-1');
      expect(bridgeService.reportedResults.single.tool, 'get_status');
      expect(
        bridgeService.reportedResults.single.result,
        <String, dynamic>{'deviceId': 'mock-sosexy-001'},
      );
    });

    test('reports failure result back to bridge when task execution fails', () async {
      final _RecordingBridgeService bridgeService = _RecordingBridgeService(
        toolNames: const <String>['get_status'],
      );
      final ConsumeRemoteBridgeTaskUseCase useCase =
          ConsumeRemoteBridgeTaskUseCase(
            remoteBridgeService: bridgeService,
            executeRemoteBridgeTaskUseCase: ExecuteRemoteBridgeTaskUseCase(
              remoteBridgeService: bridgeService,
              remoteBridgeTaskExecutor: const _FakeTaskExecutor(
                result: RemoteBridgeTaskResult(
                  ok: true,
                  requestId: 'bridge-task-2',
                  tool: 'stop_all',
                ),
              ),
            ),
          );

      final RemoteBridgeTaskResult result = await useCase.consume(
        requestId: 'bridge-task-2',
        tool: 'stop_all',
      );

      expect(result.ok, isFalse);
      expect(result.errorCode, 'tool_not_advertised_by_connector');
      expect(bridgeService.reportedResults, hasLength(1));
      expect(bridgeService.reportedResults.single.ok, isFalse);
      expect(
        bridgeService.reportedResults.single.errorCode,
        'tool_not_advertised_by_connector',
      );
    });
  });
}

class _RecordingBridgeService implements RemoteBridgeService {
  _RecordingBridgeService({required List<String> toolNames})
    : _session = RemoteBridgeSession(
        status: RemoteBridgeSessionStatus.ready,
        bridgeSessionId: 'bridge-session-test',
        connectorInfo: RemoteBridgeConnectorInfo(
          connectorUrl: 'https://bridge.toylink.local/mcp/claude',
          connectorToken: 'toy-connector-token',
          toolNames: toolNames,
        ),
      );

  final RemoteBridgeSession _session;
  final List<RemoteBridgeTaskResult> reportedResults = <RemoteBridgeTaskResult>[];

  @override
  RemoteBridgeSession get currentSession => _session;

  @override
  void dispose() {}

  @override
  Future<void> refreshConnector() async {}

  @override
  Future<RemoteBridgeTaskAssignment?> fetchNextTask() async => null;

  @override
  Future<void> reportTaskResult(RemoteBridgeTaskResult result) async {
    reportedResults.add(result);
  }

  @override
  Future<void> startSession() async {}

  @override
  Future<void> stopSession() async {}

  @override
  Stream<RemoteBridgeSession> watchSession() async* {
    yield _session;
  }
}

class _FakeTaskExecutor implements RemoteBridgeTaskExecutor {
  const _FakeTaskExecutor({required this.result});

  final RemoteBridgeTaskResult result;

  @override
  void dispose() {}

  @override
  Future<RemoteBridgeTaskResult> execute({
    String? requestId,
    required String tool,
    Map<String, Object?> input = const <String, Object?>{},
  }) async {
    return result;
  }
}

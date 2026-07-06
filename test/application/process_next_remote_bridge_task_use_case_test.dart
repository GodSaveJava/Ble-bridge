import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/application/bridge/remote_bridge_task_assignment_handler.dart';
import 'package:toylink_ai/application/use_cases/process_next_remote_bridge_task_use_case.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_session.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_assignment.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_result.dart';
import 'package:toylink_ai/domain/services/remote_bridge_service.dart';

void main() {
  group('ProcessNextRemoteBridgeTaskUseCase', () {
    test('returns null when bridge has no pending task', () async {
      final useCase = ProcessNextRemoteBridgeTaskUseCase(
        remoteBridgeService: _QueueBridgeService(),
        assignmentHandler: RemoteBridgeTaskAssignmentHandler(
          consumeTask: ({
            String? requestId,
            required String tool,
            Map<String, Object?> input = const <String, Object?>{},
          }) async {
            return RemoteBridgeTaskResult(
              ok: true,
              requestId: requestId,
              tool: tool,
              result: input,
            );
          },
        ),
      );

      final result = await useCase.processNextTask();
      expect(result, isNull);
    });

    test('fetches one task and forwards it through assignment handler', () async {
      final bridgeService = _QueueBridgeService(
        pendingTask: const RemoteBridgeTaskAssignment(
          requestId: 'bridge-task-5',
          tool: 'get_status',
          input: <String, Object?>{'source': 'bridge'},
        ),
      );
      final useCase = ProcessNextRemoteBridgeTaskUseCase(
        remoteBridgeService: bridgeService,
        assignmentHandler: RemoteBridgeTaskAssignmentHandler(
          consumeTask: ({
            String? requestId,
            required String tool,
            Map<String, Object?> input = const <String, Object?>{},
          }) async {
            return RemoteBridgeTaskResult(
              ok: true,
              requestId: requestId,
              tool: tool,
              result: input,
            );
          },
        ),
      );

      final result = await useCase.processNextTask();

      expect(result?.ok, isTrue);
      expect(result?.requestId, 'bridge-task-5');
      expect(result?.tool, 'get_status');
      expect(result?.result, <String, Object?>{'source': 'bridge'});
    });
  });
}

class _QueueBridgeService implements RemoteBridgeService {
  _QueueBridgeService({this.pendingTask});

  RemoteBridgeTaskAssignment? pendingTask;

  @override
  RemoteBridgeSession get currentSession => const RemoteBridgeSession(
    status: RemoteBridgeSessionStatus.ready,
  );

  @override
  void dispose() {}

  @override
  Future<RemoteBridgeTaskAssignment?> fetchNextTask() async {
    final next = pendingTask;
    pendingTask = null;
    return next;
  }

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

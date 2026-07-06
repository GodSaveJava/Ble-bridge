import '../../application/bridge/remote_bridge_task_assignment_handler.dart';
import '../../domain/entities/remote_bridge_task_assignment.dart';
import '../../domain/entities/remote_bridge_task_result.dart';
import '../../domain/services/remote_bridge_service.dart';

class ProcessNextRemoteBridgeTaskUseCase {
  ProcessNextRemoteBridgeTaskUseCase({
    required RemoteBridgeService remoteBridgeService,
    required RemoteBridgeTaskAssignmentHandler assignmentHandler,
  }) : _remoteBridgeService = remoteBridgeService,
       _assignmentHandler = assignmentHandler;

  final RemoteBridgeService _remoteBridgeService;
  final RemoteBridgeTaskAssignmentHandler _assignmentHandler;

  Future<RemoteBridgeTaskResult?> processNextTask() async {
    final RemoteBridgeTaskAssignment? assignment =
        await _remoteBridgeService.fetchNextTask();
    if (assignment == null) {
      return null;
    }

    return _assignmentHandler.handle(<String, Object?>{
      'requestId': assignment.requestId,
      'tool': assignment.tool,
      'input': assignment.input,
    });
  }
}

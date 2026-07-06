import '../../domain/entities/remote_bridge_task_result.dart';
import '../../domain/services/remote_bridge_service.dart';
import 'execute_remote_bridge_task_use_case.dart';

class ConsumeRemoteBridgeTaskUseCase {
  ConsumeRemoteBridgeTaskUseCase({
    required RemoteBridgeService remoteBridgeService,
    required ExecuteRemoteBridgeTaskUseCase executeRemoteBridgeTaskUseCase,
  }) : _remoteBridgeService = remoteBridgeService,
       _executeRemoteBridgeTaskUseCase = executeRemoteBridgeTaskUseCase;

  final RemoteBridgeService _remoteBridgeService;
  final ExecuteRemoteBridgeTaskUseCase _executeRemoteBridgeTaskUseCase;

  Future<RemoteBridgeTaskResult> consume({
    String? requestId,
    required String tool,
    Map<String, Object?> input = const <String, Object?>{},
  }) async {
    final RemoteBridgeTaskResult result = await _executeRemoteBridgeTaskUseCase
        .execute(
          requestId: requestId,
          tool: tool,
          input: input,
        );
    await _remoteBridgeService.reportTaskResult(result);
    return result;
  }
}

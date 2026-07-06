import '../mcp/safety_v0_tools.dart';
import '../../domain/entities/remote_bridge_session.dart';
import '../../domain/entities/remote_bridge_task_result.dart';
import '../../domain/services/remote_bridge_service.dart';
import '../../domain/services/remote_bridge_task_executor.dart';

class ExecuteRemoteBridgeTaskUseCase {
  ExecuteRemoteBridgeTaskUseCase({
    required RemoteBridgeService remoteBridgeService,
    required RemoteBridgeTaskExecutor remoteBridgeTaskExecutor,
  }) : _remoteBridgeService = remoteBridgeService,
       _remoteBridgeTaskExecutor = remoteBridgeTaskExecutor;

  final RemoteBridgeService _remoteBridgeService;
  final RemoteBridgeTaskExecutor _remoteBridgeTaskExecutor;

  Future<RemoteBridgeTaskResult> execute({
    String? requestId,
    required String tool,
    Map<String, Object?> input = const <String, Object?>{},
  }) async {
    final RemoteBridgeSession session = _remoteBridgeService.currentSession;

    if (!SafetyV0Tools.contains(tool)) {
      return RemoteBridgeTaskResult(
        ok: false,
        requestId: requestId,
        tool: tool,
        errorCode: 'tool_not_enabled_for_bridge',
        errorMessage:
            'Remote bridge Safety V0 only allows get_status and stop_all.',
      );
    }

    if (!session.isReady) {
      return RemoteBridgeTaskResult(
        ok: false,
        requestId: requestId,
        tool: tool,
        errorCode: 'bridge_session_not_ready',
        errorMessage: 'Remote bridge session is not ready.',
      );
    }

    final List<String> toolNames = session.connectorInfo?.toolNames ?? const [];
    if (!toolNames.contains(tool)) {
      return RemoteBridgeTaskResult(
        ok: false,
        requestId: requestId,
        tool: tool,
        errorCode: 'tool_not_advertised_by_connector',
        errorMessage: 'Connector does not advertise this tool: $tool',
      );
    }

    return _remoteBridgeTaskExecutor.execute(
      requestId: requestId,
      tool: tool,
      input: input,
    );
  }
}

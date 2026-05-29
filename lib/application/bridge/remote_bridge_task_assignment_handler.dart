import '../../domain/entities/remote_bridge_task_result.dart';

typedef ConsumeRemoteBridgeTask = Future<RemoteBridgeTaskResult> Function({
  String? requestId,
  required String tool,
  Map<String, Object?> input,
});

class RemoteBridgeTaskAssignmentHandler {
  RemoteBridgeTaskAssignmentHandler({
    required ConsumeRemoteBridgeTask consumeTask,
  }) : _consumeTask = consumeTask;

  final ConsumeRemoteBridgeTask _consumeTask;

  Future<RemoteBridgeTaskResult> handle(Object? payload) async {
    if (payload is! Map<String, dynamic>) {
      return const RemoteBridgeTaskResult(
        ok: false,
        errorCode: 'validation_error',
        errorMessage: 'Request body must be a JSON object.',
      );
    }

    final Object? requestId = payload['requestId'];
    final Object? tool = payload['tool'];
    final Object? input = payload['input'];

    if (tool is! String || tool.isEmpty) {
      return RemoteBridgeTaskResult(
        ok: false,
        requestId: requestId?.toString(),
        errorCode: 'validation_error',
        errorMessage: 'Missing or invalid tool field.',
      );
    }

    if (input != null && input is! Map<String, dynamic>) {
      return RemoteBridgeTaskResult(
        ok: false,
        requestId: requestId?.toString(),
        tool: tool,
        errorCode: 'validation_error',
        errorMessage: 'Input must be a JSON object.',
      );
    }

    return _consumeTask(
      requestId: requestId?.toString(),
      tool: tool,
      input: (input as Map<String, dynamic>? ?? const <String, dynamic>{})
          .cast<String, Object?>(),
    );
  }
}

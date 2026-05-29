import '../entities/remote_bridge_task_result.dart';

abstract class RemoteBridgeTaskExecutor {
  Future<RemoteBridgeTaskResult> execute({
    String? requestId,
    required String tool,
    Map<String, Object?> input = const <String, Object?>{},
  });

  void dispose();
}

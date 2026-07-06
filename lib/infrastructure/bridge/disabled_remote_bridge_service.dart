import '../../domain/entities/remote_bridge_session.dart';
import '../../domain/entities/remote_bridge_task_assignment.dart';
import '../../domain/entities/remote_bridge_task_result.dart';
import '../../domain/services/remote_bridge_service.dart';

class DisabledRemoteBridgeService
    implements RemoteBridgeService, RemoteBridgeServiceDiagnostics {
  const DisabledRemoteBridgeService();

  static const RemoteBridgeSession _offlineSession = RemoteBridgeSession(
    status: RemoteBridgeSessionStatus.offline,
  );

  @override
  RemoteBridgeSession get currentSession => _offlineSession;

  @override
  RemoteBridgeRuntimeSource get runtimeSource => RemoteBridgeRuntimeSource.disabled;

  @override
  void dispose() {}

  @override
  Future<RemoteBridgeTaskAssignment?> fetchNextTask() async => null;

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
    yield _offlineSession;
  }
}

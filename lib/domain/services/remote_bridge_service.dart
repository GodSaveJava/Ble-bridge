import '../entities/remote_bridge_session.dart';
import '../entities/remote_bridge_task_result.dart';

enum RemoteBridgeRuntimeSource { mock, dartDefine, savedConfig, unknown }

abstract class RemoteBridgeServiceDiagnostics {
  RemoteBridgeRuntimeSource get runtimeSource;
}

abstract class RemoteBridgeService {
  RemoteBridgeSession get currentSession;
  Stream<RemoteBridgeSession> watchSession();
  Future<void> startSession();
  Future<void> stopSession();
  Future<void> refreshConnector();
  Future<void> reportTaskResult(RemoteBridgeTaskResult result);
  void dispose();
}

import '../entities/remote_bridge_session.dart';

abstract class RemoteBridgeService {
  RemoteBridgeSession get currentSession;
  Stream<RemoteBridgeSession> watchSession();
  Future<void> startSession();
  Future<void> stopSession();
  Future<void> refreshConnector();
  void dispose();
}

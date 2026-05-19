import '../../domain/entities/remote_bridge_session.dart';
import '../../domain/services/remote_bridge_service.dart';

class ManageRemoteBridgeSessionUseCase {
  ManageRemoteBridgeSessionUseCase({
    required RemoteBridgeService remoteBridgeService,
  }) : _remoteBridgeService = remoteBridgeService;

  final RemoteBridgeService _remoteBridgeService;

  RemoteBridgeSession get currentSession => _remoteBridgeService.currentSession;

  Stream<RemoteBridgeSession> watchSession() =>
      _remoteBridgeService.watchSession();

  Future<void> startSession() => _remoteBridgeService.startSession();

  Future<void> stopSession() => _remoteBridgeService.stopSession();

  Future<void> refreshConnector() => _remoteBridgeService.refreshConnector();
}

import '../../domain/entities/remote_bridge_config.dart';
import '../../domain/entities/remote_bridge_probe_result.dart';
import '../../domain/services/remote_bridge_probe_service.dart';

class TestRemoteBridgeConnectionUseCase {
  TestRemoteBridgeConnectionUseCase({
    required RemoteBridgeProbeService probeService,
  }) : _probeService = probeService;

  final RemoteBridgeProbeService _probeService;

  Future<RemoteBridgeProbeResult> execute(RemoteBridgeConfig config) {
    return _probeService.probe(config.normalized());
  }
}

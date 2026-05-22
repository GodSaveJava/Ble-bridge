import '../entities/remote_bridge_config.dart';
import '../entities/remote_bridge_probe_result.dart';

abstract class RemoteBridgeProbeService {
  Future<RemoteBridgeProbeResult> probe(RemoteBridgeConfig config);
}

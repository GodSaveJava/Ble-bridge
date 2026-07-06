import '../entities/remote_bridge_config.dart';

abstract class RemoteBridgeConfigRepository {
  Future<RemoteBridgeConfig> load();

  Future<void> save(RemoteBridgeConfig config);

  Future<void> reset();
}

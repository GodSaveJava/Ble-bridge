import '../../domain/entities/remote_bridge_config.dart';
import '../../domain/repositories/remote_bridge_config_repository.dart';

class ManageRemoteBridgeConfigUseCase {
  ManageRemoteBridgeConfigUseCase({
    required RemoteBridgeConfigRepository repository,
  }) : _repository = repository;

  final RemoteBridgeConfigRepository _repository;

  Future<RemoteBridgeConfig> load() => _repository.load();

  Future<RemoteBridgeConfig> save(RemoteBridgeConfig config) async {
    final RemoteBridgeConfig normalized = config.normalized();
    await _repository.save(normalized);
    return normalized;
  }

  Future<RemoteBridgeConfig> reset() async {
    await _repository.reset();
    return const RemoteBridgeConfig();
  }
}

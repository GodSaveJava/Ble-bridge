import '../../domain/repositories/remote_bridge_auto_consume_repository.dart';

class ManageRemoteBridgeAutoConsumeUseCase {
  ManageRemoteBridgeAutoConsumeUseCase({
    required RemoteBridgeAutoConsumeRepository repository,
  }) : _repository = repository;

  final RemoteBridgeAutoConsumeRepository _repository;

  Future<bool> loadEnabled() {
    return _repository.loadEnabled();
  }

  Future<void> reset() {
    return _repository.reset();
  }

  Future<void> saveEnabled(bool enabled) {
    return _repository.saveEnabled(enabled);
  }
}

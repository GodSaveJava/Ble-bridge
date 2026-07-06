abstract class RemoteBridgeAutoConsumeRepository {
  Future<bool> loadEnabled();
  Future<void> saveEnabled(bool enabled);
  Future<void> reset();
}

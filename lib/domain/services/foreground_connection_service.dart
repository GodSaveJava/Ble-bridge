abstract class ForegroundConnectionService {
  Future<void> start();
  Future<void> stop();
  bool get isRunning;
}

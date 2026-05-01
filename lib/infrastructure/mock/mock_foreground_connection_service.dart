import '../../domain/services/foreground_connection_service.dart';

class MockForegroundConnectionService implements ForegroundConnectionService {
  bool _running = false;

  @override
  bool get isRunning => _running;

  @override
  Future<void> start() async {
    _running = true;
  }

  @override
  Future<void> stop() async {
    _running = false;
  }
}

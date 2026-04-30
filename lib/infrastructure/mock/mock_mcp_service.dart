import '../../domain/services/mcp_service.dart';

class MockMcpService implements McpService {
  bool _isRunning = false;
  McpEndpointInfo? _endpointInfo;

  @override
  bool get isRunning => _isRunning;

  @override
  McpEndpointInfo? get endpointInfo => _endpointInfo;

  @override
  Future<void> start() async {
    _isRunning = true;
    _endpointInfo = const McpEndpointInfo(
      host: '127.0.0.1',
      port: 8765,
      path: '/mcp',
    );
  }

  @override
  Future<void> stop() async {
    _isRunning = false;
    _endpointInfo = null;
  }

  @override
  Future<void> registerToolsForActiveDevice() async {}
}

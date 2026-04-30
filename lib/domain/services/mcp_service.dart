class McpEndpointInfo {
  const McpEndpointInfo({
    required this.host,
    required this.port,
    required this.path,
  });

  final String host;
  final int port;
  final String path;
}

abstract class McpService {
  Future<void> start();
  Future<void> stop();
  bool get isRunning;
  McpEndpointInfo? get endpointInfo;
  Future<void> registerToolsForActiveDevice();
}

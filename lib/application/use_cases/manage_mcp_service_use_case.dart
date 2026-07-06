import '../../domain/services/mcp_service.dart';

class ManageMcpServiceUseCase {
  ManageMcpServiceUseCase({required McpService mcpService})
    : _mcpService = mcpService;

  final McpService _mcpService;

  Future<void> start() => _mcpService.start();

  Future<void> stop() => _mcpService.stop();

  bool get isRunning => _mcpService.isRunning;

  McpEndpointInfo? get endpointInfo => _mcpService.endpointInfo;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/application_providers.dart';
import '../../domain/repositories/hardware_repository.dart';
import '../../domain/services/mcp_service.dart';
import '../mcp/local_mcp_http_service.dart';
import '../mock/mock_hardware_repository.dart';

final defaultHardwareRepositoryProvider = Provider<HardwareRepository>((ref) {
  final MockHardwareRepository repository = MockHardwareRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final defaultMcpServiceProvider = Provider<McpService>((ref) {
  return LocalMcpHttpService(toolRouter: ref.watch(mcpToolRouterProvider));
});

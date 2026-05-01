import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mcp/mcp_tool_router.dart';
import '../registry/active_device_registry.dart';
import '../safety/safety_guard.dart';
import '../use_cases/control_device_use_case.dart';
import '../use_cases/manage_mcp_service_use_case.dart';
import '../use_cases/manage_active_device_use_case.dart';
import '../../domain/entities/device_status.dart';
import '../../domain/entities/toy_device_info.dart';
import '../../domain/repositories/hardware_repository.dart';
import '../../domain/services/foreground_connection_service.dart';
import '../../domain/services/mcp_service.dart';

final hardwareRepositoryProvider = Provider<HardwareRepository>((_) {
  throw UnimplementedError(
    'Provide a concrete HardwareRepository in infrastructure layer.',
  );
});

final mcpServiceProvider = Provider<McpService>((_) {
  throw UnimplementedError('Provide a concrete McpService in infrastructure.');
});

final foregroundConnectionServiceProvider =
    Provider<ForegroundConnectionService>((_) {
      throw UnimplementedError(
        'Provide a concrete ForegroundConnectionService in infrastructure.',
      );
    });

final safetyGuardProvider = Provider<SafetyGuard>((_) => const SafetyGuard());

final activeDeviceRegistryProvider = Provider<ActiveDeviceRegistry>((ref) {
  final ActiveDeviceRegistry registry = ActiveDeviceRegistry(
    hardwareRepository: ref.watch(hardwareRepositoryProvider),
  );
  ref.onDispose(registry.dispose);
  return registry;
});

final activeDeviceStatusStreamProvider = StreamProvider<DeviceStatus>((ref) {
  return ref.watch(activeDeviceRegistryProvider).statusStream;
});

final controlDeviceUseCaseProvider = Provider<ControlDeviceUseCase>((ref) {
  return ControlDeviceUseCase(
    activeDeviceRegistry: ref.watch(activeDeviceRegistryProvider),
    safetyGuard: ref.watch(safetyGuardProvider),
  );
});

final manageActiveDeviceUseCaseProvider = Provider<ManageActiveDeviceUseCase>((
  ref,
) {
  return ManageActiveDeviceUseCase(
    hardwareRepository: ref.watch(hardwareRepositoryProvider),
  );
});

final discoveredDevicesStreamProvider = StreamProvider<List<ToyDeviceInfo>>((
  ref,
) {
  return ref.watch(manageActiveDeviceUseCaseProvider).watchDiscoveredDevices();
});

final manageMcpServiceUseCaseProvider = Provider<ManageMcpServiceUseCase>((
  ref,
) {
  return ManageMcpServiceUseCase(mcpService: ref.watch(mcpServiceProvider));
});

final mcpToolRouterProvider = Provider<McpToolRouter>((ref) {
  return McpToolRouter(
    controlDeviceUseCase: ref.watch(controlDeviceUseCaseProvider),
  );
});

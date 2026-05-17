import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/adapter_registry.dart';
import '../services/adapter_validator.dart';
import '../services/mcp_control_authorization_service.dart';
import '../mcp/mcp_tool_router.dart';
import '../registry/active_device_registry.dart';
import '../safety/safety_guard.dart';
import '../use_cases/control_device_use_case.dart';
import '../use_cases/manage_adapter_use_case.dart';
import '../use_cases/manage_mcp_service_use_case.dart';
import '../use_cases/manage_active_device_use_case.dart';
import '../../domain/repositories/adapter_manifest_repository.dart';
import '../../domain/repositories/background_stability_checklist_repository.dart';
import '../../domain/entities/device_status.dart';
import '../../domain/entities/toy_device_info.dart';
import '../../domain/repositories/hardware_repository.dart';
import '../../domain/repositories/verified_adapter_repository.dart';
import '../../domain/services/adapter_export_service.dart';
import '../../domain/services/adapter_import_service.dart';
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

final adapterManifestRepositoryProvider = Provider<AdapterManifestRepository>((
  _,
) {
  throw UnimplementedError(
    'Provide a concrete AdapterManifestRepository in infrastructure.',
  );
});

final verifiedAdapterRepositoryProvider = Provider<VerifiedAdapterRepository>((
  _,
) {
  throw UnimplementedError(
    'Provide a concrete VerifiedAdapterRepository in infrastructure.',
  );
});

final backgroundStabilityChecklistRepositoryProvider =
    Provider<BackgroundStabilityChecklistRepository>((_) {
      throw UnimplementedError(
        'Provide a concrete BackgroundStabilityChecklistRepository in infrastructure.',
      );
    });

final foregroundConnectionServiceProvider =
    Provider<ForegroundConnectionService>((_) {
      throw UnimplementedError(
        'Provide a concrete ForegroundConnectionService in infrastructure.',
      );
    });

final adapterExportServiceProvider = Provider<AdapterExportService>((_) {
  throw UnimplementedError(
    'Provide a concrete AdapterExportService in infrastructure.',
  );
});

final adapterImportServiceProvider = Provider<AdapterImportService>((_) {
  throw UnimplementedError(
    'Provide a concrete AdapterImportService in infrastructure.',
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

final mcpControlAuthorizationServiceProvider =
    Provider<McpControlAuthorizationService>((ref) {
      return McpControlAuthorizationService(
        activeDeviceRegistry: ref.watch(activeDeviceRegistryProvider),
        verifiedAdapterRepository: ref.watch(verifiedAdapterRepositoryProvider),
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
    mcpControlAuthorizationService: ref.watch(
      mcpControlAuthorizationServiceProvider,
    ),
  );
});

final adapterRegistryProvider = Provider<AdapterRegistry>((ref) {
  return AdapterRegistry(
    adapterManifestRepository: ref.watch(adapterManifestRepositoryProvider),
    verifiedAdapterRepository: ref.watch(verifiedAdapterRepositoryProvider),
  );
});

final adapterValidatorProvider = Provider<AdapterValidator>((ref) {
  return AdapterValidator(
    verifiedAdapterRepository: ref.watch(verifiedAdapterRepositoryProvider),
  );
});

final manageAdapterUseCaseProvider = Provider<ManageAdapterUseCase>((ref) {
  return ManageAdapterUseCase(
    adapterRegistry: ref.watch(adapterRegistryProvider),
    adapterValidator: ref.watch(adapterValidatorProvider),
    adapterExportService: ref.watch(adapterExportServiceProvider),
  );
});

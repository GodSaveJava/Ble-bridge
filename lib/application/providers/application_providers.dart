import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/active_device_adapter_readiness.dart';
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
import '../../domain/repositories/active_adapter_binding_repository.dart';
import '../../domain/repositories/background_stability_checklist_repository.dart';
import '../../domain/entities/active_adapter_binding.dart';
import '../../domain/entities/adapter_manifest.dart';
import '../../domain/entities/device_status.dart';
import '../../domain/entities/toy_device_info.dart';
import '../../domain/entities/verified_adapter_record.dart';
import '../../domain/repositories/hardware_repository.dart';
import '../../domain/repositories/verified_adapter_repository.dart';
import '../../domain/services/adapter_export_service.dart';
import '../../domain/services/adapter_import_service.dart';
import '../../domain/services/foreground_connection_service.dart';
import '../../domain/services/mcp_service.dart';
import '../../domain/services/remote_bridge_service.dart';
import '../use_cases/manage_remote_bridge_session_use_case.dart';

final hardwareRepositoryProvider = Provider<HardwareRepository>((_) {
  throw UnimplementedError(
    'Provide a concrete HardwareRepository in infrastructure layer.',
  );
});

final mcpServiceProvider = Provider<McpService>((_) {
  throw UnimplementedError('Provide a concrete McpService in infrastructure.');
});

final remoteBridgeServiceProvider = Provider<RemoteBridgeService>((_) {
  throw UnimplementedError(
    'Provide a concrete RemoteBridgeService in infrastructure.',
  );
});

final adapterManifestRepositoryProvider = Provider<AdapterManifestRepository>((
  _,
) {
  throw UnimplementedError(
    'Provide a concrete AdapterManifestRepository in infrastructure.',
  );
});

final activeAdapterBindingRepositoryProvider =
    Provider<ActiveAdapterBindingRepository>((_) {
      throw UnimplementedError(
        'Provide a concrete ActiveAdapterBindingRepository in infrastructure.',
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

final availableAdapterManifestsStreamProvider =
    StreamProvider<List<AdapterManifest>>((ref) {
      return ref.watch(manageAdapterUseCaseProvider).watchAvailableAdapters();
    });

final verifiedAdapterRecordsStreamProvider =
    StreamProvider<List<VerifiedAdapterRecord>>((ref) {
      return ref.watch(verifiedAdapterRepositoryProvider).watchAll();
    });

final activeAdapterBindingsStreamProvider =
    StreamProvider<List<ActiveAdapterBinding>>((ref) {
      return ref.watch(manageAdapterUseCaseProvider).watchDeviceBindings();
    });

final activeDeviceAdapterReadinessProvider =
    Provider<AsyncValue<ActiveDeviceAdapterReadiness>>((ref) {
      final activeStatusAsync = ref.watch(activeDeviceStatusStreamProvider);
      final manifestsAsync = ref.watch(availableAdapterManifestsStreamProvider);
      final recordsAsync = ref.watch(verifiedAdapterRecordsStreamProvider);
      final bindingsAsync = ref.watch(activeAdapterBindingsStreamProvider);

      if (activeStatusAsync.hasError) {
        return AsyncError<ActiveDeviceAdapterReadiness>(
          activeStatusAsync.error!,
          activeStatusAsync.stackTrace!,
        );
      }
      if (manifestsAsync.hasError) {
        return AsyncError<ActiveDeviceAdapterReadiness>(
          manifestsAsync.error!,
          manifestsAsync.stackTrace!,
        );
      }
      if (recordsAsync.hasError) {
        return AsyncError<ActiveDeviceAdapterReadiness>(
          recordsAsync.error!,
          recordsAsync.stackTrace!,
        );
      }
      if (bindingsAsync.hasError) {
        return AsyncError<ActiveDeviceAdapterReadiness>(
          bindingsAsync.error!,
          bindingsAsync.stackTrace!,
        );
      }

      if (activeStatusAsync is! AsyncData<DeviceStatus> ||
          manifestsAsync is! AsyncData<List<AdapterManifest>> ||
          recordsAsync is! AsyncData<List<VerifiedAdapterRecord>> ||
          bindingsAsync is! AsyncData<List<ActiveAdapterBinding>>) {
        return const AsyncLoading<ActiveDeviceAdapterReadiness>();
      }

      final DeviceStatus status = activeStatusAsync.value;
      final List<AdapterManifest> manifests = manifestsAsync.value;
      final List<VerifiedAdapterRecord> records = recordsAsync.value;
      final List<ActiveAdapterBinding> bindings = bindingsAsync.value;

      if (!status.isConnected || status.deviceId.isEmpty) {
        return const AsyncData<ActiveDeviceAdapterReadiness>(
          ActiveDeviceAdapterReadiness(
            state: ActiveDeviceAdapterReadinessState.noDevice,
          ),
        );
      }

      final ActiveAdapterBinding? binding = _findActiveBinding(
        bindings: bindings,
        deviceId: status.deviceId,
      );
      if (binding == null) {
        return AsyncData<ActiveDeviceAdapterReadiness>(
          ActiveDeviceAdapterReadiness(
            state: ActiveDeviceAdapterReadinessState.noBinding,
            deviceId: status.deviceId,
          ),
        );
      }

      final AdapterManifest? manifest = _findAdapterManifest(
        manifests: manifests,
        adapterId: binding.adapterId,
      );
      if (manifest == null) {
        return AsyncData<ActiveDeviceAdapterReadiness>(
          ActiveDeviceAdapterReadiness(
            state: ActiveDeviceAdapterReadinessState.bindingMissing,
            deviceId: status.deviceId,
            adapterId: binding.adapterId,
          ),
        );
      }

      final VerifiedAdapterRecord? record = _findVerifiedRecord(
        records: records,
        adapterId: binding.adapterId,
        deviceId: status.deviceId,
      );
      if (record == null) {
        return AsyncData<ActiveDeviceAdapterReadiness>(
          ActiveDeviceAdapterReadiness(
            state: ActiveDeviceAdapterReadinessState.unverified,
            deviceId: status.deviceId,
            adapterId: binding.adapterId,
            adapterDisplayName: manifest.displayName,
          ),
        );
      }

      return AsyncData<ActiveDeviceAdapterReadiness>(
        ActiveDeviceAdapterReadiness(
          state: switch (record.status) {
            AdapterVerificationStatus.verified =>
              ActiveDeviceAdapterReadinessState.verified,
            AdapterVerificationStatus.revoked =>
              ActiveDeviceAdapterReadinessState.revoked,
            AdapterVerificationStatus.needsReverify =>
              ActiveDeviceAdapterReadinessState.needsReverify,
            AdapterVerificationStatus.failed =>
              ActiveDeviceAdapterReadinessState.verificationFailed,
            AdapterVerificationStatus.unverified =>
              ActiveDeviceAdapterReadinessState.unverified,
          },
          deviceId: status.deviceId,
          adapterId: binding.adapterId,
          adapterDisplayName: manifest.displayName,
          verificationStatus: record.status,
        ),
      );
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
        adapterRegistry: ref.watch(adapterRegistryProvider),
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

final manageRemoteBridgeSessionUseCaseProvider =
    Provider<ManageRemoteBridgeSessionUseCase>((ref) {
      return ManageRemoteBridgeSessionUseCase(
        remoteBridgeService: ref.watch(remoteBridgeServiceProvider),
      );
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
    activeAdapterBindingRepository: ref.watch(
      activeAdapterBindingRepositoryProvider,
    ),
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

ActiveAdapterBinding? _findActiveBinding({
  required List<ActiveAdapterBinding> bindings,
  required String deviceId,
}) {
  for (final ActiveAdapterBinding binding in bindings) {
    if (binding.deviceFingerprint == deviceId) {
      return binding;
    }
  }
  return null;
}

AdapterManifest? _findAdapterManifest({
  required List<AdapterManifest> manifests,
  required String adapterId,
}) {
  for (final AdapterManifest manifest in manifests) {
    if (manifest.adapterId == adapterId) {
      return manifest;
    }
  }
  return null;
}

VerifiedAdapterRecord? _findVerifiedRecord({
  required List<VerifiedAdapterRecord> records,
  required String adapterId,
  required String deviceId,
}) {
  for (final VerifiedAdapterRecord record in records) {
    if (record.adapterId == adapterId &&
        record.target.deviceFingerprint == deviceId) {
      return record;
    }
  }
  return null;
}

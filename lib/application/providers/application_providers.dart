import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../registry/active_device_registry.dart';
import '../safety/safety_guard.dart';
import '../use_cases/control_device_use_case.dart';
import '../../domain/entities/device_status.dart';
import '../../domain/repositories/hardware_repository.dart';

final hardwareRepositoryProvider = Provider<HardwareRepository>((_) {
  throw UnimplementedError(
    'Provide a concrete HardwareRepository in infrastructure layer.',
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

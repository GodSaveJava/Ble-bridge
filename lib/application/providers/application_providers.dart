import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../registry/active_device_registry.dart';
import '../safety/safety_guard.dart';
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

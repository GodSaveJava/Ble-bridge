import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/application_providers.dart';
import '../../domain/repositories/adapter_manifest_repository.dart';
import '../../domain/repositories/background_stability_checklist_repository.dart';
import '../../domain/repositories/hardware_repository.dart';
import '../../domain/repositories/verified_adapter_repository.dart';
import '../../domain/services/foreground_connection_service.dart';
import '../../domain/services/mcp_service.dart';
import '../ble/sosexy_hardware_repository.dart';
import '../foreground/android_foreground_connection_service.dart';
import '../mcp/local_mcp_http_service.dart';
import '../mock/mock_foreground_connection_service.dart';
import '../mock/mock_hardware_repository.dart';
import '../storage/shared_prefs_adapter_manifest_repository.dart';
import '../storage/shared_prefs_background_stability_checklist_repository.dart';
import '../storage/shared_prefs_verified_adapter_repository.dart';

final defaultHardwareRepositoryProvider = Provider<HardwareRepository>((ref) {
  const bool useRealBle = bool.fromEnvironment(
    'TOYLINK_USE_REAL_BLE',
    defaultValue: false,
  );
  if (useRealBle) {
    final SosexyHardwareRepository repository = SosexyHardwareRepository();
    ref.onDispose(repository.dispose);
    return repository;
  } else {
    final MockHardwareRepository repository = MockHardwareRepository();
    ref.onDispose(repository.dispose);
    return repository;
  }
});

final defaultMcpServiceProvider = Provider<McpService>((ref) {
  return LocalMcpHttpService(toolRouter: ref.watch(mcpToolRouterProvider));
});

final defaultForegroundConnectionServiceProvider =
    Provider<ForegroundConnectionService>((_) {
      const bool useRealBle = bool.fromEnvironment(
        'TOYLINK_USE_REAL_BLE',
        defaultValue: false,
      );
      if (useRealBle) {
        return const AndroidForegroundConnectionService();
      }
      return MockForegroundConnectionService();
    });

final defaultAdapterManifestRepositoryProvider =
    Provider<AdapterManifestRepository>((ref) {
      final SharedPrefsAdapterManifestRepository repository =
          SharedPrefsAdapterManifestRepository();
      ref.onDispose(repository.dispose);
      return repository;
    });

final defaultVerifiedAdapterRepositoryProvider =
    Provider<VerifiedAdapterRepository>((ref) {
      final SharedPrefsVerifiedAdapterRepository repository =
          SharedPrefsVerifiedAdapterRepository();
      ref.onDispose(repository.dispose);
      return repository;
    });

final defaultBackgroundStabilityChecklistRepositoryProvider =
    Provider<BackgroundStabilityChecklistRepository>((_) {
      return SharedPrefsBackgroundStabilityChecklistRepository();
    });

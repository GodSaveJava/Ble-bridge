import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/controllers/remote_bridge_config_controller.dart';
import '../../application/providers/application_providers.dart';
import '../../domain/repositories/active_adapter_binding_repository.dart';
import '../../domain/repositories/adapter_manifest_repository.dart';
import '../../domain/repositories/background_stability_checklist_repository.dart';
import '../../domain/repositories/claude_connector_onboarding_repository.dart';
import '../../domain/repositories/hardware_repository.dart';
import '../../domain/repositories/remote_bridge_config_repository.dart';
import '../../domain/repositories/verified_adapter_repository.dart';
import '../../domain/services/remote_bridge_probe_service.dart';
import '../../domain/services/adapter_export_service.dart';
import '../../domain/services/adapter_import_service.dart';
import '../../domain/services/foreground_connection_service.dart';
import '../../domain/services/mcp_service.dart';
import '../../domain/services/remote_bridge_service.dart';
import '../ble/sosexy_hardware_repository.dart';
import '../bridge/http_remote_bridge_service.dart';
import '../bridge/http_remote_bridge_probe_service.dart';
import '../foreground/android_foreground_connection_service.dart';
import '../mcp/local_mcp_http_service.dart';
import '../mock/mock_foreground_connection_service.dart';
import '../mock/mock_hardware_repository.dart';
import '../storage/local_adapter_export_service.dart';
import '../storage/local_adapter_import_service.dart';
import '../mock/mock_remote_bridge_service.dart';
import '../storage/shared_prefs_active_adapter_binding_repository.dart';
import '../storage/shared_prefs_adapter_manifest_repository.dart';
import '../storage/shared_prefs_background_stability_checklist_repository.dart';
import '../storage/shared_prefs_claude_connector_onboarding_repository.dart';
import '../storage/shared_prefs_remote_bridge_config_repository.dart';
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

final defaultRemoteBridgeServiceProvider = Provider<RemoteBridgeService>((ref) {
  final configAsync = ref.watch(remoteBridgeConfigControllerProvider);
  const bool useRealRemoteBridge = bool.fromEnvironment(
    'TOYLINK_USE_REAL_REMOTE_BRIDGE',
    defaultValue: false,
  );
  const String baseUrl = String.fromEnvironment(
    'TOYLINK_REMOTE_BRIDGE_BASE_URL',
    defaultValue: '',
  );
  const String clientId = String.fromEnvironment(
    'TOYLINK_REMOTE_BRIDGE_CLIENT_ID',
    defaultValue: 'toylink-mobile-dev',
  );
  const String clientToken = String.fromEnvironment(
    'TOYLINK_REMOTE_BRIDGE_CLIENT_TOKEN',
    defaultValue: '',
  );

  final bool useSavedRemoteBridge =
      configAsync.hasValue &&
      configAsync.requireValue.enabled &&
      configAsync.requireValue.normalizedBaseUrl.isNotEmpty;

  if (useSavedRemoteBridge) {
    final savedConfig = configAsync.requireValue;
    final HttpRemoteBridgeService service = HttpRemoteBridgeService(
      baseUrl: Uri.parse(savedConfig.normalizedBaseUrl),
      clientId: savedConfig.normalizedClientId,
      clientToken: savedConfig.normalizedClientToken.isEmpty
          ? null
          : savedConfig.normalizedClientToken,
    );
    ref.onDispose(service.dispose);
    return service;
  }

  if (useRealRemoteBridge && baseUrl.isNotEmpty) {
    final HttpRemoteBridgeService service = HttpRemoteBridgeService(
      baseUrl: Uri.parse(baseUrl),
      clientId: clientId,
      clientToken: clientToken.isEmpty ? null : clientToken,
    );
    ref.onDispose(service.dispose);
    return service;
  }

  final MockRemoteBridgeService service = MockRemoteBridgeService();
  ref.onDispose(service.dispose);
  return service;
});

final defaultRemoteBridgeProbeServiceProvider =
    Provider<RemoteBridgeProbeService>((_) {
      return HttpRemoteBridgeProbeService();
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

final defaultAdapterExportServiceProvider = Provider<AdapterExportService>((_) {
  return const LocalAdapterExportService();
});

final defaultAdapterImportServiceProvider = Provider<AdapterImportService>((_) {
  return LocalAdapterImportService();
});

final defaultAdapterManifestRepositoryProvider =
    Provider<AdapterManifestRepository>((ref) {
      final SharedPrefsAdapterManifestRepository repository =
          SharedPrefsAdapterManifestRepository();
      ref.onDispose(repository.dispose);
      return repository;
    });

final defaultActiveAdapterBindingRepositoryProvider =
    Provider<ActiveAdapterBindingRepository>((ref) {
      final SharedPrefsActiveAdapterBindingRepository repository =
          SharedPrefsActiveAdapterBindingRepository();
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

final defaultClaudeConnectorOnboardingRepositoryProvider =
    Provider<ClaudeConnectorOnboardingRepository>((_) {
      return SharedPrefsClaudeConnectorOnboardingRepository();
    });

final defaultRemoteBridgeConfigRepositoryProvider =
    Provider<RemoteBridgeConfigRepository>((_) {
      return SharedPrefsRemoteBridgeConfigRepository();
    });

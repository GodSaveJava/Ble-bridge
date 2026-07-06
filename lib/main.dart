import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/providers/application_providers.dart';
import 'app.dart';
import 'infrastructure/providers/infrastructure_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'toylink_foreground_channel',
      channelName: 'ToyLink 后台保活',
      channelDescription: '用于维持蓝牙连接稳定',
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.nothing(),
      autoRunOnBoot: false,
      autoRunOnMyPackageReplaced: false,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        hardwareRepositoryProvider.overrideWith((ref) {
          return ref.watch(defaultHardwareRepositoryProvider);
        }),
        mcpServiceProvider.overrideWith((ref) {
          return ref.watch(defaultMcpServiceProvider);
        }),
        remoteBridgeServiceProvider.overrideWith((ref) {
          return ref.watch(defaultRemoteBridgeServiceProvider);
        }),
        remoteBridgeProbeServiceProvider.overrideWith((ref) {
          return ref.watch(defaultRemoteBridgeProbeServiceProvider);
        }),
        remoteBridgeTaskExecutorProvider.overrideWith((ref) {
          return ref.watch(defaultRemoteBridgeTaskExecutorProvider);
        }),
        foregroundConnectionServiceProvider.overrideWith((ref) {
          return ref.watch(defaultForegroundConnectionServiceProvider);
        }),
        adapterExportServiceProvider.overrideWith((ref) {
          return ref.watch(defaultAdapterExportServiceProvider);
        }),
        adapterImportServiceProvider.overrideWith((ref) {
          return ref.watch(defaultAdapterImportServiceProvider);
        }),
        adapterManifestRepositoryProvider.overrideWith((ref) {
          return ref.watch(defaultAdapterManifestRepositoryProvider);
        }),
        activeAdapterBindingRepositoryProvider.overrideWith((ref) {
          return ref.watch(defaultActiveAdapterBindingRepositoryProvider);
        }),
        verifiedAdapterRepositoryProvider.overrideWith((ref) {
          return ref.watch(defaultVerifiedAdapterRepositoryProvider);
        }),
        backgroundStabilityChecklistRepositoryProvider.overrideWith((ref) {
          return ref.watch(
            defaultBackgroundStabilityChecklistRepositoryProvider,
          );
        }),
        claudeConnectorOnboardingRepositoryProvider.overrideWith((ref) {
          return ref.watch(
            defaultClaudeConnectorOnboardingRepositoryProvider,
          );
        }),
        remoteBridgeConfigRepositoryProvider.overrideWith((ref) {
          return ref.watch(defaultRemoteBridgeConfigRepositoryProvider);
        }),
        remoteBridgeAutoConsumeRepositoryProvider.overrideWith((ref) {
          return ref.watch(defaultRemoteBridgeAutoConsumeRepositoryProvider);
        }),
      ],
      child: const ToyLinkApp(),
    ),
  );
}

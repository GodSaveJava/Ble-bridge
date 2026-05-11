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
        foregroundConnectionServiceProvider.overrideWith((ref) {
          return ref.watch(defaultForegroundConnectionServiceProvider);
        }),
        adapterManifestRepositoryProvider.overrideWith((ref) {
          return ref.watch(defaultAdapterManifestRepositoryProvider);
        }),
        verifiedAdapterRepositoryProvider.overrideWith((ref) {
          return ref.watch(defaultVerifiedAdapterRepositoryProvider);
        }),
        backgroundStabilityChecklistRepositoryProvider.overrideWith((ref) {
          return ref.watch(defaultBackgroundStabilityChecklistRepositoryProvider);
        }),
      ],
      child: const ToyLinkApp(),
    ),
  );
}

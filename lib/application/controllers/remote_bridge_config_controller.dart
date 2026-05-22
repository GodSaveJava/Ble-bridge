import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/remote_bridge_config.dart';
import '../providers/application_providers.dart';

class RemoteBridgeConfigController extends AsyncNotifier<RemoteBridgeConfig> {
  @override
  Future<RemoteBridgeConfig> build() {
    return ref.watch(manageRemoteBridgeConfigUseCaseProvider).load();
  }

  Future<void> save(RemoteBridgeConfig config) async {
    state = const AsyncLoading<RemoteBridgeConfig>();
    state = await AsyncValue.guard<RemoteBridgeConfig>(() {
      return ref.read(manageRemoteBridgeConfigUseCaseProvider).save(config);
    });
  }

  Future<void> reset() async {
    state = const AsyncLoading<RemoteBridgeConfig>();
    state = await AsyncValue.guard<RemoteBridgeConfig>(() {
      return ref.read(manageRemoteBridgeConfigUseCaseProvider).reset();
    });
  }
}

final remoteBridgeConfigControllerProvider =
    AsyncNotifierProvider<RemoteBridgeConfigController, RemoteBridgeConfig>(
      RemoteBridgeConfigController.new,
    );

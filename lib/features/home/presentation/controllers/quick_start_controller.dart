import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../../domain/entities/toy_device_info.dart';

class QuickStartState {
  const QuickStartState({
    this.isRunning = false,
    this.errorMessage,
    this.completed = false,
  });

  final bool isRunning;
  final String? errorMessage;
  final bool completed;

  QuickStartState copyWith({
    bool? isRunning,
    String? errorMessage,
    bool clearError = false,
    bool? completed,
  }) {
    return QuickStartState(
      isRunning: isRunning ?? this.isRunning,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      completed: completed ?? this.completed,
    );
  }
}

class QuickStartController extends Notifier<QuickStartState> {
  @override
  QuickStartState build() => const QuickStartState();

  Future<bool> runQuickStart() async {
    state = state.copyWith(isRunning: true, clearError: true, completed: false);

    try {
      final manageDevice = ref.read(manageActiveDeviceUseCaseProvider);
      final manageMcp = ref.read(manageMcpServiceUseCaseProvider);
      final foreground = ref.read(foregroundConnectionServiceProvider);

      await manageDevice.startScan();
      final ToyDeviceInfo selected = await manageDevice
          .watchDiscoveredDevices()
          .firstWhere((list) => list.isNotEmpty)
          .timeout(const Duration(seconds: 12))
          .then((list) => list.first);

      await manageDevice.connect(selected);
      await foreground.start();
      await manageMcp.start();
      state = state.copyWith(isRunning: false, completed: true);
      return true;
    } catch (_) {
      state = state.copyWith(
        isRunning: false,
        completed: false,
        errorMessage: '一键启动失败，请确认蓝牙和设备状态后重试。',
      );
      return false;
    } finally {
      try {
        await ref.read(manageActiveDeviceUseCaseProvider).stopScan();
      } catch (_) {}
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final quickStartControllerProvider =
    NotifierProvider<QuickStartController, QuickStartState>(
      QuickStartController.new,
    );

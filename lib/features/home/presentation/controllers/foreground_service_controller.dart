import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/application_providers.dart';

class ForegroundServiceState {
  const ForegroundServiceState({
    this.isRunning = false,
    this.isBusy = false,
    this.errorMessage,
    this.lastRefreshedAt,
  });

  final bool isRunning;
  final bool isBusy;
  final String? errorMessage;
  final DateTime? lastRefreshedAt;

  ForegroundServiceState copyWith({
    bool? isRunning,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
    DateTime? lastRefreshedAt,
  }) {
    return ForegroundServiceState(
      isRunning: isRunning ?? this.isRunning,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
    );
  }
}

class ForegroundServiceController extends Notifier<ForegroundServiceState> {
  @override
  ForegroundServiceState build() => const ForegroundServiceState();

  Future<void> refresh() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final service = ref.read(foregroundConnectionServiceProvider);
      final running = await service.isServiceRunning();
      state = state.copyWith(
        isBusy: false,
        isRunning: running,
        lastRefreshedAt: DateTime.now(),
      );
    } catch (_) {
      state = state.copyWith(isBusy: false, errorMessage: '刷新保活状态失败。');
    }
  }

  Future<void> stop() async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final service = ref.read(foregroundConnectionServiceProvider);
      await service.stop();
      final running = await service.isServiceRunning();
      state = state.copyWith(
        isBusy: false,
        isRunning: running,
        lastRefreshedAt: DateTime.now(),
      );
    } catch (_) {
      state = state.copyWith(isBusy: false, errorMessage: '停止保活失败。');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final foregroundServiceControllerProvider =
    NotifierProvider<ForegroundServiceController, ForegroundServiceState>(
      ForegroundServiceController.new,
    );

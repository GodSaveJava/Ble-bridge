import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/remote_bridge_session.dart';
import 'remote_bridge_session_controller.dart';

final remoteBridgeAutoConsumeIntervalProvider = Provider<Duration>(
  (_) => const Duration(seconds: 5),
);

class RemoteBridgeTaskPumpController extends Notifier<void> {
  Timer? _timer;
  bool _isTickInFlight = false;

  @override
  void build() {
    ref.listen<RemoteBridgeSessionState>(
      remoteBridgeSessionControllerProvider,
      (_, RemoteBridgeSessionState next) {
        _syncLoop(next);
      },
      fireImmediately: true,
    );

    ref.onDispose(() {
      _timer?.cancel();
    });
  }

  void _syncLoop(RemoteBridgeSessionState state) {
    final bool shouldRun =
        state.isAutoConsumeEnabled &&
        state.status == RemoteBridgeSessionStatus.ready &&
        !state.isConsumingTask;

    if (!shouldRun) {
      _timer?.cancel();
      _timer = null;
      return;
    }

    if (_timer?.isActive ?? false) {
      return;
    }

    unawaited(_consumeOneTick());

    final Duration interval = ref.read(remoteBridgeAutoConsumeIntervalProvider);
    _timer = Timer.periodic(interval, (_) {
      unawaited(_consumeOneTick());
    });
  }

  Future<void> _consumeOneTick() async {
    if (_isTickInFlight) {
      return;
    }

    _isTickInFlight = true;
    try {
      await ref
          .read(remoteBridgeSessionControllerProvider.notifier)
          .consumeNextTaskSilently();
    } finally {
      _isTickInFlight = false;
    }
  }
}

final remoteBridgeTaskPumpControllerProvider =
    NotifierProvider<RemoteBridgeTaskPumpController, void>(
      RemoteBridgeTaskPumpController.new,
    );

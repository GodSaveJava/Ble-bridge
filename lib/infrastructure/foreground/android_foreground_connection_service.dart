import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../domain/services/foreground_connection_service.dart';

/// Android foreground service adapter used to keep BLE alive in background.
class AndroidForegroundConnectionService
    implements ForegroundConnectionService {
  const AndroidForegroundConnectionService();

  @override
  Future<void> start() async {
    if (await FlutterForegroundTask.isRunningService) {
      return;
    }

    final result = await FlutterForegroundTask.startService(
      serviceId: 20260502,
      serviceTypes: const <ForegroundServiceTypes>[
        ForegroundServiceTypes.connectedDevice,
      ],
      notificationTitle: 'ToyLink AI 正在后台运行',
      notificationText: '已启用连接保活，设备控制更稳定',
      callback: startForegroundServiceCallback,
    );

    if (result is ServiceRequestFailure) {
      throw result.error;
    }
  }

  @override
  Future<void> stop() async {
    if (!(await FlutterForegroundTask.isRunningService)) {
      return;
    }
    final result = await FlutterForegroundTask.stopService();
    if (result is ServiceRequestFailure) {
      throw result.error;
    }
  }

  @override
  bool get isRunning => false;

  @override
  Future<bool> isServiceRunning() => FlutterForegroundTask.isRunningService;
}

@pragma('vm:entry-point')
void startForegroundServiceCallback() {
  FlutterForegroundTask.setTaskHandler(_ToyLinkTaskHandler());
}

class _ToyLinkTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

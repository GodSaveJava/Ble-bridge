import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../../domain/entities/toy_device_info.dart';

class ScanState {
  const ScanState({
    this.devices = const <ToyDeviceInfo>[],
    this.isScanning = false,
    this.isConnecting = false,
    this.connectedDeviceId,
    this.errorMessage,
  });

  final List<ToyDeviceInfo> devices;
  final bool isScanning;
  final bool isConnecting;
  final String? connectedDeviceId;
  final String? errorMessage;

  ScanState copyWith({
    List<ToyDeviceInfo>? devices,
    bool? isScanning,
    bool? isConnecting,
    String? connectedDeviceId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ScanState(
      devices: devices ?? this.devices,
      isScanning: isScanning ?? this.isScanning,
      isConnecting: isConnecting ?? this.isConnecting,
      connectedDeviceId: connectedDeviceId ?? this.connectedDeviceId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ScanController extends Notifier<ScanState> {
  @override
  ScanState build() {
    ref.listen<AsyncValue<List<ToyDeviceInfo>>>(
      discoveredDevicesStreamProvider,
      (previous, next) {
        next.whenData((devices) {
          state = state.copyWith(devices: devices);
        });
        next.whenOrNull(
          error: (error, stackTrace) {
            state = state.copyWith(
              isScanning: false,
              errorMessage: '扫描设备失败，请重试。',
            );
          },
        );
      },
    );
    return const ScanState();
  }

  Future<void> startScan() async {
    state = state.copyWith(isScanning: true, clearError: true);
    try {
      final bool permissionsGranted = await _ensureScanPermissions();
      if (!permissionsGranted) {
        state = state.copyWith(
          isScanning: false,
          errorMessage: '未获得蓝牙扫描权限，请先在系统设置中允许蓝牙相关权限。',
        );
        return;
      }

      await FlutterBluePlus.adapterState
          .where((BluetoothAdapterState state) => state == BluetoothAdapterState.on)
          .first;
      await ref.read(manageActiveDeviceUseCaseProvider).startScan();
    } catch (_) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: '无法开始扫描，请检查蓝牙是否开启并允许扫描权限。',
      );
    }
  }

  Future<void> stopScan() async {
    state = state.copyWith(isScanning: false);
    try {
      await ref.read(manageActiveDeviceUseCaseProvider).stopScan();
    } catch (_) {
      state = state.copyWith(errorMessage: '停止扫描失败。');
    }
  }

  Future<void> connect(ToyDeviceInfo info) async {
    state = state.copyWith(isConnecting: true, clearError: true);
    try {
      await ref.read(manageActiveDeviceUseCaseProvider).connect(info);
      state = state.copyWith(
        isConnecting: false,
        isScanning: false,
        connectedDeviceId: info.id,
      );
    } catch (_) {
      state = state.copyWith(isConnecting: false, errorMessage: '连接设备失败，请重试。');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<bool> _ensureScanPermissions() async {
    final List<Permission> permissions = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ];

    final Map<Permission, PermissionStatus> statuses =
        await permissions.request();

    return statuses.values.every((PermissionStatus status) => status.isGranted);
  }
}

final scanControllerProvider = NotifierProvider<ScanController, ScanState>(
  ScanController.new,
);

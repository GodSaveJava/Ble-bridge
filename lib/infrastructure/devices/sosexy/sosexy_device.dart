import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../core/error/failure.dart';
import '../../../domain/devices/toy_device.dart';
import '../../../domain/entities/device_status.dart';
import '../../../domain/entities/safety_policy.dart';
import 'sosexy_gatt_profile.dart';
import 'sosexy_protocol_codec.dart';

typedef SosexyBleWriter =
    Future<void> Function(
      List<int> payload, {
      required bool withoutResponse,
      required int timeout,
    });

class SosexyDevice implements ToyDevice {
  SosexyDevice({
    required this.id,
    this.name = 'SOSEXY Device',
    SosexyProtocolCodec? codec,
  }) : _codec = codec ?? const SosexyProtocolCodec(),
       _bleWriter = null,
       _status = DeviceStatus.disconnected(deviceId: id);

  @visibleForTesting
  SosexyDevice.test({
    required this.id,
    required SosexyBleWriter writer,
    this.name = 'SOSEXY Device',
    SosexyProtocolCodec? codec,
  }) : _codec = codec ?? const SosexyProtocolCodec(),
       _bleWriter = writer,
       _status = DeviceStatus.disconnected(
         deviceId: id,
       ).copyWith(isConnected: true);

  @override
  final String id;

  @override
  final String name;

  final SosexyProtocolCodec _codec;
  final SosexyBleWriter? _bleWriter;
  final Queue<_QueuedCommand> _queue = Queue<_QueuedCommand>();
  final StreamController<DeviceStatus> _statusController =
      StreamController<DeviceStatus>.broadcast();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSub;
  DeviceStatus _status;
  bool _draining = false;
  bool _disposed = false;

  @override
  String get bleNamePrefix => 'SOSEXY';

  @override
  Set<ToyFeature> get supportedFeatures => <ToyFeature>{
    ToyFeature.suck,
    ToyFeature.vibe,
    ToyFeature.ems,
  };

  @override
  Map<ToyFeature, ({int min, int max})> get intensityRangeByChannel =>
      <ToyFeature, ({int min, int max})>{
        ToyFeature.suck: (min: 0, max: 100),
        ToyFeature.vibe: (min: 0, max: 100),
        ToyFeature.ems: (min: 0, max: 20),
      };

  @override
  SafetyPolicy get safetyPolicy => const SafetyPolicy();

  @override
  DeviceConnectionState get connectionState => _status.isConnected
      ? DeviceConnectionState.connected
      : DeviceConnectionState.disconnected;

  @override
  Stream<DeviceStatus> get statusStream => _statusController.stream;

  @override
  Future<String> getGattFingerprint() async {
    // Deterministic GATT fingerprint for verification binding.
    return 'svc:${SosexyGattProfile.serviceUuid.toString().toLowerCase()}|'
        'write:${SosexyGattProfile.writeCharacteristicUuid.toString().toLowerCase()}|'
        'notify:${SosexyGattProfile.notifyCharacteristicUuid.toString().toLowerCase()}|'
        'wwo:${SosexyGattProfile.writeWithoutResponse}';
  }

  @override
  Future<bool> connect(BluetoothDevice device) async {
    _device = device;
    try {
      await device.connect(
        license: License.free,
        timeout: SosexyGattProfile.connectTimeout,
      );
    } catch (_) {
      // Ignore duplicate connect errors when plugin reports already connected.
    }

    await device.requestMtu(SosexyGattProfile.requestMtu);
    final services = await device.discoverServices();
    _writeCharacteristic = _resolveWriteCharacteristic(services);
    if (_writeCharacteristic == null) {
      throw const Failure(
        code: FailureCode.protocolUnsupported,
        message: 'SOSEXY write characteristic not found.',
      );
    }
    _status = _status.copyWith(isConnected: true);
    _statusController.add(_status);
    await _connectionStateSub?.cancel();
    _connectionStateSub = device.connectionState.listen((connectionState) {
      if (connectionState == BluetoothConnectionState.disconnected) {
        _writeCharacteristic = null;
        _status = _status.copyWith(
          isConnected: false,
          suckIntensity: 0,
          vibeIntensity: 0,
          emsIntensity: 0,
        );
        _statusController.add(_status);
      }
    });
    return true;
  }

  @override
  Future<void> disconnect() async {
    final device = _device;
    _writeCharacteristic = null;
    _failQueuedCommands(
      const Failure(
        code: FailureCode.deviceDisconnected,
        message: 'SOSEXY device disconnected before command could be sent.',
      ),
    );
    await _connectionStateSub?.cancel();
    _connectionStateSub = null;
    if (device != null) {
      await device.disconnect();
    }
    _status = _status.copyWith(
      isConnected: false,
      suckIntensity: 0,
      vibeIntensity: 0,
      emsIntensity: 0,
    );
    _statusController.add(_status);
  }

  @override
  Future<void> setSuck(int intensity, {int mode = 1}) async {
    final packet = _codec.buildSuckCommand(intensity, mode);
    await _enqueue(packet, isStop: false);
    _status = _status.copyWith(suckIntensity: intensity, suckMode: mode);
    _statusController.add(_status);
  }

  @override
  Future<void> setVibe(int intensity, {int mode = 1}) async {
    final packet = _codec.buildVibeCommand(intensity, mode);
    await _enqueue(packet, isStop: false);
    _status = _status.copyWith(vibeIntensity: intensity, vibeMode: mode);
    _statusController.add(_status);
  }

  @override
  Future<void> setEms(int intensity, {int mode = 1}) async {
    final packet = _codec.buildEmsCommand(intensity, mode);
    await _enqueue(packet, isStop: false);
    _status = _status.copyWith(emsIntensity: intensity, emsMode: mode);
    _statusController.add(_status);
  }

  @override
  Future<void> setAll({
    int suck = 0,
    int vibe = 0,
    int ems = 0,
    int suckMode = 1,
    int vibeMode = 1,
    int emsMode = 1,
  }) async {
    final packets = _codec.buildSetAllCommand(
      suck: suck,
      vibe: vibe,
      ems: ems,
      suckMode: suckMode,
      vibeMode: vibeMode,
      emsMode: emsMode,
    );
    for (final packet in packets) {
      await _enqueue(packet, isStop: false);
    }
    _status = _status.copyWith(
      suckIntensity: suck,
      vibeIntensity: vibe,
      emsIntensity: ems,
      suckMode: suckMode,
      vibeMode: vibeMode,
      emsMode: emsMode,
    );
    _statusController.add(_status);
  }

  @override
  Future<void> stopAll() async {
    // Stop command must preempt pending non-stop writes.
    _failQueuedCommands(
      const Failure(
        code: FailureCode.deviceWrite,
        message: 'SOSEXY command superseded by stop_all.',
      ),
      onlyNonStop: true,
    );
    await _enqueue(_codec.buildStopAllCommand(), isStop: true);
    _status = _status.copyWith(
      suckIntensity: 0,
      vibeIntensity: 0,
      emsIntensity: 0,
    );
    _statusController.add(_status);
  }

  @override
  Future<DeviceStatus> getStatus() async => _status;

  @override
  Future<void> sendRawCommand(List<int> bytes) =>
      _enqueue(bytes, isStop: false);

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _connectionStateSub?.cancel();
    await _statusController.close();
  }

  BluetoothCharacteristic? _resolveWriteCharacteristic(
    List<BluetoothService> services,
  ) {
    for (final service in services) {
      if (service.uuid != SosexyGattProfile.serviceUuid) {
        continue;
      }
      for (final c in service.characteristics) {
        if (c.uuid == SosexyGattProfile.writeCharacteristicUuid) {
          return c;
        }
      }
    }
    return null;
  }

  Future<void> _enqueue(List<int> bytes, {required bool isStop}) async {
    if (!_status.isConnected ||
        (_writeCharacteristic == null && _bleWriter == null)) {
      throw const Failure(
        code: FailureCode.deviceDisconnected,
        message: 'SOSEXY device is not connected.',
      );
    }
    final completer = Completer<void>();
    _queue.add(
      _QueuedCommand(payload: bytes, isStop: isStop, completer: completer),
    );
    unawaited(_drainQueue());
    await completer.future;
  }

  Future<void> _drainQueue() async {
    if (_draining) {
      return;
    }
    _draining = true;
    try {
      while (_queue.isNotEmpty) {
        final cmd = _queue.removeFirst();
        try {
          await _writePayload(cmd.payload);
          cmd.completer.complete();
        } catch (error) {
          if (!cmd.completer.isCompleted) {
            cmd.completer.completeError(
              Failure(
                code: FailureCode.deviceWrite,
                message: 'Failed to write SOSEXY BLE command.',
                debugMessage: error.toString(),
              ),
            );
          }
        }
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> _writePayload(List<int> payload) {
    final writer = _bleWriter;
    if (writer != null) {
      return writer(
        payload,
        withoutResponse: SosexyGattProfile.writeWithoutResponse,
        timeout: SosexyGattProfile.writeTimeout.inMilliseconds,
      );
    }
    return _writeCharacteristic!.write(
      payload,
      withoutResponse: SosexyGattProfile.writeWithoutResponse,
      timeout: SosexyGattProfile.writeTimeout.inMilliseconds,
    );
  }

  void _failQueuedCommands(Failure failure, {bool onlyNonStop = false}) {
    final superseded = _queue
        .where((cmd) => !onlyNonStop || !cmd.isStop)
        .toList(growable: false);
    _queue.removeWhere((cmd) => !onlyNonStop || !cmd.isStop);
    for (final cmd in superseded) {
      if (!cmd.completer.isCompleted) {
        cmd.completer.completeError(failure);
      }
    }
  }
}

class _QueuedCommand {
  const _QueuedCommand({
    required this.payload,
    required this.isStop,
    required this.completer,
  });

  final List<int> payload;
  final bool isStop;
  final Completer<void> completer;
}

import 'dart:async';
import 'dart:collection';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../core/error/failure.dart';
import '../../../domain/devices/toy_device.dart';
import '../../../domain/entities/device_status.dart';
import '../../../domain/entities/safety_policy.dart';
import 'sosexy_gatt_profile.dart';
import 'sosexy_protocol_codec.dart';

class SosexyDevice implements ToyDevice {
  SosexyDevice({
    required this.id,
    this.name = 'SOSEXY Device',
    SosexyProtocolCodec? codec,
  }) : _codec = codec ?? const SosexyProtocolCodec(),
       _status = DeviceStatus.disconnected(deviceId: id);

  @override
  final String id;

  @override
  final String name;

  final SosexyProtocolCodec _codec;
  final Queue<_QueuedCommand> _queue = Queue<_QueuedCommand>();
  final StreamController<DeviceStatus> _statusController =
      StreamController<DeviceStatus>.broadcast();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
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
    return true;
  }

  @override
  Future<void> disconnect() async {
    final device = _device;
    _writeCharacteristic = null;
    _queue.clear();
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
    _queue.removeWhere((cmd) => !cmd.isStop);
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
    if (!_status.isConnected || _writeCharacteristic == null) {
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
          await _writeCharacteristic!.write(
            cmd.payload,
            withoutResponse: SosexyGattProfile.writeWithoutResponse,
            timeout: SosexyGattProfile.writeTimeout.inMilliseconds,
          );
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

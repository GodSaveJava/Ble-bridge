import '../../core/error/failure.dart';
import '../../domain/entities/control_command.dart';
import '../../domain/entities/device_status.dart';
import '../registry/active_device_registry.dart';
import '../safety/safety_guard.dart';

class ControlDeviceUseCase {
  const ControlDeviceUseCase({
    required ActiveDeviceRegistry activeDeviceRegistry,
    required SafetyGuard safetyGuard,
  }) : _activeDeviceRegistry = activeDeviceRegistry,
       _safetyGuard = safetyGuard;

  final ActiveDeviceRegistry _activeDeviceRegistry;
  final SafetyGuard _safetyGuard;

  Future<DeviceStatus> setSuck({
    required int intensity,
    int mode = 1,
    CommandSource source = CommandSource.ui,
  }) async {
    _validateMode(mode);
    final command = ControlCommand(
      channel: ControlChannel.suck,
      intensity: intensity,
      mode: mode,
      source: source,
      requestedAt: DateTime.now(),
    );

    await _validateSafety(command);
    final device = _activeDeviceRegistry.requireActiveDevice();
    await device.setSuck(intensity, mode: mode);
    return device.getStatus();
  }

  Future<DeviceStatus> setVibe({
    required int intensity,
    int mode = 1,
    CommandSource source = CommandSource.ui,
  }) async {
    _validateMode(mode);
    final command = ControlCommand(
      channel: ControlChannel.vibe,
      intensity: intensity,
      mode: mode,
      source: source,
      requestedAt: DateTime.now(),
    );

    await _validateSafety(command);
    final device = _activeDeviceRegistry.requireActiveDevice();
    await device.setVibe(intensity, mode: mode);
    return device.getStatus();
  }

  Future<DeviceStatus> setEms({
    required int intensity,
    int mode = 1,
    CommandSource source = CommandSource.ui,
  }) async {
    _validateMode(mode);
    final command = ControlCommand(
      channel: ControlChannel.ems,
      intensity: intensity,
      mode: mode,
      source: source,
      requestedAt: DateTime.now(),
    );

    await _validateSafety(command);
    final device = _activeDeviceRegistry.requireActiveDevice();
    await device.setEms(intensity, mode: mode);
    return device.getStatus();
  }

  Future<DeviceStatus> setAll({
    int suck = 0,
    int vibe = 0,
    int ems = 0,
    int suckMode = 1,
    int vibeMode = 1,
    int emsMode = 1,
    CommandSource source = CommandSource.ui,
  }) async {
    _validateMode(suckMode);
    _validateMode(vibeMode);
    _validateMode(emsMode);

    await _validateSafety(
      ControlCommand(
        channel: ControlChannel.suck,
        intensity: suck,
        mode: suckMode,
        source: source,
        requestedAt: DateTime.now(),
      ),
    );
    await _validateSafety(
      ControlCommand(
        channel: ControlChannel.vibe,
        intensity: vibe,
        mode: vibeMode,
        source: source,
        requestedAt: DateTime.now(),
      ),
    );
    await _validateSafety(
      ControlCommand(
        channel: ControlChannel.ems,
        intensity: ems,
        mode: emsMode,
        source: source,
        requestedAt: DateTime.now(),
      ),
    );

    final device = _activeDeviceRegistry.requireActiveDevice();
    await device.setAll(
      suck: suck,
      vibe: vibe,
      ems: ems,
      suckMode: suckMode,
      vibeMode: vibeMode,
      emsMode: emsMode,
    );
    return device.getStatus();
  }

  Future<DeviceStatus> stopAll() async {
    final device = _activeDeviceRegistry.requireActiveDevice();
    await device.stopAll();
    return device.getStatus();
  }

  Future<DeviceStatus> getStatus() async {
    final device = _activeDeviceRegistry.requireActiveDevice();
    return device.getStatus();
  }

  Future<void> _validateSafety(ControlCommand command) async {
    final decision = _safetyGuard.evaluate(command: command);
    if (decision.type == SafetyDecisionType.allow) {
      return;
    }
    if (decision.type == SafetyDecisionType.requireConfirmation) {
      throw Failure.validation(
        message: 'Command requires explicit user confirmation.',
        details: <String, Object?>{
          'reason': 'confirmation_required',
          'channel': command.channel.name,
          'intensity': command.intensity,
        },
      );
    }
    throw decision.failure ??
        const Failure.unknown(message: 'Safety check rejected command.');
  }

  void _validateMode(int mode) {
    if (mode < 1 || mode > 4) {
      throw Failure.validation(
        message: 'Mode must be between 1 and 4.',
        details: <String, Object?>{'mode': mode},
      );
    }
  }
}

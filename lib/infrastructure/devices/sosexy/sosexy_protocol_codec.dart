import '../../../core/error/failure.dart';
import 'sosexy_protocol_spec.dart';

class SosexyProtocolCodec {
  const SosexyProtocolCodec();

  List<int> buildSuckCommand(int intensity, int mode) {
    _validateMode(mode);
    _validateRange(
      intensity,
      SosexyProtocolSpec.minSuck,
      SosexyProtocolSpec.maxSuck,
      'suck',
    );
    return _buildPacket(
      channel: SosexyChannel.ch01,
      mode: mode,
      intensity: intensity,
    );
  }

  List<int> buildVibeCommand(int intensity, int mode) {
    _validateMode(mode);
    _validateRange(
      intensity,
      SosexyProtocolSpec.minVibe,
      SosexyProtocolSpec.maxVibe,
      'vibe',
    );
    return _buildPacket(
      channel: SosexyChannel.ch03,
      mode: mode,
      intensity: intensity,
    );
  }

  List<int> buildEmsCommand(int intensity, int mode) {
    _validateMode(mode);
    _validateRange(
      intensity,
      SosexyProtocolSpec.minEms,
      SosexyProtocolSpec.maxEms,
      'ems',
    );
    return _buildPacket(
      channel: SosexyChannel.ch07,
      mode: mode,
      intensity: intensity,
    );
  }

  /// MVP strategy: protocol-combined packet is unknown, so encode as sequence.
  List<List<int>> buildSetAllCommand({
    required int suck,
    required int vibe,
    required int ems,
    required int suckMode,
    required int vibeMode,
    required int emsMode,
  }) {
    return <List<int>>[
      buildSuckCommand(suck, suckMode),
      buildVibeCommand(vibe, vibeMode),
      buildEmsCommand(ems, emsMode),
    ];
  }

  List<int> buildStopAllCommand() {
    // inferred: zero all channels through a dedicated system mode marker.
    return <int>[
      SosexyProtocolSpec.header0,
      SosexyProtocolSpec.header1,
      0x00,
      0x00,
      0x00,
      SosexyProtocolSpec.tail,
    ];
  }

  List<int> _buildPacket({
    required SosexyChannel channel,
    required int mode,
    required int intensity,
  }) {
    // Format is centralized here to make byte-level protocol review auditable.
    return <int>[
      SosexyProtocolSpec.header0,
      SosexyProtocolSpec.header1,
      channel.value,
      mode,
      intensity,
      SosexyProtocolSpec.tail,
    ];
  }

  void _validateMode(int mode) {
    if (mode < SosexyProtocolSpec.minMode ||
        mode > SosexyProtocolSpec.maxMode) {
      throw Failure.validation(
        message: 'SOSEXY mode must be between 1 and 4.',
        details: <String, Object?>{'mode': mode},
      );
    }
  }

  void _validateRange(int value, int min, int max, String channel) {
    if (value < min || value > max) {
      throw Failure.validation(
        message: 'SOSEXY $channel intensity out of range.',
        details: <String, Object?>{
          'channel': channel,
          'value': value,
          'min': min,
          'max': max,
        },
      );
    }
  }
}

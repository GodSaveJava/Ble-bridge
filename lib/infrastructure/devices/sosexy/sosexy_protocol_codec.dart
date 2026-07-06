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
      groups: <_ChannelValue>[
        _ChannelValue(SosexyChannel.suckIntensity, intensity),
        _ChannelValue(SosexyChannel.suckMode, mode),
      ],
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
      groups: <_ChannelValue>[
        _ChannelValue(SosexyChannel.vibeIntensity, intensity),
        _ChannelValue(SosexyChannel.vibeMode, mode),
      ],
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
      groups: <_ChannelValue>[
        _ChannelValue(SosexyChannel.emsIntensity, intensity),
        _ChannelValue(SosexyChannel.emsMode, mode),
      ],
    );
  }

  /// The tutorial sample shows a single packet carrying all three channels.
  List<List<int>> buildSetAllCommand({
    required int suck,
    required int vibe,
    required int ems,
    required int suckMode,
    required int vibeMode,
    required int emsMode,
  }) {
    _validateMode(suckMode);
    _validateMode(vibeMode);
    _validateMode(emsMode);
    _validateRange(
      suck,
      SosexyProtocolSpec.minSuck,
      SosexyProtocolSpec.maxSuck,
      'suck',
    );
    _validateRange(
      vibe,
      SosexyProtocolSpec.minVibe,
      SosexyProtocolSpec.maxVibe,
      'vibe',
    );
    _validateRange(
      ems,
      SosexyProtocolSpec.minEms,
      SosexyProtocolSpec.maxEms,
      'ems',
    );
    return <List<int>>[
      _buildPacket(
        groups: <_ChannelValue>[
          _ChannelValue(SosexyChannel.vibeIntensity, vibe),
          _ChannelValue(SosexyChannel.vibeMode, vibeMode),
          _ChannelValue(SosexyChannel.emsIntensity, ems),
          _ChannelValue(SosexyChannel.emsMode, emsMode),
          _ChannelValue(SosexyChannel.suckIntensity, suck),
          _ChannelValue(SosexyChannel.suckMode, suckMode),
        ],
      ),
    ];
  }

  List<int> buildStopAllCommand() {
    // Tutorial sample keeps stop_all as a dedicated packet that zeroes the
    // intensity channels while preserving mode selections.
    return _buildPacket(
      groups: <_ChannelValue>[
        const _ChannelValue(SosexyChannel.vibeIntensity, 0),
        const _ChannelValue(SosexyChannel.emsIntensity, 0),
        const _ChannelValue(SosexyChannel.suckIntensity, 0),
      ],
    );
  }

  List<int> _buildPacket({required List<_ChannelValue> groups}) {
    final List<int> bytes = <int>[
      SosexyProtocolSpec.sequenceByte,
      SosexyProtocolSpec.header0,
      SosexyProtocolSpec.header1,
      groups.length,
    ];
    for (final _ChannelValue group in groups) {
      bytes.addAll(group.toBytes());
    }
    return bytes;
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

class _ChannelValue {
  const _ChannelValue(this.channel, this.value);

  final SosexyChannel channel;
  final int value;

  List<int> toBytes() {
    return <int>[
      SosexyProtocolSpec.groupPrefix,
      channel.value,
      SosexyProtocolSpec.groupMarker,
      value,
    ];
  }
}

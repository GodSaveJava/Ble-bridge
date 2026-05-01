enum SosexyChannel {
  ch01(0x01),
  ch03(0x03),
  ch07(0x07);

  const SosexyChannel(this.value);
  final int value;
}

/// Byte-level protocol assumptions for SOSEXY.
///
/// This file is the single source of truth for protocol constants so we can
/// swap inferred values after hardware verification without touching callers.
class SosexyProtocolSpec {
  const SosexyProtocolSpec._();

  // inferred packet layout: [header0, header1, channel, mode, intensity, tail]
  static const int header0 = 0x55;
  static const int header1 = 0xAA;
  static const int tail = 0xFF;

  static const int minMode = 1;
  static const int maxMode = 4;

  static const int minSuck = 0;
  static const int maxSuck = 100;
  static const int minVibe = 0;
  static const int maxVibe = 100;
  static const int minEms = 0;
  static const int maxEms = 20;
}

enum SosexyChannel {
  vibeIntensity(0x01),
  vibeMode(0x02),
  emsIntensity(0x03),
  emsMode(0x04),
  suckIntensity(0x07),
  suckMode(0x08);

  const SosexyChannel(this.value);
  final int value;
}

/// Byte-level protocol assumptions for SOSEXY.
///
/// This file is the single source of truth for protocol constants so we can
/// swap tutorial-derived values after hardware verification without touching
/// callers.
class SosexyProtocolSpec {
  const SosexyProtocolSpec._();

  static const int sequenceByte = 0x00;
  static const int header0 = 0x01;
  static const int header1 = 0x00;
  static const int groupPrefix = 0x00;
  static const int groupMarker = 0x11;

  static const int minMode = 1;
  static const int maxMode = 4;

  static const int minSuck = 0;
  static const int maxSuck = 100;
  static const int minVibe = 0;
  static const int maxVibe = 100;
  static const int minEms = 0;
  static const int maxEms = 20;
}

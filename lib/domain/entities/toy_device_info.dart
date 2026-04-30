class ToyDeviceInfo {
  const ToyDeviceInfo({
    required this.id,
    required this.displayName,
    required this.bleNamePrefix,
    required this.protocolKey,
    required this.isKnownTemplate,
    this.rssi,
  });

  final String id;
  final String displayName;
  final String bleNamePrefix;
  final String protocolKey;
  final bool isKnownTemplate;
  final int? rssi;
}

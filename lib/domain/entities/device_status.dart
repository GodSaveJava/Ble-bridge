class DeviceStatus {
  const DeviceStatus({
    required this.deviceId,
    required this.isConnected,
    required this.suckIntensity,
    required this.vibeIntensity,
    required this.emsIntensity,
    required this.suckMode,
    required this.vibeMode,
    required this.emsMode,
    required this.lastUpdatedAt,
    this.batteryLevel,
  });

  final String deviceId;
  final bool isConnected;
  final int suckIntensity;
  final int vibeIntensity;
  final int emsIntensity;
  final int suckMode;
  final int vibeMode;
  final int emsMode;
  final DateTime lastUpdatedAt;
  final int? batteryLevel;

  factory DeviceStatus.disconnected({required String deviceId}) {
    return DeviceStatus(
      deviceId: deviceId,
      isConnected: false,
      suckIntensity: 0,
      vibeIntensity: 0,
      emsIntensity: 0,
      suckMode: 1,
      vibeMode: 1,
      emsMode: 1,
      lastUpdatedAt: DateTime.now(),
    );
  }
}

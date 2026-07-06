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

  DeviceStatus copyWith({
    String? deviceId,
    bool? isConnected,
    int? suckIntensity,
    int? vibeIntensity,
    int? emsIntensity,
    int? suckMode,
    int? vibeMode,
    int? emsMode,
    DateTime? lastUpdatedAt,
    int? batteryLevel,
  }) {
    return DeviceStatus(
      deviceId: deviceId ?? this.deviceId,
      isConnected: isConnected ?? this.isConnected,
      suckIntensity: suckIntensity ?? this.suckIntensity,
      vibeIntensity: vibeIntensity ?? this.vibeIntensity,
      emsIntensity: emsIntensity ?? this.emsIntensity,
      suckMode: suckMode ?? this.suckMode,
      vibeMode: vibeMode ?? this.vibeMode,
      emsMode: emsMode ?? this.emsMode,
      lastUpdatedAt: lastUpdatedAt ?? DateTime.now(),
      batteryLevel: batteryLevel ?? this.batteryLevel,
    );
  }
}

class ClaudeConnectorOnboardingRecord {
  const ClaudeConnectorOnboardingRecord({
    required this.deviceId,
    required this.adapterId,
    required this.completedAt,
  });

  final String deviceId;
  final String adapterId;
  final DateTime completedAt;

  factory ClaudeConnectorOnboardingRecord.fromJson(Map<String, Object?> json) {
    return ClaudeConnectorOnboardingRecord(
      deviceId: json['deviceId'] as String? ?? '',
      adapterId: json['adapterId'] as String? ?? '',
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'deviceId': deviceId,
      'adapterId': adapterId,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  bool matches({
    required String? deviceId,
    required String? adapterId,
  }) {
    return deviceId != null &&
        deviceId.isNotEmpty &&
        adapterId != null &&
        adapterId.isNotEmpty &&
        this.deviceId == deviceId &&
        this.adapterId == adapterId;
  }
}

class ActiveAdapterBinding {
  const ActiveAdapterBinding({
    required this.deviceFingerprint,
    required this.adapterId,
    required this.boundAt,
  });

  final String deviceFingerprint;
  final String adapterId;
  final DateTime boundAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'deviceFingerprint': deviceFingerprint,
    'adapterId': adapterId,
    'boundAt': boundAt.toIso8601String(),
  };

  static ActiveAdapterBinding fromJson(Map<String, Object?> json) {
    final Object? deviceFingerprintValue = json['deviceFingerprint'];
    final Object? adapterIdValue = json['adapterId'];
    final Object? boundAtValue = json['boundAt'];
    if (deviceFingerprintValue is! String ||
        adapterIdValue is! String ||
        boundAtValue is! String) {
      throw const FormatException('Invalid active adapter binding payload.');
    }
    return ActiveAdapterBinding(
      deviceFingerprint: deviceFingerprintValue,
      adapterId: adapterIdValue,
      boundAt: DateTime.parse(boundAtValue),
    );
  }
}

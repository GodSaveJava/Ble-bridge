class BackgroundStabilityChecklist {
  const BackgroundStabilityChecklist({
    this.lockScreen30Min = false,
    this.switchBackgroundAndBack = false,
    this.autoReconnectAfterDisconnect = false,
    this.mcpCallAvailableInBackground = false,
    this.lastUpdatedAt,
  });

  final bool lockScreen30Min;
  final bool switchBackgroundAndBack;
  final bool autoReconnectAfterDisconnect;
  final bool mcpCallAvailableInBackground;
  final DateTime? lastUpdatedAt;

  bool get allPassed =>
      lockScreen30Min &&
      switchBackgroundAndBack &&
      autoReconnectAfterDisconnect &&
      mcpCallAvailableInBackground;

  BackgroundStabilityChecklist copyWith({
    bool? lockScreen30Min,
    bool? switchBackgroundAndBack,
    bool? autoReconnectAfterDisconnect,
    bool? mcpCallAvailableInBackground,
    DateTime? lastUpdatedAt,
  }) {
    return BackgroundStabilityChecklist(
      lockScreen30Min: lockScreen30Min ?? this.lockScreen30Min,
      switchBackgroundAndBack:
          switchBackgroundAndBack ?? this.switchBackgroundAndBack,
      autoReconnectAfterDisconnect:
          autoReconnectAfterDisconnect ?? this.autoReconnectAfterDisconnect,
      mcpCallAvailableInBackground:
          mcpCallAvailableInBackground ?? this.mcpCallAvailableInBackground,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'lockScreen30Min': lockScreen30Min,
    'switchBackgroundAndBack': switchBackgroundAndBack,
    'autoReconnectAfterDisconnect': autoReconnectAfterDisconnect,
    'mcpCallAvailableInBackground': mcpCallAvailableInBackground,
    'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
  };

  static BackgroundStabilityChecklist fromJson(Map<String, Object?> json) {
    return BackgroundStabilityChecklist(
      lockScreen30Min: json['lockScreen30Min'] == true,
      switchBackgroundAndBack: json['switchBackgroundAndBack'] == true,
      autoReconnectAfterDisconnect: json['autoReconnectAfterDisconnect'] == true,
      mcpCallAvailableInBackground: json['mcpCallAvailableInBackground'] == true,
      lastUpdatedAt: json['lastUpdatedAt'] is String
          ? DateTime.tryParse(json['lastUpdatedAt']! as String)
          : null,
    );
  }
}

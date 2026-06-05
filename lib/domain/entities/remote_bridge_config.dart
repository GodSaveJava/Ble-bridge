class RemoteBridgeConfig {
  static const String productionBridgeBaseUrl = 'http://47.95.242.29:8100';
  static const String productionClientId = 'toylink-mobile-dev';

  const RemoteBridgeConfig({
    this.enabled = false,
    this.baseUrl = '',
    this.clientId = productionClientId,
    this.clientToken = '',
  });

  const RemoteBridgeConfig.production({
    this.clientToken = '',
    this.clientId = productionClientId,
  })  : enabled = true,
        baseUrl = productionBridgeBaseUrl;

  factory RemoteBridgeConfig.fromJson(Map<String, Object?> json) {
    return RemoteBridgeConfig(
      enabled: json['enabled'] as bool? ?? false,
      baseUrl: json['baseUrl'] as String? ?? '',
      clientId: json['clientId'] as String? ?? productionClientId,
      clientToken: json['clientToken'] as String? ?? '',
    );
  }

  final bool enabled;
  final String baseUrl;
  final String clientId;
  final String clientToken;

  bool get hasRequiredFields =>
      !enabled || (normalizedBaseUrl.isNotEmpty && normalizedClientId.isNotEmpty);

  String get normalizedBaseUrl => baseUrl.trim();

  String get normalizedClientId => clientId.trim();

  String get normalizedClientToken => clientToken.trim();

  RemoteBridgeConfig copyWith({
    bool? enabled,
    String? baseUrl,
    String? clientId,
    String? clientToken,
  }) {
    return RemoteBridgeConfig(
      enabled: enabled ?? this.enabled,
      baseUrl: baseUrl ?? this.baseUrl,
      clientId: clientId ?? this.clientId,
      clientToken: clientToken ?? this.clientToken,
    );
  }

  RemoteBridgeConfig normalized() {
    return RemoteBridgeConfig(
      enabled: enabled,
      baseUrl: normalizedBaseUrl,
      clientId: normalizedClientId.isEmpty
          ? productionClientId
          : normalizedClientId,
      clientToken: normalizedClientToken,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'enabled': enabled,
      'baseUrl': baseUrl,
      'clientId': clientId,
      'clientToken': clientToken,
    };
  }
}

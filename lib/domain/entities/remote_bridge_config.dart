class RemoteBridgeConfig {
  static const String productionBridgeBaseUrl = 'https://bridge.toylink.local';
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
  }) : enabled = true,
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
      !enabled ||
      (normalizedBaseUrl.isNotEmpty &&
          normalizedClientId.isNotEmpty &&
          isAllowedBySafetyV0EndpointPolicy);

  bool get isAllowedBySafetyV0EndpointPolicy {
    if (!enabled) {
      return true;
    }
    final Uri? uri = Uri.tryParse(normalizedBaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return false;
    }
    if (_isLoopbackHost(uri.host)) {
      return uri.scheme == 'http' || uri.scheme == 'https';
    }
    return uri.scheme == 'https' && normalizedClientToken.isNotEmpty;
  }

  String get normalizedBaseUrl => baseUrl.trim();

  String get normalizedClientId => clientId.trim();

  String get normalizedClientToken => clientToken.trim();

  bool _isLoopbackHost(String host) {
    final String normalized = host.trim().toLowerCase();
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '::1';
  }

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

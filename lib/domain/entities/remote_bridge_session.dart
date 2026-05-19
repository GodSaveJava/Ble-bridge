enum RemoteBridgeSessionStatus { offline, connecting, ready, busy, error }

class RemoteBridgeConnectorInfo {
  const RemoteBridgeConnectorInfo({
    required this.connectorUrl,
    required this.connectorToken,
    required this.toolNames,
  });

  final String connectorUrl;
  final String connectorToken;
  final List<String> toolNames;

  bool get hasToken => connectorToken.trim().isNotEmpty;

  String get maskedToken {
    if (connectorToken.length <= 8) {
      return connectorToken;
    }
    return '${connectorToken.substring(0, 4)}...'
        '${connectorToken.substring(connectorToken.length - 4)}';
  }

  RemoteBridgeConnectorInfo copyWith({
    String? connectorUrl,
    String? connectorToken,
    List<String>? toolNames,
  }) {
    return RemoteBridgeConnectorInfo(
      connectorUrl: connectorUrl ?? this.connectorUrl,
      connectorToken: connectorToken ?? this.connectorToken,
      toolNames: toolNames ?? this.toolNames,
    );
  }
}

class RemoteBridgeSession {
  const RemoteBridgeSession({
    required this.status,
    this.bridgeSessionId,
    this.connectorInfo,
    this.lastErrorCode,
    this.lastErrorMessage,
    this.lastUpdatedAt,
  });

  final RemoteBridgeSessionStatus status;
  final String? bridgeSessionId;
  final RemoteBridgeConnectorInfo? connectorInfo;
  final String? lastErrorCode;
  final String? lastErrorMessage;
  final DateTime? lastUpdatedAt;

  bool get isReady => status == RemoteBridgeSessionStatus.ready;

  bool get canOnboardClaude =>
      isReady && connectorInfo != null && connectorInfo!.hasToken;

  RemoteBridgeSession copyWith({
    RemoteBridgeSessionStatus? status,
    String? bridgeSessionId,
    RemoteBridgeConnectorInfo? connectorInfo,
    String? lastErrorCode,
    String? lastErrorMessage,
    DateTime? lastUpdatedAt,
    bool clearConnector = false,
    bool clearError = false,
  }) {
    return RemoteBridgeSession(
      status: status ?? this.status,
      bridgeSessionId: bridgeSessionId ?? this.bridgeSessionId,
      connectorInfo: clearConnector ? null : (connectorInfo ?? this.connectorInfo),
      lastErrorCode: clearError ? null : (lastErrorCode ?? this.lastErrorCode),
      lastErrorMessage: clearError
          ? null
          : (lastErrorMessage ?? this.lastErrorMessage),
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

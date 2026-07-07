import 'dart:convert';

class ConnectorCardPayload {
  const ConnectorCardPayload({
    required this.connectorUrl,
    required this.authToken,
    required this.tools,
    this.authType = 'bearer',
    this.type = expectedType,
    this.version = expectedVersion,
    this.phase = expectedPhase,
    this.instructions = safetyV0Instructions,
  });

  static const String expectedType = 'toylink_connector_card';
  static const int expectedVersion = 1;
  static const String expectedPhase = 'safety_v0';
  static const String safetyV0Instructions =
      'Only call get_status and stop_all in Phase 1. Remote set_* controls are not enabled.';
  static const Set<String> safetyV0Tools = <String>{'get_status', 'stop_all'};

  final String type;
  final int version;
  final String phase;
  final String connectorUrl;
  final String authType;
  final String authToken;
  final List<String> tools;
  final String instructions;

  factory ConnectorCardPayload.fromBridgeSession({
    required String? connectorUrl,
    required String? connectorToken,
    required List<String> toolNames,
  }) {
    return ConnectorCardPayload(
      connectorUrl: connectorUrl ?? '',
      authToken: connectorToken ?? '',
      tools: List<String>.unmodifiable(toolNames),
    );
  }

  factory ConnectorCardPayload.fromJson(Map<String, Object?> json) {
    final Object? auth = json['auth'];
    final Map<String, Object?> authJson = auth is Map
        ? auth.cast<String, Object?>()
        : const <String, Object?>{};
    final Object? tools = json['tools'];
    return ConnectorCardPayload(
      type: json['type']?.toString() ?? '',
      version: json['version'] is int ? json['version']! as int : 0,
      phase: json['phase']?.toString() ?? '',
      connectorUrl: json['connectorUrl']?.toString() ?? '',
      authType: authJson['type']?.toString() ?? '',
      authToken: authJson['token']?.toString() ?? '',
      tools: tools is List
          ? tools.map((Object? tool) => tool.toString()).toList()
          : const <String>[],
      instructions: json['instructions']?.toString() ?? '',
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'type': type,
      'version': version,
      'phase': phase,
      'connectorUrl': connectorUrl,
      'auth': <String, Object?>{'type': authType, 'token': authToken},
      'tools': tools,
      'instructions': instructions,
    };
  }

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  String toDeepLink() {
    final String payload = base64UrlEncode(utf8.encode(jsonEncode(toJson())));
    return 'toylink://connector-card/v1?payload=$payload';
  }

  String get maskedToken {
    if (authToken.length <= 8) {
      return authToken;
    }
    return '${authToken.substring(0, 4)}...'
        '${authToken.substring(authToken.length - 4)}';
  }

  List<String> get validationErrors {
    final List<String> errors = <String>[];
    if (type != expectedType) {
      errors.add('连接卡片类型不正确。');
    }
    if (version != expectedVersion) {
      errors.add('连接卡片版本不受支持。');
    }
    if (phase != expectedPhase) {
      errors.add('只支持 Safety V0 连接卡片。');
    }
    final Uri? uri = Uri.tryParse(connectorUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      errors.add('Connector URL 无效。');
    }
    if (authType != 'bearer' || authToken.trim().isEmpty) {
      errors.add('Bearer token 缺失或无效。');
    }
    final Set<String> toolSet = tools.toSet();
    if (!toolSet.containsAll(safetyV0Tools)) {
      errors.add('Safety V0 必须包含 get_status 和 stop_all。');
    }
    if (!safetyV0Tools.containsAll(toolSet)) {
      errors.add('连接卡片包含 Safety V0 以外的工具。');
    }
    return errors;
  }

  bool get isValid => validationErrors.isEmpty;

  static ConnectorCardPayload? tryParseDeepLink(Uri uri) {
    final bool isConnectorUri =
        uri.scheme == 'toylink' &&
        uri.host == 'connector-card' &&
        uri.path == '/v1';
    final bool isInternalRoute = uri.path == '/connector-card/v1';
    if (!isConnectorUri && !isInternalRoute) {
      return null;
    }
    final String? payload = uri.queryParameters['payload'];
    if (payload == null || payload.isEmpty) {
      return null;
    }
    return tryParseBase64Payload(payload);
  }

  static ConnectorCardPayload? tryParseBase64Payload(String payload) {
    try {
      final String normalized = base64Url.normalize(payload);
      final Object? decoded = jsonDecode(
        utf8.decode(base64Url.decode(normalized)),
      );
      if (decoded is! Map) {
        return null;
      }
      return ConnectorCardPayload.fromJson(decoded.cast<String, Object?>());
    } catch (_) {
      return null;
    }
  }
}

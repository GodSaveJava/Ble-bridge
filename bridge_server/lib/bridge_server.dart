import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

class BridgeServerConfig {
  const BridgeServerConfig({
    this.host = '0.0.0.0',
    this.port = 8100,
    this.publicBaseUrl = '',
    this.connectorPath = '/mcp/claude',
    this.sharedToken = '',
    this.debugToken = '',
    this.toolNames = safeDefaultToolNames,
    this.allowInsecurePublicHttpForTesting = false,
    this.sessionTtl = const Duration(hours: 1),
    this.connectorTokenTtl = const Duration(minutes: 15),
  });

  static const List<String> safeDefaultToolNames = <String>[
    'get_status',
    'stop_all',
  ];

  factory BridgeServerConfig.fromEnvironment() {
    return BridgeServerConfig(
      host: Platform.environment['BRIDGE_HOST'] ?? '0.0.0.0',
      port: int.tryParse(Platform.environment['BRIDGE_PORT'] ?? '') ?? 8100,
      publicBaseUrl: Platform.environment['BRIDGE_PUBLIC_BASE_URL'] ?? '',
      connectorPath:
          Platform.environment['BRIDGE_CONNECTOR_PATH'] ?? '/mcp/claude',
      sharedToken: Platform.environment['BRIDGE_SHARED_TOKEN'] ?? '',
      debugToken: Platform.environment['BRIDGE_DEBUG_TOKEN'] ?? '',
      toolNames: _parseToolNames(Platform.environment['BRIDGE_TOOL_NAMES']),
      allowInsecurePublicHttpForTesting:
          Platform.environment['BRIDGE_ALLOW_INSECURE_PUBLIC_HTTP'] == 'true',
    );
  }

  final String host;
  final int port;
  final String publicBaseUrl;
  final String connectorPath;
  final String sharedToken;
  final String debugToken;
  final List<String> toolNames;
  final bool allowInsecurePublicHttpForTesting;
  final Duration sessionTtl;
  final Duration connectorTokenTtl;

  Uri resolvePublicBaseUri(Uri requestUri) {
    if (publicBaseUrl.trim().isNotEmpty) {
      return Uri.parse(publicBaseUrl.trim());
    }
    final String scheme = requestUri.scheme.isNotEmpty
        ? requestUri.scheme
        : 'http';
    final String host = requestUri.host.isNotEmpty
        ? requestUri.host
        : requestUri.authority.isNotEmpty
        ? requestUri.authority
        : '127.0.0.1';
    final int port = requestUri.hasPort ? requestUri.port : this.port;
    return Uri(scheme: scheme, host: host, port: port);
  }

  Uri resolveConnectorUrl(Uri requestUri) {
    final Uri base = resolvePublicBaseUri(requestUri);
    return Uri(
      scheme: base.scheme,
      userInfo: base.userInfo,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: connectorPath,
    );
  }

  static List<String> _parseToolNames(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return safeDefaultToolNames;
    }
    final List<String> parsed = raw
        .split(',')
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);
    final List<String> safe = parsed
        .where(safeDefaultToolNames.contains)
        .toList(growable: false);
    if (safe.isEmpty) {
      return safeDefaultToolNames;
    }
    return safe;
  }
}

class BridgeServer {
  BridgeServer({required this.config});

  final BridgeServerConfig config;
  final Map<String, _BridgeSession> _sessions = <String, _BridgeSession>{};
  final Map<String, _BridgeTask> _debugTaskQueue = <String, _BridgeTask>{};
  final Random _secureRandom = Random.secure();

  List<String> get _enabledToolNames {
    final Set<String> configured = config.toolNames.toSet();
    final List<String> safe = BridgeServerConfig.safeDefaultToolNames
        .where(configured.contains)
        .toList(growable: false);
    if (safe.isEmpty) {
      return BridgeServerConfig.safeDefaultToolNames;
    }
    return safe;
  }

  Future<HttpServer> bind() async {
    _validateBindSecurity();
    final HttpServer server = await HttpServer.bind(config.host, config.port);
    server.listen(_handleRequest);
    return server;
  }

  void _validateBindSecurity() {
    final String normalizedHost = config.host.trim().toLowerCase();
    final bool isLoopbackHost =
        normalizedHost == '127.0.0.1' ||
        normalizedHost == 'localhost' ||
        normalizedHost == '::1';
    final Uri? publicUri = config.publicBaseUrl.trim().isEmpty
        ? null
        : Uri.tryParse(config.publicBaseUrl.trim());
    final String publicHost = publicUri?.host.toLowerCase() ?? '';
    final bool isLoopbackPublicBase =
        publicHost.isEmpty ||
        publicHost == '127.0.0.1' ||
        publicHost == 'localhost' ||
        publicHost == '::1';
    final bool usesInsecurePublicHttp =
        publicUri != null &&
        publicUri.scheme.toLowerCase() == 'http' &&
        !isLoopbackPublicBase;

    if ((!isLoopbackHost || !isLoopbackPublicBase) &&
        config.sharedToken.trim().isEmpty) {
      throw StateError(
        'BRIDGE_SHARED_TOKEN is required when binding a public bridge.',
      );
    }
    if (usesInsecurePublicHttp && !config.allowInsecurePublicHttpForTesting) {
      throw StateError(
        'HTTPS is required for public bridge URLs. Set '
        'BRIDGE_ALLOW_INSECURE_PUBLIC_HTTP=true only for internal testing.',
      );
    }
  }

  void _handleRequest(HttpRequest request) async {
    final String path = request.uri.path;
    try {
      if (_isBridgePath(path) && !_isAuthenticated(request)) {
        await _writeJson(request, HttpStatus.unauthorized, <String, Object?>{
          'ok': false,
          'errorCode': 'unauthorized',
          'errorMessage': 'Missing or invalid bridge token.',
        });
        return;
      }

      if (request.method == 'GET' && path == '/health') {
        await _writeJson(request, 200, <String, Object?>{
          'ok': true,
          'service': 'toylink-bridge-server',
        });
        return;
      }

      if (request.method == 'GET' && path == config.connectorPath) {
        await _writeJson(request, 200, <String, Object?>{
          'ok': true,
          'service': 'toylink-bridge-server',
          'connectorPath': config.connectorPath,
          'bridgeBaseUrl': config.publicBaseUrl.trim(),
        });
        return;
      }

      if (request.method == 'POST' && path == '/mobile-bridge/session/start') {
        await _handleStart(request);
        return;
      }

      final Uri? sessionUri = _matchSessionPath(path);
      if (sessionUri != null) {
        final String bridgeSessionId = sessionUri.pathSegments[2];
        if (request.method == 'POST' &&
            sessionUri.pathSegments.length == 4 &&
            sessionUri.pathSegments[3] == 'refresh') {
          await _handleRefresh(request, bridgeSessionId);
          return;
        }
        if (request.method == 'POST' &&
            sessionUri.pathSegments.length == 4 &&
            sessionUri.pathSegments[3] == 'next-task') {
          await _handleNextTask(request, bridgeSessionId);
          return;
        }
        if (request.method == 'POST' &&
            sessionUri.pathSegments.length == 4 &&
            sessionUri.pathSegments[3] == 'task-result') {
          await _handleTaskResult(request, bridgeSessionId);
          return;
        }
        if (request.method == 'POST' &&
            sessionUri.pathSegments.length == 4 &&
            sessionUri.pathSegments[3] == 'stop') {
          await _handleStop(request, bridgeSessionId);
          return;
        }
      }

      if (request.method == 'POST' && path == '/debug/enqueue') {
        await _handleDebugEnqueue(request);
        return;
      }

      await _writeJson(request, HttpStatus.notFound, <String, Object?>{
        'ok': false,
        'errorCode': 'not_found',
        'errorMessage': 'Unknown path: $path',
      });
    } on Object catch (error, stackTrace) {
      stderr.writeln('Bridge server error: $error');
      stderr.writeln(stackTrace);
      await _writeJson(
        request,
        HttpStatus.internalServerError,
        <String, Object?>{
          'ok': false,
          'errorCode': 'server_error',
          'errorMessage': error.toString(),
        },
      );
    } finally {
      await request.response.close();
    }
  }

  Uri? _matchSessionPath(String path) {
    final List<String> segments = Uri.parse(
      path,
    ).pathSegments.where((String s) => s.isNotEmpty).toList();
    if (segments.length == 4 &&
        segments[0] == 'mobile-bridge' &&
        segments[1] == 'session') {
      return Uri(pathSegments: segments);
    }
    return null;
  }

  bool _isBridgePath(String path) {
    return path == '/mobile-bridge/session/start' ||
        path.startsWith('/mobile-bridge/session/') ||
        path == '/debug/enqueue';
  }

  bool _isAuthenticated(HttpRequest request) {
    if (config.sharedToken.isEmpty) {
      return true;
    }
    final String token =
        request.headers.value(HttpHeaders.authorizationHeader) ??
        request.headers.value('x-bridge-token') ??
        '';
    return token == 'Bearer ${config.sharedToken}' ||
        token == config.sharedToken;
  }

  Future<void> _handleStart(HttpRequest request) async {
    final DateTime now = DateTime.now().toUtc();
    final Map<String, Object?> body = await _readJson(request);
    final String clientId = (body['clientId'] as String? ?? '').trim();
    if (clientId.isEmpty) {
      await _writeJson(request, HttpStatus.badRequest, <String, Object?>{
        'ok': false,
        'errorCode': 'invalid_request',
        'errorMessage': 'clientId is required.',
      });
      return;
    }

    final String bridgeSessionId = _newOpaqueId('bridge-session');
    final String connectorToken = _newOpaqueId('toy_bridge_token');
    final Uri connectorUrl = config.resolveConnectorUrl(request.uri);
    final _BridgeSession session = _BridgeSession(
      bridgeSessionId: bridgeSessionId,
      clientId: clientId,
      connectorToken: connectorToken,
      connectorUrl: connectorUrl.toString(),
      toolNames: _enabledToolNames,
      status: 'ready',
      expiresAt: now.add(config.sessionTtl),
      connectorTokenExpiresAt: now.add(config.connectorTokenTtl),
      updatedAt: now,
    );
    _sessions[bridgeSessionId] = session;

    await _writeJson(request, HttpStatus.ok, session.toJson());
  }

  Future<void> _handleRefresh(
    HttpRequest request,
    String bridgeSessionId,
  ) async {
    final Map<String, Object?> body = await _readJson(request);
    final _BridgeSession? session = await _requireActiveSession(
      request,
      bridgeSessionId,
      expectedClientId: (body['clientId'] as String? ?? '').trim(),
    );
    if (session == null) {
      return;
    }

    final DateTime now = DateTime.now().toUtc();
    final _BridgeSession refreshed = session.copyWith(
      connectorToken: _newOpaqueId('toy_bridge_token'),
      connectorTokenExpiresAt: now.add(config.connectorTokenTtl),
      updatedAt: now,
    );
    _sessions[bridgeSessionId] = refreshed;
    await _writeJson(request, HttpStatus.ok, refreshed.toJson());
  }

  Future<void> _handleNextTask(
    HttpRequest request,
    String bridgeSessionId,
  ) async {
    final Map<String, Object?> body = await _readJson(request);
    final _BridgeSession? session = await _requireActiveSession(
      request,
      bridgeSessionId,
      expectedClientId: (body['clientId'] as String? ?? '').trim(),
    );
    if (session == null) {
      return;
    }

    final _BridgeTask? task = _debugTaskQueue.remove(bridgeSessionId);
    if (task == null) {
      request.response.statusCode = HttpStatus.noContent;
      return;
    }

    await _writeJson(request, HttpStatus.ok, task.toJson());
  }

  Future<void> _handleTaskResult(
    HttpRequest request,
    String bridgeSessionId,
  ) async {
    final Map<String, Object?> body = await _readJson(request);
    final _BridgeSession? session = await _requireActiveSession(
      request,
      bridgeSessionId,
      expectedClientId: (body['clientId'] as String? ?? '').trim(),
    );
    if (session == null) {
      return;
    }
    _sessions[bridgeSessionId] = session.copyWith(
      lastTaskResult: body,
      updatedAt: DateTime.now().toUtc(),
    );
    await _writeJson(request, HttpStatus.ok, <String, Object?>{
      'ok': true,
      'bridgeSessionId': bridgeSessionId,
    });
  }

  Future<void> _handleStop(HttpRequest request, String bridgeSessionId) async {
    final Map<String, Object?> body = await _readJson(request);
    final _BridgeSession? session = await _requireActiveSession(
      request,
      bridgeSessionId,
      expectedClientId: (body['clientId'] as String? ?? '').trim(),
    );
    if (session == null) {
      return;
    }

    _sessions[bridgeSessionId] = session.copyWith(
      status: 'offline',
      updatedAt: DateTime.now().toUtc(),
    );
    await _writeJson(request, HttpStatus.noContent, <String, Object?>{});
  }

  Future<void> _handleDebugEnqueue(HttpRequest request) async {
    if (config.debugToken.trim().isEmpty) {
      await _writeJson(request, HttpStatus.notFound, <String, Object?>{
        'ok': false,
        'errorCode': 'not_found',
        'errorMessage': 'Unknown path: ${request.uri.path}',
      });
      return;
    }

    if (config.debugToken.isNotEmpty) {
      final String token =
          request.headers.value(HttpHeaders.authorizationHeader) ??
          request.headers.value('x-debug-token') ??
          '';
      if (token != 'Bearer ${config.debugToken}' &&
          token != config.debugToken) {
        await _writeJson(request, HttpStatus.unauthorized, <String, Object?>{
          'ok': false,
          'errorCode': 'unauthorized',
          'errorMessage': 'Invalid debug token.',
        });
        return;
      }
    }

    final Map<String, Object?> body = await _readJson(request);
    final String bridgeSessionId = (body['bridgeSessionId'] as String? ?? '')
        .trim();
    final String requestId = (body['requestId'] as String? ?? '').trim();
    final String tool = (body['tool'] as String? ?? '').trim();
    final Map<String, Object?> input =
        (body['input'] as Map?)?.cast<String, Object?>() ??
        const <String, Object?>{};
    if (bridgeSessionId.isEmpty || requestId.isEmpty || tool.isEmpty) {
      await _writeJson(request, HttpStatus.badRequest, <String, Object?>{
        'ok': false,
        'errorCode': 'invalid_request',
        'errorMessage': 'bridgeSessionId, requestId and tool are required.',
      });
      return;
    }
    if (!_enabledToolNames.contains(tool)) {
      await _writeJson(request, HttpStatus.badRequest, <String, Object?>{
        'ok': false,
        'errorCode': 'tool_not_enabled_for_bridge',
        'errorMessage': 'Debug queue only accepts Safety V0 tools.',
        'enabledToolNames': _enabledToolNames,
      });
      return;
    }
    final _BridgeSession? session = await _requireActiveSession(
      request,
      bridgeSessionId,
    );
    if (session == null) {
      return;
    }

    _debugTaskQueue[session.bridgeSessionId] = _BridgeTask(
      requestId: requestId,
      tool: tool,
      input: input,
    );
    await _writeJson(request, HttpStatus.ok, <String, Object?>{
      'ok': true,
      'bridgeSessionId': bridgeSessionId,
      'queued': true,
    });
  }

  Future<_BridgeSession?> _requireActiveSession(
    HttpRequest request,
    String bridgeSessionId, {
    String expectedClientId = '',
  }) async {
    final _BridgeSession? session = _sessions[bridgeSessionId];
    if (session == null) {
      await _writeJson(request, HttpStatus.notFound, <String, Object?>{
        'ok': false,
        'errorCode': 'bridge_session_missing',
        'errorMessage': 'Bridge session not found.',
      });
      return null;
    }
    if (session.isExpired(DateTime.now().toUtc())) {
      _sessions.remove(bridgeSessionId);
      _debugTaskQueue.remove(bridgeSessionId);
      await _writeJson(request, HttpStatus.gone, <String, Object?>{
        'ok': false,
        'errorCode': 'bridge_session_expired',
        'errorMessage': 'Bridge session expired.',
      });
      return null;
    }
    if (expectedClientId.isNotEmpty && expectedClientId != session.clientId) {
      await _writeJson(request, HttpStatus.forbidden, <String, Object?>{
        'ok': false,
        'errorCode': 'client_session_mismatch',
        'errorMessage': 'Client is not bound to this bridge session.',
      });
      return null;
    }
    return session;
  }

  String _newOpaqueId(String prefix) {
    final List<int> bytes = List<int>.generate(
      18,
      (_) => _secureRandom.nextInt(256),
      growable: false,
    );
    final String token = base64Url.encode(bytes).replaceAll('=', '');
    return '$prefix-$token';
  }

  Future<Map<String, Object?>> _readJson(HttpRequest request) async {
    final String raw = await utf8.decoder.bind(request).join();
    if (raw.trim().isEmpty) {
      return <String, Object?>{};
    }
    final Object decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw FormatException('Expected JSON object.');
    }
    return decoded.cast<String, Object?>();
  }

  Future<void> _writeJson(
    HttpRequest request,
    int statusCode,
    Map<String, Object?> json,
  ) async {
    request.response.statusCode = statusCode;
    request.response.headers.contentType = ContentType.json;
    request.response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    if (statusCode == HttpStatus.noContent) {
      return;
    }
    request.response.write(jsonEncode(json));
  }
}

class _BridgeSession {
  _BridgeSession({
    required this.bridgeSessionId,
    required this.clientId,
    required this.connectorToken,
    required this.connectorUrl,
    required this.toolNames,
    required this.status,
    this.lastTaskResult,
    required this.expiresAt,
    required this.connectorTokenExpiresAt,
    DateTime? updatedAt,
  }) : updatedAt =
           updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  final String bridgeSessionId;
  final String clientId;
  final String connectorToken;
  final String connectorUrl;
  final List<String> toolNames;
  final String status;
  final Map<String, Object?>? lastTaskResult;
  final DateTime expiresAt;
  final DateTime connectorTokenExpiresAt;
  final DateTime updatedAt;

  _BridgeSession copyWith({
    String? connectorToken,
    String? connectorUrl,
    List<String>? toolNames,
    String? status,
    Map<String, Object?>? lastTaskResult,
    DateTime? expiresAt,
    DateTime? connectorTokenExpiresAt,
    DateTime? updatedAt,
  }) {
    return _BridgeSession(
      bridgeSessionId: bridgeSessionId,
      clientId: clientId,
      connectorToken: connectorToken ?? this.connectorToken,
      connectorUrl: connectorUrl ?? this.connectorUrl,
      toolNames: toolNames ?? this.toolNames,
      status: status ?? this.status,
      lastTaskResult: lastTaskResult ?? this.lastTaskResult,
      expiresAt: expiresAt ?? this.expiresAt,
      connectorTokenExpiresAt:
          connectorTokenExpiresAt ?? this.connectorTokenExpiresAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool isExpired(DateTime now) => !expiresAt.isAfter(now);

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'bridgeSessionId': bridgeSessionId,
      'connectorUrl': connectorUrl,
      'connectorToken': connectorToken,
      'toolNames': toolNames,
      'status': status,
      'clientId': clientId,
      'expiresAt': expiresAt.toIso8601String(),
      'connectorTokenExpiresAt': connectorTokenExpiresAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class _BridgeTask {
  const _BridgeTask({
    required this.requestId,
    required this.tool,
    required this.input,
  });

  final String requestId;
  final String tool;
  final Map<String, Object?> input;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'requestId': requestId,
      'tool': tool,
      'input': input,
    };
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/entities/remote_bridge_session.dart';
import '../../domain/entities/remote_bridge_task_assignment.dart';
import '../../domain/entities/remote_bridge_task_result.dart';
import '../../domain/services/remote_bridge_service.dart';
import 'remote_bridge_protocol.dart';

class HttpRemoteBridgeService
    implements RemoteBridgeService, RemoteBridgeServiceDiagnostics {
  HttpRemoteBridgeService({
    required Uri baseUrl,
    required String clientId,
    this.runtimeSource = RemoteBridgeRuntimeSource.unknown,
    this.keepAliveInterval = const Duration(seconds: 45),
    String? clientToken,
    HttpClient? httpClient,
  }) : _baseUrl = baseUrl,
       _clientId = clientId,
       _clientToken = clientToken,
       _httpClient = httpClient ?? HttpClient(),
       _session = const RemoteBridgeSession(
         status: RemoteBridgeSessionStatus.offline,
       );

  final Uri _baseUrl;
  final String _clientId;
  final String? _clientToken;
  @override
  final RemoteBridgeRuntimeSource runtimeSource;
  final Duration keepAliveInterval;
  final HttpClient _httpClient;
  final StreamController<RemoteBridgeSession> _controller =
      StreamController<RemoteBridgeSession>.broadcast();

  RemoteBridgeSession _session;
  Timer? _keepAliveTimer;
  bool _keepAliveInFlight = false;
  bool _isDisposed = false;

  @override
  RemoteBridgeSession get currentSession => _session;

  @override
  void dispose() {
    _isDisposed = true;
    _stopKeepAliveTimer();
    _httpClient.close(force: true);
    _controller.close();
  }

  @override
  Future<void> refreshConnector() async {
    final String? bridgeSessionId = _session.bridgeSessionId;
    if (bridgeSessionId == null || bridgeSessionId.isEmpty) {
      _emit(
        _session.copyWith(
          status: RemoteBridgeSessionStatus.error,
          lastErrorCode: 'bridge_session_missing',
          lastErrorMessage: '当前还没有可刷新的桥接会话。',
          lastUpdatedAt: DateTime.now(),
        ),
      );
      return;
    }

    _emit(
      _session.copyWith(
        status: RemoteBridgeSessionStatus.busy,
        clearError: true,
        lastUpdatedAt: DateTime.now(),
      ),
    );

    try {
      final Map<String, dynamic> response = await _postJson(
        path: RemoteBridgeProtocol.sessionRefreshPath(bridgeSessionId),
        body: RemoteBridgeProtocol.sessionRequestBody(_clientId),
      );
      _emit(
        RemoteBridgeProtocol.parseSessionResponse(
          response,
          fallback: _session,
        ),
      );
      _startKeepAliveTimer();
    } on Object catch (error) {
      _stopKeepAliveTimer();
      _emit(_errorSession('bridge_refresh_failed', error));
    }
  }

  @override
  Future<RemoteBridgeTaskAssignment?> fetchNextTask() async {
    final String? bridgeSessionId = _session.bridgeSessionId;
    if (!_session.isReady || bridgeSessionId == null || bridgeSessionId.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic>? response = await _postJsonOrNull(
        path: RemoteBridgeProtocol.sessionNextTaskPath(bridgeSessionId),
        body: RemoteBridgeProtocol.sessionRequestBody(_clientId),
      );
      final RemoteBridgeTaskAssignment? task =
          RemoteBridgeProtocol.parseTaskAssignmentResponse(response);
      if (task == null) {
        return null;
      }

      _emit(
        _session.copyWith(
          clearError: true,
          lastUpdatedAt: DateTime.now(),
        ),
      );

      return task;
    } on Object catch (error) {
      _emit(_errorSession('bridge_task_fetch_failed', error));
      return null;
    }
  }

  @override
  Future<void> reportTaskResult(RemoteBridgeTaskResult result) async {
    final String? bridgeSessionId = _session.bridgeSessionId;
    if (bridgeSessionId == null || bridgeSessionId.isEmpty) {
      _emit(
        _session.copyWith(
          status: RemoteBridgeSessionStatus.error,
          lastErrorCode: 'bridge_session_missing',
          lastErrorMessage: 'Current bridge session is missing.',
          lastUpdatedAt: DateTime.now(),
        ),
      );
      return;
    }

    try {
      await _postJson(
        path: RemoteBridgeProtocol.sessionTaskResultPath(bridgeSessionId),
        body: RemoteBridgeProtocol.taskResultRequestBody(_clientId, result),
      );
      _emit(
        _session.copyWith(
          clearError: true,
          lastUpdatedAt: DateTime.now(),
        ),
      );
    } on Object catch (error) {
      _emit(_errorSession('bridge_task_result_report_failed', error));
    }
  }

  @override
  Future<void> startSession() async {
    _emit(
      _session.copyWith(
        status: RemoteBridgeSessionStatus.connecting,
        clearError: true,
        lastUpdatedAt: DateTime.now(),
      ),
    );

    try {
      final Map<String, dynamic> response = await _postJson(
        path: RemoteBridgeProtocol.sessionStartPath,
        body: RemoteBridgeProtocol.sessionRequestBody(_clientId),
      );
      _emit(
        RemoteBridgeProtocol.parseSessionResponse(
          response,
          fallback: _session,
        ),
      );
      _startKeepAliveTimer();
    } on Object catch (error) {
      _stopKeepAliveTimer();
      _emit(_errorSession('bridge_start_failed', error));
    }
  }

  @override
  Future<void> stopSession() async {
    final String? bridgeSessionId = _session.bridgeSessionId;
    _stopKeepAliveTimer();
    if (bridgeSessionId == null || bridgeSessionId.isEmpty) {
      _emit(
        RemoteBridgeSession(
          status: RemoteBridgeSessionStatus.offline,
          lastUpdatedAt: DateTime.now(),
        ),
      );
      return;
    }

    try {
      await _postWithoutBody(RemoteBridgeProtocol.sessionStopPath(bridgeSessionId));
      _emit(
        RemoteBridgeSession(
          status: RemoteBridgeSessionStatus.offline,
          lastUpdatedAt: DateTime.now(),
        ),
      );
    } on Object catch (error) {
      _emit(_errorSession('bridge_stop_failed', error));
    }
  }

  @override
  Stream<RemoteBridgeSession> watchSession() async* {
    yield _session;
    yield* _controller.stream;
  }

  Future<Map<String, dynamic>> _postJson({
    required String path,
    required Map<String, Object?> body,
  }) async {
    final HttpClientRequest request = await _httpClient.postUrl(
      _resolve(path),
    );
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (_clientToken case final String clientToken when clientToken.isNotEmpty) {
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $clientToken',
      );
    }
    request.write(jsonEncode(body));
    final HttpClientResponse response = await request.close();
    final String responseBody = await utf8.decoder.bind(response).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Remote bridge returned ${response.statusCode}: $responseBody',
      );
    }

    if (responseBody.isEmpty) {
      return const <String, dynamic>{};
    }

    return jsonDecode(responseBody) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> _postJsonOrNull({
    required String path,
    required Map<String, Object?> body,
  }) async {
    final HttpClientRequest request = await _httpClient.postUrl(_resolve(path));
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (_clientToken case final String clientToken when clientToken.isNotEmpty) {
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $clientToken',
      );
    }
    request.write(jsonEncode(body));
    final HttpClientResponse response = await request.close();
    final String responseBody = await utf8.decoder.bind(response).join();

    if (response.statusCode == HttpStatus.noContent) {
      return null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Remote bridge returned ${response.statusCode}: $responseBody',
      );
    }

    if (responseBody.isEmpty) {
      return const <String, dynamic>{};
    }

    return jsonDecode(responseBody) as Map<String, dynamic>;
  }

  Future<void> _postWithoutBody(String path) async {
    final HttpClientRequest request = await _httpClient.postUrl(_resolve(path));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (_clientToken case final String clientToken when clientToken.isNotEmpty) {
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $clientToken',
      );
    }
    final HttpClientResponse response = await request.close();
    final String responseBody = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Remote bridge returned ${response.statusCode}: $responseBody',
      );
    }
  }

  RemoteBridgeSession _errorSession(String code, Object error) {
    return _session.copyWith(
      status: RemoteBridgeSessionStatus.error,
      lastErrorCode: code,
      lastErrorMessage: error.toString(),
      lastUpdatedAt: DateTime.now(),
    );
  }

  Uri _resolve(String path) {
    final String base = _baseUrl.toString().endsWith('/')
        ? _baseUrl.toString()
        : '${_baseUrl.toString()}/';
    final String normalizedPath = path.startsWith('/')
        ? path.substring(1)
        : path;
    return Uri.parse(base).resolve(normalizedPath);
  }

  void _emit(RemoteBridgeSession next) {
    _session = next;
    if (_isDisposed || _controller.isClosed) {
      return;
    }
    _controller.add(next);
  }

  void _startKeepAliveTimer() {
    _stopKeepAliveTimer();
    if (keepAliveInterval <= Duration.zero) {
      return;
    }
    _keepAliveTimer = Timer.periodic(keepAliveInterval, (_) {
      unawaited(_runKeepAlive());
    });
  }

  void _stopKeepAliveTimer() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }

  Future<void> _runKeepAlive() async {
    if (_isDisposed || _keepAliveInFlight || !_session.isReady) {
      return;
    }

    final String? bridgeSessionId = _session.bridgeSessionId;
    if (bridgeSessionId == null || bridgeSessionId.isEmpty) {
      return;
    }

    _keepAliveInFlight = true;
    try {
      final Map<String, dynamic> response = await _postJson(
        path: RemoteBridgeProtocol.sessionRefreshPath(bridgeSessionId),
        body: RemoteBridgeProtocol.sessionRequestBody(_clientId),
      );
      _emit(
        RemoteBridgeProtocol.parseSessionResponse(
          response,
          fallback: _session,
        ),
      );
    } on Object catch (error) {
      _stopKeepAliveTimer();
      if (!_isDisposed) {
        _emit(_errorSession('bridge_keepalive_failed', error));
      }
    } finally {
      _keepAliveInFlight = false;
    }
  }
}

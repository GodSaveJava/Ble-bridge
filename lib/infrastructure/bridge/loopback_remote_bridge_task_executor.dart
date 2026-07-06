import 'dart:convert';
import 'dart:io';

import '../../domain/entities/remote_bridge_task_result.dart';
import '../../domain/services/remote_bridge_task_executor.dart';

class LoopbackRemoteBridgeTaskExecutor implements RemoteBridgeTaskExecutor {
  LoopbackRemoteBridgeTaskExecutor({
    this.baseUrl = 'http://127.0.0.1:8765',
    this.path = '/mobile-bridge/tool-call',
    this.authToken = 'toylink-local-mcp-dev-token',
    HttpClient? httpClient,
  }) : _httpClient = httpClient ?? HttpClient();

  final String baseUrl;
  final String path;
  final String authToken;
  final HttpClient _httpClient;

  @override
  Future<RemoteBridgeTaskResult> execute({
    String? requestId,
    required String tool,
    Map<String, Object?> input = const <String, Object?>{},
  }) async {
    final HttpClientRequest request = await _httpClient.postUrl(_resolve());
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (authToken.isNotEmpty) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $authToken');
    }
    request.write(
      jsonEncode(<String, Object?>{
        'requestId': requestId,
        'tool': tool,
        'input': input,
      }),
    );

    final HttpClientResponse response = await request.close();
    final String body = await utf8.decoder.bind(response).join();

    if (response.statusCode != HttpStatus.ok &&
        response.statusCode != HttpStatus.badRequest) {
      throw StateError(
        'Loopback bridge returned ${response.statusCode}: $body',
      );
    }

    final dynamic json = jsonDecode(body);
    if (json is! Map<String, dynamic>) {
      throw StateError('Loopback bridge returned an invalid JSON object.');
    }

    final Object? error = json['error'];
    final Map<String, dynamic>? errorMap = error is Map<String, dynamic>
        ? error
        : null;

    return RemoteBridgeTaskResult(
      ok: json['ok'] == true,
      requestId: json['requestId']?.toString(),
      tool: json['tool']?.toString(),
      result: json['result'] is Map<String, dynamic>
          ? json['result'] as Map<String, dynamic>
          : null,
      errorCode: errorMap?['code']?.toString(),
      errorMessage: errorMap?['message']?.toString(),
    );
  }

  @override
  void dispose() {
    _httpClient.close(force: true);
  }

  Uri _resolve() {
    final String normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final String normalizedPath = path.startsWith('/')
        ? path.substring(1)
        : path;
    return Uri.parse(normalizedBase).resolve(normalizedPath);
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/infrastructure/mcp/local_mcp_http_service.dart';

import 'connector_smoke_test_support.dart';

void main() {
  test('MCP client discovers Safety V0 tools and calls get_status', () async {
    const int port = 8892;
    const String token = 'toy-mcp-client-token';
    final container = buildConnectorSmokeTestContainer();
    addTearDown(container.dispose);

    final LocalMcpHttpService service = LocalMcpHttpService(
      toolRouter: container.read(mcpToolRouterProvider),
      remoteBridgeToolCallHandler: container.read(
        remoteBridgeToolCallHandlerProvider,
      ),
      host: '127.0.0.1',
      port: port,
      authToken: token,
    );
    addTearDown(service.stop);
    await service.start();

    final _McpSmokeClient client = _McpSmokeClient(
      origin: Uri.parse('http://127.0.0.1:$port'),
      token: token,
    );
    addTearDown(client.close);

    final Map<String, dynamic> status = await client.get(
      '/mcp/status',
      authenticate: false,
    );
    expect(status['ok'], isTrue);
    expect(status['running'], isTrue);
    expect((status['endpoint'] as Map<String, dynamic>)['port'], port);

    final Map<String, dynamic> toolsResponse = await client.get('/mcp/tools');
    expect(toolsResponse['ok'], isTrue);
    final List<String> tools = (toolsResponse['tools'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((Map<String, dynamic> tool) => tool['name'] as String)
        .toList();
    expect(tools, <String>['stop_all', 'get_status']);
    expect(tools, isNot(contains('set_suck')));

    final Map<String, dynamic> getStatusResponse = await client.post(
      '/mcp/call',
      <String, Object?>{'tool': 'get_status', 'input': <String, Object?>{}},
    );
    expect(getStatusResponse['ok'], isTrue);
    expect(
      (getStatusResponse['status'] as Map<String, dynamic>)['isConnected'],
      isTrue,
    );
    expect(
      (getStatusResponse['status'] as Map<String, dynamic>)['deviceId'],
      'mock-sosexy-001',
    );

    final Map<String, dynamic> unsafeResponse = await client.post(
      '/mcp/call',
      <String, Object?>{
        'tool': 'set_suck',
        'input': <String, Object?>{'intensity': 10, 'mode': 1},
      },
      expectedStatus: HttpStatus.badRequest,
    );
    expect(unsafeResponse['ok'], isFalse);
    expect(
      (unsafeResponse['error'] as Map<String, dynamic>)['code'],
      'tool_not_enabled_for_mcp_safety_v0',
    );
  });
}

class _McpSmokeClient {
  _McpSmokeClient({required this.origin, required this.token});

  final Uri origin;
  final String token;
  final HttpClient _client = HttpClient();

  Future<Map<String, dynamic>> get(
    String path, {
    bool authenticate = true,
    int expectedStatus = HttpStatus.ok,
  }) async {
    final HttpClientRequest request = await _client.getUrl(
      origin.resolve(path),
    );
    if (authenticate) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    final HttpClientResponse response = await request.close();
    return _decodeResponse(response, expectedStatus);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, Object?> body, {
    int expectedStatus = HttpStatus.ok,
  }) async {
    final HttpClientRequest request = await _client.postUrl(
      origin.resolve(path),
    );
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.write(jsonEncode(body));
    final HttpClientResponse response = await request.close();
    return _decodeResponse(response, expectedStatus);
  }

  Future<Map<String, dynamic>> _decodeResponse(
    HttpClientResponse response,
    int expectedStatus,
  ) async {
    final String body = await utf8.decodeStream(response);
    expect(response.statusCode, expectedStatus, reason: body);
    return jsonDecode(body) as Map<String, dynamic>;
  }

  void close() {
    _client.close();
  }
}

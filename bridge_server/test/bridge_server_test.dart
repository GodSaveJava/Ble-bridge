import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:toylink_bridge_server/bridge_server.dart';

void main() {
  late HttpServer server;
  late Uri baseUri;

  setUp(() async {
    final BridgeServer bridgeServer = BridgeServer(
      config: const BridgeServerConfig(
        host: '127.0.0.1',
        port: 0,
        publicBaseUrl: 'http://127.0.0.1',
        connectorPath: '/mcp/claude',
      ),
    );
    server = await bridgeServer.bind();
    baseUri = Uri.parse('http://127.0.0.1:${server.port}');
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('start session returns connector info', () async {
    final HttpClient client = HttpClient();
    final HttpClientRequest request = await client.postUrl(
      baseUri.resolve('/mobile-bridge/session/start'),
    );
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(<String, Object?>{'clientId': 'client-1'}));
    final HttpClientResponse response = await request.close();
    final Map<String, dynamic> body = await utf8.decoder
        .bind(response)
        .join()
        .then((String content) => jsonDecode(content) as Map<String, dynamic>);

    expect(response.statusCode, 200);
    expect(body['bridgeSessionId'], startsWith('bridge-session-'));
    expect(body['connectorUrl'], 'http://127.0.0.1/mcp/claude');
    expect(body['connectorToken'], startsWith('toy_bridge_token-'));
    expect(body['toolNames'], <String>['get_status', 'stop_all']);
    expect(body['expiresAt'], isA<String>());
    expect(body['connectorTokenExpiresAt'], isA<String>());
  });

  test(
    'session advertises only Safety V0 tools even if configured otherwise',
    () async {
      final BridgeServer unsafeConfiguredServer = BridgeServer(
        config: const BridgeServerConfig(
          host: '127.0.0.1',
          port: 0,
          publicBaseUrl: 'http://127.0.0.1',
          connectorPath: '/mcp/claude',
          toolNames: <String>['set_suck', 'get_status', 'stop_all', 'set_ems'],
        ),
      );
      final HttpServer unsafeHttpServer = await unsafeConfiguredServer.bind();
      addTearDown(() async {
        await unsafeHttpServer.close(force: true);
      });

      final client = HttpClient();
      addTearDown(client.close);
      final Uri unsafeBaseUri = Uri.parse(
        'http://127.0.0.1:${unsafeHttpServer.port}',
      );

      final Map<String, dynamic> body = await _postJson(
        client,
        unsafeBaseUri.resolve('/mobile-bridge/session/start'),
        <String, Object?>{'clientId': 'client-1'},
      );

      expect(body['toolNames'], <String>['get_status', 'stop_all']);
    },
  );

  test('debug enqueue is disabled unless debug token is configured', () async {
    final HttpClient client = HttpClient();

    final Map<String, dynamic> start = await _postJson(
      client,
      baseUri.resolve('/mobile-bridge/session/start'),
      <String, Object?>{'clientId': 'client-1'},
    );
    final String bridgeSessionId = start['bridgeSessionId'] as String;

    final HttpClientRequest request = await client.postUrl(
      baseUri.resolve('/debug/enqueue'),
    );
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode(<String, Object?>{
        'bridgeSessionId': bridgeSessionId,
        'requestId': 'req-1',
        'tool': 'get_status',
        'input': <String, Object?>{},
      }),
    );
    final HttpClientResponse response = await request.close();

    expect(response.statusCode, 404);
  });

  test('debug enqueue requires debug token and returns queued task', () async {
    final BridgeServer debugServer = BridgeServer(
      config: const BridgeServerConfig(
        host: '127.0.0.1',
        port: 0,
        publicBaseUrl: 'http://127.0.0.1',
        connectorPath: '/mcp/claude',
        debugToken: 'debug-secret',
      ),
    );
    final HttpServer debugHttpServer = await debugServer.bind();
    addTearDown(() async {
      await debugHttpServer.close(force: true);
    });

    final Uri debugBaseUri = Uri.parse(
      'http://127.0.0.1:${debugHttpServer.port}',
    );
    final HttpClient client = HttpClient();

    final Map<String, dynamic> start = await _postJson(
      client,
      debugBaseUri.resolve('/mobile-bridge/session/start'),
      <String, Object?>{'clientId': 'client-1'},
    );
    final String bridgeSessionId = start['bridgeSessionId'] as String;

    final HttpClientRequest unauthorized = await client.postUrl(
      debugBaseUri.resolve('/debug/enqueue'),
    );
    unauthorized.headers.contentType = ContentType.json;
    unauthorized.write(
      jsonEncode(<String, Object?>{
        'bridgeSessionId': bridgeSessionId,
        'requestId': 'req-unauthorized',
        'tool': 'get_status',
        'input': <String, Object?>{},
      }),
    );
    final HttpClientResponse unauthorizedResponse = await unauthorized.close();
    expect(unauthorizedResponse.statusCode, 401);

    await _postJson(
      client,
      debugBaseUri.resolve('/debug/enqueue'),
      <String, Object?>{
        'bridgeSessionId': bridgeSessionId,
        'requestId': 'req-1',
        'tool': 'get_status',
        'input': <String, Object?>{},
      },
      token: 'debug-secret',
    );

    final HttpClientResponse response = await (await client.postUrl(
      debugBaseUri.resolve('/mobile-bridge/session/$bridgeSessionId/next-task'),
    )).close();
    final Map<String, dynamic> body = await utf8.decoder
        .bind(response)
        .join()
        .then((String content) => jsonDecode(content) as Map<String, dynamic>);

    expect(response.statusCode, 200);
    expect(body['requestId'], 'req-1');
    expect(body['tool'], 'get_status');
  });

  test('debug enqueue rejects non-allowlisted tools', () async {
    final BridgeServer debugServer = BridgeServer(
      config: const BridgeServerConfig(
        host: '127.0.0.1',
        port: 0,
        publicBaseUrl: 'http://127.0.0.1',
        connectorPath: '/mcp/claude',
        debugToken: 'debug-secret',
      ),
    );
    final HttpServer debugHttpServer = await debugServer.bind();
    addTearDown(() async {
      await debugHttpServer.close(force: true);
    });

    final Uri debugBaseUri = Uri.parse(
      'http://127.0.0.1:${debugHttpServer.port}',
    );
    final HttpClient client = HttpClient();
    addTearDown(client.close);

    final Map<String, dynamic> start = await _postJson(
      client,
      debugBaseUri.resolve('/mobile-bridge/session/start'),
      <String, Object?>{'clientId': 'client-1'},
    );
    final String bridgeSessionId = start['bridgeSessionId'] as String;

    final HttpClientRequest request = await client.postUrl(
      debugBaseUri.resolve('/debug/enqueue'),
    );
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer debug-secret');
    request.write(
      jsonEncode(<String, Object?>{
        'bridgeSessionId': bridgeSessionId,
        'requestId': 'req-set-suck',
        'tool': 'set_suck',
        'input': <String, Object?>{'intensity': 10},
      }),
    );
    final HttpClientResponse response = await request.close();
    final String raw = await utf8.decoder.bind(response).join();
    final Map<String, dynamic> body = jsonDecode(raw) as Map<String, dynamic>;

    expect(response.statusCode, HttpStatus.badRequest);
    expect(body['errorCode'], 'tool_not_enabled_for_bridge');

    final HttpClientResponse next = await (await client.postUrl(
      debugBaseUri.resolve('/mobile-bridge/session/$bridgeSessionId/next-task'),
    )).close();
    expect(next.statusCode, HttpStatus.noContent);
  });

  test('session refresh rejects client mismatch', () async {
    final HttpClient client = HttpClient();
    addTearDown(client.close);

    final Map<String, dynamic> start = await _postJson(
      client,
      baseUri.resolve('/mobile-bridge/session/start'),
      <String, Object?>{'clientId': 'client-1'},
    );
    final String bridgeSessionId = start['bridgeSessionId'] as String;

    final HttpClientRequest request = await client.postUrl(
      baseUri.resolve('/mobile-bridge/session/$bridgeSessionId/refresh'),
    );
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(<String, Object?>{'clientId': 'client-2'}));
    final HttpClientResponse response = await request.close();
    final String raw = await utf8.decoder.bind(response).join();
    final Map<String, dynamic> body = jsonDecode(raw) as Map<String, dynamic>;

    expect(response.statusCode, HttpStatus.forbidden);
    expect(body['errorCode'], 'client_session_mismatch');
  });

  test('expired session cannot return queued tasks', () async {
    final BridgeServer expiringServer = BridgeServer(
      config: const BridgeServerConfig(
        host: '127.0.0.1',
        port: 0,
        publicBaseUrl: 'http://127.0.0.1',
        connectorPath: '/mcp/claude',
        debugToken: 'debug-secret',
        sessionTtl: Duration.zero,
      ),
    );
    final HttpServer expiringHttpServer = await expiringServer.bind();
    addTearDown(() async {
      await expiringHttpServer.close(force: true);
    });

    final Uri expiringBaseUri = Uri.parse(
      'http://127.0.0.1:${expiringHttpServer.port}',
    );
    final HttpClient client = HttpClient();
    addTearDown(client.close);

    final Map<String, dynamic> start = await _postJson(
      client,
      expiringBaseUri.resolve('/mobile-bridge/session/start'),
      <String, Object?>{'clientId': 'client-1'},
    );
    final String bridgeSessionId = start['bridgeSessionId'] as String;

    final HttpClientRequest request = await client.postUrl(
      expiringBaseUri.resolve(
        '/mobile-bridge/session/$bridgeSessionId/next-task',
      ),
    );
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(<String, Object?>{'clientId': 'client-1'}));
    final HttpClientResponse response = await request.close();
    final String raw = await utf8.decoder.bind(response).join();
    final Map<String, dynamic> body = jsonDecode(raw) as Map<String, dynamic>;

    expect(response.statusCode, HttpStatus.gone);
    expect(body['errorCode'], 'bridge_session_expired');
  });

  test('public bind requires shared token', () async {
    final BridgeServer publicServerWithoutToken = BridgeServer(
      config: const BridgeServerConfig(
        host: '0.0.0.0',
        port: 0,
        publicBaseUrl: 'http://47.95.242.29:8100',
      ),
    );

    await expectLater(
      publicServerWithoutToken.bind(),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'public bridge rejects non-loopback HTTP even with shared token',
    () async {
      final BridgeServer publicHttpServer = BridgeServer(
        config: const BridgeServerConfig(
          host: '0.0.0.0',
          port: 0,
          publicBaseUrl: 'http://47.95.242.29:8100',
          sharedToken: 'bridge-secret',
        ),
      );

      await expectLater(publicHttpServer.bind(), throwsA(isA<StateError>()));
    },
  );

  test('shared token protects bridge endpoints', () async {
    final BridgeServer protectedServer = BridgeServer(
      config: const BridgeServerConfig(
        host: '127.0.0.1',
        port: 0,
        publicBaseUrl: 'http://127.0.0.1',
        connectorPath: '/mcp/claude',
        sharedToken: 'bridge-secret',
      ),
    );
    final HttpServer protectedHttpServer = await protectedServer.bind();
    addTearDown(() async {
      await protectedHttpServer.close(force: true);
    });

    final Uri protectedBaseUri = Uri.parse(
      'http://127.0.0.1:${protectedHttpServer.port}',
    );
    final HttpClient client = HttpClient();

    final HttpClientResponse unauthorized = await (await client.postUrl(
      protectedBaseUri.resolve('/mobile-bridge/session/start'),
    )).close();
    expect(unauthorized.statusCode, 401);

    final Map<String, dynamic> authorized = await _postJson(
      client,
      protectedBaseUri.resolve('/mobile-bridge/session/start'),
      <String, Object?>{'clientId': 'client-2'},
      token: 'bridge-secret',
    );
    expect(authorized['bridgeSessionId'], startsWith('bridge-session-'));
  });
}

Future<Map<String, dynamic>> _postJson(
  HttpClient client,
  Uri uri,
  Map<String, Object?> body, {
  String? token,
}) async {
  final HttpClientRequest request = await client.postUrl(uri);
  request.headers.contentType = ContentType.json;
  if (token case final String value when value.isNotEmpty) {
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $value');
  }
  request.write(jsonEncode(body));
  final HttpClientResponse response = await request.close();
  final String raw = await utf8.decoder.bind(response).join();
  expect(response.statusCode, inInclusiveRange(200, 299));
  return jsonDecode(raw) as Map<String, dynamic>;
}

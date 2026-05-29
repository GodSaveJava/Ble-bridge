import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_session.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_result.dart';
import 'package:toylink_ai/infrastructure/bridge/http_remote_bridge_service.dart';

void main() {
  group('HttpRemoteBridgeService', () {
    late HttpServer server;
    late List<_CapturedRequest> capturedRequests;

    setUp(() async {
      capturedRequests = <_CapturedRequest>[];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        String body;
        try {
          body = await utf8.decoder.bind(request).join();
        } on HttpException {
          return;
        }
        capturedRequests.add(
          _CapturedRequest(
            method: request.method,
            path: request.uri.path,
            authorization: request.headers.value(HttpHeaders.authorizationHeader),
            body: body,
          ),
        );

        if (request.method == 'POST' &&
            request.uri.path == '/mobile-bridge/session/start') {
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode(_sessionPayload(token: 'bridge_token_1')),
          );
          await request.response.close();
          return;
        }

        if (request.method == 'POST' &&
            request.uri.path == '/mobile-bridge/session/bridge-session-1/refresh') {
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode(_sessionPayload(token: 'bridge_token_2')),
          );
          await request.response.close();
          return;
        }

        if (request.method == 'POST' &&
            request.uri.path == '/mobile-bridge/session/bridge-session-1/stop') {
          request.response.statusCode = HttpStatus.noContent;
          await request.response.close();
          return;
        }

        if (request.method == 'POST' &&
            request.uri.path ==
                '/mobile-bridge/session/bridge-session-1/task-result') {
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode(<String, Object?>{'ok': true}));
          await request.response.close();
          return;
        }

        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('startSession bootstraps remote connector info from HTTP bridge', () async {
      final HttpRemoteBridgeService service = HttpRemoteBridgeService(
        baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
        clientId: 'test-client',
        clientToken: 'secret-token',
      );
      addTearDown(service.dispose);

      await service.startSession();

      expect(service.currentSession.status, RemoteBridgeSessionStatus.ready);
      expect(service.currentSession.bridgeSessionId, 'bridge-session-1');
      expect(
        service.currentSession.connectorInfo?.connectorUrl,
        'https://bridge.toylink.local/mcp/claude',
      );
      expect(
        capturedRequests.single.authorization,
        'Bearer secret-token',
      );
      final Map<String, dynamic> requestBody =
          jsonDecode(capturedRequests.single.body) as Map<String, dynamic>;
      expect(requestBody['clientId'], 'test-client');
    });

    test('refreshConnector rotates connector token via HTTP bridge', () async {
      final HttpRemoteBridgeService service = HttpRemoteBridgeService(
        baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
        clientId: 'test-client',
      );
      addTearDown(service.dispose);

      await service.startSession();
      final String? firstToken = service.currentSession.connectorInfo?.connectorToken;

      await service.refreshConnector();

      expect(service.currentSession.status, RemoteBridgeSessionStatus.ready);
      expect(
        service.currentSession.connectorInfo?.connectorToken,
        isNot(firstToken),
      );
      expect(capturedRequests.last.path, '/mobile-bridge/session/bridge-session-1/refresh');
    });

    test('refreshConnector without session returns bridge_session_missing error', () async {
      final HttpRemoteBridgeService service = HttpRemoteBridgeService(
        baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
        clientId: 'test-client',
      );
      addTearDown(service.dispose);

      await service.refreshConnector();

      expect(service.currentSession.status, RemoteBridgeSessionStatus.error);
      expect(service.currentSession.lastErrorCode, 'bridge_session_missing');
    });

    test('stopSession closes remote session and returns offline', () async {
      final HttpRemoteBridgeService service = HttpRemoteBridgeService(
        baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
        clientId: 'test-client',
      );
      addTearDown(service.dispose);

      await service.startSession();
      await service.stopSession();

      expect(service.currentSession.status, RemoteBridgeSessionStatus.offline);
      expect(capturedRequests.last.path, '/mobile-bridge/session/bridge-session-1/stop');
    });

    test('reportTaskResult posts execution outcome to remote bridge', () async {
      final HttpRemoteBridgeService service = HttpRemoteBridgeService(
        baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
        clientId: 'test-client',
      );
      addTearDown(service.dispose);

      await service.startSession();
      await service.reportTaskResult(
        const RemoteBridgeTaskResult(
          ok: true,
          requestId: 'bridge-task-1',
          tool: 'get_status',
          result: <String, dynamic>{'deviceId': 'mock-sosexy-001'},
        ),
      );

      expect(
        capturedRequests.last.path,
        '/mobile-bridge/session/bridge-session-1/task-result',
      );
      final Map<String, dynamic> requestBody =
          jsonDecode(capturedRequests.last.body) as Map<String, dynamic>;
      expect(requestBody['clientId'], 'test-client');
      expect(requestBody['requestId'], 'bridge-task-1');
      expect(requestBody['tool'], 'get_status');
      expect(requestBody['ok'], isTrue);
      expect(
        requestBody['result'],
        <String, dynamic>{'deviceId': 'mock-sosexy-001'},
      );
      expect(service.currentSession.lastErrorCode, isNull);
    });

    test('reportTaskResult without session returns bridge_session_missing error', () async {
      final HttpRemoteBridgeService service = HttpRemoteBridgeService(
        baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
        clientId: 'test-client',
      );
      addTearDown(service.dispose);

      await service.reportTaskResult(
        const RemoteBridgeTaskResult(
          ok: false,
          requestId: 'bridge-task-2',
          tool: 'stop_all',
          errorCode: 'bridge_dispatch_failed',
          errorMessage: 'dispatcher failed',
        ),
      );

      expect(service.currentSession.status, RemoteBridgeSessionStatus.error);
      expect(service.currentSession.lastErrorCode, 'bridge_session_missing');
    });

    test('startSession schedules keepalive refreshes automatically', () async {
      final HttpRemoteBridgeService service = HttpRemoteBridgeService(
        baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
        clientId: 'test-client',
        keepAliveInterval: const Duration(milliseconds: 20),
      );
      addTearDown(() async {
        service.dispose();
        await Future<void>.delayed(const Duration(milliseconds: 40));
      });

      await service.startSession();
      await Future<void>.delayed(const Duration(milliseconds: 70));

      final Iterable<_CapturedRequest> refreshRequests = capturedRequests.where(
        (_CapturedRequest request) =>
            request.path == '/mobile-bridge/session/bridge-session-1/refresh',
      );
      expect(refreshRequests, isNotEmpty);
      expect(service.currentSession.status, RemoteBridgeSessionStatus.ready);
    });

    test('keepalive failure moves session into bridge_keepalive_failed error', () async {
      var refreshShouldFail = false;
      await server.close(force: true);
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        String body;
        try {
          body = await utf8.decoder.bind(request).join();
        } on HttpException {
          return;
        }
        capturedRequests.add(
          _CapturedRequest(
            method: request.method,
            path: request.uri.path,
            authorization: request.headers.value(HttpHeaders.authorizationHeader),
            body: body,
          ),
        );

        if (request.method == 'POST' &&
            request.uri.path == '/mobile-bridge/session/start') {
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode(_sessionPayload(token: 'bridge_token_1')),
          );
          await request.response.close();
          refreshShouldFail = true;
          return;
        }

        if (request.method == 'POST' &&
            request.uri.path == '/mobile-bridge/session/bridge-session-1/refresh') {
          request.response.statusCode = refreshShouldFail
              ? HttpStatus.internalServerError
              : HttpStatus.ok;
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            refreshShouldFail
                ? jsonEncode(<String, Object?>{'error': 'keepalive failed'})
                : jsonEncode(_sessionPayload(token: 'bridge_token_2')),
          );
          await request.response.close();
          return;
        }

        if (request.method == 'POST' &&
            request.uri.path == '/mobile-bridge/session/bridge-session-1/stop') {
          request.response.statusCode = HttpStatus.noContent;
          await request.response.close();
          return;
        }

        if (request.method == 'POST' &&
            request.uri.path ==
                '/mobile-bridge/session/bridge-session-1/task-result') {
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode(<String, Object?>{'ok': true}));
          await request.response.close();
          return;
        }

        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });

      final HttpRemoteBridgeService service = HttpRemoteBridgeService(
        baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
        clientId: 'test-client',
        keepAliveInterval: const Duration(milliseconds: 20),
      );
      addTearDown(() async {
        service.dispose();
        await Future<void>.delayed(const Duration(milliseconds: 40));
      });

      await service.startSession();
      await Future<void>.delayed(const Duration(milliseconds: 70));

      expect(service.currentSession.status, RemoteBridgeSessionStatus.error);
      expect(service.currentSession.lastErrorCode, 'bridge_keepalive_failed');
    });
  });
}

Map<String, Object?> _sessionPayload({required String token}) {
  return <String, Object?>{
    'bridgeSessionId': 'bridge-session-1',
    'status': 'ready',
    'connectorUrl': 'https://bridge.toylink.local/mcp/claude',
    'connectorToken': token,
    'toolNames': <String>[
      'set_suck',
      'set_vibe',
      'set_ems',
      'set_all',
      'stop_all',
      'get_status',
    ],
  };
}

class _CapturedRequest {
  const _CapturedRequest({
    required this.method,
    required this.path,
    required this.authorization,
    required this.body,
  });

  final String method;
  final String path;
  final String? authorization;
  final String body;
}

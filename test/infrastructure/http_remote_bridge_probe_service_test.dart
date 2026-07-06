import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_config.dart';
import 'package:toylink_ai/infrastructure/bridge/http_remote_bridge_probe_service.dart';

void main() {
  group('HttpRemoteBridgeProbeService', () {
    late HttpServer server;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('returns success when bridge start returns connector info', () async {
      server.listen((HttpRequest request) async {
        if (request.uri.path == '/mobile-bridge/session/start') {
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode(<String, Object?>{
              'bridgeSessionId': 'bridge-session-1',
              'connectorUrl': 'https://bridge.toylink.local/mcp/claude',
              'connectorToken': 'token-a',
              'toolNames': <String>['set_suck', 'stop_all'],
            }),
          );
          await request.response.close();
          return;
        }
        if (request.uri.path == '/mobile-bridge/session/bridge-session-1/stop') {
          request.response.statusCode = HttpStatus.noContent;
          await request.response.close();
          return;
        }
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });

      final result = await HttpRemoteBridgeProbeService().probe(
        RemoteBridgeConfig(
          enabled: true,
          baseUrl: 'http://127.0.0.1:${server.port}',
          clientId: 'device-a',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.summary, contains('连接测试成功'));
      expect(result.detail, contains('当前工具数量：2'));
    });

    test('returns friendly failure when bridge is unreachable', () async {
      final result = await HttpRemoteBridgeProbeService().probe(
        const RemoteBridgeConfig(
          enabled: true,
          baseUrl: 'http://127.0.0.1:1',
          clientId: 'device-a',
        ),
      );

      expect(result.isSuccess, isFalse);
      expect(result.summary, contains('连接测试失败'));
    });
  });
}

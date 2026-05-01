import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/infrastructure/mcp/local_mcp_http_service.dart';
import 'package:toylink_ai/infrastructure/mock/mock_hardware_repository.dart';

void main() {
  group('LocalMcpHttpService', () {
    test('executes set_suck via HTTP tool endpoint', () async {
      final container = ProviderContainer(
        overrides: [
          hardwareRepositoryProvider.overrideWith(
            (_) => MockHardwareRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(mcpToolRouterProvider);
      final service = LocalMcpHttpService(
        toolRouter: router,
        host: '127.0.0.1',
        port: 8871,
      );
      addTearDown(service.stop);

      await service.start();

      final client = HttpClient();
      addTearDown(client.close);

      final request = await client.postUrl(
        Uri.parse('http://127.0.0.1:8871/mcp/tool'),
      );
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode(<String, Object?>{
          'name': 'set_suck',
          'arguments': <String, Object?>{'intensity': 25, 'mode': 1},
        }),
      );
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      final Map<String, dynamic> json =
          jsonDecode(body) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.ok);
      expect(json['ok'], true);
      expect((json['status'] as Map<String, dynamic>)['suckIntensity'], 25);
    });

    test('returns validation error for malformed payload', () async {
      final container = ProviderContainer(
        overrides: [
          hardwareRepositoryProvider.overrideWith(
            (_) => MockHardwareRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(mcpToolRouterProvider);
      final service = LocalMcpHttpService(
        toolRouter: router,
        host: '127.0.0.1',
        port: 8872,
      );
      addTearDown(service.stop);

      await service.start();

      final client = HttpClient();
      addTearDown(client.close);

      final request = await client.postUrl(
        Uri.parse('http://127.0.0.1:8872/mcp/tool'),
      );
      request.headers.contentType = ContentType.json;
      request.write('{ bad json');
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      final Map<String, dynamic> json =
          jsonDecode(body) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.badRequest);
      expect(json['ok'], false);
      expect(
        (json['error'] as Map<String, dynamic>)['code'],
        'validation_error',
      );
    });

    test('returns tool definitions from /mcp/tools', () async {
      final container = ProviderContainer(
        overrides: [
          hardwareRepositoryProvider.overrideWith(
            (_) => MockHardwareRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(mcpToolRouterProvider);
      final service = LocalMcpHttpService(
        toolRouter: router,
        host: '127.0.0.1',
        port: 8873,
      );
      addTearDown(service.stop);

      await service.start();

      final client = HttpClient();
      addTearDown(client.close);

      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:8873/mcp/tools'),
      );
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      final Map<String, dynamic> json =
          jsonDecode(body) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.ok);
      expect(json['ok'], true);
      expect((json['tools'] as List<dynamic>).length, 6);
    });

    test('supports call-style payload at /mcp/call', () async {
      final container = ProviderContainer(
        overrides: [
          hardwareRepositoryProvider.overrideWith(
            (_) => MockHardwareRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(mcpToolRouterProvider);
      final service = LocalMcpHttpService(
        toolRouter: router,
        host: '127.0.0.1',
        port: 8874,
      );
      addTearDown(service.stop);

      await service.start();

      final client = HttpClient();
      addTearDown(client.close);

      final request = await client.postUrl(
        Uri.parse('http://127.0.0.1:8874/mcp/call'),
      );
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode(<String, Object?>{
          'tool': 'set_vibe',
          'input': <String, Object?>{'intensity': 40, 'mode': 1},
        }),
      );
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      final Map<String, dynamic> json =
          jsonDecode(body) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.ok);
      expect(json['ok'], true);
      expect((json['status'] as Map<String, dynamic>)['vibeIntensity'], 40);
    });
  });
}

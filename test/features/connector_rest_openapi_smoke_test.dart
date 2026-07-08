import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/features/mcp_server/domain/connector_card_payload.dart';
import 'package:toylink_ai/features/mcp_server/domain/connector_platform_template.dart';
import 'package:toylink_ai/infrastructure/mcp/local_mcp_http_service.dart';

import 'connector_smoke_test_support.dart';

void main() {
  test(
    'OpenAPI REST tool template drives a real get_status HTTP call',
    () async {
      const int port = 8891;
      const String token = 'toy-connector-token';
      const ConnectorCardPayload card = ConnectorCardPayload(
        connectorUrl: 'http://127.0.0.1:$port/mcp/claude',
        authToken: token,
        tools: <String>['get_status', 'stop_all'],
      );
      final ConnectorPlatformTemplate template =
          buildConnectorPlatformTemplates(card).singleWhere(
            (ConnectorPlatformTemplate template) =>
                template.kind == ConnectorPlatformTemplateKind.openApiTool,
          );
      final Map<String, Object?> schema =
          (jsonDecode(template.content) as Map<String, dynamic>)
              .cast<String, Object?>();
      final Uri toolCallUri = _toolCallUriFromOpenApi(schema);
      final List<String> toolEnum = _toolEnumFromOpenApi(schema);

      expect(toolEnum, <String>['get_status', 'stop_all']);
      expect(toolEnum, isNot(contains('set_suck')));

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

      final HttpClient client = HttpClient();
      addTearDown(client.close);

      final HttpClientRequest request = await client.postUrl(toolCallUri);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.write(
        jsonEncode(<String, Object?>{
          'requestId': 'openapi-smoke-1',
          'tool': 'get_status',
          'input': <String, Object?>{},
        }),
      );

      final HttpClientResponse response = await request.close();
      final String body = await utf8.decodeStream(response);
      final Map<String, dynamic> json =
          jsonDecode(body) as Map<String, dynamic>;

      expect(response.statusCode, HttpStatus.ok);
      expect(json['ok'], isTrue);
      expect(json['requestId'], 'openapi-smoke-1');
      expect(json['tool'], 'get_status');
      expect((json['result'] as Map<String, dynamic>)['isConnected'], isTrue);
      expect((json['result'] as Map<String, dynamic>)['deviceId'], isNull);
    },
  );
}

Uri _toolCallUriFromOpenApi(Map<String, Object?> schema) {
  final List<dynamic> servers = schema['servers']! as List<dynamic>;
  final Map<String, dynamic> server = servers.single as Map<String, dynamic>;
  final Map<String, dynamic> paths = schema['paths']! as Map<String, dynamic>;
  final String path = paths.keys.single;
  return Uri.parse('${server['url']}$path');
}

List<String> _toolEnumFromOpenApi(Map<String, Object?> schema) {
  final Map<String, dynamic> paths = schema['paths']! as Map<String, dynamic>;
  final Map<String, dynamic> operation =
      (paths.values.single as Map<String, dynamic>)['post']
          as Map<String, dynamic>;
  final Map<String, dynamic> requestBody =
      operation['requestBody']! as Map<String, dynamic>;
  final Map<String, dynamic> content =
      requestBody['content']! as Map<String, dynamic>;
  final Map<String, dynamic> applicationJson =
      content['application/json']! as Map<String, dynamic>;
  final Map<String, dynamic> bodySchema =
      applicationJson['schema']! as Map<String, dynamic>;
  final Map<String, dynamic> properties =
      bodySchema['properties']! as Map<String, dynamic>;
  final Map<String, dynamic> tool = properties['tool']! as Map<String, dynamic>;
  return (tool['enum']! as List<dynamic>).cast<String>();
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/features/mcp_server/domain/connector_card_payload.dart';
import 'package:toylink_ai/features/mcp_server/domain/connector_platform_template.dart';

void main() {
  group('buildConnectorPlatformTemplates', () {
    const ConnectorCardPayload card = ConnectorCardPayload(
      connectorUrl: 'https://bridge.toylink.local/mcp/claude',
      authToken: 'toy-connector-token',
      tools: <String>['get_status', 'stop_all'],
    );

    test('builds the expected platform templates', () {
      final List<ConnectorPlatformTemplate> templates =
          buildConnectorPlatformTemplates(card);

      expect(
        templates.map((ConnectorPlatformTemplate template) => template.title),
        <String>[
          'Claude Remote MCP',
          'ChatGPT / GPT Actions',
          'OpenAPI / REST Tool',
          'Webhook',
        ],
      );
    });

    test('GPT Actions OpenAPI schema only advertises Safety V0 tools', () {
      final ConnectorPlatformTemplate gptTemplate =
          buildConnectorPlatformTemplates(card).singleWhere(
            (ConnectorPlatformTemplate template) =>
                template.kind ==
                ConnectorPlatformTemplateKind.gptActionsOpenApi,
          );

      final Map<String, Object?> schema =
          (jsonDecode(gptTemplate.content) as Map<String, dynamic>)
              .cast<String, Object?>();

      final paths = schema['paths']! as Map<String, dynamic>;
      final toolPath =
          paths['/mobile-bridge/tool-call']! as Map<String, dynamic>;
      final post = toolPath['post']! as Map<String, dynamic>;
      final requestBody = post['requestBody']! as Map<String, dynamic>;
      final content = requestBody['content']! as Map<String, dynamic>;
      final applicationJson =
          content['application/json']! as Map<String, dynamic>;
      final bodySchema = applicationJson['schema']! as Map<String, dynamic>;
      final properties = bodySchema['properties']! as Map<String, dynamic>;
      final tool = properties['tool']! as Map<String, dynamic>;

      expect(tool['enum'], <String>['get_status', 'stop_all']);
      expect(gptTemplate.content, contains('bearerAuth'));
      expect(gptTemplate.content, contains('disabledTools'));
    });

    test('webhook template includes bearer token and tool-call endpoint', () {
      final ConnectorPlatformTemplate webhookTemplate =
          buildConnectorPlatformTemplates(card).singleWhere(
            (ConnectorPlatformTemplate template) =>
                template.kind == ConnectorPlatformTemplateKind.webhook,
          );

      expect(
        webhookTemplate.content,
        contains('https://bridge.toylink.local/mobile-bridge/tool-call'),
      );
      expect(webhookTemplate.content, contains('Bearer toy-connector-token'));
      expect(webhookTemplate.content, contains('get_status'));
      expect(webhookTemplate.content, contains('stop_all'));
    });
  });
}

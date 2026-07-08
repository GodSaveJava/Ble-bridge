import 'dart:convert';

import 'connector_card_payload.dart';

enum ConnectorPlatformTemplateKind {
  claudeRemoteMcp,
  gptActionsOpenApi,
  openApiTool,
  webhook,
}

class ConnectorPlatformTemplate {
  const ConnectorPlatformTemplate({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.copyLabel,
    required this.content,
  });

  final ConnectorPlatformTemplateKind kind;
  final String title;
  final String subtitle;
  final String copyLabel;
  final String content;
}

List<ConnectorPlatformTemplate> buildConnectorPlatformTemplates(
  ConnectorCardPayload card,
) {
  return <ConnectorPlatformTemplate>[
    ConnectorPlatformTemplate(
      kind: ConnectorPlatformTemplateKind.claudeRemoteMcp,
      title: 'Claude Remote MCP',
      subtitle: '复制 connector 地址和 Bearer token，到 Claude 的 connector 配置中粘贴。',
      copyLabel: '复制 Claude 模板',
      content: _prettyJson(<String, Object?>{
        'platform': 'claude_remote_mcp',
        'connectorUrl': card.connectorUrl,
        'authentication': <String, Object?>{
          'type': 'bearer',
          'token': card.authToken,
        },
        'allowedTools': card.tools,
        'verificationPrompt':
            'After adding this connector, call get_status once to verify the connection.',
        'safety':
            'Safety V0 only allows get_status and stop_all. Do not call set_* tools.',
      }),
    ),
    ConnectorPlatformTemplate(
      kind: ConnectorPlatformTemplateKind.gptActionsOpenApi,
      title: 'ChatGPT / GPT Actions',
      subtitle: '复制 OpenAPI schema 到 GPT Action；认证使用 Bearer token。',
      copyLabel: '复制 GPT Actions schema',
      content: _prettyJson(_openApiSchema(card, title: 'ToyLink GPT Action')),
    ),
    ConnectorPlatformTemplate(
      kind: ConnectorPlatformTemplateKind.openApiTool,
      title: 'OpenAPI / REST Tool',
      subtitle: '给支持 OpenAPI 或 REST tool 的自建 Agent 使用。',
      copyLabel: '复制 OpenAPI 模板',
      content: _prettyJson(_openApiSchema(card, title: 'ToyLink REST Tool')),
    ),
    ConnectorPlatformTemplate(
      kind: ConnectorPlatformTemplateKind.webhook,
      title: 'Webhook',
      subtitle: '给只支持通用 webhook 的工具调用平台使用。',
      copyLabel: '复制 Webhook 模板',
      content: _prettyJson(<String, Object?>{
        'method': 'POST',
        'url': _toolCallUrl(card).toString(),
        'headers': <String, Object?>{
          'authorization': 'Bearer ${card.authToken}',
          'content-type': 'application/json',
        },
        'body': <String, Object?>{
          'requestId': '{{request_id}}',
          'tool': '{{get_status_or_stop_all}}',
          'input': <String, Object?>{},
        },
        'allowedTools': card.tools,
        'verificationPrompt':
            'Send {"tool":"get_status","input":{}} once and confirm ToyLink marks the connector as verified.',
        'safety':
            'Safety V0 only allows get_status and stop_all. Reject set_* tools.',
      }),
    ),
  ];
}

Map<String, Object?> _openApiSchema(
  ConnectorCardPayload card, {
  required String title,
}) {
  final Uri toolCallUrl = _toolCallUrl(card);
  return <String, Object?>{
    'openapi': '3.1.0',
    'info': <String, Object?>{
      'title': title,
      'version': '1.0.0',
      'description':
          'ToyLink Safety V0 connector. Only get_status and stop_all are enabled.',
    },
    'servers': <Object?>[
      <String, Object?>{'url': toolCallUrl.origin},
    ],
    'paths': <String, Object?>{
      toolCallUrl.path: <String, Object?>{
        'post': <String, Object?>{
          'operationId': 'callToyLinkSafetyTool',
          'summary': 'Call a ToyLink Safety V0 tool',
          'description':
              'Allowed tools are get_status and stop_all. set_* controls are not enabled in Phase 1.',
          'security': <Object?>[
            <String, Object?>{'bearerAuth': <Object?>[]},
          ],
          'requestBody': <String, Object?>{
            'required': true,
            'content': <String, Object?>{
              'application/json': <String, Object?>{
                'schema': <String, Object?>{
                  'type': 'object',
                  'required': <String>['tool'],
                  'properties': <String, Object?>{
                    'requestId': <String, Object?>{'type': 'string'},
                    'tool': <String, Object?>{
                      'type': 'string',
                      'enum': card.tools,
                    },
                    'input': <String, Object?>{
                      'type': 'object',
                      'additionalProperties': true,
                    },
                  },
                  'additionalProperties': false,
                },
              },
            },
          },
          'responses': <String, Object?>{
            '200': <String, Object?>{
              'description': 'Tool result returned by ToyLink.',
            },
            '400': <String, Object?>{
              'description': 'Validation or Safety V0 allowlist error.',
            },
          },
        },
      },
    },
    'components': <String, Object?>{
      'securitySchemes': <String, Object?>{
        'bearerAuth': <String, Object?>{
          'type': 'http',
          'scheme': 'bearer',
          'bearerFormat': 'ToyLink connector token',
        },
      },
    },
    'x-toylink': <String, Object?>{
      'phase': card.phase,
      'connectorUrl': card.connectorUrl,
      'token': card.authToken,
      'verificationTool': 'get_status',
      'disabledTools': <String>['set_suck', 'set_vibe', 'set_ems', 'set_all'],
    },
  };
}

Uri _toolCallUrl(ConnectorCardPayload card) {
  final Uri connectorUri = Uri.parse(card.connectorUrl);
  return Uri(
    scheme: connectorUri.scheme,
    userInfo: connectorUri.userInfo,
    host: connectorUri.host,
    port: connectorUri.hasPort ? connectorUri.port : null,
    path: '/mobile-bridge/tool-call',
  );
}

String _prettyJson(Map<String, Object?> value) {
  return const JsonEncoder.withIndent('  ').convert(value);
}

import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/features/mcp_server/domain/connector_card_payload.dart';

void main() {
  group('ConnectorCardPayload', () {
    test('round trips through ToyLink deep link', () {
      const ConnectorCardPayload card = ConnectorCardPayload(
        connectorUrl: 'https://bridge.toylink.local/mcp/claude',
        authToken: 'toy-connector-token',
        tools: <String>['get_status', 'stop_all'],
      );

      final Uri uri = Uri.parse(card.toDeepLink());
      final ConnectorCardPayload? parsed =
          ConnectorCardPayload.tryParseDeepLink(uri);

      expect(parsed, isNotNull);
      expect(parsed!.connectorUrl, card.connectorUrl);
      expect(parsed.authToken, card.authToken);
      expect(parsed.tools, card.tools);
      expect(parsed.isValid, isTrue);
    });

    test('rejects unsafe tools in imported payload', () {
      const ConnectorCardPayload card = ConnectorCardPayload(
        connectorUrl: 'https://bridge.toylink.local/mcp/claude',
        authToken: 'toy-connector-token',
        tools: <String>['get_status', 'stop_all', 'set_suck'],
      );

      final ConnectorCardPayload? parsed =
          ConnectorCardPayload.tryParseDeepLink(Uri.parse(card.toDeepLink()));

      expect(parsed, isNotNull);
      expect(parsed!.isValid, isFalse);
      expect(parsed.validationErrors, contains('连接卡片包含 Safety V0 以外的工具。'));
    });

    test('returns null for non connector uri', () {
      final ConnectorCardPayload? parsed =
          ConnectorCardPayload.tryParseDeepLink(
            Uri.parse('toylink://other/v1'),
          );

      expect(parsed, isNull);
    });
  });
}

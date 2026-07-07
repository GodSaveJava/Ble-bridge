import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/features/mcp_server/domain/connector_card_payload.dart';
import 'package:toylink_ai/features/mcp_server/presentation/pages/connector_card_import_page.dart';

void main() {
  testWidgets('connector card import page shows valid card preview', (
    WidgetTester tester,
  ) async {
    const ConnectorCardPayload card = ConnectorCardPayload(
      connectorUrl: 'https://bridge.toylink.local/mcp/claude',
      authToken: 'toy-connector-token',
      tools: <String>['get_status', 'stop_all'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ConnectorCardImportPage(uri: Uri.parse(card.toDeepLink())),
      ),
    );

    expect(find.text('连接卡片已识别'), findsOneWidget);
    expect(find.text('Safety V0'), findsOneWidget);
    expect(
      find.text('https://bridge.toylink.local/mcp/claude'),
      findsOneWidget,
    );
    expect(find.text('开放工具'), findsOneWidget);
    expect(find.text('get_status / stop_all'), findsOneWidget);
    expect(find.text('复制连接卡片'), findsOneWidget);
  });

  testWidgets('connector card import page blocks malformed link', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConnectorCardImportPage(
          uri: Uri.parse('toylink://connector-card/v1?payload=bad'),
        ),
      ),
    );

    expect(find.text('连接卡片无法导入'), findsOneWidget);
    expect(find.text('连接卡片链接缺少有效 payload。'), findsOneWidget);
  });
}

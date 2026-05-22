import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_config.dart';
import 'package:toylink_ai/domain/repositories/remote_bridge_config_repository.dart';
import 'package:toylink_ai/features/settings/presentation/pages/remote_bridge_config_page.dart';

void main() {
  testWidgets('remote bridge config page saves config and shows success', (
    WidgetTester tester,
  ) async {
    final _InMemoryRemoteBridgeConfigRepository repository =
        _InMemoryRemoteBridgeConfigRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remoteBridgeConfigRepositoryProvider.overrideWith((_) => repository),
        ],
        child: const MaterialApp(home: RemoteBridgeConfigPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Bridge 地址'),
      'https://bridge.example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '客户端 ID'),
      'device-a',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '客户端令牌'),
      'secret-token',
    );
    await tester.tap(find.text('保存配置'));
    await tester.pumpAndSettle();

    expect(find.text('远程桥接配置已保存。'), findsOneWidget);
    expect(repository.config.enabled, isTrue);
    expect(repository.config.baseUrl, 'https://bridge.example.com');
    expect(repository.config.clientToken, 'secret-token');
  });
}

class _InMemoryRemoteBridgeConfigRepository
    implements RemoteBridgeConfigRepository {
  RemoteBridgeConfig config = const RemoteBridgeConfig();

  @override
  Future<RemoteBridgeConfig> load() async => config;

  @override
  Future<void> reset() async {
    config = const RemoteBridgeConfig();
  }

  @override
  Future<void> save(RemoteBridgeConfig next) async {
    config = next;
  }
}

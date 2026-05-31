import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_session.dart';
import 'package:toylink_ai/features/mcp_server/presentation/controllers/remote_bridge_session_controller.dart';
import 'package:toylink_ai/features/settings/presentation/pages/settings_page.dart';
import 'package:toylink_ai/infrastructure/mock/mock_remote_bridge_service.dart';

void main() {
  testWidgets('settings page exposes bridge status and source actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remoteBridgeServiceProvider.overrideWith(
            (_) => MockRemoteBridgeService(),
          ),
          remoteBridgeSessionControllerProvider.overrideWith(
            _ReadyRemoteBridgeSessionController.new,
          ),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    expect(find.widgetWithText(SwitchListTile, '启用应用锁'), findsOneWidget);
    expect(
      find.widgetWithText(SwitchListTile, '自动拉取远程任务'),
      findsOneWidget,
    );
    expect(find.byType(OutlinedButton), findsOneWidget);
  });

  testWidgets('settings page disables auto consume when bridge is not ready', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remoteBridgeServiceProvider.overrideWith(
            (_) => MockRemoteBridgeService(),
          ),
          remoteBridgeSessionControllerProvider.overrideWith(
            _OfflineRemoteBridgeSessionController.new,
          ),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('自动拉取远程任务'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final SwitchListTile autoConsumeTile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, '自动拉取远程任务'),
    );

    expect(autoConsumeTile.onChanged, isNull);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });

  testWidgets('settings page updates auto consume preference', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remoteBridgeServiceProvider.overrideWith(
            (_) => MockRemoteBridgeService(),
          ),
          remoteBridgeSessionControllerProvider.overrideWith(
            _ReadyRemoteBridgeSessionController.new,
          ),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('自动拉取远程任务'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final Finder switchFinder = find.descendant(
      of: find.widgetWithText(SwitchListTile, '自动拉取远程任务'),
      matching: find.byType(Switch),
    );
    await tester.ensureVisible(switchFinder);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(switchFinder).value, isTrue);

    await tester.tap(switchFinder);
    await tester.pump();

    expect(tester.widget<Switch>(switchFinder).value, isFalse);
  });
}

class _ReadyRemoteBridgeSessionController
    extends RemoteBridgeSessionController {
  @override
  RemoteBridgeSessionState build() {
    return const RemoteBridgeSessionState(
      status: RemoteBridgeSessionStatus.ready,
      isAutoConsumeEnabled: true,
      taskFeedbackMessage: '已恢复自动拉取远程任务。',
    );
  }

  @override
  Future<void> setAutoConsumeEnabled(bool enabled) async {
    state = state.copyWith(isAutoConsumeEnabled: enabled);
  }
}

class _OfflineRemoteBridgeSessionController
    extends RemoteBridgeSessionController {
  @override
  RemoteBridgeSessionState build() {
    return const RemoteBridgeSessionState(
      status: RemoteBridgeSessionStatus.offline,
      isAutoConsumeEnabled: false,
    );
  }
}

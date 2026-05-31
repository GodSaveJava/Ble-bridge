import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/domain/entities/remote_bridge_session.dart';
import 'package:toylink_ai/features/mcp_server/presentation/controllers/remote_bridge_session_controller.dart';
import 'package:toylink_ai/features/settings/presentation/pages/settings_page.dart';

void main() {
  testWidgets('settings page shows auto consume preference and restore note', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remoteBridgeSessionControllerProvider.overrideWith(
            _FakeRemoteBridgeSessionController.new,
          ),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    expect(find.text('自动拉取远程任务'), findsOneWidget);
    expect(find.text('已恢复自动拉取远程任务。'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(SwitchListTile, '自动拉取远程任务'),
        matching: find.byType(Switch),
      ),
      findsOneWidget,
    );
  });

  testWidgets('settings page updates auto consume preference', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remoteBridgeSessionControllerProvider.overrideWith(
            _FakeRemoteBridgeSessionController.new,
          ),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(SwitchListTile, '自动拉取远程任务'),
        matching: find.byType(Switch),
      ),
    );
    await tester.pump();

    expect(find.text('已关闭自动拉取远程任务。'), findsOneWidget);
  });
}

class _FakeRemoteBridgeSessionController extends RemoteBridgeSessionController {
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
    state = state.copyWith(
      isAutoConsumeEnabled: enabled,
      taskFeedbackMessage: enabled ? '已开启自动拉取远程任务。' : '已关闭自动拉取远程任务。',
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/domain/entities/remote_bridge_session.dart';
import 'package:toylink_ai/features/mcp_server/presentation/controllers/remote_bridge_session_controller.dart';
import 'package:toylink_ai/features/settings/presentation/pages/settings_page.dart';

void main() {
  testWidgets('settings page shows bridge status and auto consume note', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remoteBridgeSessionControllerProvider.overrideWith(
            _ReadyRemoteBridgeSessionController.new,
          ),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    expect(find.text('当前 Bridge 状态'), findsOneWidget);
    expect(find.text('Bridge 已就绪，自动拉取会在安全节奏下运行。'), findsOneWidget);
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

  testWidgets('settings page disables auto consume when bridge is not ready', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remoteBridgeSessionControllerProvider.overrideWith(
            _OfflineRemoteBridgeSessionController.new,
          ),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    expect(
      find.text('当前 Bridge 还未就绪，先去 MCP 页或桥接配置页把连接准备好，再开启这里的自动拉取。'),
      findsOneWidget,
    );
    final Finder switchFinder = find.descendant(
      of: find.widgetWithText(SwitchListTile, '自动拉取远程任务'),
      matching: find.byType(Switch),
    );
    expect(tester.widget<Switch>(switchFinder).onChanged, isNull);
  });

  testWidgets('settings page updates auto consume preference', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remoteBridgeSessionControllerProvider.overrideWith(
            _ReadyRemoteBridgeSessionController.new,
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
    state = state.copyWith(
      isAutoConsumeEnabled: enabled,
      taskFeedbackMessage: enabled ? '已开启自动拉取远程任务。' : '已关闭自动拉取远程任务。',
    );
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

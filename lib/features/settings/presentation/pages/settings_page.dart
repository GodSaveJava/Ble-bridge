import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/app_lock_controller.dart';
import '../../../../domain/entities/remote_bridge_session.dart';
import '../../../mcp_server/presentation/controllers/remote_bridge_session_controller.dart';
import '../../../../shared/widgets/toylink_background.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLockState lockState = ref.watch(appLockControllerProvider);
    final RemoteBridgeSessionState bridgeState = ref.watch(
      remoteBridgeSessionControllerProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ToyLinkBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: SwitchListTile(
                title: const Text('启用应用锁'),
                subtitle: const Text('开启后，进入应用时需要先解锁。'),
                value: lockState.enabled,
                onChanged: (bool value) => ref
                    .read(appLockControllerProvider.notifier)
                    .setEnabled(value),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('立即锁定'),
                subtitle: const Text('用于测试锁屏和解锁流程。'),
                trailing: FilledButton.tonal(
                  onPressed: lockState.enabled
                      ? () => ref
                            .read(appLockControllerProvider.notifier)
                            .lockNow()
                      : null,
                  child: const Text('锁定'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('远程桥接配置'),
                subtitle: const Text(
                  '配置 Claude Remote MCP 使用的 Bridge 地址、客户端 ID 和令牌。',
                ),
                trailing: FilledButton.tonal(
                  onPressed: () => context.push('/settings/bridge'),
                  child: const Text('去配置'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('当前 Bridge 状态'),
                subtitle: Text(
                  bridgeState.status == RemoteBridgeSessionStatus.ready
                      ? 'Bridge 已就绪，自动拉取会在安全节奏下运行。'
                      : 'Bridge 还未就绪，先去 MCP 页面确认连接或回到桥接配置页测试连接。',
                ),
                trailing: FilledButton.tonal(
                  onPressed: () => context.push('/mcp'),
                  child: const Text('去 MCP 页'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                title: const Text('自动拉取远程任务'),
                subtitle: Text(
                  bridgeState.isAutoConsumeEnabled
                      ? '已开启。Bridge 就绪时会按安全节奏自动拉取白名单任务，并在重启后自动恢复。'
                      : '默认关闭。建议先在 MCP 页手动验证闭环，再在这里开启。',
                ),
                value: bridgeState.isAutoConsumeEnabled,
                onChanged: bridgeState.isBusy || bridgeState.isConsumingTask
                    ? null
                    : (bool enabled) => ref
                          .read(remoteBridgeSessionControllerProvider.notifier)
                          .setAutoConsumeEnabled(enabled),
              ),
            ),
            if (bridgeState.taskFeedbackMessage != null) ...<Widget>[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: const Text('自动拉取状态'),
                  subtitle: Text(bridgeState.taskFeedbackMessage!),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                title: Text('安全提醒'),
                subtitle: Text('微电流建议上限默认为 8，超过时会触发额外确认。'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

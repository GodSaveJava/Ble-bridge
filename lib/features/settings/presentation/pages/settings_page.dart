import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../../core/security/app_lock_controller.dart';
import '../../../../domain/entities/remote_bridge_session.dart';
import '../../../../domain/services/remote_bridge_service.dart';
import '../../../../shared/widgets/bridge_diagnostics_banner.dart';
import '../../../../shared/widgets/toylink_background.dart';
import '../../../mcp_server/presentation/controllers/remote_bridge_diagnostics_controller.dart';
import '../../../mcp_server/presentation/controllers/remote_bridge_session_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLockState lockState = ref.watch(appLockControllerProvider);
    final RemoteBridgeSessionState bridgeState = ref.watch(
      remoteBridgeSessionControllerProvider,
    );
    final Object remoteBridgeService = ref.watch(remoteBridgeServiceProvider);
    final RemoteBridgeRuntimeSource bridgeSource =
        remoteBridgeService is RemoteBridgeServiceDiagnostics
        ? remoteBridgeService.runtimeSource
        : RemoteBridgeRuntimeSource.unknown;
    final RemoteBridgeDiagnostics bridgeDiagnostics = ref.watch(
      remoteBridgeDiagnosticsProvider,
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
                      : 'Bridge 还未就绪，先去 MCP 页或桥接配置页把连接准备好，再开启自动拉取。',
                ),
                trailing: FilledButton.tonal(
                  onPressed: () => context.push('/mcp'),
                  child: const Text('去 MCP 页'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      '桥接诊断',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    BridgeDiagnosticsBanner(
                      diagnostics: bridgeDiagnostics,
                      onActionPressed: () => handleRemoteBridgeDiagnosticsAction(
                        context: context,
                        diagnostics: bridgeDiagnostics,
                        onRestartBridgeSession: () => ref
                            .read(
                              remoteBridgeSessionControllerProvider.notifier,
                            )
                            .startSession(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('当前 Bridge 来源'),
                subtitle: Text(_bridgeSourceDescription(bridgeSource)),
                trailing: Text(_bridgeSourceLabel(bridgeSource)),
              ),
            ),
            if (bridgeSource == RemoteBridgeRuntimeSource.savedConfig &&
                bridgeState.status !=
                    RemoteBridgeSessionStatus.ready) ...<Widget>[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    OutlinedButton(
                      onPressed: () => context.push('/mcp'),
                      child: const Text('去 MCP 页'),
                    ),
                    OutlinedButton(
                      onPressed: () => context.push('/settings/bridge'),
                      child: const Text('去桥接配置'),
                    ),
                  ],
                ),
              ),
            ] else if (bridgeSource == RemoteBridgeRuntimeSource.mock ||
                bridgeSource == RemoteBridgeRuntimeSource.unknown) ...<Widget>[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () => context.push('/settings/bridge'),
                  child: const Text('去桥接配置'),
                ),
              ),
            ] else if (bridgeState.status ==
                RemoteBridgeSessionStatus.ready) ...<Widget>[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () => context.push('/mcp'),
                  child: const Text('去 MCP 页'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                title: const Text('自动拉取远程任务'),
                subtitle: Text(
                  bridgeState.isAutoConsumeEnabled
                      ? '已开启。Bridge 就绪时会按安全节奏自动拉取白名单任务，并在重启后自动恢复。'
                      : bridgeState.status == RemoteBridgeSessionStatus.ready
                      ? '默认关闭。建议先在 MCP 页手动验证闭环，再在这里开启。'
                      : '当前 Bridge 还未就绪，先去 MCP 页或桥接配置页把连接准备好，再开启这里的自动拉取。',
                ),
                value: bridgeState.isAutoConsumeEnabled,
                onChanged:
                    bridgeState.isBusy ||
                        bridgeState.isConsumingTask ||
                        (bridgeState.status !=
                                RemoteBridgeSessionStatus.ready &&
                            !bridgeState.isAutoConsumeEnabled)
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

String _bridgeSourceLabel(RemoteBridgeRuntimeSource source) {
  return switch (source) {
    RemoteBridgeRuntimeSource.mock => '来源：本地 mock',
    RemoteBridgeRuntimeSource.dartDefine => '来源：dart-define',
    RemoteBridgeRuntimeSource.savedConfig => '来源：真实 Bridge',
    RemoteBridgeRuntimeSource.unknown => '来源：未知',
  };
}

String _bridgeSourceDescription(RemoteBridgeRuntimeSource source) {
  return switch (source) {
    RemoteBridgeRuntimeSource.mock => '当前仍在使用本地 mock 桥接，只适合开发和演示。',
    RemoteBridgeRuntimeSource.dartDefine => '当前通过启动参数注入真实 Bridge，适合开发阶段手动联调。',
    RemoteBridgeRuntimeSource.savedConfig => '当前优先使用你在设置页保存的真实 Bridge 配置。',
    RemoteBridgeRuntimeSource.unknown => '当前桥接来源无法识别，请检查运行配置。',
  };
}

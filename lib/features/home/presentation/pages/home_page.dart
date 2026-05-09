import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../../shared/widgets/toylink_background.dart';
import '../../../mcp_server/presentation/controllers/mcp_service_controller.dart';
import '../controllers/foreground_service_controller.dart';
import '../controllers/quick_start_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeStatus = ref.watch(activeDeviceStatusStreamProvider);
    final mcpState = ref.watch(mcpServiceControllerProvider);
    final quickStart = ref.watch(quickStartControllerProvider);
    final fgState = ref.watch(foregroundServiceControllerProvider);

    final String deviceSubtitle = activeStatus.maybeWhen(
      data: (status) =>
          status.isConnected ? '已连接：${status.deviceId}' : '当前没有已连接设备',
      orElse: () => '当前没有已连接设备',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('ToyLink AI')),
      body: ToyLinkBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: ListTile(
                title: const Text('设备状态'),
                subtitle: Text(deviceSubtitle),
                trailing: FilledButton(
                  onPressed: () => context.push('/scan'),
                  child: Text(deviceSubtitle.startsWith('已连接') ? '管理' : '连接'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('MCP 服务'),
                subtitle: Text(
                  mcpState.isRunning
                      ? '运行中：${mcpState.endpointInfo?.host}:${mcpState.endpointInfo?.port}'
                      : '未启动',
                ),
                trailing: FilledButton.tonal(
                  onPressed: () => context.push('/mcp'),
                  child: const Text('打开'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      '后台保活',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text('状态：${fgState.isRunning ? '运行中' : '未运行'}'),
                    if (fgState.lastRefreshedAt != null)
                      Text(
                        '最近刷新：${fgState.lastRefreshedAt!.hour.toString().padLeft(2, '0')}:${fgState.lastRefreshedAt!.minute.toString().padLeft(2, '0')}:${fgState.lastRefreshedAt!.second.toString().padLeft(2, '0')}',
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        FilledButton.tonal(
                          onPressed: fgState.isBusy
                              ? null
                              : () => ref
                                    .read(
                                      foregroundServiceControllerProvider
                                          .notifier,
                                    )
                                    .refresh(),
                          child: const Text('刷新状态'),
                        ),
                        OutlinedButton(
                          onPressed: fgState.isBusy || !fgState.isRunning
                              ? null
                              : () => ref
                                    .read(
                                      foregroundServiceControllerProvider
                                          .notifier,
                                    )
                                    .stop(),
                          child: const Text('停止保活'),
                        ),
                      ],
                    ),
                    if (fgState.errorMessage != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        fgState.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      '一键启动',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text('自动完成：扫描设备 → 连接设备 → 启动后台保活 → 启动 MCP'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: quickStart.isRunning
                          ? null
                          : () async {
                              final bool ok = await ref
                                  .read(quickStartControllerProvider.notifier)
                                  .runQuickStart();
                              if (!ok || !context.mounted) {
                                return;
                              }
                              await ref
                                  .read(
                                    foregroundServiceControllerProvider
                                        .notifier,
                                  )
                                  .refresh();
                              if (!context.mounted) {
                                return;
                              }
                              context.go('/control');
                            },
                      child: Text(quickStart.isRunning ? '启动中...' : '开始一键启动'),
                    ),
                    if (quickStart.errorMessage != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        quickStart.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _QuickNavButton(
                  label: '扫描连接',
                  onTap: () => context.push('/scan'),
                ),
                _QuickNavButton(
                  label: '手动控制',
                  onTap: () => context.push('/control'),
                ),
                _QuickNavButton(
                  label: '设备管理',
                  onTap: () => context.push('/device-manager'),
                ),
                _QuickNavButton(
                  label: '聊天',
                  onTap: () => context.push('/chat'),
                ),
                _QuickNavButton(
                  label: '设置',
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickNavButton extends StatelessWidget {
  const _QuickNavButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      child: OutlinedButton(onPressed: onTap, child: Text(label)),
    );
  }
}

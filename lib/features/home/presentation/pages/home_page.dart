import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../mcp_server/presentation/controllers/mcp_service_controller.dart';
import '../controllers/quick_start_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeStatus = ref.watch(activeDeviceStatusStreamProvider);
    final mcpState = ref.watch(mcpServiceControllerProvider);
    final quickStart = ref.watch(quickStartControllerProvider);

    final deviceSubtitle = activeStatus.maybeWhen(
      data: (status) =>
          status.isConnected ? '已连接：${status.deviceId}' : '当前没有已连接设备',
      orElse: () => '当前没有已连接设备',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('ToyLink AI')),
      body: ListView(
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
                    '一键启动',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text('自动完成：扫描设备 → 连接设备 → 启动 MCP 服务'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: quickStart.isRunning
                        ? null
                        : () async {
                            final bool ok = await ref
                                .read(quickStartControllerProvider.notifier)
                                .runQuickStart();
                            if (ok && context.mounted) {
                              context.go('/control');
                            }
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
              _QuickNavButton(label: '聊天', onTap: () => context.push('/chat')),
              _QuickNavButton(
                label: '设置',
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ],
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

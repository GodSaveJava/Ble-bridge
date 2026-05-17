import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../application/models/active_device_adapter_readiness.dart';
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
    final readinessAsync = ref.watch(activeDeviceAdapterReadinessProvider);
    final mcpState = ref.watch(mcpServiceControllerProvider);
    final quickStart = ref.watch(quickStartControllerProvider);
    final fgState = ref.watch(foregroundServiceControllerProvider);

    final String deviceSubtitle = activeStatus.maybeWhen(
      data: (status) =>
          status.isConnected ? '已连接设备：${status.deviceId}' : '当前没有已连接设备',
      orElse: () => '当前没有已连接设备',
    );

    final String readinessTitle = readinessAsync.maybeWhen(
      data: (readiness) => _homeReadinessTitle(readiness, mcpState.isRunning),
      orElse: () => 'AI 控制状态读取中',
    );
    final String readinessSubtitle = readinessAsync.maybeWhen(
      data: (readiness) =>
          _homeReadinessSubtitle(readiness, mcpState.isRunning),
      orElse: () => '正在同步当前设备、适配器和验证状态。',
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
                  child: Text(deviceSubtitle.startsWith('已连接设备') ? '管理' : '连接'),
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
                      'MCP 服务',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mcpState.isRunning
                          ? '运行中：${mcpState.endpointInfo?.host}:${mcpState.endpointInfo?.port}'
                          : '未启动',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      readinessTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(readinessSubtitle),
                    if (readinessAsync.hasError) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        '适配器状态读取失败，请进入设备管理页检查本地数据。',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        FilledButton.tonal(
                          onPressed: () => context.push('/mcp'),
                          child: const Text('打开 MCP'),
                        ),
                        OutlinedButton(
                          onPressed: () => context.push('/device-manager'),
                          child: const Text('查看适配器状态'),
                        ),
                      ],
                    ),
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
                      '后台保活',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text('状态：${fgState.isRunning ? '运行中' : '未运行'}'),
                    if (fgState.lastRefreshedAt != null)
                      Text(
                        '最近刷新：${fgState.lastRefreshedAt!.hour.toString().padLeft(2, '0')}:${fgState.lastRefreshedAt!.minute.toString().padLeft(2, '0')}:${fgState.lastRefreshedAt!.second.toString().padLeft(2, '0')}',
                      ),
                    const SizedBox(height: 8),
                    const Text('如果切到后台后连接容易断开，请在系统设置中关闭电池优化并允许自启动。'),
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
                        OutlinedButton(
                          onPressed: () async {
                            await openAppSettings();
                          },
                          child: const Text('去系统设置'),
                        ),
                        OutlinedButton(
                          onPressed: () =>
                              context.push('/background-checklist'),
                          child: const Text('验收清单'),
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
                    const Text('自动完成：扫描设备 -> 连接设备 -> 启动后台保活 -> 启动 MCP'),
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
                              context.push(
                                '/control?returnTo=%2Fhome&returnLabel=%E8%BF%94%E5%9B%9E%E9%A6%96%E9%A1%B5',
                              );
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
                  onTap: () => context.push(
                    '/control?returnTo=%2Fhome&returnLabel=%E8%BF%94%E5%9B%9E%E9%A6%96%E9%A1%B5',
                  ),
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

String _homeReadinessTitle(
  ActiveDeviceAdapterReadiness readiness,
  bool mcpRunning,
) {
  switch (readiness.state) {
    case ActiveDeviceAdapterReadinessState.noDevice:
      return 'AI 控制未就绪';
    case ActiveDeviceAdapterReadinessState.noBinding:
      return '当前设备还没有绑定适配器';
    case ActiveDeviceAdapterReadinessState.bindingMissing:
      return '当前设备绑定的适配器已缺失';
    case ActiveDeviceAdapterReadinessState.unverified:
      return '当前适配器尚未验证';
    case ActiveDeviceAdapterReadinessState.verified:
      return mcpRunning ? 'AI 控制已就绪' : '适配器已验证，等待启动 MCP';
    case ActiveDeviceAdapterReadinessState.revoked:
      return '当前适配器验证已撤销';
    case ActiveDeviceAdapterReadinessState.needsReverify:
      return '当前适配器需要重新验证';
    case ActiveDeviceAdapterReadinessState.verificationFailed:
      return '当前适配器验证未通过';
  }
}

String _homeReadinessSubtitle(
  ActiveDeviceAdapterReadiness readiness,
  bool mcpRunning,
) {
  final String adapterName =
      readiness.adapterDisplayName ?? readiness.adapterId ?? '未指定适配器';
  switch (readiness.state) {
    case ActiveDeviceAdapterReadinessState.noDevice:
      return '请先连接设备，再绑定并验证适配器。';
    case ActiveDeviceAdapterReadinessState.noBinding:
      return '请到设备管理页为当前设备指定一份适配器，然后再进行验证。';
    case ActiveDeviceAdapterReadinessState.bindingMissing:
      return '当前设备绑定的是 $adapterName，但这份适配器本地已不存在，请重新选择。';
    case ActiveDeviceAdapterReadinessState.unverified:
      return '$adapterName 已绑定到当前设备，但还没有完成本机验证。';
    case ActiveDeviceAdapterReadinessState.verified:
      return mcpRunning
          ? '$adapterName 已验证通过，AI 可以开始通过 MCP 控制设备。'
          : '$adapterName 已验证通过，启动 MCP 后就可以让 AI 控制设备。';
    case ActiveDeviceAdapterReadinessState.revoked:
      return '$adapterName 的本机验证已被撤销，AI 控制会被拦截。';
    case ActiveDeviceAdapterReadinessState.needsReverify:
      return '$adapterName 因规则变化需要重新验证，重新通过前 AI 控制会被拦截。';
    case ActiveDeviceAdapterReadinessState.verificationFailed:
      return '$adapterName 上次验证未通过，请重新走低强度验证流程。';
  }
}

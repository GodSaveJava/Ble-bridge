import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../application/models/active_device_adapter_readiness.dart';
import '../../../../application/providers/application_providers.dart';
import '../../../../shared/widgets/premium_bouncing_wrapper.dart';
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
    final List<_HomeAction> readinessActions = readinessAsync.maybeWhen(
      data: (readiness) => _buildHomeActions(
        readiness: readiness,
        mcpRunning: mcpState.isRunning,
      ),
      orElse: () => const <_HomeAction>[],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ToyLink AI',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      body: ToyLinkBackground(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ), // Premium spacious padding
          children: <Widget>[
            // DEVICE STATUS CARD
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '设备状态',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            deviceSubtitle,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => context.push('/scan'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                      child: Text(
                        deviceSubtitle.startsWith('已连接设备') ? '管理' : '连接',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // MCP SERVICE CARD
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'MCP 桥接服务',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: mcpState.isRunning
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        mcpState.isRunning
                            ? '运行中：${mcpState.endpointInfo?.host}:${mcpState.endpointInfo?.port}'
                            : '未启动',
                        style: TextStyle(
                          color: mcpState.isRunning
                              ? Colors.green[700]
                              : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      readinessTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      readinessSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (readinessAsync.hasError) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        '适配器状态读取失败，请进入设备管理页检查本地数据。',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        FilledButton.tonal(
                          onPressed: () => context.push('/mcp'),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('打开 MCP'),
                        ),
                        OutlinedButton(
                          onPressed: () => context.push('/device-manager'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('适配器状态'),
                        ),
                        for (final _HomeAction action in readinessActions)
                          action.isPrimary
                              ? FilledButton(
                                  onPressed: () => context.push(action.route),
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(action.label),
                                )
                              : OutlinedButton(
                                  onPressed: () => context.push(action.route),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(action.label),
                                ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // BACKGROUND SERVICE CARD
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '后台保活',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '状态：${fgState.isRunning ? '运行中' : '未运行'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (fgState.lastRefreshedAt != null)
                      Text(
                        '最近刷新：${fgState.lastRefreshedAt!.hour.toString().padLeft(2, '0')}:${fgState.lastRefreshedAt!.minute.toString().padLeft(2, '0')}:${fgState.lastRefreshedAt!.second.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 12),
                    Text(
                      '如果切到后台后连接容易断开，请在系统设置中关闭电池优化并允许自启动。',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
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
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('停止保活'),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            await openAppSettings();
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('去系统设置'),
                        ),
                        OutlinedButton(
                          onPressed: () =>
                              context.push('/background-checklist'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('验收清单'),
                        ),
                      ],
                    ),
                    if (fgState.errorMessage != null) ...<Widget>[
                      const SizedBox(height: 12),
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
            const SizedBox(height: 20),

            // QUICK START CARD
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '一键启动',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '自动完成：扫描设备 -> 连接设备 -> 启动后台保活 -> 启动 MCP',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
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
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          quickStart.isRunning ? '启动中...' : '开始一键启动',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (quickStart.errorMessage != null) ...<Widget>[
                      const SizedBox(height: 12),
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
            const SizedBox(height: 32),

            // QUICK NAV
            Text(
              '快速导航',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _QuickNavButton(
                  label: '扫描连接',
                  icon: Icons.bluetooth_searching,
                  onTap: () => context.push('/scan'),
                ),
                _QuickNavButton(
                  label: '手动控制',
                  icon: Icons.gamepad,
                  onTap: () => context.push(
                    '/control?returnTo=%2Fhome&returnLabel=%E8%BF%94%E5%9B%9E%E9%A6%96%E9%A1%B5',
                  ),
                ),
                _QuickNavButton(
                  label: '设备管理',
                  icon: Icons.settings_input_component,
                  onTap: () => context.push('/device-manager'),
                ),
                _QuickNavButton(
                  label: '聊天',
                  icon: Icons.chat_bubble_outline,
                  onTap: () => context.push('/chat'),
                ),
                _QuickNavButton(
                  label: '设置',
                  icon: Icons.settings,
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
            const SizedBox(
              height: 80,
            ), // Extra space for the floating emergency stop bar
          ],
        ),
      ),
    );
  }
}

class _QuickNavButton extends StatelessWidget {
  const _QuickNavButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 40 - 12) / 2, // 2 columns
      child: PremiumBouncingWrapper(
        onTap: onTap,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
          ),
        ),
      ),
    );
  }
}

class _HomeAction {
  const _HomeAction({
    required this.label,
    required this.route,
    this.isPrimary = false,
  });

  final String label;
  final String route;
  final bool isPrimary;
}

List<_HomeAction> _buildHomeActions({
  required ActiveDeviceAdapterReadiness readiness,
  required bool mcpRunning,
}) {
  final String? adapterId = readiness.adapterId;
  switch (readiness.state) {
    case ActiveDeviceAdapterReadinessState.noDevice:
      return const <_HomeAction>[
        _HomeAction(label: '去连接设备', route: '/scan', isPrimary: true),
      ];
    case ActiveDeviceAdapterReadinessState.noBinding:
      return const <_HomeAction>[
        _HomeAction(label: '去绑定适配器', route: '/device-manager', isPrimary: true),
      ];
    case ActiveDeviceAdapterReadinessState.bindingMissing:
      return const <_HomeAction>[
        _HomeAction(
          label: '去重新选择适配器',
          route: '/device-manager',
          isPrimary: true,
        ),
      ];
    case ActiveDeviceAdapterReadinessState.unverified:
      return <_HomeAction>[
        if (adapterId != null && adapterId.isNotEmpty)
          _HomeAction(
            label: '去开始验证',
            route: '/verification/$adapterId',
            isPrimary: true,
          )
        else
          const _HomeAction(
            label: '去设备管理',
            route: '/device-manager',
            isPrimary: true,
          ),
      ];
    case ActiveDeviceAdapterReadinessState.verified:
      if (mcpRunning) {
        return const <_HomeAction>[
          _HomeAction(
            label: '进入手动控制',
            route:
                '/control?returnTo=%2Fhome&returnLabel=%E8%BF%94%E5%9B%9E%E9%A6%96%E9%A1%B5',
            isPrimary: true,
          ),
        ];
      }
      return const <_HomeAction>[
        _HomeAction(label: '去启动 MCP', route: '/mcp', isPrimary: true),
      ];
    case ActiveDeviceAdapterReadinessState.revoked:
    case ActiveDeviceAdapterReadinessState.needsReverify:
    case ActiveDeviceAdapterReadinessState.verificationFailed:
      return <_HomeAction>[
        if (adapterId != null && adapterId.isNotEmpty)
          _HomeAction(
            label: '去重新验证',
            route: '/verification/$adapterId',
            isPrimary: true,
          )
        else
          const _HomeAction(
            label: '去设备管理',
            route: '/device-manager',
            isPrimary: true,
          ),
      ];
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../application/models/active_device_adapter_readiness.dart';
import '../../../../application/providers/application_providers.dart';
import '../../../../shared/widgets/toylink_background.dart';
import '../controllers/mcp_service_controller.dart';

class McpPage extends ConsumerWidget {
  const McpPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mcpServiceControllerProvider);
    final readinessAsync = ref.watch(activeDeviceAdapterReadinessProvider);

    final String controlTitle = readinessAsync.maybeWhen(
      data: (readiness) => _mcpControlTitle(readiness, state.isRunning),
      orElse: () => '正在读取控制资格',
    );
    final String controlSubtitle = readinessAsync.maybeWhen(
      data: (readiness) => _mcpControlSubtitle(readiness, state.isRunning),
      orElse: () => '正在同步当前设备与适配器验证状态。',
    );
    final List<_McpAction> controlActions = readinessAsync.maybeWhen(
      data: (readiness) =>
          _buildMcpActions(readiness: readiness, mcpRunning: state.isRunning),
      orElse: () => const <_McpAction>[],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('MCP 服务')),
      body: ToyLinkBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      state.isRunning ? '状态：运行中' : '状态：未启动',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.endpointInfo == null
                          ? '地址：-'
                          : '地址：http://${state.endpointInfo!.host}:${state.endpointInfo!.port}${state.endpointInfo!.path}',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        FilledButton(
                          onPressed: state.isBusy || state.isRunning
                              ? null
                              : () => ref
                                    .read(mcpServiceControllerProvider.notifier)
                                    .start(),
                          child: const Text('启动'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: state.isBusy || !state.isRunning
                              ? null
                              : () => ref
                                    .read(mcpServiceControllerProvider.notifier)
                                    .stop(),
                          child: const Text('停止'),
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
                      '当前控制资格',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controlTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(controlSubtitle),
                    if (readinessAsync.hasError) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        '适配器状态读取失败，请进入设备管理页检查适配器和验证记录。',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (controlActions.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          for (final _McpAction action in controlActions)
                            action.isPrimary
                                ? FilledButton(
                                    onPressed: () => context.push(action.route),
                                    child: Text(action.label),
                                  )
                                : OutlinedButton(
                                    onPressed: () => context.push(action.route),
                                    child: Text(action.label),
                                  ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (state.errorMessage != null) ...<Widget>[
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: ListTile(
                  title: Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () => ref
                        .read(mcpServiceControllerProvider.notifier)
                        .clearError(),
                    child: const Text('关闭'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _McpAction {
  const _McpAction({
    required this.label,
    required this.route,
    this.isPrimary = false,
  });

  final String label;
  final String route;
  final bool isPrimary;
}

List<_McpAction> _buildMcpActions({
  required ActiveDeviceAdapterReadiness readiness,
  required bool mcpRunning,
}) {
  final String? adapterId = readiness.adapterId;
  switch (readiness.state) {
    case ActiveDeviceAdapterReadinessState.noDevice:
      return const <_McpAction>[
        _McpAction(label: '去连接设备', route: '/scan', isPrimary: true),
      ];
    case ActiveDeviceAdapterReadinessState.noBinding:
      return const <_McpAction>[
        _McpAction(label: '去绑定适配器', route: '/device-manager', isPrimary: true),
      ];
    case ActiveDeviceAdapterReadinessState.bindingMissing:
      return const <_McpAction>[
        _McpAction(
          label: '去重新选择适配器',
          route: '/device-manager',
          isPrimary: true,
        ),
      ];
    case ActiveDeviceAdapterReadinessState.unverified:
      return <_McpAction>[
        if (adapterId != null && adapterId.isNotEmpty)
          _McpAction(
            label: '去开始验证',
            route: '/verification/$adapterId',
            isPrimary: true,
          )
        else
          const _McpAction(
            label: '去设备管理',
            route: '/device-manager',
            isPrimary: true,
          ),
      ];
    case ActiveDeviceAdapterReadinessState.verified:
      if (mcpRunning) {
        return const <_McpAction>[
          _McpAction(
            label: '进入手动控制',
            route:
                '/control?returnTo=%2Fmcp&returnLabel=%E8%BF%94%E5%9B%9E%20MCP',
            isPrimary: true,
          ),
        ];
      }
      return const <_McpAction>[];
    case ActiveDeviceAdapterReadinessState.revoked:
    case ActiveDeviceAdapterReadinessState.needsReverify:
    case ActiveDeviceAdapterReadinessState.verificationFailed:
      return <_McpAction>[
        if (adapterId != null && adapterId.isNotEmpty)
          _McpAction(
            label: '去重新验证',
            route: '/verification/$adapterId',
            isPrimary: true,
          )
        else
          const _McpAction(
            label: '去设备管理',
            route: '/device-manager',
            isPrimary: true,
          ),
      ];
  }
}

String _mcpControlTitle(
  ActiveDeviceAdapterReadiness readiness,
  bool mcpRunning,
) {
  switch (readiness.state) {
    case ActiveDeviceAdapterReadinessState.noDevice:
      return '当前没有可供 MCP 控制的设备';
    case ActiveDeviceAdapterReadinessState.noBinding:
      return '当前设备还没有绑定适配器';
    case ActiveDeviceAdapterReadinessState.bindingMissing:
      return '当前设备绑定的适配器已缺失';
    case ActiveDeviceAdapterReadinessState.unverified:
      return '当前适配器尚未验证';
    case ActiveDeviceAdapterReadinessState.verified:
      return mcpRunning ? 'MCP 可控制当前设备' : '控制资格已满足，等待启动 MCP';
    case ActiveDeviceAdapterReadinessState.revoked:
      return '当前适配器验证已撤销';
    case ActiveDeviceAdapterReadinessState.needsReverify:
      return '当前适配器需要重新验证';
    case ActiveDeviceAdapterReadinessState.verificationFailed:
      return '当前适配器验证未通过';
  }
}

String _mcpControlSubtitle(
  ActiveDeviceAdapterReadiness readiness,
  bool mcpRunning,
) {
  final String adapterName =
      readiness.adapterDisplayName ?? readiness.adapterId ?? '未指定适配器';
  switch (readiness.state) {
    case ActiveDeviceAdapterReadinessState.noDevice:
      return '请先连接设备，再启动 MCP 服务。';
    case ActiveDeviceAdapterReadinessState.noBinding:
      return '请先在设备管理页把当前设备绑定到一份适配器。';
    case ActiveDeviceAdapterReadinessState.bindingMissing:
      return '当前绑定的 $adapterName 已从本地适配器列表中移除，请重新选择。';
    case ActiveDeviceAdapterReadinessState.unverified:
      return '$adapterName 还没有在当前设备上完成验证，MCP 控制请求会被拦截。';
    case ActiveDeviceAdapterReadinessState.verified:
      return mcpRunning
          ? '$adapterName 已验证通过，Claude 或其他 MCP 客户端现在可以调用控制工具。'
          : '$adapterName 已验证通过，启动 MCP 服务后就可以接收 AI 工具调用。';
    case ActiveDeviceAdapterReadinessState.revoked:
      return '$adapterName 的本机验证已撤销，除了 stop_all 之外的控制请求都会被拒绝。';
    case ActiveDeviceAdapterReadinessState.needsReverify:
      return '$adapterName 需要重新验证，重新通过前 AI 控制请求都会被拒绝。';
    case ActiveDeviceAdapterReadinessState.verificationFailed:
      return '$adapterName 上次验证失败，请重新执行低强度验证后再启用 AI 控制。';
  }
}

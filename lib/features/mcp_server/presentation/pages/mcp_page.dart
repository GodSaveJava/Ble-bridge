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
      orElse: () => '正在读取当前设备状态',
    );
    final String controlSubtitle = readinessAsync.maybeWhen(
      data: (readiness) => _mcpControlSubtitle(readiness, state.isRunning),
      orElse: () => '正在同步设备、适配器和验证结果，请稍候。',
    );
    final String nextStepText = readinessAsync.maybeWhen(
      data: (readiness) => _mcpNextStepText(readiness, state.isRunning),
      orElse: () => '请先等待页面完成状态同步。',
    );
    final String aiControlStatus = readinessAsync.maybeWhen(
      data: (readiness) => _aiControlStatusText(readiness, state.isRunning),
      orElse: () => '读取中',
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '本地 AI 控制服务',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('这里决定 AI 现在能不能通过本机 MCP 工具控制玩具。'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _StatusChip(
                          label: state.isRunning ? 'MCP 已启动' : 'MCP 未启动',
                        ),
                        _StatusChip(label: aiControlStatus),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.endpointInfo == null
                          ? '本地地址：启动后自动生成'
                          : '本地地址：http://${state.endpointInfo!.host}:${state.endpointInfo!.port}${state.endpointInfo!.path}',
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
                          child: Text(state.isBusy ? '处理中...' : '启动 MCP'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: state.isBusy || !state.isRunning
                              ? null
                              : () => ref
                                    .read(mcpServiceControllerProvider.notifier)
                                    .stop(),
                          child: const Text('停止 MCP'),
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
                padding: const EdgeInsets.all(16),
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
                    const SizedBox(height: 12),
                    _NextStepBanner(message: nextStepText),
                    if (readinessAsync.hasError) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        '适配器状态读取失败，请进入设备管理页检查模板绑定和验证记录。',
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

class _NextStepBanner extends StatelessWidget {
  const _NextStepBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '下一步建议',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(message),
        ],
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
        _McpAction(label: '重新选择适配器', route: '/device-manager', isPrimary: true),
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
      return '当前还没有可供 AI 控制的设备';
    case ActiveDeviceAdapterReadinessState.noBinding:
      return '当前设备还没有绑定适配器';
    case ActiveDeviceAdapterReadinessState.bindingMissing:
      return '当前设备绑定的适配器已经不存在';
    case ActiveDeviceAdapterReadinessState.unverified:
      return '当前适配器还没有完成本机验证';
    case ActiveDeviceAdapterReadinessState.verified:
      return mcpRunning ? '现在可以让 AI 控制当前设备' : '当前设备已经完成验证';
    case ActiveDeviceAdapterReadinessState.revoked:
      return '当前适配器的验证已被撤销';
    case ActiveDeviceAdapterReadinessState.needsReverify:
      return '当前适配器需要重新验证';
    case ActiveDeviceAdapterReadinessState.verificationFailed:
      return '当前适配器上次验证没有通过';
  }
}

String _mcpControlSubtitle(
  ActiveDeviceAdapterReadiness readiness,
  bool mcpRunning,
) {
  final String adapterName =
      readiness.adapterDisplayName ?? readiness.adapterId ?? '当前适配器';
  switch (readiness.state) {
    case ActiveDeviceAdapterReadinessState.noDevice:
      return '请先连接设备，再启动 MCP 服务。';
    case ActiveDeviceAdapterReadinessState.noBinding:
      return '请先在设备管理页为当前设备选择一份适配器模板。';
    case ActiveDeviceAdapterReadinessState.bindingMissing:
      return '当前绑定的 $adapterName 已从本地模板列表移除，请重新选择。';
    case ActiveDeviceAdapterReadinessState.unverified:
      return '$adapterName 还没有在当前设备上完成低强度验证，AI 控制会被安全拦截。';
    case ActiveDeviceAdapterReadinessState.verified:
      return mcpRunning
          ? '$adapterName 已验证通过，现在 AI 可以通过本机 MCP 工具调用控制能力。'
          : '$adapterName 已验证通过，现在只差启动 MCP 服务。';
    case ActiveDeviceAdapterReadinessState.revoked:
      return '$adapterName 的本机验证已撤销，除了 stop_all 之外的 AI 控制请求都会被拒绝。';
    case ActiveDeviceAdapterReadinessState.needsReverify:
      return '$adapterName 因为规则或模板变化需要重新验证，验证前 AI 还不能接管控制。';
    case ActiveDeviceAdapterReadinessState.verificationFailed:
      return '$adapterName 上次验证失败，请重新完成低强度验证后再启用 AI 控制。';
  }
}

String _mcpNextStepText(
  ActiveDeviceAdapterReadiness readiness,
  bool mcpRunning,
) {
  final String adapterName =
      readiness.adapterDisplayName ?? readiness.adapterId ?? '当前适配器';
  switch (readiness.state) {
    case ActiveDeviceAdapterReadinessState.noDevice:
      return '先去扫描并连接设备，连接成功后再回来启动 MCP。';
    case ActiveDeviceAdapterReadinessState.noBinding:
      return '先为当前设备绑定一份适配器模板，再进行低强度验证。';
    case ActiveDeviceAdapterReadinessState.bindingMissing:
      return '当前模板记录已经失效，请重新选择适配器后再继续。';
    case ActiveDeviceAdapterReadinessState.unverified:
      return '请先完成 $adapterName 的低强度验证。验证通过前，AI 还不能直接控制设备。';
    case ActiveDeviceAdapterReadinessState.verified:
      return mcpRunning
          ? '现在已经可以让 AI 控制设备了。如果你还不放心，也可以先进入手动控制再确认一次。'
          : '当前设备已经完成验证，现在只差启动 MCP 服务。启动后，AI 才能通过本机工具控制设备。';
    case ActiveDeviceAdapterReadinessState.revoked:
      return '请重新完成验证。撤销验证后，系统会继续拦截 AI 控制请求。';
    case ActiveDeviceAdapterReadinessState.needsReverify:
      return '请重新验证当前模板；如果验证反应不对，再回到设备管理页更换模板。';
    case ActiveDeviceAdapterReadinessState.verificationFailed:
      return '请回到验证页面重新做低强度测试，确认停止、吸力、震动和微电流反应都正确。';
  }
}

String _aiControlStatusText(
  ActiveDeviceAdapterReadiness readiness,
  bool mcpRunning,
) {
  if (!readiness.canControlViaMcp) {
    return 'AI 控制暂不可用';
  }
  return mcpRunning ? 'AI 控制已可用' : '等待启动 MCP';
}

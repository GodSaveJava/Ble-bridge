import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../application/models/active_device_adapter_readiness.dart';
import '../../../../application/providers/application_providers.dart';
import '../../../../domain/entities/remote_bridge_session.dart';
import '../../../../shared/widgets/toylink_background.dart';
import '../controllers/claude_connector_health_controller.dart';
import '../controllers/claude_connector_onboarding_controller.dart';
import '../controllers/mcp_service_controller.dart';
import '../controllers/remote_bridge_session_controller.dart';

class McpPage extends ConsumerWidget {
  const McpPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final McpServiceState localMcpState = ref.watch(
      mcpServiceControllerProvider,
    );
    final RemoteBridgeSessionState bridgeState = ref.watch(
      remoteBridgeSessionControllerProvider,
    );
    final ClaudeConnectorOnboardingState onboardingState = ref.watch(
      claudeConnectorOnboardingControllerProvider,
    );
    final AsyncValue<ClaudeConnectorHealthCheck> claudeHealthAsync = ref.watch(
      claudeConnectorHealthCheckProvider,
    );
    final AsyncValue<ActiveDeviceAdapterReadiness> readinessAsync = ref.watch(
      activeDeviceAdapterReadinessProvider,
    );

    final String controlTitle = readinessAsync.maybeWhen(
      data: (ActiveDeviceAdapterReadiness readiness) =>
          _mcpControlTitle(readiness, localMcpState.isRunning),
      orElse: () => '正在读取当前设备状态',
    );
    final String controlSubtitle = readinessAsync.maybeWhen(
      data: (ActiveDeviceAdapterReadiness readiness) =>
          _mcpControlSubtitle(readiness, localMcpState.isRunning),
      orElse: () => '正在同步设备、适配器和验证结果，请稍等。',
    );
    final String nextStepText = readinessAsync.maybeWhen(
      data: (ActiveDeviceAdapterReadiness readiness) =>
          _mcpNextStepText(readiness, localMcpState.isRunning),
      orElse: () => '请先等待页面完成状态同步。',
    );
    final String aiControlStatus = readinessAsync.maybeWhen(
      data: (ActiveDeviceAdapterReadiness readiness) =>
          _aiControlStatusText(readiness, localMcpState.isRunning),
      orElse: () => '读取中',
    );
    final List<_McpAction> controlActions = readinessAsync.maybeWhen(
      data: (ActiveDeviceAdapterReadiness readiness) => _buildMcpActions(
        readiness: readiness,
        mcpRunning: localMcpState.isRunning,
      ),
      orElse: () => const <_McpAction>[],
    );
    final bool claudeSetupCompleted = readinessAsync.maybeWhen(
      data: (ActiveDeviceAdapterReadiness readiness) =>
          onboardingState.matchesReadiness(readiness),
      orElse: () => false,
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
                      '本地 MCP 服务',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('这里决定本机是否已经把控制工具暴露给外部调用。'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _StatusChip(
                          label: localMcpState.isRunning ? 'MCP 已启动' : 'MCP 未启动',
                        ),
                        _StatusChip(label: aiControlStatus),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localMcpState.endpointInfo == null
                          ? '本地地址：启动后自动生成'
                          : '本地地址：http://${localMcpState.endpointInfo!.host}:${localMcpState.endpointInfo!.port}${localMcpState.endpointInfo!.path}',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        FilledButton(
                          onPressed:
                              localMcpState.isBusy || localMcpState.isRunning
                              ? null
                              : () => ref
                                    .read(mcpServiceControllerProvider.notifier)
                                    .start(),
                          child: Text(
                            localMcpState.isBusy ? '处理中...' : '启动 MCP',
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed:
                              localMcpState.isBusy || !localMcpState.isRunning
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
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Claude 远程接入',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '这里管理给 Claude 原对话使用的远程桥接会话。聊天和记忆仍然留在 Claude，那边只通过这里拿到控制能力。',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _StatusChip(label: _bridgeStatusLabel(bridgeState.status)),
                        _StatusChip(
                          label: bridgeState.canOnboardClaude
                              ? (claudeSetupCompleted
                                    ? 'Claude 已完成接入'
                                    : 'Claude 可接入')
                              : '等待生成接入信息',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      bridgeState.connectorUrl == null
                          ? '接入地址：尚未生成'
                          : '接入地址：${bridgeState.connectorUrl}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bridgeState.connectorToken == null ||
                              bridgeState.connectorToken!.isEmpty
                          ? '接入令牌：尚未生成'
                          : '接入令牌：已生成',
                    ),
                    if (bridgeState.maskedToken != null &&
                        bridgeState.maskedToken!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text('当前令牌：${bridgeState.maskedToken}'),
                    ],
                    if (bridgeState.toolNames.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text('工具数量：${bridgeState.toolNames.length}'),
                    ],
                    const SizedBox(height: 12),
                    _NextStepBanner(message: _bridgeGuidanceText(bridgeState)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        FilledButton(
                          onPressed: bridgeState.isBusy
                              ? null
                              : () => ref
                                    .read(
                                      remoteBridgeSessionControllerProvider
                                          .notifier,
                                    )
                                    .startSession(),
                          child: Text(
                            bridgeState.isBusy ? '处理中...' : '启动桥接会话',
                          ),
                        ),
                        OutlinedButton(
                          onPressed: bridgeState.isBusy
                              ? null
                              : () => ref
                                    .read(
                                      remoteBridgeSessionControllerProvider
                                          .notifier,
                                    )
                                    .refreshConnector(),
                          child: const Text('刷新接入信息'),
                        ),
                        OutlinedButton(
                          onPressed: bridgeState.isBusy
                              ? null
                              : () => ref
                                    .read(
                                      remoteBridgeSessionControllerProvider
                                          .notifier,
                                    )
                                    .refreshConnector()
                                    .then((_) {
                                      return ref
                                          .read(
                                            claudeConnectorOnboardingControllerProvider
                                                .notifier,
                                          )
                                          .reset();
                                    }),
                          child: const Text('重新生成接入信息'),
                        ),
                        OutlinedButton(
                          onPressed: bridgeState.isBusy ||
                                  bridgeState.status ==
                                      RemoteBridgeSessionStatus.offline
                              ? null
                              : () => ref
                                    .read(
                                      remoteBridgeSessionControllerProvider
                                          .notifier,
                                    )
                                    .stopSession(),
                          child: const Text('停止桥接会话'),
                        ),
                        if (bridgeState.canOnboardClaude)
                          OutlinedButton(
                            onPressed: () => context.push('/claude-onboarding'),
                            child: Text(
                              claudeSetupCompleted
                                  ? '查看接入信息'
                                  : '去配置 Claude',
                            ),
                          ),
                      ],
                    ),
                    if (claudeSetupCompleted) ...<Widget>[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: onboardingState.isSaving
                              ? null
                              : () => ref
                                    .read(
                                      claudeConnectorOnboardingControllerProvider
                                          .notifier,
                                    )
                                    .reset(),
                          child: const Text('重置 Claude 接入状态'),
                        ),
                      ),
                    ],
                    if (bridgeState.errorMessage != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        bridgeState.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (claudeHealthAsync case AsyncData<ClaudeConnectorHealthCheck>(:final value))
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Claude 接入自检',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _StatusChip(label: _claudeHealthStatusLabel(value.status)),
                      const SizedBox(height: 12),
                      Text(
                        value.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(value.summary),
                      const SizedBox(height: 12),
                      _HealthRow(
                        label: '设备验证通过',
                        passed: value.deviceReady,
                      ),
                      _HealthRow(
                        label: '桥接会话已就绪',
                        passed: value.bridgeReady,
                      ),
                      _HealthRow(
                        label: '接入信息已生成',
                        passed: value.connectorReady,
                      ),
                      _HealthRow(
                        label: 'Claude 向导已完成',
                        passed: value.onboardingCompleted,
                      ),
                      if (value.actionLabel != null &&
                          value.actionRoute != null) ...<Widget>[
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => context.push(value.actionRoute!),
                          child: Text(value.actionLabel!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (localMcpState.errorMessage != null) ...<Widget>[
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: ListTile(
                  title: Text(
                    localMcpState.errorMessage!,
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

class _HealthRow extends StatelessWidget {
  const _HealthRow({required this.label, required this.passed});

  final String label;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    final Color color = passed
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Icon(
            passed ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
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
      return '当前绑定的是 $adapterName，但这份适配器已经从本地模板列表中移除，请重新选择。';
    case ActiveDeviceAdapterReadinessState.unverified:
      return '$adapterName 还没有在当前设备上完成低强度验证，AI 控制会被安全拦截。';
    case ActiveDeviceAdapterReadinessState.verified:
      return mcpRunning
          ? '$adapterName 已验证通过，现在 AI 可以通过本机 MCP 工具调用控制能力。'
          : '$adapterName 已验证通过，现在只差启动 MCP 服务。启动后，AI 才能通过本机工具控制设备。';
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
          : '现在只差启动 MCP 服务';
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

String _bridgeStatusLabel(RemoteBridgeSessionStatus status) {
  return switch (status) {
    RemoteBridgeSessionStatus.offline => '桥接未启动',
    RemoteBridgeSessionStatus.connecting => '桥接连接中',
    RemoteBridgeSessionStatus.ready => '桥接已就绪',
    RemoteBridgeSessionStatus.busy => '桥接处理中',
    RemoteBridgeSessionStatus.error => '桥接异常',
  };
}

String _claudeHealthStatusLabel(ClaudeConnectorHealthStatus status) {
  return switch (status) {
    ClaudeConnectorHealthStatus.blocked => '自检未通过',
    ClaudeConnectorHealthStatus.pending => '还需处理',
    ClaudeConnectorHealthStatus.ready => '自检通过',
  };
}

String _bridgeGuidanceText(RemoteBridgeSessionState state) {
  switch (state.status) {
    case RemoteBridgeSessionStatus.offline:
      return '先启动桥接会话。接入地址和令牌生成后，你才能去 Claude 里添加 connector。';
    case RemoteBridgeSessionStatus.connecting:
      return '桥接正在建立会话，请稍等片刻，不要重复点击。';
    case RemoteBridgeSessionStatus.ready:
      return '接入信息已经准备好了。下一步可以复制这些信息，并按教程去 Claude 完成一次 connector 配置。';
    case RemoteBridgeSessionStatus.busy:
      return '桥接正在刷新接入信息，请稍等当前操作完成。';
    case RemoteBridgeSessionStatus.error:
      return '桥接会话出现异常。请重新启动桥接会话；如果仍然失败，再检查网络和后台保活状态。';
  }
}

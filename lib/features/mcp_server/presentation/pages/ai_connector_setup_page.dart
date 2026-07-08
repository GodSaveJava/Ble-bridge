import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../application/models/active_device_adapter_readiness.dart';
import '../../../../application/providers/application_providers.dart';
import '../../../../shared/widgets/toylink_background.dart';
import '../../domain/connector_card_payload.dart';
import '../../domain/connector_platform_template.dart';
import '../controllers/remote_bridge_session_controller.dart';

class AiConnectorSetupPage extends ConsumerStatefulWidget {
  const AiConnectorSetupPage({super.key});

  @override
  ConsumerState<AiConnectorSetupPage> createState() =>
      _AiConnectorSetupPageState();
}

class _AiConnectorSetupPageState extends ConsumerState<AiConnectorSetupPage> {
  String? _copyFeedback;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ActiveDeviceAdapterReadiness> readinessAsync = ref.watch(
      activeDeviceAdapterReadinessProvider,
    );
    final RemoteBridgeSessionState bridgeState = ref.watch(
      remoteBridgeSessionControllerProvider,
    );
    final ActiveDeviceAdapterReadiness? readiness = switch (readinessAsync) {
      AsyncData<ActiveDeviceAdapterReadiness>(:final value) => value,
      _ => null,
    };
    final _SetupBlocker? blocker = _buildBlocker(
      readiness: readiness,
      bridgeState: bridgeState,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('AI Connector Setup')),
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
                      '连接你的原有 AI',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '选择你的 AI 平台，复制对应模板。聊天页面、记忆和关系仍留在原来的 AI 里，ToyLink 只提供安全硬件连接能力。',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const <Widget>[
                        _SetupChip(label: 'Safety V0'),
                        _SetupChip(label: 'get_status'),
                        _SetupChip(label: 'stop_all'),
                        _SetupChip(label: 'set_* 未开放'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (blocker != null)
              _BlockedSetupCard(blocker: blocker)
            else
              _ReadySetupContent(
                bridgeState: bridgeState,
                copyFeedback: _copyFeedback,
                onCopyCard: () => _copy(
                  _payload(bridgeState).toPrettyJson(),
                  '连接卡片已复制',
                  markVerificationWaiting: true,
                ),
                onCopyDeepLink: () => _copy(
                  _payload(bridgeState).toDeepLink(),
                  'Deep link 已复制',
                  markVerificationWaiting: true,
                ),
                onCopyTemplate: (ConnectorPlatformTemplate template) => _copy(
                  template.content,
                  '${template.title} 模板已复制',
                  markVerificationWaiting: true,
                ),
              ),
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(
    String value,
    String message, {
    required bool markVerificationWaiting,
  }) async {
    if (value.isEmpty) {
      return;
    }
    if (markVerificationWaiting) {
      ref
          .read(remoteBridgeSessionControllerProvider.notifier)
          .markConnectorCardCopied();
    }
    await Clipboard.setData(ClipboardData(text: value));
    setState(() {
      _copyFeedback = message;
    });
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReadySetupContent extends StatelessWidget {
  const _ReadySetupContent({
    required this.bridgeState,
    required this.copyFeedback,
    required this.onCopyCard,
    required this.onCopyDeepLink,
    required this.onCopyTemplate,
  });

  final RemoteBridgeSessionState bridgeState;
  final String? copyFeedback;
  final VoidCallback onCopyCard;
  final VoidCallback onCopyDeepLink;
  final void Function(ConnectorPlatformTemplate template) onCopyTemplate;

  @override
  Widget build(BuildContext context) {
    final ConnectorCardPayload payload = _payload(bridgeState);
    final List<ConnectorPlatformTemplate> templates =
        buildConnectorPlatformTemplates(payload);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '连接卡片',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text('接入地址：${payload.connectorUrl}'),
                const SizedBox(height: 4),
                Text('Token：${payload.maskedToken}'),
                const SizedBox(height: 4),
                Text('开放工具：${payload.tools.join(' / ')}'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: onCopyCard,
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('复制连接卡片'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onCopyDeepLink,
                      icon: const Icon(Icons.qr_code_2, size: 18),
                      label: const Text('复制 Deep link'),
                    ),
                  ],
                ),
                if (copyFeedback != null && copyFeedback!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    copyFeedback!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '选择平台',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('每个平台都使用同一张 Safety V0 连接卡片，只是复制格式不同。'),
                const SizedBox(height: 12),
                DefaultTabController(
                  length: templates.length,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TabBar(
                        isScrollable: true,
                        tabs: <Widget>[
                          for (final ConnectorPlatformTemplate template
                              in templates)
                            Tab(text: template.title),
                        ],
                      ),
                      SizedBox(
                        height: 210,
                        child: TabBarView(
                          children: <Widget>[
                            for (final ConnectorPlatformTemplate template
                                in templates)
                              _PlatformTemplatePanel(
                                template: template,
                                onCopy: () => onCopyTemplate(template),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _VerificationCard(),
      ],
    );
  }
}

class _PlatformTemplatePanel extends StatelessWidget {
  const _PlatformTemplatePanel({required this.template, required this.onCopy});

  final ConnectorPlatformTemplate template;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            template.title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(template.subtitle),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy, size: 18),
            label: Text(template.copyLabel),
          ),
          const SizedBox(height: 12),
          const Text('验证口令：配置完成后，让你的 AI 调用 get_status。需要立即停机时，只允许调用 stop_all。'),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '验收边界',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('1. AI 能调用 get_status，ToyLink 页面显示等待状态或验证成功。'),
            const SizedBox(height: 6),
            const Text('2. AI 只能看到 Safety V0 工具范围。'),
            const SizedBox(height: 6),
            const Text('3. 如果 AI 尝试 set_*，这是未开放能力，不按故障处理。'),
          ],
        ),
      ),
    );
  }
}

class _BlockedSetupCard extends StatelessWidget {
  const _BlockedSetupCard({required this.blocker});

  final _SetupBlocker blocker;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '还不能开始 AI 接入',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(blocker.message),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton(
                  onPressed: () => context.push(blocker.primaryRoute),
                  child: Text(blocker.primaryLabel),
                ),
                if (blocker.secondaryRoute != null)
                  OutlinedButton(
                    onPressed: () => context.push(blocker.secondaryRoute!),
                    child: Text(blocker.secondaryLabel!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupChip extends StatelessWidget {
  const _SetupChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

class _SetupBlocker {
  const _SetupBlocker({
    required this.message,
    required this.primaryLabel,
    required this.primaryRoute,
    this.secondaryLabel,
    this.secondaryRoute,
  });

  final String message;
  final String primaryLabel;
  final String primaryRoute;
  final String? secondaryLabel;
  final String? secondaryRoute;
}

_SetupBlocker? _buildBlocker({
  required ActiveDeviceAdapterReadiness? readiness,
  required RemoteBridgeSessionState bridgeState,
}) {
  if (readiness == null) {
    return const _SetupBlocker(
      message: '系统还在读取设备和适配器状态，请稍等。',
      primaryLabel: '返回 MCP 页面',
      primaryRoute: '/mcp',
    );
  }
  if (readiness.state != ActiveDeviceAdapterReadinessState.verified) {
    return const _SetupBlocker(
      message: '请先完成设备连接、适配器绑定和低强度验证，再把 ToyLink 接给外部 AI。',
      primaryLabel: '去设备管理',
      primaryRoute: '/device-manager',
      secondaryLabel: '去连接设备',
      secondaryRoute: '/scan',
    );
  }
  if (!bridgeState.canOnboardClaude) {
    return const _SetupBlocker(
      message: '接入信息还没有生成。请先回到 MCP 页面启动桥接会话。',
      primaryLabel: '返回 MCP 页面',
      primaryRoute: '/mcp',
    );
  }
  return null;
}

ConnectorCardPayload _payload(RemoteBridgeSessionState state) {
  return ConnectorCardPayload.fromBridgeSession(
    connectorUrl: state.connectorUrl,
    connectorToken: state.connectorToken,
    toolNames: state.toolNames,
  );
}

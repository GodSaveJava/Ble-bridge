import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../application/models/active_device_adapter_readiness.dart';
import '../../../../application/providers/application_providers.dart';
import '../../../../shared/widgets/toylink_background.dart';
import '../controllers/remote_bridge_session_controller.dart';

class ClaudeOnboardingPage extends ConsumerWidget {
  const ClaudeOnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final _OnboardingBlocker? blocker = _buildBlocker(
      readiness: readiness,
      bridgeState: bridgeState,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Claude 接入向导')),
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
                      '把 Claude 接到 ToyLink',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '这个向导只负责把当前手机里的 ToyLink 能力接给 Claude。你原来在 Claude 里的对话、记忆和相处方式都继续保留在那边，不会被替换成新的聊天。',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (blocker != null)
              _BlockedStateCard(blocker: blocker)
            else
              _ReadyStateContent(
                readiness: readiness!,
                bridgeState: bridgeState,
              ),
          ],
        ),
      ),
    );
  }
}

class _ReadyStateContent extends StatelessWidget {
  const _ReadyStateContent({
    required this.readiness,
    required this.bridgeState,
  });

  final ActiveDeviceAdapterReadiness readiness;
  final RemoteBridgeSessionState bridgeState;

  @override
  Widget build(BuildContext context) {
    final String adapterName =
        readiness.adapterDisplayName ?? readiness.adapterId ?? '当前适配器';

    return Column(
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '现在可以开始接入 Claude',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '$adapterName 已经完成本机验证，桥接会话也已经准备好。下面按步骤去 Claude 添加 connector，之后就可以回到原来的对话里继续互动。',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _StepCard(
          title: '第 1 步：确认本地准备',
          body:
              '确认当前设备已连接、适配器已绑定、低强度验证已通过。只要这三项任意一项失效，Claude 的控制请求就会被本地安全规则拦住。',
          footerChips: <String>[
            '设备已连接',
            '适配器已验证',
            '桥接已就绪',
          ],
        ),
        const SizedBox(height: 12),
        _StepCard(
          title: '第 2 步：记下接入信息',
          body:
              '在 Claude 添加 connector 时，需要用到下面这两项。地址决定 Claude 去哪里找 ToyLink，令牌用来证明这次接入属于你。',
          extra: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('接入地址：${bridgeState.connectorUrl}'),
              const SizedBox(height: 4),
              const Text('接入令牌：已生成'),
              if (bridgeState.maskedToken != null &&
                  bridgeState.maskedToken!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text('当前令牌：${bridgeState.maskedToken}'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _StepCard(
          title: '第 3 步：去 Claude 添加 connector',
          body:
              '打开 claude.ai 的 connector 配置页，新增一个 Remote MCP connector，把上面的接入地址和令牌填进去。完成保存后，Claude 才能在原对话里调用 ToyLink 的控制工具。',
        ),
        const SizedBox(height: 12),
        _StepCard(
          title: '第 4 步：回到原对话测试',
          body:
              '回到你原来的 Claude 对话里，用自然的话确认它是否已经能控制设备。例如：“你现在可以控制我的设备了吗？” 如果它能正常调用工具，再开始正式互动。',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('返回 MCP 页面'),
                ),
                OutlinedButton(
                  onPressed: () => context.push(
                    '/control?returnTo=%2Fclaude-onboarding&returnLabel=%E8%BF%94%E5%9B%9E%20Claude%20%E6%8E%A5%E5%85%A5',
                  ),
                  child: const Text('先进入手动控制确认'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BlockedStateCard extends StatelessWidget {
  const _BlockedStateCard({required this.blocker});

  final _OnboardingBlocker blocker;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '还不能开始 Claude 接入',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(blocker.message),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                FilledButton(
                  onPressed: () => context.push(blocker.primaryRoute),
                  child: Text(blocker.primaryLabel),
                ),
                if (blocker.secondaryRoute != null &&
                    blocker.secondaryLabel != null)
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

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.title,
    required this.body,
    this.extra,
    this.footerChips = const <String>[],
  });

  final String title;
  final String body;
  final Widget? extra;
  final List<String> footerChips;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(body),
            if (extra != null) ...<Widget>[
              const SizedBox(height: 12),
              extra!,
            ],
            if (footerChips.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: footerChips
                    .map(
                      (String chip) => Chip(
                        label: Text(chip),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OnboardingBlocker {
  const _OnboardingBlocker({
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

_OnboardingBlocker? _buildBlocker({
  required ActiveDeviceAdapterReadiness? readiness,
  required RemoteBridgeSessionState bridgeState,
}) {
  if (readiness == null) {
    return const _OnboardingBlocker(
      message: '系统还在读取当前设备、适配器和验证状态，请稍等页面同步完成。',
      primaryLabel: '返回 MCP 页面',
      primaryRoute: '/mcp',
    );
  }

  switch (readiness.state) {
    case ActiveDeviceAdapterReadinessState.noDevice:
      return const _OnboardingBlocker(
        message: '还没有连接可供 Claude 控制的设备。先完成设备连接，后面的适配器绑定、验证和桥接接入才有意义。',
        primaryLabel: '去连接设备',
        primaryRoute: '/scan',
      );
    case ActiveDeviceAdapterReadinessState.noBinding:
      return const _OnboardingBlocker(
        message: '当前设备还没有绑定适配器。先告诉 ToyLink 这是什么协议，后面 Claude 才知道自己的控制会落到哪种玩具上。',
        primaryLabel: '去绑定适配器',
        primaryRoute: '/device-manager',
      );
    case ActiveDeviceAdapterReadinessState.bindingMissing:
      return const _OnboardingBlocker(
        message: '当前设备之前绑定过的适配器已经失效或被移除。请先回到设备管理页重新选择模板，再继续 Claude 接入。',
        primaryLabel: '去绑定适配器',
        primaryRoute: '/device-manager',
      );
    case ActiveDeviceAdapterReadinessState.unverified:
      final String route = readiness.adapterId == null
          ? '/device-manager'
          : '/verification/${readiness.adapterId}';
      return _OnboardingBlocker(
        message: '当前设备的适配器还没完成低强度验证。验证通过前，Claude 的控制请求会被本地安全规则直接拦住。',
        primaryLabel: '去开始验证',
        primaryRoute: route,
        secondaryLabel: '去设备管理',
        secondaryRoute: '/device-manager',
      );
    case ActiveDeviceAdapterReadinessState.revoked:
    case ActiveDeviceAdapterReadinessState.needsReverify:
    case ActiveDeviceAdapterReadinessState.verificationFailed:
      final String route = readiness.adapterId == null
          ? '/device-manager'
          : '/verification/${readiness.adapterId}';
      return _OnboardingBlocker(
        message: '当前适配器需要重新验证，才能重新开放给 Claude 控制。请先回到验证页，重新确认停止、吸力、震动和微电流的低强度反应。',
        primaryLabel: '去重新验证',
        primaryRoute: route,
        secondaryLabel: '去设备管理',
        secondaryRoute: '/device-manager',
      );
    case ActiveDeviceAdapterReadinessState.verified:
      break;
  }

  if (!bridgeState.canOnboardClaude) {
    return const _OnboardingBlocker(
      message: '本地设备已经准备好了，但 Claude 接入信息还没生成。请先回到 MCP 页面启动桥接会话，再回来继续。',
      primaryLabel: '返回 MCP 页面',
      primaryRoute: '/mcp',
    );
  }

  return null;
}

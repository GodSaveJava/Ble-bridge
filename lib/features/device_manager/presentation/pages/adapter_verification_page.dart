import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../../shared/widgets/toylink_background.dart';
import '../controllers/adapter_verification_controller.dart';

class AdapterVerificationPage extends ConsumerWidget {
  const AdapterVerificationPage({required this.adapterId, super.key});

  final String adapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AdapterVerificationState state = ref.watch(
      adapterVerificationControllerProvider,
    );
    final activeStatus = ref.watch(activeDeviceStatusStreamProvider);
    final String deviceFingerprint = activeStatus.maybeWhen(
      data: (status) => status.deviceId,
      orElse: () => 'unknown-device',
    );
    final bool hasConnectedDevice = activeStatus.maybeWhen(
      data: (status) => status.isConnected,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('适配器验证')),
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
                    const Text(
                      '验证说明',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text('适配器 ID：$adapterId'),
                    const SizedBox(height: 6),
                    Text('当前设备标识：$deviceFingerprint'),
                    const SizedBox(height: 8),
                    const Text('请在低强度下按顺序测试，每次动作建议不超过 3 秒。'),
                    const SizedBox(height: 6),
                    const Text('点击“执行”会真实发送 BLE 控制命令，请确认环境安全。'),
                    if (!hasConnectedDevice) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        '当前还没有连接设备，建议先返回扫描页连接设备后再继续。',
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
                      '当前进度',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '已确认 ${state.completedCount}/${state.steps.length} 个步骤',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.canSubmit
                          ? '四个步骤都已确认，可以提交验证结果。'
                          : '全部步骤都确认通过后，才能启用 AI 控制。',
                    ),
                    const SizedBox(height: 6),
                    const Text('特别注意：`stop_all` 必须可靠通过，这是安全底线。'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: state.steps.map((VerificationStepDraft step) {
                    final bool isRunningCurrentStep =
                        state.isRunningStep && state.runningStepKey == step.key;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(step.label),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 4),
                          Text(step.description),
                          const SizedBox(height: 4),
                          Text(
                            step.safetyHint,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(step.passed ? '当前状态：已确认通过' : '当前状态：尚未确认'),
                        ],
                      ),
                      trailing: OutlinedButton(
                        onPressed: state.isSubmitting || state.isRunningStep
                            ? null
                            : () => ref
                                  .read(
                                    adapterVerificationControllerProvider
                                        .notifier,
                                  )
                                  .runStep(step.key),
                        child: Text(isRunningCurrentStep ? '执行中...' : '执行'),
                      ),
                      leading: Checkbox(
                        value: step.passed,
                        onChanged: state.isSubmitting || state.isRunningStep
                            ? null
                            : (bool? value) {
                                ref
                                    .read(
                                      adapterVerificationControllerProvider
                                          .notifier,
                                    )
                                    .setStepPassed(
                                      stepKey: step.key,
                                      passed: value ?? false,
                                    );
                              },
                      ),
                    );
                  }).toList(),
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
                      '如果某一步与预期不一致',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. 不要勾选通过。'),
                    const Text('2. 先执行“测试一键停止”，确认设备已经停下。'),
                    const Text('3. 返回设备管理，尝试切换适配器或重新导入文件。'),
                    const Text('4. 如果是微电流异常，请立即停止，不要继续尝试。'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: state.isSubmitting || !state.canSubmit
                  ? null
                  : () => ref
                        .read(adapterVerificationControllerProvider.notifier)
                        .submit(
                          adapterId: adapterId,
                          deviceFingerprint: deviceFingerprint,
                        ),
              child: Text(state.isSubmitting ? '提交中...' : '确认验证通过并启用 AI 控制'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                OutlinedButton(
                  onPressed: () => context.push('/device-manager'),
                  child: const Text('返回设备管理'),
                ),
                if (hasConnectedDevice)
                  OutlinedButton(
                    onPressed: () => context.push(
                      '/control?returnTo=%2Fdevice-manager&returnLabel=%E8%BF%94%E5%9B%9E%E8%AE%BE%E5%A4%87%E7%AE%A1%E7%90%86',
                    ),
                    child: const Text('去手动控制'),
                  ),
                OutlinedButton(
                  onPressed: () => context.push('/mcp'),
                  child: const Text('查看 MCP 状态'),
                ),
              ],
            ),
            if (state.errorMessage != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                state.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (state.successMessage != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                state.successMessage!,
                style: const TextStyle(color: Colors.green),
              ),
              const SizedBox(height: 8),
              const Text('下一步建议：回到首页启动 MCP，或进入手动控制再做一次低强度确认。'),
            ],
          ],
        ),
      ),
    );
  }
}

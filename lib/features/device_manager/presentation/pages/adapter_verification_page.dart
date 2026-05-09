import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                    Text('适配器 ID：$adapterId'),
                    const SizedBox(height: 6),
                    Text('当前设备标识：$deviceFingerprint'),
                    const SizedBox(height: 6),
                    const Text(
                      '请先在低强度下逐项测试，再勾选“通过”。建议每次动作不超过 3 秒。',
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
                  children: state.steps
                      .map(
                        (step) => CheckboxListTile(
                          value: step.passed,
                          title: Text(step.label),
                          subtitle: const Text('确认该动作结果符合预期后再勾选'),
                          onChanged: state.isSubmitting
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
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: state.isSubmitting
                  ? null
                  : () => ref
                        .read(adapterVerificationControllerProvider.notifier)
                        .submit(
                          adapterId: adapterId,
                          deviceFingerprint: deviceFingerprint,
                        ),
              child: Text(state.isSubmitting ? '提交中...' : '提交验证结果'),
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
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/app_lock_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockState = ref.watch(appLockControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: SwitchListTile(
              title: const Text('启用应用锁'),
              subtitle: const Text('开启后，进入应用时需要先解锁。'),
              value: lockState.enabled,
              onChanged: (value) => ref
                  .read(appLockControllerProvider.notifier)
                  .setEnabled(value),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('立即锁定'),
              subtitle: const Text('用于测试锁屏和解锁流程。'),
              trailing: FilledButton.tonal(
                onPressed: lockState.enabled
                    ? () =>
                          ref.read(appLockControllerProvider.notifier).lockNow()
                    : null,
                child: const Text('锁定'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              title: Text('安全提醒'),
              subtitle: Text('微电流建议上限默认为 8，超过时会触发额外确认。'),
            ),
          ),
        ],
      ),
    );
  }
}

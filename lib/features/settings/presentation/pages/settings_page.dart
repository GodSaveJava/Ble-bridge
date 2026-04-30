import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/app_lock_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLockState lockState = ref.watch(appLockControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: SwitchListTile(
              title: const Text('启用 App Lock'),
              subtitle: const Text('开启后进入应用将需要解锁（MVP PIN 模式）。'),
              value: lockState.enabled,
              onChanged: (value) {
                ref.read(appLockControllerProvider.notifier).setEnabled(value);
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('立即锁定'),
              subtitle: const Text('用于测试锁屏覆盖层和解锁流程。'),
              trailing: FilledButton.tonal(
                onPressed: lockState.enabled
                    ? () =>
                          ref.read(appLockControllerProvider.notifier).lockNow()
                    : null,
                child: const Text('Lock'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              title: Text('EMS 安全提示'),
              subtitle: Text('当前默认软上限为 8；超过后需要明确确认。'),
            ),
          ),
        ],
      ),
    );
  }
}

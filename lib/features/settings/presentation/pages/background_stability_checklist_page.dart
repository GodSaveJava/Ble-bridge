import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/toylink_background.dart';
import '../controllers/background_stability_checklist_controller.dart';

class BackgroundStabilityChecklistPage extends ConsumerWidget {
  const BackgroundStabilityChecklistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backgroundChecklistControllerProvider);
    final checklist = state.checklist;
    final bool allPassed = checklist.allPassed;

    return Scaffold(
      appBar: AppBar(title: const Text('后台稳定性验收清单')),
      body: ToyLinkBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const Card(
              child: ListTile(
                title: Text('使用说明'),
                subtitle: Text(
                  '请按顺序在真机上完成以下 4 项检查，全部通过后再进行对外演示或发布测试包。',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: <Widget>[
                  CheckboxListTile(
                    value: checklist.lockScreen30Min,
                    onChanged: state.isLoading || state.isSaving
                        ? null
                        : (value) => ref
                              .read(backgroundChecklistControllerProvider.notifier)
                              .update(lockScreen30Min: value ?? false),
                    title: const Text('锁屏 30 分钟后连接仍保持'),
                  ),
                  CheckboxListTile(
                    value: checklist.switchBackgroundAndBack,
                    onChanged: state.isLoading || state.isSaving
                        ? null
                        : (value) => ref
                              .read(backgroundChecklistControllerProvider.notifier)
                              .update(switchBackgroundAndBack: value ?? false),
                    title: const Text('切后台并返回前台后可继续控制'),
                  ),
                  CheckboxListTile(
                    value: checklist.autoReconnectAfterDisconnect,
                    onChanged: state.isLoading || state.isSaving
                        ? null
                        : (value) => ref
                              .read(backgroundChecklistControllerProvider.notifier)
                              .update(
                                autoReconnectAfterDisconnect: value ?? false,
                              ),
                    title: const Text('蓝牙短断后自动重连成功'),
                  ),
                  CheckboxListTile(
                    value: checklist.mcpCallAvailableInBackground,
                    onChanged: state.isLoading || state.isSaving
                        ? null
                        : (value) => ref
                              .read(backgroundChecklistControllerProvider.notifier)
                              .update(
                                mcpCallAvailableInBackground: value ?? false,
                              ),
                    title: const Text('后台状态下 MCP 调用可用'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: Text(allPassed ? '验收结果：通过' : '验收结果：未完成'),
                subtitle: Text(
                  allPassed
                      ? '四项检查均已通过，可以进入下一阶段。'
                      : '请继续完成未通过项，避免后台断连风险。',
                ),
              ),
            ),
            if (checklist.lastUpdatedAt != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                '最近保存：${checklist.lastUpdatedAt!.toLocal().toString().split('.').first}',
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                OutlinedButton(
                  onPressed: state.isLoading || state.isSaving
                      ? null
                      : () => ref
                            .read(backgroundChecklistControllerProvider.notifier)
                            .reset(),
                  child: const Text('重置清单'),
                ),
                OutlinedButton(
                  onPressed: state.isLoading || state.isSaving
                      ? null
                      : () => ref
                            .read(backgroundChecklistControllerProvider.notifier)
                            .load(),
                  child: const Text('重新加载'),
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
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/entities/adapter_manifest.dart';
import '../../../../shared/widgets/toylink_background.dart';
import '../controllers/device_manager_controller.dart';

class DeviceManagerPage extends ConsumerStatefulWidget {
  const DeviceManagerPage({super.key});

  @override
  ConsumerState<DeviceManagerPage> createState() => _DeviceManagerPageState();
}

class _DeviceManagerPageState extends ConsumerState<DeviceManagerPage> {
  final TextEditingController _jsonController = TextEditingController();

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DeviceManagerState state = ref.watch(deviceManagerControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设备管理')),
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
                      '导入适配器 JSON',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '粘贴适配器说明书 JSON 后点击导入。第一阶段仅支持 manifest + 内置 codecKey。',
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _jsonController,
                      minLines: 8,
                      maxLines: 12,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '{"schemaVersion":1,...}',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        FilledButton(
                          onPressed: state.isImporting
                              ? null
                              : () => ref
                                    .read(
                                      deviceManagerControllerProvider.notifier,
                                    )
                                    .importJsonText(_jsonController.text),
                          child: Text(state.isImporting ? '导入中...' : '导入'),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () {
                            _jsonController.clear();
                            ref
                                .read(deviceManagerControllerProvider.notifier)
                                .clearFeedback();
                          },
                          child: const Text('清空'),
                        ),
                      ],
                    ),
                    if (state.errorMessage != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        state.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
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
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      '已导入适配器',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (state.adapters.isEmpty) const Text('暂无适配器，请先导入。'),
                    for (final AdapterManifest manifest in state.adapters)
                      ListTile(
                        dense: true,
                        title: Text(manifest.displayName),
                        subtitle: Text(
                          'ID: ${manifest.adapterId}\ncodec: ${manifest.codecKey}\nversion: ${manifest.version}',
                        ),
                        trailing: OutlinedButton(
                          onPressed: () => context.push(
                            '/verification/${manifest.adapterId}',
                          ),
                          child: const Text('开始验证'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

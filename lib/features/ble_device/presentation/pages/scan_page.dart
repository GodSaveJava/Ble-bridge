import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/scan_controller.dart';

class ScanPage extends ConsumerWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ScanState state = ref.watch(scanControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('扫描与连接')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      state.isScanning ? '正在扫描 SOSEXY 设备...' : '点击开始扫描',
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: state.isScanning
                        ? null
                        : () => ref
                              .read(scanControllerProvider.notifier)
                              .startScan(),
                    child: const Text('开始扫描'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: state.isScanning
                        ? () => ref
                              .read(scanControllerProvider.notifier)
                              .stopScan()
                        : null,
                    child: const Text('停止'),
                  ),
                ],
              ),
            ),
          ),
          if (state.errorMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      state.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(scanControllerProvider.notifier)
                          .clearError(),
                      child: const Text('关闭'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (state.devices.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('暂无发现设备。请先开始扫描。'),
              ),
            ),
          for (final device in state.devices) ...<Widget>[
            Card(
              child: ListTile(
                title: Text(device.displayName),
                subtitle: Text(
                  'RSSI: ${device.rssi ?? '--'}  协议: ${device.protocolKey}',
                ),
                trailing: FilledButton.tonal(
                  onPressed: state.isConnecting
                      ? null
                      : () async {
                          await ref
                              .read(scanControllerProvider.notifier)
                              .connect(device);
                          if (context.mounted) {
                            context.go('/control');
                          }
                        },
                  child: Text(
                    state.isConnecting && state.connectedDeviceId != device.id
                        ? '连接中...'
                        : '连接',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/toylink_background.dart';
import '../controllers/scan_controller.dart';

class ScanPage extends ConsumerWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scanControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '扫描与连接',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ToyLinkBackground(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: <Widget>[
            // SCAN CONTROL CARD
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (state.isScanning) ...[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            state.isScanning ? '正在搜寻附近的设备...' : '点击下方按钮开始扫描',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: state.isScanning
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: state.isScanning
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey[700],
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FilledButton(
                            onPressed: state.isScanning
                                ? null
                                : () => ref
                                      .read(scanControllerProvider.notifier)
                                      .startScan(),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              '开始扫描',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: state.isScanning
                                ? () => ref
                                      .read(scanControllerProvider.notifier)
                                      .stopScan()
                                : null,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              '停止',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ERROR MESSAGE
            if (state.errorMessage != null) ...<Widget>[
              const SizedBox(height: 16),
              Card(
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => ref
                            .read(scanControllerProvider.notifier)
                            .clearError(),
                        icon: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            Text(
              '发现的设备',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),

            // EMPTY STATE
            if (state.devices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    state.isScanning ? '扫描中，请稍候...' : '暂无设备，请确保设备已开机并靠近手机',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ),
              ),

            // DEVICE LIST
            for (final device in state.devices) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.bluetooth,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.displayName,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '信号: ${device.rssi ?? '--'} dBm  •  协议: ${device.protocolKey}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.tonal(
                          onPressed: state.isConnecting
                              ? null
                              : () async {
                                  await ref
                                      .read(scanControllerProvider.notifier)
                                      .connect(device);
                                  final latestState = ref.read(
                                    scanControllerProvider,
                                  );
                                  if (context.mounted &&
                                      latestState.connectedDeviceId ==
                                          device.id) {
                                    context.push(
                                      '/control?returnTo=%2Fscan&returnLabel=%E8%BF%94%E5%9B%9E%E6%89%AB%E6%8F%8F%E9%A1%B5',
                                    );
                                  }
                                },
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            state.isConnecting &&
                                    state.connectedDeviceId == device.id
                                ? '连接中...'
                                : '连接',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 100), // Space for Emergency Stop bar
          ],
        ),
      ),
    );
  }
}

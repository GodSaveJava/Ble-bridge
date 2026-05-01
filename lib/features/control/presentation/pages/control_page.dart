import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../../domain/entities/device_status.dart';
import '../../../../shared/widgets/toylink_background.dart';
import '../controllers/control_panel_controller.dart';

class ControlPage extends ConsumerWidget {
  const ControlPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(controlPanelControllerProvider);
    final activeStatus = ref.watch(activeDeviceStatusStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('手动控制')),
      body: ToyLinkBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _StatusCard(activeStatus: activeStatus),
            const SizedBox(height: 16),
            _ChannelSlider(
              title: '吮吸强度',
              value: state.suck.toDouble(),
              max: 100,
              onChanged: state.isBusy
                  ? null
                  : (value) => ref
                        .read(controlPanelControllerProvider.notifier)
                        .setSuck(value.round()),
            ),
            const SizedBox(height: 16),
            _ChannelSlider(
              title: '震动强度',
              value: state.vibe.toDouble(),
              max: 100,
              onChanged: state.isBusy
                  ? null
                  : (value) => ref
                        .read(controlPanelControllerProvider.notifier)
                        .setVibe(value.round()),
            ),
            const SizedBox(height: 16),
            _ChannelSlider(
              title: '微电流强度',
              value: state.ems.toDouble(),
              max: 20,
              onChanged: state.isBusy
                  ? null
                  : (value) => ref
                        .read(controlPanelControllerProvider.notifier)
                        .setEms(value.round()),
            ),
            if (state.requiresEmsConfirmation) ...<Widget>[
              const SizedBox(height: 12),
              const Text(
                '当前微电流超过建议值，需要你在本机再次确认后才可执行。',
                style: TextStyle(color: Colors.orange),
              ),
            ],
            if (state.errorMessage != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
              TextButton(
                onPressed: () => ref
                    .read(controlPanelControllerProvider.notifier)
                    .clearError(),
                child: const Text('知道了'),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: state.isBusy
                  ? null
                  : () => ref
                        .read(controlPanelControllerProvider.notifier)
                        .stopAll(),
              child: Text(state.isBusy ? '执行中...' : '一键停止'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.activeStatus});

  final AsyncValue<DeviceStatus> activeStatus;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: activeStatus.when(
          data: (status) => Text(
            '设备：${status.deviceId}\n'
            '连接状态：${status.isConnected ? '已连接' : '未连接'}\n'
            '吮吸：${status.suckIntensity}  震动：${status.vibeIntensity}  微电流：${status.emsIntensity}',
          ),
          error: (error, stackTrace) => const Text('设备状态暂时不可用'),
          loading: () => const Text('正在读取设备状态...'),
        ),
      ),
    );
  }
}

class _ChannelSlider extends StatelessWidget {
  const _ChannelSlider({
    required this.title,
    required this.value,
    required this.max,
    this.onChanged,
  });

  final String title;
  final double value;
  final double max;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('$title：${value.round()}'),
            Slider(
              min: 0,
              max: max,
              value: value.clamp(0, max),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

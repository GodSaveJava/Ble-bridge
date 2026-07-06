import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../../domain/entities/device_status.dart';
import '../../../../shared/widgets/toylink_background.dart';
import '../controllers/control_panel_controller.dart';

class ControlPage extends ConsumerWidget {
  const ControlPage({super.key, this.returnPath, this.returnLabel});

  final String? returnPath;
  final String? returnLabel;

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(returnPath ?? '/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(controlPanelControllerProvider);
    final activeStatus = ref.watch(activeDeviceStatusStreamProvider);
    final String resolvedReturnLabel = returnLabel ?? '返回首页';

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        context.go(returnPath ?? '/home');
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBack(context),
          ),
          title: const Text(
            '手动控制',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: ToyLinkBackground(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: <Widget>[
              // BACK NAVIGATION CARD
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '当前页面支持直接返回',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _handleBack(context),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: Text(resolvedReturnLabel),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _StatusCard(activeStatus: activeStatus),

              const SizedBox(height: 24),
              Text(
                '控制面板',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),

              _ChannelSlider(
                title: '吮吸强度 (Suction)',
                value: state.suck.toDouble(),
                max: 100,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: state.isBusy
                    ? null
                    : (value) => ref
                          .read(controlPanelControllerProvider.notifier)
                          .setSuck(value.round()),
              ),
              const SizedBox(height: 16),

              _ChannelSlider(
                title: '震动强度 (Vibration)',
                value: state.vibe.toDouble(),
                max: 100,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: state.isBusy
                    ? null
                    : (value) => ref
                          .read(controlPanelControllerProvider.notifier)
                          .setVibe(value.round()),
              ),
              const SizedBox(height: 16),

              _ChannelSlider(
                title: '微电流强度 (EMS)',
                value: state.ems.toDouble(),
                max: 20,
                activeColor: Colors
                    .orange[400]!, // Distinguish EMS with a warmer/warning color
                onChanged: state.isBusy
                    ? null
                    : (value) => ref
                          .read(controlPanelControllerProvider.notifier)
                          .setEms(value.round()),
              ),

              // EMS WARNING
              if (state.requiresEmsConfirmation) ...<Widget>[
                const SizedBox(height: 16),
                Card(
                  color: Colors.orange.withValues(alpha: 0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.orange.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '微电流安全警告',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.orange[800],
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '当前微电流 (EMS) 设定值超过了建议的安全软限制，需要您在本机再次确认后才可执行此操作。',
                          style: TextStyle(
                            color: Colors.orange[900],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // GENERAL ERROR
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
                        TextButton(
                          onPressed: () => ref
                              .read(controlPanelControllerProvider.notifier)
                              .clearError(),
                          child: const Text('知道了'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(
                height: 120,
              ), // Extra space for Global AppShell Emergency Stop
            ],
          ),
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
        padding: const EdgeInsets.all(24),
        child: activeStatus.when(
          data: (status) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: status.isConnected ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    status.isConnected ? '设备已连接' : '设备未连接',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'ID: ${status.deviceId}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatusItem(
                      label: '吮吸',
                      value: status.suckIntensity.toString(),
                    ),
                    _StatusItem(
                      label: '震动',
                      value: status.vibeIntensity.toString(),
                    ),
                    _StatusItem(
                      label: 'EMS',
                      value: status.emsIntensity.toString(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          error: (error, stackTrace) => const Text('设备状态暂时不可用'),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ],
    );
  }
}

class _ChannelSlider extends StatelessWidget {
  const _ChannelSlider({
    required this.title,
    required this.value,
    required this.max,
    required this.activeColor,
    this.onChanged,
  });

  final String title;
  final double value;
  final double max;
  final Color activeColor;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    value.round().toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: activeColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 12, // Thick track
                activeTrackColor: activeColor,
                inactiveTrackColor: activeColor.withValues(alpha: 0.2),
                thumbColor: activeColor,
                overlayColor: activeColor.withValues(alpha: 0.1),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
              ),
              child: Slider(
                min: 0,
                max: max,
                value: value.clamp(0, max),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../../domain/entities/device_status.dart';
import '../controllers/control_panel_controller.dart';

class ControlPage extends ConsumerWidget {
  const ControlPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(controlPanelControllerProvider);
    final activeStatus = ref.watch(activeDeviceStatusStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manual Control')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _StatusCard(activeStatus: activeStatus),
          const SizedBox(height: 16),
          _ChannelSlider(
            title: 'Suck',
            value: state.suck.toDouble(),
            max: 100,
            onChanged: state.isBusy
                ? null
                : (double value) => ref
                      .read(controlPanelControllerProvider.notifier)
                      .setSuck(value.round()),
          ),
          const SizedBox(height: 16),
          _ChannelSlider(
            title: 'Vibe',
            value: state.vibe.toDouble(),
            max: 100,
            onChanged: state.isBusy
                ? null
                : (double value) => ref
                      .read(controlPanelControllerProvider.notifier)
                      .setVibe(value.round()),
          ),
          const SizedBox(height: 16),
          _ChannelSlider(
            title: 'EMS',
            value: state.ems.toDouble(),
            max: 20,
            onChanged: state.isBusy
                ? null
                : (double value) => ref
                      .read(controlPanelControllerProvider.notifier)
                      .setEms(value.round()),
          ),
          if (state.requiresEmsConfirmation) ...<Widget>[
            const SizedBox(height: 12),
            const Text(
              'EMS above soft limit requires explicit confirmation.',
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
              child: const Text('Dismiss'),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: state.isBusy
                ? null
                : () => ref
                      .read(controlPanelControllerProvider.notifier)
                      .stopAll(),
            child: Text(state.isBusy ? 'Working...' : 'Stop All'),
          ),
        ],
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
          data: (status) {
            return Text(
              'Device: ${status.deviceId}\n'
              'Connected: ${status.isConnected}\n'
              'Suck: ${status.suckIntensity}  '
              'Vibe: ${status.vibeIntensity}  '
              'EMS: ${status.emsIntensity}',
            );
          },
          error: (Object error, StackTrace stackTrace) =>
              const Text('Status stream unavailable'),
          loading: () => const Text('Waiting for device status...'),
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
            Text('$title: ${value.round()}'),
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

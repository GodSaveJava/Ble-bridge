import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/application_providers.dart';
import '../error/failure.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          _buildEmergencyStopBar(context, ref),
        ],
      ),
    );
  }

  Widget _buildEmergencyStopBar(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: InkWell(
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          try {
            await ref.read(controlDeviceUseCaseProvider).stopAll();
            if (!context.mounted) {
              return;
            }
            messenger.showSnackBar(
              const SnackBar(content: Text('All device output stopped')),
            );
          } on Failure catch (failure) {
            if (!context.mounted) {
              return;
            }
            messenger.showSnackBar(
              SnackBar(content: Text('Stop failed: ${failure.message}')),
            );
          } catch (_) {
            if (!context.mounted) {
              return;
            }
            messenger.showSnackBar(
              const SnackBar(content: Text('Stop failed. Please try again.')),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.error.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: const Center(
            child: Text(
              'EMERGENCY STOP ALL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          _buildEmergencyStopBar(context),
        ],
      ),
    );
  }

  Widget _buildEmergencyStopBar(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      color: theme.scaffoldBackgroundColor, // Blend with background
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: InkWell(
        onTap: () {
          // TODO: Dispatch global StopAll command
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Emergency Stop Triggered')),
          );
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

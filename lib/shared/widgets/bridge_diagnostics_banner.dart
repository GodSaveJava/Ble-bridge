import 'package:flutter/material.dart';

import '../../features/mcp_server/presentation/controllers/remote_bridge_diagnostics_controller.dart';

class BridgeDiagnosticsBanner extends StatelessWidget {
  const BridgeDiagnosticsBanner({
    super.key,
    required this.diagnostics,
    required this.onActionPressed,
  });

  final RemoteBridgeDiagnostics diagnostics;
  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isWarning =
        diagnostics.action != null || diagnostics.title.contains('失败');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWarning
            ? colorScheme.errorContainer.withValues(alpha: 0.82)
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            diagnostics.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isWarning
                  ? colorScheme.onErrorContainer
                  : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            diagnostics.summary,
            style: TextStyle(
              color: isWarning
                  ? colorScheme.onErrorContainer
                  : colorScheme.onSurface,
            ),
          ),
          if (diagnostics.lastSyncLabel case final String label) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isWarning
                    ? colorScheme.onErrorContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (diagnostics.actionLabel != null &&
              diagnostics.action != null) ...<Widget>[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onActionPressed,
              child: Text(diagnostics.actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

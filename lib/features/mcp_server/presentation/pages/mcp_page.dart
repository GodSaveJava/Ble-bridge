import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/mcp_service_controller.dart';

class McpPage extends ConsumerWidget {
  const McpPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final McpServiceState state = ref.watch(mcpServiceControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('MCP 服务')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    state.isRunning ? '状态: 运行中' : '状态: 已停止',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.endpointInfo == null
                        ? 'Endpoint: -'
                        : 'Endpoint: http://${state.endpointInfo!.host}:${state.endpointInfo!.port}${state.endpointInfo!.path}',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      FilledButton(
                        onPressed: state.isBusy || state.isRunning
                            ? null
                            : () => ref
                                  .read(mcpServiceControllerProvider.notifier)
                                  .start(),
                        child: const Text('启动'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: state.isBusy || !state.isRunning
                            ? null
                            : () => ref
                                  .read(mcpServiceControllerProvider.notifier)
                                  .stop(),
                        child: const Text('停止'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (state.errorMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                title: Text(
                  state.errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                trailing: TextButton(
                  onPressed: () => ref
                      .read(mcpServiceControllerProvider.notifier)
                      .clearError(),
                  child: const Text('关闭'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

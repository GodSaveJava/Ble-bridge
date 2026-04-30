import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../mcp_server/presentation/controllers/mcp_service_controller.dart';
import '../controllers/chat_session_controller.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  late final TextEditingController _inputController;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ChatSessionState state = ref.watch(chatSessionControllerProvider);
    final mcpState = ref.watch(mcpServiceControllerProvider);
    final activeStatus = ref.watch(activeDeviceStatusStreamProvider);

    final bool hasActiveDevice = activeStatus.maybeWhen(
      data: (status) => status.isConnected,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Chat Shell')),
      body: Column(
        children: <Widget>[
          _ChatHeader(
            mcpRunning: mcpState.isRunning,
            hasActiveDevice: hasActiveDevice,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.messages.length,
              itemBuilder: (context, index) {
                final ChatMessage msg = state.messages[index];
                return _MessageCard(message: msg);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    onChanged: ref
                        .read(chatSessionControllerProvider.notifier)
                        .updateDraft,
                    controller: _inputController,
                    decoration: const InputDecoration(
                      hintText: '输入消息（本地壳层，不连接真实模型）',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    ref
                        .read(chatSessionControllerProvider.notifier)
                        .sendUserMessage();
                    _inputController.clear();
                  },
                  child: const Text('发送'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed: () => ref
                      .read(chatSessionControllerProvider.notifier)
                      .addToolEvent(
                        toolName: 'get_status',
                        payload: <String, Object?>{},
                        accepted: hasActiveDevice,
                      ),
                  child: const Text('记录 get_status'),
                ),
                OutlinedButton(
                  onPressed: () => ref
                      .read(chatSessionControllerProvider.notifier)
                      .addToolEvent(
                        toolName: 'set_ems',
                        payload: <String, Object?>{'intensity': 9, 'mode': 1},
                        accepted: false,
                      ),
                  child: const Text('记录 set_ems(9)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.mcpRunning, required this.hasActiveDevice});

  final bool mcpRunning;
  final bool hasActiveDevice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        'MCP: ${mcpRunning ? 'Running' : 'Stopped'} | Device: ${hasActiveDevice ? 'Connected' : 'Not Connected'}',
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final Color tint = switch (message.role) {
      ChatMessageRole.user => Colors.blueGrey,
      ChatMessageRole.assistant => Colors.teal,
      ChatMessageRole.system => Colors.deepPurple,
      ChatMessageRole.toolEvent => Colors.orange,
    };

    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: tint, radius: 8),
        title: Text(message.content),
        subtitle: Text(
          '${message.role.name} · ${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}

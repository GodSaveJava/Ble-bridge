import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../../shared/widgets/toylink_background.dart';
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
    final state = ref.watch(chatSessionControllerProvider);
    final mcpState = ref.watch(mcpServiceControllerProvider);
    final activeStatus = ref.watch(activeDeviceStatusStreamProvider);

    final hasActiveDevice = activeStatus.maybeWhen(
      data: (status) => status.isConnected,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('智能聊天')),
      body: ToyLinkBackground(
        child: Column(
          children: <Widget>[
            _ChatHeader(
              mcpRunning: mcpState.isRunning,
              hasActiveDevice: hasActiveDevice,
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: state.messages.length,
                itemBuilder: (context, index) =>
                    _MessageCard(message: state.messages[index]),
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
                      decoration: const InputDecoration(hintText: '请输入你想说的话'),
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
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Text(
        'MCP：${mcpRunning ? '运行中' : '未启动'} | 设备：${hasActiveDevice ? '已连接' : '未连接'}',
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
      ChatMessageRole.user => Colors.pink.shade200,
      ChatMessageRole.assistant => Colors.pink.shade400,
      ChatMessageRole.system => Colors.deepPurple.shade300,
      ChatMessageRole.toolEvent => Colors.orange.shade400,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../../domain/services/mcp_service.dart';

enum ChatMessageRole { user, assistant, system, toolEvent }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  final String id;
  final ChatMessageRole role;
  final String content;
  final DateTime timestamp;
}

class ChatSessionState {
  const ChatSessionState({
    this.messages = const <ChatMessage>[],
    this.inputDraft = '',
  });

  final List<ChatMessage> messages;
  final String inputDraft;

  ChatSessionState copyWith({List<ChatMessage>? messages, String? inputDraft}) {
    return ChatSessionState(
      messages: messages ?? this.messages,
      inputDraft: inputDraft ?? this.inputDraft,
    );
  }
}

class ChatSessionController extends Notifier<ChatSessionState> {
  int _sequence = 0;

  @override
  ChatSessionState build() {
    return ChatSessionState(
      messages: <ChatMessage>[
        _message(
          role: ChatMessageRole.system,
          content: '聊天功能已就绪。当前为本地演示模式，暂未接入真实大模型。',
        ),
      ],
    );
  }

  void updateDraft(String value) {
    state = state.copyWith(inputDraft: value);
  }

  void sendUserMessage() {
    final text = state.inputDraft.trim();
    if (text.isEmpty) {
      return;
    }

    final updated = <ChatMessage>[
      ...state.messages,
      _message(role: ChatMessageRole.user, content: text),
      _message(role: ChatMessageRole.assistant, content: '收到：$text'),
    ];
    state = state.copyWith(messages: updated, inputDraft: '');
  }

  void addToolEvent({
    required String toolName,
    required Map<String, Object?> payload,
    required bool accepted,
  }) {
    final McpEndpointInfo? endpoint = ref.read(mcpServiceProvider).endpointInfo;
    final endpointText = endpoint == null
        ? 'MCP 未启动'
        : '${endpoint.host}:${endpoint.port}${endpoint.path}';

    final event = _message(
      role: ChatMessageRole.toolEvent,
      content:
          '工具：$toolName | 是否执行：${accepted ? '是' : '否'} | 服务：$endpointText | 参数：$payload',
    );
    state = state.copyWith(messages: <ChatMessage>[...state.messages, event]);
  }

  ChatMessage _message({
    required ChatMessageRole role,
    required String content,
  }) {
    _sequence += 1;
    return ChatMessage(
      id: 'msg_$_sequence',
      role: role,
      content: content,
      timestamp: DateTime.now(),
    );
  }
}

final chatSessionControllerProvider =
    NotifierProvider<ChatSessionController, ChatSessionState>(
      ChatSessionController.new,
    );

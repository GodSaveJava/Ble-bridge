import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/features/chat/presentation/controllers/chat_session_controller.dart';
import 'package:toylink_ai/infrastructure/mock/mock_mcp_service.dart';

void main() {
  group('ChatSessionController', () {
    test('appends user and assistant messages when sending input', () {
      final container = ProviderContainer(
        overrides: [mcpServiceProvider.overrideWith((_) => MockMcpService())],
      );
      addTearDown(container.dispose);

      final controller = container.read(chatSessionControllerProvider.notifier);
      controller.updateDraft('hello');
      controller.sendUserMessage();

      final state = container.read(chatSessionControllerProvider);
      expect(state.messages.length, 3);
      expect(state.messages[1].role, ChatMessageRole.user);
      expect(state.messages[1].content, 'hello');
      expect(state.messages[2].role, ChatMessageRole.assistant);
    });

    test('records tool events with payload', () {
      final container = ProviderContainer(
        overrides: [mcpServiceProvider.overrideWith((_) => MockMcpService())],
      );
      addTearDown(container.dispose);

      final controller = container.read(chatSessionControllerProvider.notifier);
      controller.addToolEvent(
        toolName: 'get_status',
        payload: <String, Object?>{},
        accepted: true,
      );

      final state = container.read(chatSessionControllerProvider);
      expect(state.messages.last.role, ChatMessageRole.toolEvent);
      expect(state.messages.last.content, contains('Tool=get_status'));
    });
  });
}

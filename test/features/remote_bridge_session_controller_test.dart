import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/application/bridge/remote_bridge_task_assignment_handler.dart';
import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/application/use_cases/process_next_remote_bridge_task_use_case.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_session.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_assignment.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_result.dart';
import 'package:toylink_ai/domain/services/remote_bridge_service.dart';
import 'package:toylink_ai/features/mcp_server/presentation/controllers/remote_bridge_session_controller.dart';
import 'package:toylink_ai/infrastructure/mock/mock_remote_bridge_service.dart';

void main() {
  group('RemoteBridgeSessionController', () {
    test('starts from offline state', () {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          remoteBridgeServiceProvider.overrideWith(
            (_) => MockRemoteBridgeService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final RemoteBridgeSessionState state = container.read(
        remoteBridgeSessionControllerProvider,
      );
      expect(state.status, RemoteBridgeSessionStatus.offline);
      expect(state.canOnboardClaude, isFalse);
    });

    test('becomes ready and onboardable after starting a session', () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          remoteBridgeServiceProvider.overrideWith(
            (_) => MockRemoteBridgeService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(remoteBridgeSessionControllerProvider.notifier)
          .startSession();

      final RemoteBridgeSessionState state = container.read(
        remoteBridgeSessionControllerProvider,
      );
      expect(state.status, RemoteBridgeSessionStatus.ready);
      expect(state.canOnboardClaude, isTrue);
      expect(state.connectorUrl, startsWith('https://'));
      expect(state.connectorToken, isNotEmpty);
    });

    test('surfaces a friendly error when bridge session start fails', () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          remoteBridgeServiceProvider.overrideWith((_) => _FailingBridgeService()),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(remoteBridgeSessionControllerProvider.notifier)
          .startSession();

      final RemoteBridgeSessionState state = container.read(
        remoteBridgeSessionControllerProvider,
      );
      expect(state.status, RemoteBridgeSessionStatus.error);
      expect(state.errorMessage, contains('桥接'));
    });

    test('consumeNextTask surfaces empty queue feedback', () async {
      final _TaskQueueBridgeService bridgeService = _TaskQueueBridgeService();
      final ProviderContainer container = ProviderContainer(
        overrides: [
          remoteBridgeServiceProvider.overrideWith((_) => bridgeService),
          processNextRemoteBridgeTaskUseCaseProvider.overrideWith(
            (_) => _testProcessUseCase(bridgeService),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(remoteBridgeSessionControllerProvider.notifier)
          .consumeNextTask();

      final RemoteBridgeSessionState state = container.read(
        remoteBridgeSessionControllerProvider,
      );
      expect(state.isConsumingTask, isFalse);
      expect(state.taskFeedbackMessage, contains('没有'));
    });

    test('consumeNextTask surfaces handled task feedback', () async {
      final _TaskQueueBridgeService bridgeService = _TaskQueueBridgeService(
        pendingTask: const RemoteBridgeTaskAssignment(
          requestId: 'bridge-task-7',
          tool: 'get_status',
        ),
      );
      final ProviderContainer container = ProviderContainer(
        overrides: [
          remoteBridgeServiceProvider.overrideWith((_) => bridgeService),
          processNextRemoteBridgeTaskUseCaseProvider.overrideWith(
            (_) => _testProcessUseCase(bridgeService),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(remoteBridgeSessionControllerProvider.notifier)
          .consumeNextTask();

      final RemoteBridgeSessionState state = container.read(
        remoteBridgeSessionControllerProvider,
      );
      expect(state.lastTaskResult?.requestId, 'bridge-task-7');
      expect(state.taskFeedbackMessage, contains('get_status'));
    });

    test('auto consume fetches ready task after enabling loop', () async {
      final _TaskQueueBridgeService bridgeService = _TaskQueueBridgeService(
        pendingTask: const RemoteBridgeTaskAssignment(
          requestId: 'bridge-task-auto-1',
          tool: 'stop_all',
        ),
      );
      final ProviderContainer container = ProviderContainer(
        overrides: [
          remoteBridgeServiceProvider.overrideWith((_) => bridgeService),
          processNextRemoteBridgeTaskUseCaseProvider.overrideWith(
            (_) => _testProcessUseCase(bridgeService),
          ),
          remoteBridgeAutoConsumeIntervalProvider.overrideWith(
            (_) => const Duration(milliseconds: 20),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(remoteBridgeSessionControllerProvider.notifier)
          .setAutoConsumeEnabled(true);
      await Future<void>.delayed(const Duration(milliseconds: 60));

      final RemoteBridgeSessionState state = container.read(
        remoteBridgeSessionControllerProvider,
      );
      expect(state.isAutoConsumeEnabled, isTrue);
      expect(state.lastTaskResult?.requestId, 'bridge-task-auto-1');
      expect(state.taskFeedbackMessage, contains('已自动处理远程任务'));
    });
  });
}

ProcessNextRemoteBridgeTaskUseCase _testProcessUseCase(
  RemoteBridgeService bridgeService,
) {
  return ProcessNextRemoteBridgeTaskUseCase(
    remoteBridgeService: bridgeService,
    assignmentHandler: RemoteBridgeTaskAssignmentHandler(
      consumeTask: ({
        String? requestId,
        required String tool,
        Map<String, Object?> input = const <String, Object?>{},
      }) async {
        return RemoteBridgeTaskResult(
          ok: true,
          requestId: requestId,
          tool: tool,
          result: tool == 'get_status'
              ? const <String, Object?>{'deviceId': 'mock-sosexy-001'}
              : const <String, Object?>{'stopped': true},
        );
      },
    ),
  );
}

class _FailingBridgeService implements RemoteBridgeService {
  RemoteBridgeSession _session = const RemoteBridgeSession(
    status: RemoteBridgeSessionStatus.offline,
  );

  @override
  RemoteBridgeSession get currentSession => _session;

  @override
  void dispose() {}

  @override
  Future<RemoteBridgeTaskAssignment?> fetchNextTask() async => null;

  @override
  Future<void> reportTaskResult(RemoteBridgeTaskResult result) async {}

  @override
  Future<void> refreshConnector() async {}

  @override
  Future<void> startSession() async {
    _session = const RemoteBridgeSession(
      status: RemoteBridgeSessionStatus.error,
      lastErrorCode: 'bridge_start_failed',
      lastErrorMessage: 'bridge start failed',
    );
    throw StateError('bridge start failed');
  }

  @override
  Future<void> stopSession() async {
    _session = const RemoteBridgeSession(
      status: RemoteBridgeSessionStatus.offline,
    );
  }

  @override
  Stream<RemoteBridgeSession> watchSession() async* {
    yield _session;
  }
}

class _TaskQueueBridgeService implements RemoteBridgeService {
  _TaskQueueBridgeService({this.pendingTask});

  RemoteBridgeTaskAssignment? pendingTask;

  @override
  RemoteBridgeSession get currentSession => const RemoteBridgeSession(
    status: RemoteBridgeSessionStatus.ready,
    bridgeSessionId: 'bridge-session-test',
    connectorInfo: RemoteBridgeConnectorInfo(
      connectorUrl: 'https://bridge.toylink.local/mcp/claude',
      connectorToken: 'toy-connector-token',
      toolNames: <String>['get_status', 'stop_all'],
    ),
  );

  @override
  void dispose() {}

  @override
  Future<RemoteBridgeTaskAssignment?> fetchNextTask() async {
    final RemoteBridgeTaskAssignment? next = pendingTask;
    pendingTask = null;
    return next;
  }

  @override
  Future<void> reportTaskResult(RemoteBridgeTaskResult result) async {}

  @override
  Future<void> refreshConnector() async {}

  @override
  Future<void> startSession() async {}

  @override
  Future<void> stopSession() async {}

  @override
  Stream<RemoteBridgeSession> watchSession() async* {
    yield currentSession;
  }
}

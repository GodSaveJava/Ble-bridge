import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../../domain/entities/remote_bridge_session.dart';
import '../../../../domain/entities/remote_bridge_task_result.dart';

class RemoteBridgeSessionState {
  const RemoteBridgeSessionState({
    required this.status,
    this.bridgeSessionId,
    this.connectorUrl,
    this.connectorToken,
    this.maskedToken,
    this.toolNames = const <String>[],
    this.errorCode,
    this.errorMessage,
    this.lastUpdatedAt,
    this.isConsumingTask = false,
    this.lastTaskResult,
    this.taskFeedbackMessage,
  });

  factory RemoteBridgeSessionState.fromSession(RemoteBridgeSession session) {
    return RemoteBridgeSessionState(
      status: session.status,
      bridgeSessionId: session.bridgeSessionId,
      connectorUrl: session.connectorInfo?.connectorUrl,
      connectorToken: session.connectorInfo?.connectorToken,
      maskedToken: session.connectorInfo?.maskedToken,
      toolNames: session.connectorInfo?.toolNames ?? const <String>[],
      errorCode: session.lastErrorCode,
      errorMessage: session.lastErrorMessage,
      lastUpdatedAt: session.lastUpdatedAt,
    );
  }

  final RemoteBridgeSessionStatus status;
  final String? bridgeSessionId;
  final String? connectorUrl;
  final String? connectorToken;
  final String? maskedToken;
  final List<String> toolNames;
  final String? errorCode;
  final String? errorMessage;
  final DateTime? lastUpdatedAt;
  final bool isConsumingTask;
  final RemoteBridgeTaskResult? lastTaskResult;
  final String? taskFeedbackMessage;

  bool get isBusy =>
      status == RemoteBridgeSessionStatus.connecting ||
      status == RemoteBridgeSessionStatus.busy;

  bool get canOnboardClaude =>
      status == RemoteBridgeSessionStatus.ready &&
      connectorUrl != null &&
      connectorUrl!.isNotEmpty &&
      connectorToken != null &&
      connectorToken!.isNotEmpty;

  RemoteBridgeSessionState copyWith({
    RemoteBridgeSessionStatus? status,
    String? bridgeSessionId,
    String? connectorUrl,
    String? connectorToken,
    String? maskedToken,
    List<String>? toolNames,
    String? errorCode,
    String? errorMessage,
    DateTime? lastUpdatedAt,
    bool? isConsumingTask,
    RemoteBridgeTaskResult? lastTaskResult,
    String? taskFeedbackMessage,
    bool clearError = false,
    bool clearTaskFeedback = false,
  }) {
    return RemoteBridgeSessionState(
      status: status ?? this.status,
      bridgeSessionId: bridgeSessionId ?? this.bridgeSessionId,
      connectorUrl: connectorUrl ?? this.connectorUrl,
      connectorToken: connectorToken ?? this.connectorToken,
      maskedToken: maskedToken ?? this.maskedToken,
      toolNames: toolNames ?? this.toolNames,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isConsumingTask: isConsumingTask ?? this.isConsumingTask,
      lastTaskResult: clearTaskFeedback
          ? null
          : (lastTaskResult ?? this.lastTaskResult),
      taskFeedbackMessage: clearTaskFeedback
          ? null
          : (taskFeedbackMessage ?? this.taskFeedbackMessage),
    );
  }
}

class RemoteBridgeSessionController extends Notifier<RemoteBridgeSessionState> {
  StreamSubscription<RemoteBridgeSession>? _subscription;

  @override
  RemoteBridgeSessionState build() {
    final useCase = ref.watch(manageRemoteBridgeSessionUseCaseProvider);
    _subscription?.cancel();
    _subscription = useCase.watchSession().listen((RemoteBridgeSession session) {
      state = _mergeSession(session);
    });
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return RemoteBridgeSessionState.fromSession(useCase.currentSession);
  }

  Future<void> startSession() async {
    try {
      final useCase = ref.read(manageRemoteBridgeSessionUseCaseProvider);
      await useCase.startSession();
      state = _mergeSession(useCase.currentSession);
    } catch (_) {
      state = state.copyWith(
        status: RemoteBridgeSessionStatus.error,
        errorCode: 'bridge_start_failed',
        errorMessage: '桥接会话启动失败，请稍后重试。',
      );
    }
  }

  Future<void> stopSession() async {
    try {
      final useCase = ref.read(manageRemoteBridgeSessionUseCaseProvider);
      await useCase.stopSession();
      state = _mergeSession(useCase.currentSession);
    } catch (_) {
      state = state.copyWith(
        status: RemoteBridgeSessionStatus.error,
        errorCode: 'bridge_stop_failed',
        errorMessage: '桥接会话停止失败，请稍后重试。',
      );
    }
  }

  Future<void> refreshConnector() async {
    try {
      final useCase = ref.read(manageRemoteBridgeSessionUseCaseProvider);
      await useCase.refreshConnector();
      state = _mergeSession(useCase.currentSession);
    } catch (_) {
      state = state.copyWith(
        status: RemoteBridgeSessionStatus.error,
        errorCode: 'bridge_refresh_failed',
        errorMessage: '接入信息刷新失败，请稍后重试。',
      );
    }
  }

  Future<void> consumeNextTask() async {
    state = state.copyWith(
      isConsumingTask: true,
      clearTaskFeedback: true,
    );

    try {
      final RemoteBridgeTaskResult? result = await ref
          .read(processNextRemoteBridgeTaskUseCaseProvider)
          .processNextTask();

      if (result == null) {
        state = state.copyWith(
          isConsumingTask: false,
          taskFeedbackMessage: '当前没有待处理的远程任务。',
        );
        return;
      }

      state = state.copyWith(
        isConsumingTask: false,
        lastTaskResult: result,
        taskFeedbackMessage: result.ok
            ? '已处理远程任务：${result.tool ?? 'unknown'}'
            : (result.errorMessage ?? '远程任务处理失败。'),
      );
    } catch (_) {
      state = state.copyWith(
        isConsumingTask: false,
        taskFeedbackMessage: '手动拉取远程任务失败，请稍后重试。',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  RemoteBridgeSessionState _mergeSession(RemoteBridgeSession session) {
    return RemoteBridgeSessionState.fromSession(session).copyWith(
      isConsumingTask: state.isConsumingTask,
      lastTaskResult: state.lastTaskResult,
      taskFeedbackMessage: state.taskFeedbackMessage,
    );
  }
}

final remoteBridgeSessionControllerProvider = NotifierProvider<
  RemoteBridgeSessionController,
  RemoteBridgeSessionState
>(RemoteBridgeSessionController.new);

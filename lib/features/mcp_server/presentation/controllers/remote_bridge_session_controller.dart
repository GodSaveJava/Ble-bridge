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
    this.isAutoConsumeEnabled = false,
    this.lastTaskResult,
    this.taskFeedbackMessage,
    this.connectorCardCopiedAt,
    this.connectorVerifiedAt,
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
  final bool isAutoConsumeEnabled;
  final RemoteBridgeTaskResult? lastTaskResult;
  final String? taskFeedbackMessage;
  final DateTime? connectorCardCopiedAt;
  final DateTime? connectorVerifiedAt;

  bool get isBusy =>
      status == RemoteBridgeSessionStatus.connecting ||
      status == RemoteBridgeSessionStatus.busy;

  bool get canOnboardClaude =>
      status == RemoteBridgeSessionStatus.ready &&
      connectorUrl != null &&
      connectorUrl!.isNotEmpty &&
      connectorToken != null &&
      connectorToken!.isNotEmpty;

  bool get isConnectorVerificationWaiting =>
      connectorCardCopiedAt != null && connectorVerifiedAt == null;

  bool get isConnectorVerified => connectorVerifiedAt != null;

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
    bool? isAutoConsumeEnabled,
    RemoteBridgeTaskResult? lastTaskResult,
    String? taskFeedbackMessage,
    DateTime? connectorCardCopiedAt,
    DateTime? connectorVerifiedAt,
    bool clearError = false,
    bool clearTaskFeedback = false,
    bool clearConnectorVerification = false,
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
      isAutoConsumeEnabled: isAutoConsumeEnabled ?? this.isAutoConsumeEnabled,
      lastTaskResult: clearTaskFeedback
          ? null
          : (lastTaskResult ?? this.lastTaskResult),
      taskFeedbackMessage: clearTaskFeedback
          ? null
          : (taskFeedbackMessage ?? this.taskFeedbackMessage),
      connectorCardCopiedAt: clearConnectorVerification
          ? null
          : (connectorCardCopiedAt ?? this.connectorCardCopiedAt),
      connectorVerifiedAt: clearConnectorVerification
          ? null
          : (connectorVerifiedAt ?? this.connectorVerifiedAt),
    );
  }
}

class RemoteBridgeSessionController extends Notifier<RemoteBridgeSessionState> {
  StreamSubscription<RemoteBridgeSession>? _subscription;
  bool _autoConsumePreferenceLoaded = false;

  @override
  RemoteBridgeSessionState build() {
    final useCase = ref.watch(manageRemoteBridgeSessionUseCaseProvider);
    _subscription?.cancel();
    _subscription = useCase.watchSession().listen((
      RemoteBridgeSession session,
    ) {
      state = _mergeSession(session);
    });
    ref.onDispose(() {
      _subscription?.cancel();
    });
    _loadAutoConsumePreferenceOnce();
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
    await _consumeNextTask(
      surfaceEmptyQueueFeedback: true,
      failureMessage: '手动拉取远程任务失败，请稍后重试。',
      successPrefix: '已处理远程任务：',
    );
  }

  Future<void> consumeNextTaskSilently() async {
    await _consumeNextTask(
      surfaceEmptyQueueFeedback: false,
      failureMessage: '自动拉取远程任务失败，请稍后重试。',
      successPrefix: '已自动处理远程任务：',
    );
  }

  Future<void> setAutoConsumeEnabled(bool enabled) async {
    try {
      await ref
          .read(manageRemoteBridgeAutoConsumeUseCaseProvider)
          .saveEnabled(enabled);
      state = state.copyWith(
        isAutoConsumeEnabled: enabled,
        taskFeedbackMessage: enabled ? '已开启自动拉取远程任务。' : '已关闭自动拉取远程任务。',
        lastTaskResult: enabled ? state.lastTaskResult : null,
      );
    } catch (_) {
      state = state.copyWith(
        taskFeedbackMessage: enabled ? '自动拉取启用失败，请稍后重试。' : '自动拉取关闭失败，请稍后重试。',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void markConnectorCardCopied() {
    state = state.copyWith(
      connectorCardCopiedAt: DateTime.now(),
      taskFeedbackMessage: state.isConnectorVerified
          ? state.taskFeedbackMessage
          : '连接卡片已复制，等待 AI 调用 get_status。',
    );
  }

  Future<void> _consumeNextTask({
    required bool surfaceEmptyQueueFeedback,
    required String failureMessage,
    required String successPrefix,
  }) async {
    if (state.isConsumingTask ||
        state.status != RemoteBridgeSessionStatus.ready) {
      return;
    }

    state = state.copyWith(
      isConsumingTask: true,
      clearTaskFeedback: surfaceEmptyQueueFeedback,
    );

    try {
      final RemoteBridgeTaskResult? result = await ref
          .read(processNextRemoteBridgeTaskUseCaseProvider)
          .processNextTask();

      if (result == null) {
        state = state.copyWith(
          isConsumingTask: false,
          taskFeedbackMessage: surfaceEmptyQueueFeedback
              ? '当前没有待处理的远程任务。'
              : state.taskFeedbackMessage,
        );
        return;
      }

      final bool verifiesConnector = result.ok && result.tool == 'get_status';
      state = state.copyWith(
        isConsumingTask: false,
        lastTaskResult: result,
        connectorVerifiedAt: verifiesConnector ? DateTime.now() : null,
        taskFeedbackMessage: result.ok
            ? '$successPrefix${result.tool ?? 'unknown'}'
            : (result.errorMessage ?? '远程任务处理失败。'),
      );
    } catch (_) {
      state = state.copyWith(
        isConsumingTask: false,
        taskFeedbackMessage: failureMessage,
      );
    }
  }

  RemoteBridgeSessionState _mergeSession(RemoteBridgeSession session) {
    final RemoteBridgeSessionState next = RemoteBridgeSessionState.fromSession(
      session,
    );
    final bool sameConnector =
        next.connectorUrl == state.connectorUrl &&
        next.connectorToken == state.connectorToken;
    return next.copyWith(
      isConsumingTask: state.isConsumingTask,
      isAutoConsumeEnabled: state.isAutoConsumeEnabled,
      lastTaskResult: state.lastTaskResult,
      taskFeedbackMessage: state.taskFeedbackMessage,
      connectorCardCopiedAt: sameConnector ? state.connectorCardCopiedAt : null,
      connectorVerifiedAt: sameConnector ? state.connectorVerifiedAt : null,
      clearConnectorVerification: !sameConnector,
    );
  }

  void _loadAutoConsumePreferenceOnce() {
    if (_autoConsumePreferenceLoaded) {
      return;
    }
    _autoConsumePreferenceLoaded = true;
    unawaited(_hydrateAutoConsumePreference());
  }

  Future<void> _hydrateAutoConsumePreference() async {
    try {
      final bool enabled = await ref
          .read(manageRemoteBridgeAutoConsumeUseCaseProvider)
          .loadEnabled();
      if (!ref.mounted || state.isAutoConsumeEnabled == enabled) {
        return;
      }
      if (state.isAutoConsumeEnabled && !enabled) {
        return;
      }
      state = state.copyWith(
        isAutoConsumeEnabled: enabled,
        taskFeedbackMessage: enabled
            ? '已恢复自动拉取远程任务。'
            : state.taskFeedbackMessage,
      );
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      if (!state.isAutoConsumeEnabled) {
        state = state.copyWith(taskFeedbackMessage: '自动拉取设置读取失败，已保持关闭。');
      }
    }
  }
}

final remoteBridgeSessionControllerProvider =
    NotifierProvider<RemoteBridgeSessionController, RemoteBridgeSessionState>(
      RemoteBridgeSessionController.new,
    );

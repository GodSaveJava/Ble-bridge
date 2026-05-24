import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../../domain/entities/remote_bridge_session.dart';

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
    bool clearError = false,
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
      state = RemoteBridgeSessionState.fromSession(session);
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
      state = RemoteBridgeSessionState.fromSession(useCase.currentSession);
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
      state = RemoteBridgeSessionState.fromSession(useCase.currentSession);
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
      state = RemoteBridgeSessionState.fromSession(useCase.currentSession);
    } catch (_) {
      state = state.copyWith(
        status: RemoteBridgeSessionStatus.error,
        errorCode: 'bridge_refresh_failed',
        errorMessage: '接入信息刷新失败，请稍后重试。',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final remoteBridgeSessionControllerProvider = NotifierProvider<
  RemoteBridgeSessionController,
  RemoteBridgeSessionState
>(RemoteBridgeSessionController.new);

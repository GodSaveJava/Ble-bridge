import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/remote_bridge_session.dart';
import 'remote_bridge_session_controller.dart';

enum RemoteBridgeDiagnosticsAction {
  restartBridgeSession,
  openBridgeSettings,
}

class RemoteBridgeDiagnostics {
  const RemoteBridgeDiagnostics({
    required this.title,
    required this.summary,
    this.lastSyncLabel,
    this.action,
    this.actionLabel,
    this.actionRoute,
  });

  final String title;
  final String summary;
  final String? lastSyncLabel;
  final RemoteBridgeDiagnosticsAction? action;
  final String? actionLabel;
  final String? actionRoute;
}

final remoteBridgeDiagnosticsProvider = Provider<RemoteBridgeDiagnostics>((
  Ref ref,
) {
  final RemoteBridgeSessionState state = ref.watch(
    remoteBridgeSessionControllerProvider,
  );

  final String? lastSyncLabel = state.lastUpdatedAt == null
      ? null
      : '最近同步：${_formatBridgeTimestamp(state.lastUpdatedAt!)}';

  if (state.errorCode == 'bridge_keepalive_failed') {
    return RemoteBridgeDiagnostics(
      title: '桥接保活失败',
      summary: '上一段桥接会话曾成功建立，但后续保活刷新失败。请先尝试重新启动桥接会话；如果仍失败，再检查网络、后台保活和远程 Bridge 配置。',
      lastSyncLabel: lastSyncLabel,
      action: RemoteBridgeDiagnosticsAction.restartBridgeSession,
      actionLabel: '重新启动桥接会话',
    );
  }

  return switch (state.status) {
    RemoteBridgeSessionStatus.offline => const RemoteBridgeDiagnostics(
      title: '桥接尚未启动',
      summary: '先启动桥接会话，等接入地址和令牌生成后，再继续 Claude 接入。',
    ),
    RemoteBridgeSessionStatus.connecting => const RemoteBridgeDiagnostics(
      title: '桥接连接中',
      summary: '桥接正在建立连接，请稍等片刻，不要重复点击。',
    ),
    RemoteBridgeSessionStatus.ready => RemoteBridgeDiagnostics(
      title: '桥接连接正常',
      summary: '桥接会话已经在线，可以继续使用当前 connector 信息。',
      lastSyncLabel: lastSyncLabel,
    ),
    RemoteBridgeSessionStatus.busy => RemoteBridgeDiagnostics(
      title: '桥接处理中',
      summary: '桥接正在刷新接入信息或处理请求，请等待当前操作完成。',
      lastSyncLabel: lastSyncLabel,
    ),
    RemoteBridgeSessionStatus.error => RemoteBridgeDiagnostics(
      title: '桥接会话异常',
      summary: '桥接当前处于异常状态。请先尝试重新启动桥接会话；如果仍失败，再检查远程 Bridge 配置。',
      lastSyncLabel: lastSyncLabel,
      action: RemoteBridgeDiagnosticsAction.restartBridgeSession,
      actionLabel: '重新启动桥接会话',
    ),
  };
});

String _formatBridgeTimestamp(DateTime time) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${time.year}-${twoDigits(time.month)}-${twoDigits(time.day)} '
      '${twoDigits(time.hour)}:${twoDigits(time.minute)}';
}

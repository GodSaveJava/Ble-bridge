import '../../domain/entities/remote_bridge_session.dart';

String bridgeSessionStatusLabel(RemoteBridgeSessionStatus status) {
  return switch (status) {
    RemoteBridgeSessionStatus.offline => '桥接未启动',
    RemoteBridgeSessionStatus.connecting => '桥接连接中',
    RemoteBridgeSessionStatus.ready => '桥接已就绪',
    RemoteBridgeSessionStatus.busy => '桥接处理中',
    RemoteBridgeSessionStatus.error => '桥接异常',
  };
}

String bridgeSessionGuidanceText(RemoteBridgeSessionStatus status) {
  switch (status) {
    case RemoteBridgeSessionStatus.offline:
      return '先启动桥接会话。接入地址和令牌生成后，你才能去 Claude 里添加 connector。';
    case RemoteBridgeSessionStatus.connecting:
      return '桥接正在建立会话，请稍等片刻，不要重复点击。';
    case RemoteBridgeSessionStatus.ready:
      return '接入信息已经准备好了。下一步可以复制这些信息，并按教程去 Claude 完成一次 connector 配置。';
    case RemoteBridgeSessionStatus.busy:
      return '桥接正在刷新接入信息，请稍等当前操作完成。';
    case RemoteBridgeSessionStatus.error:
      return '桥接会话出现异常。请重新启动桥接会话；如果仍然失败，再检查网络和后台保活状态。';
  }
}

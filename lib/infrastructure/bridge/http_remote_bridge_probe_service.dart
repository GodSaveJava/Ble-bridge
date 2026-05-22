import '../../domain/entities/remote_bridge_config.dart';
import '../../domain/entities/remote_bridge_probe_result.dart';
import '../../domain/entities/remote_bridge_session.dart';
import '../../domain/services/remote_bridge_probe_service.dart';
import 'http_remote_bridge_service.dart';

class HttpRemoteBridgeProbeService implements RemoteBridgeProbeService {
  @override
  Future<RemoteBridgeProbeResult> probe(RemoteBridgeConfig config) async {
    if (config.normalizedBaseUrl.isEmpty || config.normalizedClientId.isEmpty) {
      return const RemoteBridgeProbeResult(
        isSuccess: false,
        summary: '请先填写 Bridge 地址和客户端 ID。',
      );
    }

    final HttpRemoteBridgeService service = HttpRemoteBridgeService(
      baseUrl: Uri.parse(config.normalizedBaseUrl),
      clientId: config.normalizedClientId,
      clientToken: config.normalizedClientToken.isEmpty
          ? null
          : config.normalizedClientToken,
    );

    try {
      await service.startSession();
      final RemoteBridgeSession session = service.currentSession;
      if (session.status == RemoteBridgeSessionStatus.ready &&
          session.connectorInfo != null) {
        final toolCount = session.connectorInfo!.toolNames.length;
        final connectorUrl = session.connectorInfo!.connectorUrl;
        await service.stopSession();
        return RemoteBridgeProbeResult(
          isSuccess: true,
          summary: '连接测试成功，Bridge 可以正常返回接入信息。',
          detail: '已拿到 connector 地址，当前工具数量：$toolCount\n$connectorUrl',
        );
      }

      return RemoteBridgeProbeResult(
        isSuccess: false,
        summary: '连接测试失败，Bridge 没有返回可用的接入信息。',
        detail: session.lastErrorMessage,
      );
    } on FormatException {
      return const RemoteBridgeProbeResult(
        isSuccess: false,
        summary: 'Bridge 地址格式不正确，请检查是否带有 http 或 https。',
      );
    } on Object catch (error) {
      return RemoteBridgeProbeResult(
        isSuccess: false,
        summary: '连接测试失败，请检查 Bridge 地址、令牌或服务状态。',
        detail: error.toString(),
      );
    } finally {
      service.dispose();
    }
  }
}

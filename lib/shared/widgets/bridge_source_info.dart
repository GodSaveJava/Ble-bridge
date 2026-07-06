import '../../domain/services/remote_bridge_service.dart';

String bridgeSourceLabel(RemoteBridgeRuntimeSource source) {
  return switch (source) {
    RemoteBridgeRuntimeSource.disabled => '来源：未启用',
    RemoteBridgeRuntimeSource.mock => '来源：本地 mock',
    RemoteBridgeRuntimeSource.dartDefine => '来源：dart-define',
    RemoteBridgeRuntimeSource.savedConfig => '来源：真实 Bridge',
    RemoteBridgeRuntimeSource.unknown => '来源：未知',
  };
}

String bridgeSourceDescription(RemoteBridgeRuntimeSource source) {
  return switch (source) {
    RemoteBridgeRuntimeSource.disabled =>
      '当前未启用远程 Bridge。需要显式配置 HTTPS Bridge 或 dart-define 后才会连接。',
    RemoteBridgeRuntimeSource.mock =>
      '当前仍在使用本地 mock 桥接，只适合开发和演示。',
    RemoteBridgeRuntimeSource.dartDefine =>
      '当前通过启动参数注入真实 Bridge，适合开发阶段手动联调。',
    RemoteBridgeRuntimeSource.savedConfig =>
      '当前优先使用你在设置页保存的真实 Bridge 配置。',
    RemoteBridgeRuntimeSource.unknown =>
      '当前桥接来源无法识别，请检查运行配置。',
  };
}

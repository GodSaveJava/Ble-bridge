import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/domain/services/remote_bridge_service.dart';
import 'package:toylink_ai/shared/widgets/bridge_source_info.dart';

void main() {
  test('bridge source helper returns readable labels and descriptions', () {
    expect(
      bridgeSourceLabel(RemoteBridgeRuntimeSource.disabled),
      '来源：未启用',
    );
    expect(
      bridgeSourceDescription(RemoteBridgeRuntimeSource.disabled),
      contains('未启用远程 Bridge'),
    );

    expect(bridgeSourceLabel(RemoteBridgeRuntimeSource.mock), '来源：本地 mock');
    expect(
      bridgeSourceDescription(RemoteBridgeRuntimeSource.mock),
      contains('本地 mock 桥接'),
    );

    expect(
      bridgeSourceLabel(RemoteBridgeRuntimeSource.dartDefine),
      '来源：dart-define',
    );
    expect(
      bridgeSourceDescription(RemoteBridgeRuntimeSource.dartDefine),
      contains('启动参数'),
    );

    expect(
      bridgeSourceLabel(RemoteBridgeRuntimeSource.savedConfig),
      '来源：真实 Bridge',
    );
    expect(
      bridgeSourceDescription(RemoteBridgeRuntimeSource.savedConfig),
      contains('设置页保存'),
    );
  });
}

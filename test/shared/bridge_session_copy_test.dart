import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_session.dart';
import 'package:toylink_ai/shared/widgets/bridge_session_copy.dart';

void main() {
  test('bridge session helper returns readable labels and guidance', () {
    expect(
      bridgeSessionStatusLabel(RemoteBridgeSessionStatus.offline),
      '桥接未启动',
    );
    expect(
      bridgeSessionGuidanceText(
        RemoteBridgeSessionStatus.offline,
      ),
      contains('先启动桥接会话'),
    );

    expect(
      bridgeSessionStatusLabel(RemoteBridgeSessionStatus.ready),
      '桥接已就绪',
    );
    expect(
      bridgeSessionGuidanceText(
        RemoteBridgeSessionStatus.ready,
      ),
      contains('接入信息已经准备好了'),
    );

    expect(
      bridgeSessionStatusLabel(RemoteBridgeSessionStatus.error),
      '桥接异常',
    );
    expect(
      bridgeSessionGuidanceText(
        RemoteBridgeSessionStatus.error,
      ),
      contains('重新启动桥接会话'),
    );
  });
}

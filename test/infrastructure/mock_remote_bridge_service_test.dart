import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/domain/entities/remote_bridge_session.dart';
import 'package:toylink_ai/infrastructure/mock/mock_remote_bridge_service.dart';

void main() {
  group('MockRemoteBridgeService', () {
    test('starts offline and becomes ready with connector info', () async {
      final MockRemoteBridgeService service = MockRemoteBridgeService();
      addTearDown(service.dispose);

      expect(
        service.currentSession.status,
        RemoteBridgeSessionStatus.offline,
      );

      await service.startSession();

      expect(service.currentSession.status, RemoteBridgeSessionStatus.ready);
      expect(service.currentSession.bridgeSessionId, isNotEmpty);
      expect(service.currentSession.connectorInfo, isNotNull);
      expect(
        service.currentSession.connectorInfo?.connectorUrl,
        startsWith('https://'),
      );
      expect(service.currentSession.connectorInfo?.connectorToken, isNotEmpty);
    });

    test('refreshConnector rotates connector token while staying ready', () async {
      final MockRemoteBridgeService service = MockRemoteBridgeService();
      addTearDown(service.dispose);

      await service.startSession();
      final String firstToken =
          service.currentSession.connectorInfo!.connectorToken;

      await service.refreshConnector();

      expect(service.currentSession.status, RemoteBridgeSessionStatus.ready);
      expect(service.currentSession.connectorInfo?.connectorToken, isNotEmpty);
      expect(service.currentSession.connectorInfo?.connectorToken, isNot(firstToken));
    });

    test('stopSession returns the session to offline', () async {
      final MockRemoteBridgeService service = MockRemoteBridgeService();
      addTearDown(service.dispose);

      await service.startSession();
      await service.stopSession();

      expect(service.currentSession.status, RemoteBridgeSessionStatus.offline);
      expect(service.currentSession.connectorInfo, isNull);
    });
  });
}

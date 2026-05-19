import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_session.dart';
import 'package:toylink_ai/domain/services/remote_bridge_service.dart';
import 'package:toylink_ai/features/mcp_server/presentation/controllers/remote_bridge_session_controller.dart';
import 'package:toylink_ai/infrastructure/mock/mock_remote_bridge_service.dart';

void main() {
  group('RemoteBridgeSessionController', () {
    test('starts from offline state', () {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          remoteBridgeServiceProvider.overrideWith(
            (_) => MockRemoteBridgeService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final RemoteBridgeSessionState state = container.read(
        remoteBridgeSessionControllerProvider,
      );
      expect(state.status, RemoteBridgeSessionStatus.offline);
      expect(state.canOnboardClaude, isFalse);
    });

    test('becomes ready and onboardable after starting a session', () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          remoteBridgeServiceProvider.overrideWith(
            (_) => MockRemoteBridgeService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(remoteBridgeSessionControllerProvider.notifier)
          .startSession();

      final RemoteBridgeSessionState state = container.read(
        remoteBridgeSessionControllerProvider,
      );
      expect(state.status, RemoteBridgeSessionStatus.ready);
      expect(state.canOnboardClaude, isTrue);
      expect(state.connectorUrl, startsWith('https://'));
      expect(state.connectorToken, isNotEmpty);
    });

    test('surfaces a friendly error when bridge session start fails', () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          remoteBridgeServiceProvider.overrideWith((_) => _FailingBridgeService()),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(remoteBridgeSessionControllerProvider.notifier)
          .startSession();

      final RemoteBridgeSessionState state = container.read(
        remoteBridgeSessionControllerProvider,
      );
      expect(state.status, RemoteBridgeSessionStatus.error);
      expect(state.errorMessage, contains('桥接'));
    });
  });
}

class _FailingBridgeService implements RemoteBridgeService {
  RemoteBridgeSession _session = const RemoteBridgeSession(
    status: RemoteBridgeSessionStatus.offline,
  );

  @override
  RemoteBridgeSession get currentSession => _session;

  @override
  void dispose() {}

  @override
  Future<void> refreshConnector() async {}

  @override
  Future<void> startSession() async {
    _session = const RemoteBridgeSession(
      status: RemoteBridgeSessionStatus.error,
      lastErrorCode: 'bridge_start_failed',
      lastErrorMessage: '桥接连接失败',
    );
    throw StateError('bridge start failed');
  }

  @override
  Future<void> stopSession() async {
    _session = const RemoteBridgeSession(
      status: RemoteBridgeSessionStatus.offline,
    );
  }

  @override
  Stream<RemoteBridgeSession> watchSession() async* {
    yield _session;
  }
}

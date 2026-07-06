import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/domain/entities/active_adapter_binding.dart';
import 'package:toylink_ai/domain/entities/adapter_manifest.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_session.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_assignment.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_task_result.dart';
import 'package:toylink_ai/domain/entities/verified_adapter_record.dart';
import 'package:toylink_ai/domain/repositories/active_adapter_binding_repository.dart';
import 'package:toylink_ai/domain/repositories/adapter_manifest_repository.dart';
import 'package:toylink_ai/domain/repositories/verified_adapter_repository.dart';
import 'package:toylink_ai/domain/services/remote_bridge_service.dart';
import 'package:toylink_ai/domain/services/remote_bridge_task_executor.dart';
import 'package:toylink_ai/infrastructure/bridge/loopback_remote_bridge_task_executor.dart';
import 'package:toylink_ai/infrastructure/mcp/local_mcp_http_service.dart';
import 'package:toylink_ai/infrastructure/mock/mock_hardware_repository.dart';

void main() {
  group('ExecuteRemoteBridgeTaskUseCase', () {
    test(
      'executes get_status when bridge session is ready and tool is advertised',
      () async {
        final ProviderContainer container = _buildContainer(
          remoteBridgeService: _ReadyBridgeService(
            toolNames: const <String>['get_status', 'stop_all'],
          ),
          remoteBridgeTaskExecutor: LoopbackRemoteBridgeTaskExecutor(
            baseUrl: 'http://127.0.0.1:8883',
          ),
        );
        addTearDown(container.dispose);

        final service = LocalMcpHttpService(
          toolRouter: container.read(mcpToolRouterProvider),
          remoteBridgeToolCallHandler: container.read(
            remoteBridgeToolCallHandlerProvider,
          ),
          host: '127.0.0.1',
          port: 8883,
        );
        addTearDown(service.stop);
        await service.start();

        final result = await container
            .read(executeRemoteBridgeTaskUseCaseProvider)
            .execute(requestId: 'exec-usecase-1', tool: 'get_status');

        expect(result.ok, isTrue);
        expect(result.requestId, 'exec-usecase-1');
        expect(result.result?['deviceId'], isNull);
        expect(result.result?['isConnected'], isTrue);
      },
    );

    test('rejects execution when bridge session is not ready', () async {
      final ProviderContainer container = _buildContainer(
        remoteBridgeService: _OfflineBridgeService(),
        remoteBridgeTaskExecutor: LoopbackRemoteBridgeTaskExecutor(
          baseUrl: 'http://127.0.0.1:8884',
        ),
      );
      addTearDown(container.dispose);

      final RemoteBridgeTaskResult result = await container
          .read(executeRemoteBridgeTaskUseCaseProvider)
          .execute(requestId: 'exec-usecase-2', tool: 'get_status');

      expect(result.ok, isFalse);
      expect(result.errorCode, 'bridge_session_not_ready');
    });

    test('rejects execution when connector does not advertise tool', () async {
      final ProviderContainer container = _buildContainer(
        remoteBridgeService: _ReadyBridgeService(
          toolNames: const <String>['get_status'],
        ),
        remoteBridgeTaskExecutor: LoopbackRemoteBridgeTaskExecutor(
          baseUrl: 'http://127.0.0.1:8885',
        ),
      );
      addTearDown(container.dispose);

      final RemoteBridgeTaskResult result = await container
          .read(executeRemoteBridgeTaskUseCaseProvider)
          .execute(requestId: 'exec-usecase-3', tool: 'stop_all');

      expect(result.ok, isFalse);
      expect(result.errorCode, 'tool_not_advertised_by_connector');
    });

    test(
      'rejects unsafe tool before calling executor even if advertised',
      () async {
        final _RecordingExecutor executor = _RecordingExecutor();
        final ProviderContainer container = _buildContainer(
          remoteBridgeService: _ReadyBridgeService(
            toolNames: const <String>['get_status', 'stop_all', 'set_suck'],
          ),
          remoteBridgeTaskExecutor: executor,
        );
        addTearDown(container.dispose);

        final RemoteBridgeTaskResult result = await container
            .read(executeRemoteBridgeTaskUseCaseProvider)
            .execute(
              requestId: 'exec-usecase-4',
              tool: 'set_suck',
              input: const <String, Object?>{'intensity': 10},
            );

        expect(result.ok, isFalse);
        expect(result.errorCode, 'tool_not_enabled_for_bridge');
        expect(executor.callCount, 0);
      },
    );
  });
}

ProviderContainer _buildContainer({
  required RemoteBridgeService remoteBridgeService,
  required RemoteBridgeTaskExecutor remoteBridgeTaskExecutor,
}) {
  return ProviderContainer(
    overrides: [
      hardwareRepositoryProvider.overrideWith((_) => MockHardwareRepository()),
      adapterManifestRepositoryProvider.overrideWith(
        (_) => _InMemoryManifestRepository(),
      ),
      verifiedAdapterRepositoryProvider.overrideWith(
        (_) => _InMemoryVerifiedRepository(),
      ),
      activeAdapterBindingRepositoryProvider.overrideWith(
        (_) => _InMemoryActiveBindingRepository(),
      ),
      remoteBridgeServiceProvider.overrideWith((_) => remoteBridgeService),
      remoteBridgeTaskExecutorProvider.overrideWith(
        (_) => remoteBridgeTaskExecutor,
      ),
    ],
  );
}

class _InMemoryManifestRepository implements AdapterManifestRepository {
  @override
  Future<AdapterManifest?> findById(String adapterId) async => null;

  @override
  Future<void> remove(String adapterId) async {}

  @override
  Future<void> save(AdapterManifest manifest) async {}

  @override
  Stream<List<AdapterManifest>> watchAll() async* {
    yield const <AdapterManifest>[];
  }
}

class _InMemoryVerifiedRepository implements VerifiedAdapterRepository {
  @override
  Stream<List<VerifiedAdapterRecord>> watchAll() async* {
    yield const <VerifiedAdapterRecord>[];
  }

  @override
  Future<VerifiedAdapterRecord?> find({
    required String adapterId,
    required String deviceFingerprint,
  }) async => null;

  @override
  Future<void> remove({
    required String adapterId,
    required String deviceFingerprint,
  }) async {}

  @override
  Future<void> save(VerifiedAdapterRecord record) async {}
}

class _InMemoryActiveBindingRepository
    implements ActiveAdapterBindingRepository {
  @override
  Stream<List<ActiveAdapterBinding>> watchAll() async* {
    yield const <ActiveAdapterBinding>[];
  }

  @override
  Future<ActiveAdapterBinding?> findByDeviceFingerprint(
    String deviceFingerprint,
  ) async => null;

  @override
  Future<void> removeByDeviceFingerprint(String deviceFingerprint) async {}

  @override
  Future<void> save(ActiveAdapterBinding binding) async {}
}

class _ReadyBridgeService implements RemoteBridgeService {
  _ReadyBridgeService({required List<String> toolNames})
    : _session = RemoteBridgeSession(
        status: RemoteBridgeSessionStatus.ready,
        bridgeSessionId: 'bridge-session-test',
        connectorInfo: RemoteBridgeConnectorInfo(
          connectorUrl: 'https://bridge.toylink.local/mcp/claude',
          connectorToken: 'toy-connector-token',
          toolNames: toolNames,
        ),
      );

  final RemoteBridgeSession _session;

  @override
  RemoteBridgeSession get currentSession => _session;

  @override
  void dispose() {}

  @override
  Future<void> reportTaskResult(RemoteBridgeTaskResult result) async {}

  @override
  Future<RemoteBridgeTaskAssignment?> fetchNextTask() async => null;

  @override
  Future<void> refreshConnector() async {}

  @override
  Future<void> startSession() async {}

  @override
  Future<void> stopSession() async {}

  @override
  Stream<RemoteBridgeSession> watchSession() async* {
    yield _session;
  }
}

class _OfflineBridgeService implements RemoteBridgeService {
  @override
  RemoteBridgeSession get currentSession =>
      const RemoteBridgeSession(status: RemoteBridgeSessionStatus.offline);

  @override
  void dispose() {}

  @override
  Future<void> reportTaskResult(RemoteBridgeTaskResult result) async {}

  @override
  Future<RemoteBridgeTaskAssignment?> fetchNextTask() async => null;

  @override
  Future<void> refreshConnector() async {}

  @override
  Future<void> startSession() async {}

  @override
  Future<void> stopSession() async {}

  @override
  Stream<RemoteBridgeSession> watchSession() async* {
    yield currentSession;
  }
}

class _RecordingExecutor implements RemoteBridgeTaskExecutor {
  int callCount = 0;

  @override
  void dispose() {}

  @override
  Future<RemoteBridgeTaskResult> execute({
    String? requestId,
    required String tool,
    Map<String, Object?> input = const <String, Object?>{},
  }) async {
    callCount += 1;
    return RemoteBridgeTaskResult(ok: true, requestId: requestId, tool: tool);
  }
}

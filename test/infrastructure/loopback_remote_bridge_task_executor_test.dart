import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/domain/entities/active_adapter_binding.dart';
import 'package:toylink_ai/domain/entities/adapter_manifest.dart';
import 'package:toylink_ai/domain/entities/verified_adapter_record.dart';
import 'package:toylink_ai/domain/repositories/active_adapter_binding_repository.dart';
import 'package:toylink_ai/domain/repositories/adapter_manifest_repository.dart';
import 'package:toylink_ai/domain/repositories/verified_adapter_repository.dart';
import 'package:toylink_ai/infrastructure/bridge/loopback_remote_bridge_task_executor.dart';
import 'package:toylink_ai/infrastructure/mcp/local_mcp_http_service.dart';
import 'package:toylink_ai/infrastructure/mock/mock_hardware_repository.dart';

void main() {
  group('LoopbackRemoteBridgeTaskExecutor', () {
    test('executes get_status through local bridge route', () async {
      final ProviderContainer container = _buildContainer();
      addTearDown(container.dispose);

      final service = LocalMcpHttpService(
        toolRouter: container.read(mcpToolRouterProvider),
        remoteBridgeToolCallHandler: container.read(
          remoteBridgeToolCallHandlerProvider,
        ),
        host: '127.0.0.1',
        port: 8881,
      );
      addTearDown(service.stop);
      await service.start();

      final executor = LoopbackRemoteBridgeTaskExecutor(
        baseUrl: 'http://127.0.0.1:8881',
      );
      addTearDown(executor.dispose);

      final result = await executor.execute(
        requestId: 'bridge-exec-1',
        tool: 'get_status',
      );

      expect(result.ok, isTrue);
      expect(result.requestId, 'bridge-exec-1');
      expect(result.tool, 'get_status');
      expect(result.result?['deviceId'], isNull);
      expect(result.result?['isConnected'], isTrue);
    });

    test('returns whitelist error for disabled tool', () async {
      final ProviderContainer container = _buildContainer();
      addTearDown(container.dispose);

      final service = LocalMcpHttpService(
        toolRouter: container.read(mcpToolRouterProvider),
        remoteBridgeToolCallHandler: container.read(
          remoteBridgeToolCallHandlerProvider,
        ),
        host: '127.0.0.1',
        port: 8882,
      );
      addTearDown(service.stop);
      await service.start();

      final executor = LoopbackRemoteBridgeTaskExecutor(
        baseUrl: 'http://127.0.0.1:8882',
      );
      addTearDown(executor.dispose);

      final result = await executor.execute(
        requestId: 'bridge-exec-2',
        tool: 'set_suck',
        input: const <String, Object?>{'intensity': 10, 'mode': 1},
      );

      expect(result.ok, isFalse);
      expect(result.requestId, 'bridge-exec-2');
      expect(result.errorCode, 'tool_not_enabled_for_bridge');
    });
  });
}

ProviderContainer _buildContainer() {
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

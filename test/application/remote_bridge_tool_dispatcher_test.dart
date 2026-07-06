import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/application/mcp/mcp_tool_router.dart';
import 'package:toylink_ai/application/mcp/remote_bridge_tool_dispatcher.dart';
import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/domain/entities/active_adapter_binding.dart';
import 'package:toylink_ai/domain/entities/adapter_manifest.dart';
import 'package:toylink_ai/domain/entities/verified_adapter_record.dart';
import 'package:toylink_ai/domain/repositories/active_adapter_binding_repository.dart';
import 'package:toylink_ai/domain/repositories/adapter_manifest_repository.dart';
import 'package:toylink_ai/domain/repositories/verified_adapter_repository.dart';
import 'package:toylink_ai/infrastructure/mock/mock_hardware_repository.dart';

void main() {
  group('RemoteBridgeToolDispatcher', () {
    test('dispatches get_status through MCP tool router', () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          hardwareRepositoryProvider.overrideWith(
            (_) => MockHardwareRepository(),
          ),
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
      addTearDown(container.dispose);

      final RemoteBridgeToolDispatcher dispatcher = container.read(
        remoteBridgeToolDispatcherProvider,
      );

      final McpToolResult result = await dispatcher.dispatchTool('get_status');

      expect(result.ok, isTrue);
      expect(result.data?['deviceId'], isNull);
      expect(result.data?['isConnected'], isTrue);
    });

    test('dispatches stop_all through MCP tool router', () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          hardwareRepositoryProvider.overrideWith(
            (_) => MockHardwareRepository(),
          ),
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
      addTearDown(container.dispose);

      final RemoteBridgeToolDispatcher dispatcher = container.read(
        remoteBridgeToolDispatcherProvider,
      );

      final McpToolResult result = await dispatcher.dispatchTool('stop_all');

      expect(result.ok, isTrue);
      expect(result.data?['suckIntensity'], 0);
      expect(result.data?['vibeIntensity'], 0);
      expect(result.data?['emsIntensity'], 0);
    });

    test(
      'rejects control tools that are not enabled for remote bridge yet',
      () async {
        final ProviderContainer container = ProviderContainer(
          overrides: [
            hardwareRepositoryProvider.overrideWith(
              (_) => MockHardwareRepository(),
            ),
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
        addTearDown(container.dispose);

        final RemoteBridgeToolDispatcher dispatcher = container.read(
          remoteBridgeToolDispatcherProvider,
        );

        final McpToolResult result = await dispatcher.dispatchTool(
          'set_suck',
          arguments: const <String, Object?>{'intensity': 10, 'mode': 1},
        );

        expect(result.ok, isFalse);
        expect(result.errorCode, 'tool_not_enabled_for_bridge');
      },
    );
  });
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

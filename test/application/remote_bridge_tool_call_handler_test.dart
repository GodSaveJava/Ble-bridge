import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/application/mcp/remote_bridge_tool_call_handler.dart';
import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/domain/entities/active_adapter_binding.dart';
import 'package:toylink_ai/domain/entities/adapter_manifest.dart';
import 'package:toylink_ai/domain/entities/verified_adapter_record.dart';
import 'package:toylink_ai/domain/repositories/active_adapter_binding_repository.dart';
import 'package:toylink_ai/domain/repositories/adapter_manifest_repository.dart';
import 'package:toylink_ai/domain/repositories/verified_adapter_repository.dart';
import 'package:toylink_ai/infrastructure/mock/mock_hardware_repository.dart';

void main() {
  group('RemoteBridgeToolCallHandler', () {
    test('handles get_status request with request id passthrough', () async {
      final ProviderContainer container = _buildContainer();
      addTearDown(container.dispose);

      final RemoteBridgeToolCallHandler handler = container.read(
        remoteBridgeToolCallHandlerProvider,
      );

      final Map<String, Object?> response = await handler.handle(
        <String, Object?>{'requestId': 'req-1', 'tool': 'get_status'},
      );

      expect(response['ok'], true);
      expect(response['requestId'], 'req-1');
      expect(response['tool'], 'get_status');
      expect((response['result'] as Map<String, Object?>)['deviceId'], isNull);
      expect(
        (response['result'] as Map<String, Object?>)['isConnected'],
        isTrue,
      );
    });

    test('handles stop_all request with structured result', () async {
      final ProviderContainer container = _buildContainer();
      addTearDown(container.dispose);

      final RemoteBridgeToolCallHandler handler = container.read(
        remoteBridgeToolCallHandlerProvider,
      );

      final Map<String, Object?> response = await handler.handle(
        <String, Object?>{
          'tool': 'stop_all',
          'input': const <String, Object?>{},
        },
      );

      expect(response['ok'], true);
      expect((response['result'] as Map<String, Object?>)['suckIntensity'], 0);
    });

    test('returns validation error when tool field is missing', () async {
      final ProviderContainer container = _buildContainer();
      addTearDown(container.dispose);

      final RemoteBridgeToolCallHandler handler = container.read(
        remoteBridgeToolCallHandlerProvider,
      );

      final Map<String, Object?> response = await handler.handle(
        <String, Object?>{'requestId': 'req-2'},
      );

      expect(response['ok'], false);
      expect(response['requestId'], 'req-2');
      expect(
        ((response['error'] as Map<String, Object?>)['code']),
        'validation_error',
      );
    });

    test('returns bridge whitelist error for disabled tool', () async {
      final ProviderContainer container = _buildContainer();
      addTearDown(container.dispose);

      final RemoteBridgeToolCallHandler handler = container.read(
        remoteBridgeToolCallHandlerProvider,
      );

      final Map<String, Object?> response = await handler.handle(
        <String, Object?>{
          'tool': 'set_suck',
          'input': const <String, Object?>{'intensity': 10, 'mode': 1},
        },
      );

      expect(response['ok'], false);
      expect(
        ((response['error'] as Map<String, Object?>)['code']),
        'tool_not_enabled_for_bridge',
      );
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

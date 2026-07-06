import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/application/controllers/remote_bridge_config_controller.dart';
import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_config.dart';
import 'package:toylink_ai/domain/repositories/remote_bridge_config_repository.dart';

void main() {
  group('RemoteBridgeConfigController', () {
    test('loads saved config from repository', () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          remoteBridgeConfigRepositoryProvider.overrideWith(
            (_) => _InMemoryRemoteBridgeConfigRepository(
              const RemoteBridgeConfig(
                enabled: true,
                baseUrl: 'https://bridge.example.com',
                clientId: 'device-a',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final RemoteBridgeConfig config = await container.read(
        remoteBridgeConfigControllerProvider.future,
      );

      expect(config.enabled, isTrue);
      expect(config.baseUrl, 'https://bridge.example.com');
    });

    test('save normalizes values before storing', () async {
      final _InMemoryRemoteBridgeConfigRepository repository =
          _InMemoryRemoteBridgeConfigRepository(const RemoteBridgeConfig());
      final ProviderContainer container = ProviderContainer(
        overrides: [
          remoteBridgeConfigRepositoryProvider.overrideWith((_) => repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(remoteBridgeConfigControllerProvider.future);
      await container
          .read(remoteBridgeConfigControllerProvider.notifier)
          .save(
            const RemoteBridgeConfig(
              enabled: true,
              baseUrl: ' https://bridge.example.com ',
              clientId: ' device-a ',
              clientToken: ' secret-token ',
            ),
          );

      final RemoteBridgeConfig config = container.read(
        remoteBridgeConfigControllerProvider,
      ).requireValue;
      expect(config.baseUrl, 'https://bridge.example.com');
      expect(config.clientId, 'device-a');
      expect(config.clientToken, 'secret-token');
      expect(repository.current.clientToken, 'secret-token');
    });

    test('reset returns disabled config', () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          remoteBridgeConfigRepositoryProvider.overrideWith(
            (_) => _InMemoryRemoteBridgeConfigRepository(
              const RemoteBridgeConfig(
                enabled: true,
                baseUrl: 'https://bridge.example.com',
                clientId: 'device-a',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(remoteBridgeConfigControllerProvider.future);
      await container
          .read(remoteBridgeConfigControllerProvider.notifier)
          .reset();

      final RemoteBridgeConfig config = container.read(
        remoteBridgeConfigControllerProvider,
      ).requireValue;
      expect(config.enabled, isFalse);
      expect(config.baseUrl, isEmpty);
    });
  });
}

class _InMemoryRemoteBridgeConfigRepository
    implements RemoteBridgeConfigRepository {
  _InMemoryRemoteBridgeConfigRepository(this.current);

  RemoteBridgeConfig current;

  @override
  Future<RemoteBridgeConfig> load() async => current;

  @override
  Future<void> reset() async {
    current = const RemoteBridgeConfig();
  }

  @override
  Future<void> save(RemoteBridgeConfig config) async {
    current = config;
  }
}

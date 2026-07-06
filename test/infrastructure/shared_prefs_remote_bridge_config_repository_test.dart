import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toylink_ai/domain/entities/remote_bridge_config.dart';
import 'package:toylink_ai/infrastructure/storage/shared_prefs_remote_bridge_config_repository.dart';

void main() {
  group('SharedPrefsRemoteBridgeConfigRepository', () {
    late SharedPrefsRemoteBridgeConfigRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      repository = SharedPrefsRemoteBridgeConfigRepository();
    });

    test('loads disabled config when storage is empty', () async {
      final RemoteBridgeConfig config = await repository.load();

      expect(config.enabled, isFalse);
      expect(config.baseUrl, isEmpty);
      expect(config.clientId, 'toylink-mobile-dev');
      expect(config.clientToken, isEmpty);
    });

    test('saves public fields to prefs and token to secure storage', () async {
      await repository.save(
        const RemoteBridgeConfig(
          enabled: true,
          baseUrl: 'https://bridge.example.com',
          clientId: 'device-a',
          clientToken: 'secret-token',
        ),
      );

      final RemoteBridgeConfig reloaded = await repository.load();
      expect(reloaded.enabled, isTrue);
      expect(reloaded.baseUrl, 'https://bridge.example.com');
      expect(reloaded.clientId, 'device-a');
      expect(reloaded.clientToken, 'secret-token');
    });

    test('reset clears both prefs and secure token', () async {
      await repository.save(
        const RemoteBridgeConfig(
          enabled: true,
          baseUrl: 'https://bridge.example.com',
          clientId: 'device-a',
          clientToken: 'secret-token',
        ),
      );

      await repository.reset();
      final RemoteBridgeConfig reloaded = await repository.load();

      expect(reloaded.enabled, isFalse);
      expect(reloaded.baseUrl, isEmpty);
      expect(reloaded.clientToken, isEmpty);
    });

    test(
      'disables legacy mock config instead of using public defaults',
      () async {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'remote_bridge_config_v1',
          '{"enabled":true,"baseUrl":"https://bridge.toylink.local","clientId":"device-a"}',
        );

        final RemoteBridgeConfig config = await repository.load();

        expect(config.enabled, isFalse);
        expect(config.baseUrl, isEmpty);
        expect(config.clientId, RemoteBridgeConfig.productionClientId);
      },
    );

    test('disables saved non-loopback HTTP config', () async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'remote_bridge_config_v1',
        '{"enabled":true,"baseUrl":"http://47.95.242.29:8100","clientId":"device-a"}',
      );

      final RemoteBridgeConfig config = await repository.load();

      expect(config.enabled, isFalse);
      expect(config.baseUrl, isEmpty);
    });
  });
}

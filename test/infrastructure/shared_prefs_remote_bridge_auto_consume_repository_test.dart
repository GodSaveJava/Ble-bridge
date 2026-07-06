import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toylink_ai/infrastructure/storage/shared_prefs_remote_bridge_auto_consume_repository.dart';

void main() {
  group('SharedPrefsRemoteBridgeAutoConsumeRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('defaults to disabled when unset', () async {
      final repository = SharedPrefsRemoteBridgeAutoConsumeRepository();

      expect(await repository.loadEnabled(), isFalse);
    });

    test('persists enabled state', () async {
      final repository = SharedPrefsRemoteBridgeAutoConsumeRepository();

      await repository.saveEnabled(true);

      expect(await repository.loadEnabled(), isTrue);
    });

    test('reset clears enabled state', () async {
      final repository = SharedPrefsRemoteBridgeAutoConsumeRepository();

      await repository.saveEnabled(true);
      await repository.reset();

      expect(await repository.loadEnabled(), isFalse);
    });
  });
}

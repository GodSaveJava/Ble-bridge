import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toylink_ai/domain/entities/claude_connector_onboarding_record.dart';
import 'package:toylink_ai/infrastructure/storage/shared_prefs_claude_connector_onboarding_repository.dart';

void main() {
  group('SharedPrefsClaudeConnectorOnboardingRepository', () {
    late SharedPrefsClaudeConnectorOnboardingRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = SharedPrefsClaudeConnectorOnboardingRepository();
    });

    test('loads null when storage is empty', () async {
      final ClaudeConnectorOnboardingRecord? record = await repository.load();
      expect(record, isNull);
    });

    test('saves and reloads onboarding record', () async {
      final ClaudeConnectorOnboardingRecord record =
          ClaudeConnectorOnboardingRecord(
            deviceId: 'device-a',
            adapterId: 'generic.triple_channel.v1',
            completedAt: DateTime(2026, 5, 21, 12),
          );

      await repository.save(record);

      final ClaudeConnectorOnboardingRecord? loaded = await repository.load();
      expect(loaded?.deviceId, 'device-a');
      expect(loaded?.adapterId, 'generic.triple_channel.v1');
      expect(loaded?.completedAt, DateTime(2026, 5, 21, 12));
    });

    test('reset clears saved onboarding record', () async {
      await repository.save(
        ClaudeConnectorOnboardingRecord(
          deviceId: 'device-a',
          adapterId: 'generic.triple_channel.v1',
          completedAt: DateTime(2026, 5, 21, 12),
        ),
      );

      await repository.reset();

      final ClaudeConnectorOnboardingRecord? loaded = await repository.load();
      expect(loaded, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toylink_ai/domain/entities/background_stability_checklist.dart';
import 'package:toylink_ai/infrastructure/storage/shared_prefs_background_stability_checklist_repository.dart';

void main() {
  group('SharedPrefsBackgroundStabilityChecklistRepository', () {
    late SharedPrefsBackgroundStabilityChecklistRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = SharedPrefsBackgroundStabilityChecklistRepository();
    });

    test('loads default checklist when storage is empty', () async {
      final BackgroundStabilityChecklist checklist = await repository.load();
      expect(checklist.allPassed, isFalse);
      expect(checklist.lockScreen30Min, isFalse);
    });

    test('saves and reloads checklist state', () async {
      const BackgroundStabilityChecklist checklist = BackgroundStabilityChecklist(
        lockScreen30Min: true,
        switchBackgroundAndBack: true,
        autoReconnectAfterDisconnect: false,
        mcpCallAvailableInBackground: true,
      );
      await repository.save(checklist);

      final BackgroundStabilityChecklist loaded = await repository.load();
      expect(loaded.lockScreen30Min, isTrue);
      expect(loaded.switchBackgroundAndBack, isTrue);
      expect(loaded.autoReconnectAfterDisconnect, isFalse);
      expect(loaded.mcpCallAvailableInBackground, isTrue);
    });

    test('reset clears saved checklist', () async {
      await repository.save(
        const BackgroundStabilityChecklist(lockScreen30Min: true),
      );
      await repository.reset();
      final BackgroundStabilityChecklist loaded = await repository.load();
      expect(loaded.lockScreen30Min, isFalse);
    });
  });
}

import '../entities/background_stability_checklist.dart';

abstract class BackgroundStabilityChecklistRepository {
  Future<BackgroundStabilityChecklist> load();
  Future<void> save(BackgroundStabilityChecklist checklist);
  Future<void> reset();
}

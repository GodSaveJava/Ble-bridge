import '../entities/claude_connector_onboarding_record.dart';

abstract class ClaudeConnectorOnboardingRepository {
  Future<ClaudeConnectorOnboardingRecord?> load();

  Future<void> save(ClaudeConnectorOnboardingRecord record);

  Future<void> reset();
}

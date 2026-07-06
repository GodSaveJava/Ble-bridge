import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toylink_ai/application/models/active_device_adapter_readiness.dart';
import 'package:toylink_ai/application/providers/application_providers.dart';
import 'package:toylink_ai/domain/entities/claude_connector_onboarding_record.dart';
import 'package:toylink_ai/domain/repositories/claude_connector_onboarding_repository.dart';
import 'package:toylink_ai/features/mcp_server/presentation/controllers/claude_connector_onboarding_controller.dart';

void main() {
  group('ClaudeConnectorOnboardingController', () {
    test('loads empty state when repository has no record', () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => _InMemoryClaudeConnectorOnboardingRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await Future<void>.delayed(Duration.zero);

      final ClaudeConnectorOnboardingState state = container.read(
        claudeConnectorOnboardingControllerProvider,
      );
      expect(state.record, isNull);
    });

    test('markCompleted saves current device and adapter', () async {
      final _InMemoryClaudeConnectorOnboardingRepository repository =
          _InMemoryClaudeConnectorOnboardingRepository();
      final ProviderContainer container = ProviderContainer(
        overrides: [
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => repository,
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(claudeConnectorOnboardingControllerProvider.notifier)
          .markCompleted(
            const ActiveDeviceAdapterReadiness(
              state: ActiveDeviceAdapterReadinessState.verified,
              deviceId: 'device-a',
              adapterId: 'generic.triple_channel.v1',
            ),
          );

      final ClaudeConnectorOnboardingState state = container.read(
        claudeConnectorOnboardingControllerProvider,
      );
      expect(state.record?.deviceId, 'device-a');
      expect(state.record?.adapterId, 'generic.triple_channel.v1');
      expect(
        repository.record?.matches(
          deviceId: 'device-a',
          adapterId: 'generic.triple_channel.v1',
        ),
        isTrue,
      );
    });

    test('reset clears saved onboarding record', () async {
      final _InMemoryClaudeConnectorOnboardingRepository repository =
          _InMemoryClaudeConnectorOnboardingRepository();
      final ProviderContainer container = ProviderContainer(
        overrides: [
          claudeConnectorOnboardingRepositoryProvider.overrideWith(
            (_) => repository,
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(claudeConnectorOnboardingControllerProvider.notifier)
          .markCompleted(
            const ActiveDeviceAdapterReadiness(
              state: ActiveDeviceAdapterReadinessState.verified,
              deviceId: 'device-a',
              adapterId: 'generic.triple_channel.v1',
            ),
          );
      await container
          .read(claudeConnectorOnboardingControllerProvider.notifier)
          .reset();

      final ClaudeConnectorOnboardingState state = container.read(
        claudeConnectorOnboardingControllerProvider,
      );
      expect(state.record, isNull);
      expect(repository.record, isNull);
    });
  });
}

class _InMemoryClaudeConnectorOnboardingRepository
    implements ClaudeConnectorOnboardingRepository {
  ClaudeConnectorOnboardingRecord? record;

  @override
  Future<ClaudeConnectorOnboardingRecord?> load() async => record;

  @override
  Future<void> reset() async {
    record = null;
  }

  @override
  Future<void> save(ClaudeConnectorOnboardingRecord record) async {
    this.record = record;
  }
}

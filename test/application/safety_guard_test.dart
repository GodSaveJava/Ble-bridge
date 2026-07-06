import 'package:flutter_test/flutter_test.dart';
import 'package:toylink_ai/application/safety/safety_guard.dart';
import 'package:toylink_ai/domain/entities/control_command.dart';

void main() {
  group('SafetyGuard', () {
    const SafetyGuard guard = SafetyGuard();

    test('allows ems intensity at soft limit', () {
      final ControlCommand command = ControlCommand(
        channel: ControlChannel.ems,
        intensity: 8,
        mode: 1,
        source: CommandSource.ui,
        requestedAt: DateTime(2026),
      );

      final SafetyDecision decision = guard.evaluate(command: command);
      expect(decision.type, SafetyDecisionType.allow);
    });

    test('requires confirmation above soft limit', () {
      final ControlCommand command = ControlCommand(
        channel: ControlChannel.ems,
        intensity: 9,
        mode: 1,
        source: CommandSource.ui,
        requestedAt: DateTime(2026),
      );

      final SafetyDecision decision = guard.evaluate(command: command);
      expect(decision.type, SafetyDecisionType.requireConfirmation);
    });

    test('rejects ems intensity above hard limit', () {
      final ControlCommand command = ControlCommand(
        channel: ControlChannel.ems,
        intensity: 21,
        mode: 1,
        source: CommandSource.ui,
        requestedAt: DateTime(2026),
      );

      final SafetyDecision decision = guard.evaluate(command: command);
      expect(decision.type, SafetyDecisionType.reject);
      expect(decision.failure, isNotNull);
    });

    test('allows non-ems command', () {
      final ControlCommand command = ControlCommand(
        channel: ControlChannel.suck,
        intensity: 100,
        mode: 1,
        source: CommandSource.ui,
        requestedAt: DateTime(2026),
      );

      final SafetyDecision decision = guard.evaluate(command: command);
      expect(decision.type, SafetyDecisionType.allow);
    });
  });
}

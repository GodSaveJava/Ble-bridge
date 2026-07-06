import '../../core/constants/app_constants.dart';
import '../../core/error/failure.dart';
import '../../domain/entities/control_command.dart';
import '../../domain/entities/safety_policy.dart';

enum SafetyDecisionType { allow, requireConfirmation, reject }

class SafetyDecision {
  const SafetyDecision._({required this.type, this.failure});

  const SafetyDecision.allow() : this._(type: SafetyDecisionType.allow);

  const SafetyDecision.requireConfirmation()
    : this._(type: SafetyDecisionType.requireConfirmation);

  const SafetyDecision.reject(Failure failure)
    : this._(type: SafetyDecisionType.reject, failure: failure);

  final SafetyDecisionType type;
  final Failure? failure;
}

class SafetyGuard {
  const SafetyGuard({
    this.defaultPolicy = const SafetyPolicy(
      emsSoftLimit: AppConstants.emsSoftLimit,
      emsHardLimit: AppConstants.emsHardLimit,
      requiresExplicitConfirmationAboveSoftLimit: true,
    ),
  });

  final SafetyPolicy defaultPolicy;

  SafetyDecision evaluate({
    required ControlCommand command,
    SafetyPolicy? policy,
  }) {
    final SafetyPolicy targetPolicy = policy ?? defaultPolicy;

    if (command.intensity < 0) {
      return const SafetyDecision.reject(
        Failure.validation(message: 'Intensity must be >= 0.'),
      );
    }

    if (command.channel != ControlChannel.ems) {
      return const SafetyDecision.allow();
    }

    if (command.intensity > targetPolicy.emsHardLimit) {
      return SafetyDecision.reject(
        Failure.validation(
          message:
              'EMS intensity exceeds hard limit (${targetPolicy.emsHardLimit}).',
          details: <String, Object?>{
            'intensity': command.intensity,
            'hardLimit': targetPolicy.emsHardLimit,
          },
        ),
      );
    }

    if (command.intensity <= targetPolicy.emsSoftLimit) {
      return const SafetyDecision.allow();
    }

    if (!targetPolicy.requiresExplicitConfirmationAboveSoftLimit) {
      return const SafetyDecision.allow();
    }

    return const SafetyDecision.requireConfirmation();
  }
}

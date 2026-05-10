import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../../application/use_cases/control_device_use_case.dart';
import '../../../../application/use_cases/manage_adapter_use_case.dart';
import '../../../../domain/entities/verified_adapter_record.dart';

class VerificationStepDraft {
  const VerificationStepDraft({
    required this.key,
    required this.label,
    this.passed = false,
  });

  final String key;
  final String label;
  final bool passed;

  VerificationStepDraft copyWith({bool? passed}) {
    return VerificationStepDraft(
      key: key,
      label: label,
      passed: passed ?? this.passed,
    );
  }
}

class AdapterVerificationState {
  const AdapterVerificationState({
    this.isSubmitting = false,
    this.isRunningStep = false,
    this.runningStepKey,
    this.errorMessage,
    this.successMessage,
    this.steps = const <VerificationStepDraft>[
      VerificationStepDraft(key: 'set_suck', label: '吮吸强度 10（模式 1）'),
      VerificationStepDraft(key: 'set_vibe', label: '震动强度 10（模式 1）'),
      VerificationStepDraft(key: 'set_ems', label: '微电流强度 1（模式 1）'),
      VerificationStepDraft(key: 'stop_all', label: '一键停止 stop_all'),
    ],
  });

  final bool isSubmitting;
  final bool isRunningStep;
  final String? runningStepKey;
  final String? errorMessage;
  final String? successMessage;
  final List<VerificationStepDraft> steps;

  AdapterVerificationState copyWith({
    bool? isSubmitting,
    bool? isRunningStep,
    String? runningStepKey,
    String? errorMessage,
    String? successMessage,
    List<VerificationStepDraft>? steps,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearRunningStepKey = false,
  }) {
    return AdapterVerificationState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isRunningStep: isRunningStep ?? this.isRunningStep,
      runningStepKey: clearRunningStepKey
          ? null
          : (runningStepKey ?? this.runningStepKey),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      steps: steps ?? this.steps,
    );
  }
}

class AdapterVerificationController extends Notifier<AdapterVerificationState> {
  @override
  AdapterVerificationState build() => const AdapterVerificationState();

  void setStepPassed({required String stepKey, required bool passed}) {
    final List<VerificationStepDraft> next = state.steps
        .map(
          (VerificationStepDraft step) =>
              step.key == stepKey ? step.copyWith(passed: passed) : step,
        )
        .toList();
    state = state.copyWith(steps: next, clearError: true, clearSuccess: true);
  }

  Future<void> runStep(String stepKey) async {
    state = state.copyWith(
      isRunningStep: true,
      runningStepKey: stepKey,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final ControlDeviceUseCase controlUseCase = ref.read(
        controlDeviceUseCaseProvider,
      );
      switch (stepKey) {
        case 'set_suck':
          await controlUseCase.setSuck(intensity: 10, mode: 1);
          break;
        case 'set_vibe':
          await controlUseCase.setVibe(intensity: 10, mode: 1);
          break;
        case 'set_ems':
          await controlUseCase.setEms(intensity: 1, mode: 1);
          break;
        case 'stop_all':
          await controlUseCase.stopAll();
          break;
        default:
          throw ArgumentError('Unsupported step key: $stepKey');
      }
      setStepPassed(stepKey: stepKey, passed: true);
      state = state.copyWith(
        isRunningStep: false,
        clearRunningStepKey: true,
        successMessage: '步骤执行成功，请确认体感后可取消勾选。',
      );
    } catch (error) {
      state = state.copyWith(
        isRunningStep: false,
        clearRunningStepKey: true,
        errorMessage: '步骤执行失败：$error',
      );
    }
  }

  Future<void> submit({
    required String adapterId,
    required String deviceFingerprint,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      clearRunningStepKey: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final List<VerificationStepResult> stepResults = state.steps
          .map(
            (VerificationStepDraft step) =>
                VerificationStepResult(stepKey: step.key, passed: step.passed),
          )
          .toList();

      String gattFingerprint = 'unknown-gatt';
      final activeDevice = ref
          .read(activeDeviceRegistryProvider)
          .getActiveDeviceOrNull();
      if (activeDevice != null) {
        gattFingerprint = await activeDevice.getGattFingerprint();
      }

      await ref.read(manageAdapterUseCaseProvider).markVerificationPassed(
            AdapterVerificationInput(
              adapterId: adapterId,
              deviceFingerprint: deviceFingerprint,
              gattFingerprint: gattFingerprint,
              appVersion: '1.0.0',
              stepResults: stepResults,
            ),
          );

      state = state.copyWith(
        isSubmitting: false,
        successMessage: '验证已通过：该适配器可用于 MCP 控制。',
      );
    } catch (error) {
      state = state.copyWith(isSubmitting: false, errorMessage: '验证失败：$error');
    }
  }
}

final adapterVerificationControllerProvider =
    NotifierProvider<AdapterVerificationController, AdapterVerificationState>(
      AdapterVerificationController.new,
    );

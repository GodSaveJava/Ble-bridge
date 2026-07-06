import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../../application/use_cases/control_device_use_case.dart';
import '../../../../application/use_cases/manage_adapter_use_case.dart';
import '../../../../domain/entities/verified_adapter_record.dart';

class VerificationStepDraft {
  const VerificationStepDraft({
    required this.key,
    required this.label,
    required this.description,
    required this.safetyHint,
    this.passed = false,
  });

  final String key;
  final String label;
  final String description;
  final String safetyHint;
  final bool passed;

  VerificationStepDraft copyWith({bool? passed}) {
    return VerificationStepDraft(
      key: key,
      label: label,
      description: description,
      safetyHint: safetyHint,
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
      VerificationStepDraft(
        key: 'stop_all',
        label: '先确认一键停止正常',
        description: '先发送停止命令，确认设备能立即停下。这一步是安全底线。',
        safetyHint: '如果停止无效，请不要继续后面的测试。',
      ),
      VerificationStepDraft(
        key: 'set_suck',
        label: '轻微吸力测试',
        description: '使用模式 1、强度 10，短暂确认吸力反应是否正确。',
        safetyHint: '每次测试建议不超过 3 秒；如果反应不对，请取消勾选。',
      ),
      VerificationStepDraft(
        key: 'set_vibe',
        label: '轻微震动测试',
        description: '使用模式 1、强度 10，短暂确认震动反应是否正确。',
        safetyHint: '如果功能错位，请先停止，再返回设备管理切换模板。',
      ),
      VerificationStepDraft(
        key: 'set_ems',
        label: '微电流低强度测试（请谨慎）',
        description: '仅使用模式 1、强度 1 做短暂测试，不做高强度尝试。',
        safetyHint: '如有任何不适，请立即停止，不要继续提高强度。',
      ),
    ],
  });

  final bool isSubmitting;
  final bool isRunningStep;
  final String? runningStepKey;
  final String? errorMessage;
  final String? successMessage;
  final List<VerificationStepDraft> steps;

  int get completedCount =>
      steps.where((VerificationStepDraft step) => step.passed).length;

  bool get canSubmit =>
      steps.isNotEmpty &&
      steps.every((VerificationStepDraft step) => step.passed);

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

      final VerificationStepDraft executedStep = state.steps.firstWhere(
        (VerificationStepDraft step) => step.key == stepKey,
      );

      setStepPassed(stepKey: stepKey, passed: true);
      state = state.copyWith(
        isRunningStep: false,
        clearRunningStepKey: true,
        successMessage:
            '已执行“${executedStep.label}”。如果反应正确，请保留勾选；如果不对，请取消勾选并立即停止。',
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

      await ref
          .read(manageAdapterUseCaseProvider)
          .markVerificationPassed(
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
        successMessage: '验证已通过：这份适配器现在可以用于 MCP 控制。',
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

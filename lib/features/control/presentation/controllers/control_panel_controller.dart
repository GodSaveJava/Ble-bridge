import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../domain/entities/device_status.dart';

class ControlPanelState {
  const ControlPanelState({
    this.suck = 0,
    this.vibe = 0,
    this.ems = 0,
    this.suckMode = 1,
    this.vibeMode = 1,
    this.emsMode = 1,
    this.isBusy = false,
    this.errorMessage,
    this.requiresEmsConfirmation = false,
  });

  final int suck;
  final int vibe;
  final int ems;
  final int suckMode;
  final int vibeMode;
  final int emsMode;
  final bool isBusy;
  final String? errorMessage;
  final bool requiresEmsConfirmation;

  ControlPanelState copyWith({
    int? suck,
    int? vibe,
    int? ems,
    int? suckMode,
    int? vibeMode,
    int? emsMode,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
    bool? requiresEmsConfirmation,
  }) {
    return ControlPanelState(
      suck: suck ?? this.suck,
      vibe: vibe ?? this.vibe,
      ems: ems ?? this.ems,
      suckMode: suckMode ?? this.suckMode,
      vibeMode: vibeMode ?? this.vibeMode,
      emsMode: emsMode ?? this.emsMode,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      requiresEmsConfirmation:
          requiresEmsConfirmation ?? this.requiresEmsConfirmation,
    );
  }
}

class ControlPanelController extends Notifier<ControlPanelState> {
  @override
  ControlPanelState build() {
    return const ControlPanelState();
  }

  Future<void> refreshStatus() async {
    await _runCommand(() => ref.read(controlDeviceUseCaseProvider).getStatus());
  }

  Future<void> setSuck(int value) async {
    await _runCommand(
      () => ref.read(controlDeviceUseCaseProvider).setSuck(intensity: value),
    );
  }

  Future<void> setVibe(int value) async {
    await _runCommand(
      () => ref.read(controlDeviceUseCaseProvider).setVibe(intensity: value),
    );
  }

  Future<void> setEms(int value) async {
    await _runCommand(
      () => ref.read(controlDeviceUseCaseProvider).setEms(intensity: value),
    );
  }

  Future<void> stopAll() async {
    await _runCommand(() => ref.read(controlDeviceUseCaseProvider).stopAll());
  }

  void clearError() {
    state = state.copyWith(clearError: true, requiresEmsConfirmation: false);
  }

  Future<void> _runCommand(Future<DeviceStatus> Function() execute) async {
    state = state.copyWith(
      isBusy: true,
      clearError: true,
      requiresEmsConfirmation: false,
    );

    try {
      final DeviceStatus status = await execute();
      state = state.copyWith(
        suck: status.suckIntensity,
        vibe: status.vibeIntensity,
        ems: status.emsIntensity,
        suckMode: status.suckMode,
        vibeMode: status.vibeMode,
        emsMode: status.emsMode,
        isBusy: false,
      );
    } on Failure catch (failure) {
      final bool confirmationRequired =
          failure.code == FailureCode.validation &&
          failure.details?['reason'] == 'confirmation_required';

      state = state.copyWith(
        isBusy: false,
        errorMessage: failure.message,
        requiresEmsConfirmation: confirmationRequired,
      );
    } catch (_) {
      state = state.copyWith(isBusy: false, errorMessage: '控制失败，请稍后重试。');
    }
  }
}

final controlPanelControllerProvider =
    NotifierProvider<ControlPanelController, ControlPanelState>(
      ControlPanelController.new,
    );

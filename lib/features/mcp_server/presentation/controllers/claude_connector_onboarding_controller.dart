import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/models/active_device_adapter_readiness.dart';
import '../../../../application/providers/application_providers.dart';
import '../../../../domain/entities/claude_connector_onboarding_record.dart';

class ClaudeConnectorOnboardingState {
  const ClaudeConnectorOnboardingState({
    this.isLoading = true,
    this.isSaving = false,
    this.record,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final ClaudeConnectorOnboardingRecord? record;
  final String? errorMessage;

  bool matchesReadiness(ActiveDeviceAdapterReadiness readiness) {
    return record?.matches(
          deviceId: readiness.deviceId,
          adapterId: readiness.adapterId,
        ) ??
        false;
  }

  ClaudeConnectorOnboardingState copyWith({
    bool? isLoading,
    bool? isSaving,
    ClaudeConnectorOnboardingRecord? record,
    String? errorMessage,
    bool clearError = false,
    bool clearRecord = false,
  }) {
    return ClaudeConnectorOnboardingState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      record: clearRecord ? null : (record ?? this.record),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ClaudeConnectorOnboardingController
    extends Notifier<ClaudeConnectorOnboardingState> {
  @override
  ClaudeConnectorOnboardingState build() {
    Future<void>.microtask(load);
    return const ClaudeConnectorOnboardingState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final record = await ref
          .read(claudeConnectorOnboardingRepositoryProvider)
          .load();
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(isLoading: false, record: record);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: '读取 Claude 接入状态失败。',
      );
    }
  }

  Future<void> markCompleted(
    ActiveDeviceAdapterReadiness readiness,
  ) async {
    final String? deviceId = readiness.deviceId;
    final String? adapterId = readiness.adapterId;
    if (deviceId == null ||
        deviceId.isEmpty ||
        adapterId == null ||
        adapterId.isEmpty) {
      state = state.copyWith(errorMessage: '当前设备还不能记录 Claude 接入状态。');
      return;
    }

    final ClaudeConnectorOnboardingRecord record =
        ClaudeConnectorOnboardingRecord(
          deviceId: deviceId,
          adapterId: adapterId,
          completedAt: DateTime.now(),
        );

    state = state.copyWith(isSaving: true, clearError: true, record: record);
    try {
      await ref
          .read(claudeConnectorOnboardingRepositoryProvider)
          .save(record);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(isSaving: false, record: record);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        isSaving: false,
        errorMessage: '保存 Claude 接入状态失败。',
      );
    }
  }

  Future<void> reset() async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await ref.read(claudeConnectorOnboardingRepositoryProvider).reset();
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(isSaving: false, clearRecord: true);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        isSaving: false,
        errorMessage: '重置 Claude 接入状态失败。',
      );
    }
  }
}

final claudeConnectorOnboardingControllerProvider = NotifierProvider<
  ClaudeConnectorOnboardingController,
  ClaudeConnectorOnboardingState
>(ClaudeConnectorOnboardingController.new);

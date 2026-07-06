import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../../domain/entities/background_stability_checklist.dart';

class BackgroundChecklistState {
  const BackgroundChecklistState({
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
    this.checklist = const BackgroundStabilityChecklist(),
  });

  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final BackgroundStabilityChecklist checklist;

  BackgroundChecklistState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    BackgroundStabilityChecklist? checklist,
    bool clearError = false,
  }) {
    return BackgroundChecklistState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      checklist: checklist ?? this.checklist,
    );
  }
}

class BackgroundChecklistController extends Notifier<BackgroundChecklistState> {
  @override
  BackgroundChecklistState build() {
    unawaited(load());
    return const BackgroundChecklistState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final checklist = await ref
          .read(backgroundStabilityChecklistRepositoryProvider)
          .load();
      state = state.copyWith(isLoading: false, checklist: checklist);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '加载验收清单失败。',
      );
    }
  }

  Future<void> update({
    bool? lockScreen30Min,
    bool? switchBackgroundAndBack,
    bool? autoReconnectAfterDisconnect,
    bool? mcpCallAvailableInBackground,
  }) async {
    final next = state.checklist.copyWith(
      lockScreen30Min: lockScreen30Min,
      switchBackgroundAndBack: switchBackgroundAndBack,
      autoReconnectAfterDisconnect: autoReconnectAfterDisconnect,
      mcpCallAvailableInBackground: mcpCallAvailableInBackground,
      lastUpdatedAt: DateTime.now(),
    );
    state = state.copyWith(checklist: next, isSaving: true, clearError: true);
    try {
      await ref
          .read(backgroundStabilityChecklistRepositoryProvider)
          .save(next);
      state = state.copyWith(isSaving: false);
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '保存验收清单失败。',
      );
    }
  }

  Future<void> reset() async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await ref.read(backgroundStabilityChecklistRepositoryProvider).reset();
      final checklist = await ref
          .read(backgroundStabilityChecklistRepositoryProvider)
          .load();
      state = state.copyWith(
        isSaving: false,
        checklist: checklist,
      );
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '重置验收清单失败。',
      );
    }
  }
}

final backgroundChecklistControllerProvider =
    NotifierProvider<BackgroundChecklistController, BackgroundChecklistState>(
      BackgroundChecklistController.new,
    );

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../../domain/entities/adapter_manifest.dart';

class DeviceManagerState {
  const DeviceManagerState({
    this.adapters = const <AdapterManifest>[],
    this.isImporting = false,
    this.errorMessage,
    this.successMessage,
  });

  final List<AdapterManifest> adapters;
  final bool isImporting;
  final String? errorMessage;
  final String? successMessage;

  DeviceManagerState copyWith({
    List<AdapterManifest>? adapters,
    bool? isImporting,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return DeviceManagerState(
      adapters: adapters ?? this.adapters,
      isImporting: isImporting ?? this.isImporting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

class DeviceManagerController extends Notifier<DeviceManagerState> {
  @override
  DeviceManagerState build() {
    ref.listen<AsyncValue<List<AdapterManifest>>>(adapterListProvider, (
      previous,
      next,
    ) {
      next.whenData((List<AdapterManifest> adapters) {
        state = state.copyWith(adapters: adapters);
      });
      next.whenOrNull(
        error: (Object error, StackTrace stackTrace) {
          state = state.copyWith(
            errorMessage: 'Failed to load adapter list.',
            clearSuccess: true,
          );
        },
      );
    });
    return const DeviceManagerState();
  }

  Future<void> importJsonText(String rawJson) async {
    if (rawJson.trim().isEmpty) {
      state = state.copyWith(
        isImporting: false,
        errorMessage: '请输入适配器 JSON 内容后再导入。',
        clearSuccess: true,
      );
      return;
    }

    state = state.copyWith(
      isImporting: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final Object decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Adapter file must be a JSON object.');
      }

      await ref.read(manageAdapterUseCaseProvider).importManifestJson(decoded);
      state = state.copyWith(
        isImporting: false,
        successMessage: '适配器导入成功。',
      );
    } catch (error) {
      state = state.copyWith(
        isImporting: false,
        errorMessage: '适配器导入失败：$error',
      );
    }
  }

  void clearFeedback() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final adapterListProvider = StreamProvider<List<AdapterManifest>>((ref) {
  return ref.read(manageAdapterUseCaseProvider).watchAvailableAdapters();
});

final deviceManagerControllerProvider =
    NotifierProvider<DeviceManagerController, DeviceManagerState>(
      DeviceManagerController.new,
    );

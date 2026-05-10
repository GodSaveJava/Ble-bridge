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
    this.importedAdapterId,
  });

  final List<AdapterManifest> adapters;
  final bool isImporting;
  final String? errorMessage;
  final String? successMessage;
  final String? importedAdapterId;

  DeviceManagerState copyWith({
    List<AdapterManifest>? adapters,
    bool? isImporting,
    String? errorMessage,
    String? successMessage,
    String? importedAdapterId,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearImportedAdapterId = false,
  }) {
    return DeviceManagerState(
      adapters: adapters ?? this.adapters,
      isImporting: isImporting ?? this.isImporting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      importedAdapterId: clearImportedAdapterId
          ? null
          : (importedAdapterId ?? this.importedAdapterId),
    );
  }
}

class DeviceManagerController extends Notifier<DeviceManagerState> {
  @override
  DeviceManagerState build() {
    ref.listen<AsyncValue<List<AdapterManifest>>>(adapterListProvider, (
      _,
      next,
    ) {
      next.whenData((List<AdapterManifest> adapters) {
        state = state.copyWith(adapters: adapters);
      });
      next.whenOrNull(
        error: (Object error, StackTrace stackTrace) {
          state = state.copyWith(
            errorMessage: '加载适配器列表失败。',
            clearSuccess: true,
            clearImportedAdapterId: true,
          );
        },
      );
    });
    return const DeviceManagerState();
  }

  Future<void> precheckJsonText(String rawJson) async {
    if (rawJson.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: '请输入适配器 JSON 内容后再预检。',
        clearSuccess: true,
        clearImportedAdapterId: true,
      );
      return;
    }

    try {
      final Object decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('适配器文件必须是 JSON 对象。');
      }

      final AdapterManifest manifest = AdapterManifest.fromJson(decoded);
      final int emsMax = manifest.ranges.emsIntensity.max;
      if (emsMax > 8) {
        state = state.copyWith(
          successMessage: '预检通过（警告）：EMS 上限为 $emsMax，超过建议软上限 8。',
          clearError: true,
          clearImportedAdapterId: true,
        );
        return;
      }

      state = state.copyWith(
        successMessage: '预检通过：结构与核心安全范围校验成功。',
        clearError: true,
        clearImportedAdapterId: true,
      );
    } catch (error) {
      state = state.copyWith(
        errorMessage: '预检失败：$error',
        clearSuccess: true,
        clearImportedAdapterId: true,
      );
    }
  }

  Future<void> importJsonText(String rawJson) async {
    if (rawJson.trim().isEmpty) {
      state = state.copyWith(
        isImporting: false,
        errorMessage: '请输入适配器 JSON 内容后再导入。',
        clearSuccess: true,
        clearImportedAdapterId: true,
      );
      return;
    }

    state = state.copyWith(
      isImporting: true,
      clearError: true,
      clearSuccess: true,
      clearImportedAdapterId: true,
    );

    try {
      final Object decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Adapter file must be a JSON object.');
      }

      AdapterManifest.fromJson(decoded);
      await ref.read(manageAdapterUseCaseProvider).importManifestJson(decoded);

      state = state.copyWith(
        isImporting: false,
        successMessage: '适配器导入成功。',
        importedAdapterId: decoded['adapterId'] as String?,
      );
    } catch (error) {
      state = state.copyWith(
        isImporting: false,
        errorMessage: '适配器导入失败：$error',
        clearImportedAdapterId: true,
      );
    }
  }

  void clearFeedback() {
    state = state.copyWith(
      clearError: true,
      clearSuccess: true,
      clearImportedAdapterId: true,
    );
  }

  void consumeImportedAdapterId() {
    state = state.copyWith(clearImportedAdapterId: true);
  }
}

final adapterListProvider = StreamProvider<List<AdapterManifest>>((ref) {
  return ref.read(manageAdapterUseCaseProvider).watchAvailableAdapters();
});

final deviceManagerControllerProvider =
    NotifierProvider<DeviceManagerController, DeviceManagerState>(
      DeviceManagerController.new,
    );

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../../domain/entities/active_adapter_binding.dart';
import '../../../../domain/entities/adapter_manifest.dart';
import '../../../../domain/entities/verified_adapter_record.dart';

class AdapterRecommendation {
  const AdapterRecommendation({
    required this.manifest,
    required this.reasons,
    required this.score,
    required this.isCurrentBinding,
    this.verificationStatus,
  });

  final AdapterManifest manifest;
  final List<String> reasons;
  final int score;
  final bool isCurrentBinding;
  final AdapterVerificationStatus? verificationStatus;
}

class DeviceManagerState {
  const DeviceManagerState({
    this.adapters = const <AdapterManifest>[],
    this.isImporting = false,
    this.isPickingFile = false,
    this.errorMessage,
    this.successMessage,
    this.importedAdapterId,
    this.exportedJsonText,
    this.exportedFilePath,
    this.pickedJsonText,
  });

  final List<AdapterManifest> adapters;
  final bool isImporting;
  final bool isPickingFile;
  final String? errorMessage;
  final String? successMessage;
  final String? importedAdapterId;
  final String? exportedJsonText;
  final String? exportedFilePath;
  final String? pickedJsonText;

  DeviceManagerState copyWith({
    List<AdapterManifest>? adapters,
    bool? isImporting,
    bool? isPickingFile,
    String? errorMessage,
    String? successMessage,
    String? importedAdapterId,
    String? exportedJsonText,
    String? exportedFilePath,
    String? pickedJsonText,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearImportedAdapterId = false,
    bool clearExportedJsonText = false,
    bool clearExportedFilePath = false,
    bool clearPickedJsonText = false,
  }) {
    return DeviceManagerState(
      adapters: adapters ?? this.adapters,
      isImporting: isImporting ?? this.isImporting,
      isPickingFile: isPickingFile ?? this.isPickingFile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      importedAdapterId: clearImportedAdapterId
          ? null
          : (importedAdapterId ?? this.importedAdapterId),
      exportedJsonText: clearExportedJsonText
          ? null
          : (exportedJsonText ?? this.exportedJsonText),
      exportedFilePath: clearExportedFilePath
          ? null
          : (exportedFilePath ?? this.exportedFilePath),
      pickedJsonText: clearPickedJsonText
          ? null
          : (pickedJsonText ?? this.pickedJsonText),
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

  Future<void> pickJsonFile() async {
    state = state.copyWith(
      isPickingFile: true,
      clearError: true,
      clearSuccess: true,
      clearPickedJsonText: true,
    );

    try {
      final String? jsonText = await ref
          .read(adapterImportServiceProvider)
          .pickJsonText();
      if (jsonText == null || jsonText.trim().isEmpty) {
        state = state.copyWith(
          isPickingFile: false,
          successMessage: '已取消选择文件。',
          clearError: true,
        );
        return;
      }

      state = state.copyWith(
        isPickingFile: false,
        pickedJsonText: jsonText,
        successMessage: '已读取本地 JSON 文件，可继续预检或导入。',
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isPickingFile: false,
        errorMessage: '读取本地文件失败：$error',
        clearSuccess: true,
        clearPickedJsonText: true,
      );
    }
  }

  Future<void> exportAdapterJson(String adapterId) async {
    try {
      final String jsonText = await ref
          .read(manageAdapterUseCaseProvider)
          .exportManifestJson(adapterId);
      state = state.copyWith(
        exportedJsonText: jsonText,
        successMessage: '适配器 JSON 导出成功，可继续复制或分享。',
        clearError: true,
        clearImportedAdapterId: true,
        clearExportedFilePath: true,
      );
    } catch (error) {
      state = state.copyWith(
        errorMessage: '导出适配器失败：$error',
        clearSuccess: true,
        clearImportedAdapterId: true,
        clearExportedJsonText: true,
        clearExportedFilePath: true,
      );
    }
  }

  Future<void> saveAdapterJsonFile(String adapterId) async {
    try {
      final String filePath = await ref
          .read(manageAdapterUseCaseProvider)
          .saveManifestJsonFile(adapterId);
      state = state.copyWith(
        exportedFilePath: filePath,
        successMessage: '适配器 JSON 已保存到本地文件。',
        clearError: true,
        clearImportedAdapterId: true,
      );
    } catch (error) {
      state = state.copyWith(
        errorMessage: '保存适配器文件失败：$error',
        clearSuccess: true,
        clearImportedAdapterId: true,
        clearExportedFilePath: true,
      );
    }
  }

  Future<void> deleteAdapter(String adapterId) async {
    try {
      await ref.read(manageAdapterUseCaseProvider).removeManifest(adapterId);
      state = state.copyWith(
        successMessage: '适配器已删除。',
        clearError: true,
        clearImportedAdapterId: true,
        clearExportedJsonText: true,
        clearExportedFilePath: true,
      );
    } catch (error) {
      state = state.copyWith(
        errorMessage: '删除适配器失败：$error',
        clearSuccess: true,
        clearImportedAdapterId: true,
      );
    }
  }

  Future<void> revokeAdapterVerification({
    required String adapterId,
    required String deviceFingerprint,
  }) async {
    try {
      await ref
          .read(manageAdapterUseCaseProvider)
          .revokeVerification(
            adapterId: adapterId,
            deviceFingerprint: deviceFingerprint,
          );
      state = state.copyWith(
        successMessage: '当前设备的本地验证已撤销。',
        clearError: true,
        clearImportedAdapterId: true,
      );
    } catch (error) {
      state = state.copyWith(
        errorMessage: '撤销验证失败：$error',
        clearSuccess: true,
        clearImportedAdapterId: true,
      );
    }
  }

  Future<void> bindAdapterForCurrentDevice({
    required String adapterId,
    required String deviceFingerprint,
  }) async {
    try {
      await ref
          .read(manageAdapterUseCaseProvider)
          .bindAdapterToDevice(
            adapterId: adapterId,
            deviceFingerprint: deviceFingerprint,
          );
      state = state.copyWith(
        successMessage: '已将当前设备切换到所选适配器。',
        clearError: true,
        clearImportedAdapterId: true,
      );
    } catch (error) {
      state = state.copyWith(
        errorMessage: '切换当前设备适配器失败：$error',
        clearSuccess: true,
        clearImportedAdapterId: true,
      );
    }
  }

  void clearFeedback() {
    state = state.copyWith(
      clearError: true,
      clearSuccess: true,
      clearImportedAdapterId: true,
      clearExportedJsonText: true,
      clearExportedFilePath: true,
      clearPickedJsonText: true,
    );
  }

  void consumeImportedAdapterId() {
    state = state.copyWith(clearImportedAdapterId: true);
  }

  void consumeExportedJsonText() {
    state = state.copyWith(clearExportedJsonText: true);
  }

  void consumeExportedFilePath() {
    state = state.copyWith(clearExportedFilePath: true);
  }

  void consumePickedJsonText() {
    state = state.copyWith(clearPickedJsonText: true);
  }
}

final adapterListProvider = StreamProvider<List<AdapterManifest>>((ref) {
  return ref.read(manageAdapterUseCaseProvider).watchAvailableAdapters();
});

final verifiedAdapterRecordsProvider =
    StreamProvider<List<VerifiedAdapterRecord>>((ref) {
      return ref.read(verifiedAdapterRepositoryProvider).watchAll();
    });

final activeAdapterBindingsProvider =
    StreamProvider<List<ActiveAdapterBinding>>((ref) {
      return ref.read(manageAdapterUseCaseProvider).watchDeviceBindings();
    });

final activeAdapterRecommendationsProvider =
    Provider<AsyncValue<List<AdapterRecommendation>>>((ref) {
      final activeStatusAsync = ref.watch(activeDeviceStatusStreamProvider);
      final adaptersAsync = ref.watch(adapterListProvider);
      final recordsAsync = ref.watch(verifiedAdapterRecordsProvider);
      final bindingsAsync = ref.watch(activeAdapterBindingsProvider);

      if (activeStatusAsync.hasError) {
        return AsyncError<List<AdapterRecommendation>>(
          activeStatusAsync.error!,
          activeStatusAsync.stackTrace!,
        );
      }
      if (adaptersAsync.hasError) {
        return AsyncError<List<AdapterRecommendation>>(
          adaptersAsync.error!,
          adaptersAsync.stackTrace!,
        );
      }
      if (recordsAsync.hasError) {
        return AsyncError<List<AdapterRecommendation>>(
          recordsAsync.error!,
          recordsAsync.stackTrace!,
        );
      }
      if (bindingsAsync.hasError) {
        return AsyncError<List<AdapterRecommendation>>(
          bindingsAsync.error!,
          bindingsAsync.stackTrace!,
        );
      }

      if (activeStatusAsync is! AsyncData ||
          adaptersAsync is! AsyncData<List<AdapterManifest>> ||
          recordsAsync is! AsyncData<List<VerifiedAdapterRecord>> ||
          bindingsAsync is! AsyncData<List<ActiveAdapterBinding>>) {
        return const AsyncLoading<List<AdapterRecommendation>>();
      }

      final activeDevice = ref
          .watch(hardwareRepositoryProvider)
          .getActiveDevice();

      return AsyncData<List<AdapterRecommendation>>(
        buildAdapterRecommendations(
          manifests: adaptersAsync.value,
          activeDeviceId: activeStatusAsync.value!.deviceId,
          activeDeviceName: activeDevice?.name,
          activeBleNamePrefix: activeDevice?.bleNamePrefix,
          bindings: bindingsAsync.value,
          records: recordsAsync.value,
        ),
      );
    });

final deviceManagerControllerProvider =
    NotifierProvider<DeviceManagerController, DeviceManagerState>(
      DeviceManagerController.new,
    );

List<AdapterRecommendation> buildAdapterRecommendations({
  required List<AdapterManifest> manifests,
  required String? activeDeviceId,
  required String? activeDeviceName,
  required String? activeBleNamePrefix,
  required List<ActiveAdapterBinding> bindings,
  required List<VerifiedAdapterRecord> records,
}) {
  if (activeDeviceId == null || activeDeviceId.isEmpty || manifests.isEmpty) {
    return const <AdapterRecommendation>[];
  }

  final ActiveAdapterBinding? currentBinding = _findBinding(
    bindings: bindings,
    deviceFingerprint: activeDeviceId,
  );

  final List<AdapterRecommendation> recommendations = manifests
      .map(
        (manifest) => _buildAdapterRecommendation(
          manifest: manifest,
          activeDeviceId: activeDeviceId,
          activeDeviceName: activeDeviceName,
          activeBleNamePrefix: activeBleNamePrefix,
          currentBinding: currentBinding,
          records: records,
        ),
      )
      .toList();

  recommendations.sort((left, right) {
    final int scoreCompare = right.score.compareTo(left.score);
    if (scoreCompare != 0) {
      return scoreCompare;
    }
    return left.manifest.displayName.compareTo(right.manifest.displayName);
  });
  return recommendations;
}

AdapterRecommendation _buildAdapterRecommendation({
  required AdapterManifest manifest,
  required String activeDeviceId,
  required String? activeDeviceName,
  required String? activeBleNamePrefix,
  required ActiveAdapterBinding? currentBinding,
  required List<VerifiedAdapterRecord> records,
}) {
  final List<String> reasons = <String>[];
  int score = manifest.matching.priority;

  final bool isCurrentBinding = currentBinding?.adapterId == manifest.adapterId;
  if (isCurrentBinding) {
    score += 1000;
    reasons.add('当前设备已经绑定这份适配器');
  }

  final String? matchedPrefix = _matchBlePrefix(
    prefixes: manifest.bleNamePrefixes,
    activeDeviceName: activeDeviceName,
    activeBleNamePrefix: activeBleNamePrefix,
  );
  if (matchedPrefix != null) {
    score += 500;
    reasons.add('设备前缀与模板匹配：$matchedPrefix');
  }

  final VerifiedAdapterRecord? record = _findRecord(
    records: records,
    adapterId: manifest.adapterId,
    deviceFingerprint: activeDeviceId,
  );

  switch (record?.status) {
    case AdapterVerificationStatus.verified:
      score += 800;
      reasons.add('这份适配器已经在当前设备上验证通过');
    case AdapterVerificationStatus.needsReverify:
      score += 200;
      reasons.add('这份适配器曾被使用，但现在需要重新验证');
    case AdapterVerificationStatus.revoked:
      score -= 200;
      reasons.add('这份适配器的历史验证已被撤销');
    case AdapterVerificationStatus.failed:
      score -= 100;
      reasons.add('这份适配器在当前设备上曾验证失败');
    case AdapterVerificationStatus.unverified:
    case null:
      reasons.add('导入后仍需在本机完成低强度验证');
  }

  if (manifest.capabilities.supportsSuck &&
      manifest.capabilities.supportsVibe &&
      manifest.capabilities.supportsEms &&
      manifest.capabilities.supportsStopAll) {
    score += 80;
    reasons.add('支持吸吮、震动、微电流和一键停止');
  }

  return AdapterRecommendation(
    manifest: manifest,
    reasons: reasons,
    score: score,
    isCurrentBinding: isCurrentBinding,
    verificationStatus: record?.status,
  );
}

String? _matchBlePrefix({
  required List<String> prefixes,
  required String? activeDeviceName,
  required String? activeBleNamePrefix,
}) {
  final String normalizedName = activeDeviceName?.toUpperCase() ?? '';
  final String normalizedPrefix = activeBleNamePrefix?.toUpperCase() ?? '';

  for (final String prefix in prefixes) {
    final String normalizedCandidate = prefix.toUpperCase();
    if (normalizedCandidate.isEmpty) {
      continue;
    }
    if (normalizedCandidate == normalizedPrefix ||
        normalizedName.contains(normalizedCandidate)) {
      return prefix;
    }
  }
  return null;
}

ActiveAdapterBinding? _findBinding({
  required List<ActiveAdapterBinding> bindings,
  required String? deviceFingerprint,
}) {
  if (deviceFingerprint == null || deviceFingerprint.isEmpty) {
    return null;
  }
  for (final binding in bindings) {
    if (binding.deviceFingerprint == deviceFingerprint) {
      return binding;
    }
  }
  return null;
}

VerifiedAdapterRecord? _findRecord({
  required List<VerifiedAdapterRecord> records,
  required String adapterId,
  required String? deviceFingerprint,
}) {
  if (deviceFingerprint == null || deviceFingerprint.isEmpty) {
    return null;
  }
  for (final record in records) {
    if (record.adapterId == adapterId &&
        record.target.deviceFingerprint == deviceFingerprint) {
      return record;
    }
  }
  return null;
}

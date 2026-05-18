import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../../domain/entities/active_adapter_binding.dart';
import '../../../../domain/entities/adapter_manifest.dart';
import '../../../../domain/entities/verified_adapter_record.dart';
import '../../../../shared/widgets/toylink_background.dart';
import '../controllers/device_manager_controller.dart';

class DeviceManagerPage extends ConsumerStatefulWidget {
  const DeviceManagerPage({super.key});

  @override
  ConsumerState<DeviceManagerPage> createState() => _DeviceManagerPageState();
}

enum _GuidanceAction {
  goScan,
  bindRecommended,
  verifyCurrent,
  verifyRecommended,
  switchToRecommended,
  goControl,
  goMcp,
}

class _DeviceManagerGuidance {
  const _DeviceManagerGuidance({
    required this.title,
    required this.message,
    required this.actions,
  });

  final String title;
  final String message;
  final List<_GuidanceAction> actions;
}

String _recommendationStatusLabel(AdapterRecommendation recommendation) {
  return switch (recommendation.verificationStatus) {
    AdapterVerificationStatus.verified => '已验证',
    AdapterVerificationStatus.needsReverify => '需重验',
    AdapterVerificationStatus.revoked => '已撤销',
    AdapterVerificationStatus.failed => '曾失败',
    AdapterVerificationStatus.unverified || null => '待验证',
  };
}

class _DeviceManagerPageState extends ConsumerState<DeviceManagerPage> {
  final TextEditingController _jsonController = TextEditingController();
  late final ProviderSubscription<DeviceManagerState> _importListener;
  late final ProviderSubscription<DeviceManagerState> _pickFileListener;
  late final ProviderSubscription<DeviceManagerState> _exportListener;
  late final ProviderSubscription<DeviceManagerState> _fileExportListener;

  @override
  void initState() {
    super.initState();
    _importListener = ref.listenManual<DeviceManagerState>(
      deviceManagerControllerProvider,
      (_, next) {
        final String? adapterId = next.importedAdapterId;
        if (adapterId == null || adapterId.isEmpty) {
          return;
        }
        ref
            .read(deviceManagerControllerProvider.notifier)
            .consumeImportedAdapterId();
        if (!mounted) {
          return;
        }
        context.push('/verification/$adapterId');
      },
    );
    _pickFileListener = ref.listenManual<DeviceManagerState>(
      deviceManagerControllerProvider,
      (_, next) {
        final String? pickedJsonText = next.pickedJsonText;
        if (pickedJsonText == null || pickedJsonText.isEmpty) {
          return;
        }
        _jsonController.text = pickedJsonText;
        _jsonController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: pickedJsonText.length,
        );
        ref
            .read(deviceManagerControllerProvider.notifier)
            .consumePickedJsonText();
      },
    );
    _exportListener = ref.listenManual<DeviceManagerState>(
      deviceManagerControllerProvider,
      (_, next) {
        final String? exportedJsonText = next.exportedJsonText;
        if (exportedJsonText == null || exportedJsonText.isEmpty) {
          return;
        }
        _jsonController.text = exportedJsonText;
        _jsonController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: exportedJsonText.length,
        );
        ref
            .read(deviceManagerControllerProvider.notifier)
            .consumeExportedJsonText();
      },
    );
    _fileExportListener = ref.listenManual<DeviceManagerState>(
      deviceManagerControllerProvider,
      (_, next) {
        final String? exportedFilePath = next.exportedFilePath;
        if (exportedFilePath == null || exportedFilePath.isEmpty || !mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('文件已保存：$exportedFilePath')));
        ref
            .read(deviceManagerControllerProvider.notifier)
            .consumeExportedFilePath();
      },
    );
  }

  @override
  void dispose() {
    _importListener.close();
    _pickFileListener.close();
    _exportListener.close();
    _fileExportListener.close();
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _openFormWizard() async {
    final Map<String, Object?>? result = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (_) => const _AdapterWizardDialog(),
    );
    if (result == null) {
      return;
    }
    _jsonController.text = const JsonEncoder.withIndent('  ').convert(result);
  }

  Widget _buildGuidanceActionButton({
    required BuildContext context,
    required _GuidanceAction action,
    required String? activeDeviceId,
    required ActiveAdapterBinding? currentBinding,
    required AdapterManifest? currentBindingManifest,
    required AdapterRecommendation? recommendedAdapter,
  }) {
    switch (action) {
      case _GuidanceAction.goScan:
        return FilledButton(
          onPressed: () => context.push('/scan'),
          child: const Text('去连接设备'),
        );
      case _GuidanceAction.bindRecommended:
        if (recommendedAdapter == null ||
            activeDeviceId == null ||
            activeDeviceId.isEmpty) {
          return const SizedBox.shrink();
        }
        return FilledButton.tonal(
          onPressed: () async {
            await ref
                .read(deviceManagerControllerProvider.notifier)
                .bindAdapterForCurrentDevice(
                  adapterId: recommendedAdapter.manifest.adapterId,
                  deviceFingerprint: activeDeviceId,
                );
          },
          child: const Text('绑定推荐模板'),
        );
      case _GuidanceAction.verifyCurrent:
        final String? adapterId =
            currentBindingManifest?.adapterId ?? currentBinding?.adapterId;
        if (adapterId == null || adapterId.isEmpty) {
          return const SizedBox.shrink();
        }
        return OutlinedButton(
          onPressed: () => context.push('/verification/$adapterId'),
          child: const Text('重新验证当前模板'),
        );
      case _GuidanceAction.verifyRecommended:
        if (recommendedAdapter == null) {
          return const SizedBox.shrink();
        }
        return OutlinedButton(
          onPressed: () => context.push(
            '/verification/${recommendedAdapter.manifest.adapterId}',
          ),
          child: const Text('开始验证推荐模板'),
        );
      case _GuidanceAction.switchToRecommended:
        if (recommendedAdapter == null ||
            activeDeviceId == null ||
            activeDeviceId.isEmpty) {
          return const SizedBox.shrink();
        }
        return OutlinedButton(
          onPressed: () async {
            await ref
                .read(deviceManagerControllerProvider.notifier)
                .bindAdapterForCurrentDevice(
                  adapterId: recommendedAdapter.manifest.adapterId,
                  deviceFingerprint: activeDeviceId,
                );
          },
          child: const Text('改用推荐模板'),
        );
      case _GuidanceAction.goControl:
        return OutlinedButton(
          onPressed: () => context.push(
            '/control?returnTo=/device-manager&returnLabel=返回设备管理',
          ),
          child: const Text('进入手动控制排查'),
        );
      case _GuidanceAction.goMcp:
        return OutlinedButton(
          onPressed: () => context.push('/mcp'),
          child: const Text('查看 MCP 状态'),
        );
    }
  }

  String _statusExplanation(VerifiedAdapterRecord? record) {
    if (record == null ||
        record.status == AdapterVerificationStatus.unverified) {
      return '这份适配器还没在当前设备上做过本机验证。';
    }

    return switch (record.status) {
      AdapterVerificationStatus.verified =>
        '这份适配器已经在当前设备上验证通过，可以继续用于 MCP 和 AI 控制。',
      AdapterVerificationStatus.failed =>
        '上次验证没有通过，通常表示当前模板和设备反应不一致，或测试步骤里有项目失败。',
      AdapterVerificationStatus.revoked =>
        '这份适配器的本机信任已被撤销，系统会继续拦住 AI 控制，直到重新验证通过。',
      AdapterVerificationStatus.needsReverify =>
        '这份适配器之前可用，但因为模板内容或验证条件变化，现在需要重新确认一次。${_statusReasonSuffix(record)}',
      AdapterVerificationStatus.unverified => '这份适配器还没在当前设备上做过本机验证。',
    };
  }

  String _statusActionHint(
    VerifiedAdapterRecord? record, {
    required bool hasActiveDevice,
    required bool isCurrentBinding,
  }) {
    if (!hasActiveDevice) {
      return '先连接设备，再绑定或验证适配器。';
    }
    if (!isCurrentBinding) {
      return '如果想让当前设备使用这份模板，先把它设为当前设备适配器。';
    }
    if (record == null ||
        record.status == AdapterVerificationStatus.unverified) {
      return '先做低强度验证，确认吸吮、震动和停止都符合预期。';
    }

    return switch (record.status) {
      AdapterVerificationStatus.verified => '可以回首页启动 MCP，或者先进入手动控制再确认一次。',
      AdapterVerificationStatus.failed => '先进入手动控制做低强度排查；如果反应不对，再改用推荐模板。',
      AdapterVerificationStatus.revoked => '需要重新验证后，系统才会恢复 MCP 和 AI 控制权限。',
      AdapterVerificationStatus.needsReverify => '先重新验证；如果反应和之前不一致，再改用推荐模板。',
      AdapterVerificationStatus.unverified => '先做低强度验证，确认吸吮、震动和停止都符合预期。',
    };
  }

  String _statusReasonSuffix(VerifiedAdapterRecord record) {
    final String? reason = record.revokedReason;
    if (reason == null || reason.trim().isEmpty) {
      return '';
    }
    return '原因：${_humanizeVerificationReason(reason)}';
  }

  String _humanizeVerificationReason(String reason) {
    final String normalized = reason.trim().toLowerCase();
    if (normalized == 'manifest changed') {
      return '适配器内容发生变化。';
    }
    if (normalized == 'manual revoke') {
      return '这份适配器被手动撤销信任。';
    }
    return reason;
  }

  @override
  Widget build(BuildContext context) {
    final DeviceManagerState state = ref.watch(deviceManagerControllerProvider);
    final recordsAsync = ref.watch(verifiedAdapterRecordsProvider);
    final bindingsAsync = ref.watch(activeAdapterBindingsProvider);
    final recommendationsAsync = ref.watch(
      activeAdapterRecommendationsProvider,
    );
    final activeStatus = ref.watch(activeDeviceStatusStreamProvider);
    final String? activeDeviceId = activeStatus.maybeWhen(
      data: (status) => status.deviceId,
      orElse: () => null,
    );
    final List<VerifiedAdapterRecord> records = recordsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <VerifiedAdapterRecord>[],
    );
    final List<ActiveAdapterBinding> bindings = bindingsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <ActiveAdapterBinding>[],
    );
    final ActiveAdapterBinding? currentBinding = _findBinding(
      bindings: bindings,
      deviceFingerprint: activeDeviceId,
    );
    final AdapterManifest? currentBindingManifest = _findManifest(
      manifests: state.adapters,
      adapterId: currentBinding?.adapterId,
    );
    final VerifiedAdapterRecord? currentBindingRecord = currentBinding == null
        ? null
        : _findRecord(
            records: records,
            adapterId: currentBinding.adapterId,
            deviceFingerprint: activeDeviceId,
          );
    final List<AdapterRecommendation> recommendations = recommendationsAsync
        .maybeWhen(
          data: (value) => value,
          orElse: () => const <AdapterRecommendation>[],
        );
    final AdapterRecommendation? recommendedAdapter = recommendations.isEmpty
        ? null
        : recommendations.first;
    final String currentStatusExplanation = _statusExplanation(
      currentBindingRecord,
    );
    final String currentStatusActionHint = _statusActionHint(
      currentBindingRecord,
      hasActiveDevice: activeDeviceId != null && activeDeviceId.isNotEmpty,
      isCurrentBinding: currentBinding != null,
    );
    final _DeviceManagerGuidance guidance;
    if (activeDeviceId == null || activeDeviceId.isEmpty) {
      guidance = const _DeviceManagerGuidance(
        title: '下一步建议',
        message: '当前还没有连接设备。先去扫描并连接设备，后面才能绑定模板、运行验证和启用 AI 控制。',
        actions: <_GuidanceAction>[_GuidanceAction.goScan],
      );
    } else if (currentBinding == null) {
      guidance = const _DeviceManagerGuidance(
        title: '下一步建议',
        message: '当前设备已经连接，但还没有绑定适配器。建议先绑定系统推荐模板，再开始低强度验证。',
        actions: <_GuidanceAction>[
          _GuidanceAction.bindRecommended,
          _GuidanceAction.verifyRecommended,
        ],
      );
    } else {
      final String adapterName =
          currentBindingManifest?.displayName ?? currentBinding.adapterId;
      switch (currentBindingRecord?.status) {
        case AdapterVerificationStatus.verified:
          guidance = _DeviceManagerGuidance(
            title: '下一步建议',
            message:
                '$adapterName 已经在当前设备上验证通过。现在可以进入手动控制做最后确认，或直接查看 MCP 状态准备交给 AI 调用。',
            actions: const <_GuidanceAction>[
              _GuidanceAction.goControl,
              _GuidanceAction.goMcp,
            ],
          );
        case AdapterVerificationStatus.needsReverify:
          guidance = _DeviceManagerGuidance(
            title: '下一步建议',
            message: '$adapterName 之前用过，但当前状态要求重新验证。建议先重跑低强度验证；如果反应不对，再改用推荐模板。',
            actions: const <_GuidanceAction>[
              _GuidanceAction.verifyCurrent,
              _GuidanceAction.switchToRecommended,
              _GuidanceAction.goControl,
            ],
          );
        case AdapterVerificationStatus.revoked:
          guidance = _DeviceManagerGuidance(
            title: '下一步建议',
            message: '$adapterName 的本机信任已经被撤销。请先重新验证，确认反应正确后再继续交给 AI 控制。',
            actions: const <_GuidanceAction>[
              _GuidanceAction.verifyCurrent,
              _GuidanceAction.switchToRecommended,
            ],
          );
        case AdapterVerificationStatus.failed:
          guidance = _DeviceManagerGuidance(
            title: '下一步建议',
            message:
                '$adapterName 在当前设备上的验证曾失败。建议先进入手动控制低强度排查，或者直接切换到推荐模板后再验证。',
            actions: const <_GuidanceAction>[
              _GuidanceAction.goControl,
              _GuidanceAction.switchToRecommended,
              _GuidanceAction.verifyRecommended,
            ],
          );
        case AdapterVerificationStatus.unverified:
        case null:
          guidance = _DeviceManagerGuidance(
            title: '下一步建议',
            message:
                '$adapterName 已经绑定到当前设备，但还没有完成本机验证。下一步应该先跑低强度验证，再决定是否交给 AI 使用。',
            actions: const <_GuidanceAction>[
              _GuidanceAction.verifyCurrent,
              _GuidanceAction.goControl,
            ],
          );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('设备管理')),
      body: ToyLinkBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      '导入适配器 JSON',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text('建议先点“预检”查看结构与安全风险，再导入。也可用“表单生成”自动创建。'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _jsonController,
                      minLines: 8,
                      maxLines: 12,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '{"schemaVersion":1,...}',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: <Widget>[
                        FilledButton(
                          onPressed: state.isImporting
                              ? null
                              : () => ref
                                    .read(
                                      deviceManagerControllerProvider.notifier,
                                    )
                                    .importJsonText(_jsonController.text),
                          child: Text(state.isImporting ? '导入中...' : '导入'),
                        ),
                        OutlinedButton(
                          onPressed: state.isPickingFile
                              ? null
                              : () => ref
                                    .read(
                                      deviceManagerControllerProvider.notifier,
                                    )
                                    .pickJsonFile(),
                          child: Text(
                            state.isPickingFile ? '读取文件中...' : '选择本地文件',
                          ),
                        ),
                        OutlinedButton(
                          onPressed: state.isImporting
                              ? null
                              : () => ref
                                    .read(
                                      deviceManagerControllerProvider.notifier,
                                    )
                                    .precheckJsonText(_jsonController.text),
                          child: const Text('预检'),
                        ),
                        OutlinedButton(
                          onPressed: _openFormWizard,
                          child: const Text('表单生成'),
                        ),
                        OutlinedButton(
                          onPressed: state.adapters.isEmpty
                              ? null
                              : () {
                                  final Map<String, Object?> sample = state
                                      .adapters
                                      .first
                                      .toJson();
                                  _jsonController.text =
                                      const JsonEncoder.withIndent(
                                        '  ',
                                      ).convert(sample);
                                },
                          child: const Text('填充示例'),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            if (_jsonController.text.trim().isEmpty) {
                              return;
                            }
                            await Clipboard.setData(
                              ClipboardData(text: _jsonController.text),
                            );
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('JSON 已复制到剪贴板')),
                            );
                          },
                          child: const Text('复制 JSON'),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            _jsonController.clear();
                            ref
                                .read(deviceManagerControllerProvider.notifier)
                                .clearFeedback();
                          },
                          child: const Text('清空'),
                        ),
                      ],
                    ),
                    if (state.errorMessage != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        state.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (state.successMessage != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        state.successMessage!,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (recommendations.isNotEmpty) ...<Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        '系统推荐模板',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Text('我们会结合当前连接设备、历史验证结果和模板能力，优先推荐更适合先尝试的模板。'),
                      const SizedBox(height: 12),
                      for (final AdapterRecommendation recommendation
                          in recommendations.take(3)) ...<Widget>[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      recommendation.manifest.displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: recommendation.isCurrentBinding
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer
                                          : Theme.of(
                                              context,
                                            ).colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      recommendation.isCurrentBinding
                                          ? '当前正在使用'
                                          : _recommendationStatusLabel(
                                              recommendation,
                                            ),
                                      style: TextStyle(
                                        color: recommendation.isCurrentBinding
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onPrimaryContainer
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              for (final String reason
                                  in recommendation.reasons.take(3))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text('• $reason'),
                                ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  if (!recommendation.isCurrentBinding &&
                                      activeDeviceId != null &&
                                      activeDeviceId.isNotEmpty)
                                    FilledButton.tonal(
                                      onPressed: () async {
                                        await ref
                                            .read(
                                              deviceManagerControllerProvider
                                                  .notifier,
                                            )
                                            .bindAdapterForCurrentDevice(
                                              adapterId: recommendation
                                                  .manifest
                                                  .adapterId,
                                              deviceFingerprint: activeDeviceId,
                                            );
                                      },
                                      child: const Text('优先使用这份模板'),
                                    ),
                                  OutlinedButton(
                                    onPressed: () => context.push(
                                      '/verification/${recommendation.manifest.adapterId}',
                                    ),
                                    child: const Text('开始验证'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (activeDeviceId != null &&
                activeDeviceId.isNotEmpty &&
                state.adapters.isNotEmpty) ...<Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        '快速切换当前设备适配器',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text('当前设备：$activeDeviceId'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: state.adapters.map((
                          AdapterManifest manifest,
                        ) {
                          final bool isBoundToCurrentDevice =
                              currentBinding?.adapterId == manifest.adapterId;
                          if (isBoundToCurrentDevice) {
                            return FilledButton.tonal(
                              onPressed: null,
                              child: Text('当前：${manifest.displayName}'),
                            );
                          }
                          return OutlinedButton(
                            onPressed: () async {
                              await ref
                                  .read(
                                    deviceManagerControllerProvider.notifier,
                                  )
                                  .bindAdapterForCurrentDevice(
                                    adapterId: manifest.adapterId,
                                    deviceFingerprint: activeDeviceId,
                                  );
                            },
                            child: Text('切换到：${manifest.displayName}'),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      '当前设备适配器',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text('当前连接设备：${activeDeviceId ?? '未连接设备'}'),
                    const SizedBox(height: 4),
                    Text(
                      '当前适配器：${currentBindingManifest?.displayName ?? currentBinding?.adapterId ?? '尚未指定'}',
                    ),
                    const SizedBox(height: 4),
                    Text('验证状态：${_statusLabel(currentBindingRecord)}'),
                    const SizedBox(height: 6),
                    Text(currentStatusExplanation),
                    const SizedBox(height: 4),
                    Text(currentStatusActionHint),
                    const SizedBox(height: 8),
                    Text(
                      activeDeviceId == null || activeDeviceId.isEmpty
                          ? '请先连接设备，然后再指定当前设备使用的适配器。'
                          : currentBinding == null
                          ? '当前设备还没有绑定适配器，可在下方列表中选择“设为当前设备适配器”。'
                          : '当前设备后续会优先使用这份适配器执行 MCP 控制和验证检查。',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      guidance.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(guidance.message),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: guidance.actions.map((action) {
                        return _buildGuidanceActionButton(
                          context: context,
                          action: action,
                          activeDeviceId: activeDeviceId,
                          currentBinding: currentBinding,
                          currentBindingManifest: currentBindingManifest,
                          recommendedAdapter: recommendedAdapter,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      '已导入适配器',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (state.adapters.isEmpty) const Text('暂无适配器，请先导入。'),
                    for (final AdapterManifest manifest in state.adapters)
                      Builder(
                        builder: (_) {
                          final bool isCurrentBinding =
                              currentBinding?.adapterId == manifest.adapterId;
                          final VerifiedAdapterRecord? record = _findRecord(
                            records: records,
                            adapterId: manifest.adapterId,
                            deviceFingerprint: activeDeviceId,
                          );
                          final String verifyLabel = _statusLabel(record);
                          final String verifyTime = record == null
                              ? '最近验证：无'
                              : '最近验证：${record.updatedAt.toLocal().toString().split('.').first}';
                          final String stepSummary = _stepSummary(record);
                          final String verifyExplanation = _statusExplanation(
                            record,
                          );
                          final String actionHint = _statusActionHint(
                            record,
                            hasActiveDevice:
                                activeDeviceId != null &&
                                activeDeviceId.isNotEmpty,
                            isCurrentBinding: isCurrentBinding,
                          );
                          return ListTile(
                            dense: true,
                            title: Row(
                              children: <Widget>[
                                Expanded(child: Text(manifest.displayName)),
                                if (isCurrentBinding)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '当前设备',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              'ID: ${manifest.adapterId}\n'
                              'codec: ${manifest.codecKey}\n'
                              'version: ${manifest.version}\n'
                              '当前绑定：${isCurrentBinding ? '是' : '否'}\n'
                              '状态：$verifyLabel\n'
                              '$verifyTime\n'
                              '步骤：$stepSummary\n'
                              '说明：$verifyExplanation\n'
                              '建议：$actionHint',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (String value) async {
                                if (value == 'verify') {
                                  context.push(
                                    '/verification/${manifest.adapterId}',
                                  );
                                  return;
                                }
                                if (value == 'bind_current') {
                                  if (activeDeviceId == null ||
                                      activeDeviceId.isEmpty) {
                                    if (!context.mounted) {
                                      return;
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('请先连接设备，再设置当前适配器。'),
                                      ),
                                    );
                                    return;
                                  }
                                  await ref
                                      .read(
                                        deviceManagerControllerProvider
                                            .notifier,
                                      )
                                      .bindAdapterForCurrentDevice(
                                        adapterId: manifest.adapterId,
                                        deviceFingerprint: activeDeviceId,
                                      );
                                  return;
                                }
                                if (value == 'export') {
                                  await ref
                                      .read(
                                        deviceManagerControllerProvider
                                            .notifier,
                                      )
                                      .exportAdapterJson(manifest.adapterId);
                                  return;
                                }
                                if (value == 'save_file') {
                                  await ref
                                      .read(
                                        deviceManagerControllerProvider
                                            .notifier,
                                      )
                                      .saveAdapterJsonFile(manifest.adapterId);
                                  return;
                                }
                                if (value == 'revoke') {
                                  if (activeDeviceId == null ||
                                      activeDeviceId.isEmpty) {
                                    if (!context.mounted) {
                                      return;
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('请先连接设备后再撤销本地验证'),
                                      ),
                                    );
                                    return;
                                  }
                                  final bool?
                                  confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('撤销当前设备验证'),
                                        content: Text(
                                          '这会把 ${manifest.displayName} 在当前设备上的本地验证状态标记为“已撤销”，后续需要重新验证后才能继续信任使用。',
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              context,
                                            ).pop(false),
                                            child: const Text('取消'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text('确认撤销'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (confirmed != true) {
                                    return;
                                  }
                                  await ref
                                      .read(
                                        deviceManagerControllerProvider
                                            .notifier,
                                      )
                                      .revokeAdapterVerification(
                                        adapterId: manifest.adapterId,
                                        deviceFingerprint: activeDeviceId,
                                      );
                                  return;
                                }
                                if (value == 'delete') {
                                  final bool?
                                  confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('删除适配器'),
                                        content: Text(
                                          '这会删除 ${manifest.displayName} 的本地适配器定义。已保存的导出文件不会被删除。',
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              context,
                                            ).pop(false),
                                            child: const Text('取消'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text('确认删除'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (confirmed != true) {
                                    return;
                                  }
                                  await ref
                                      .read(
                                        deviceManagerControllerProvider
                                            .notifier,
                                      )
                                      .deleteAdapter(manifest.adapterId);
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  const <PopupMenuEntry<String>>[
                                    PopupMenuItem<String>(
                                      value: 'verify',
                                      child: Text('开始验证'),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'export',
                                      child: Text('导出 JSON'),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'save_file',
                                      child: Text('保存到本地文件'),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'revoke',
                                      child: Text('撤销当前设备验证'),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Text('删除适配器'),
                                    ),
                                  ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdapterWizardDialog extends StatefulWidget {
  const _AdapterWizardDialog();

  @override
  State<_AdapterWizardDialog> createState() => _AdapterWizardDialogState();
}

class _AdapterWizardDialogState extends State<_AdapterWizardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{4,8}(-[0-9a-fA-F]{4}){0,4}$|^[0-9a-fA-F]{32}$',
  );

  final _adapterId = TextEditingController(text: 'custom.toy.v1');
  final _displayName = TextEditingController(text: '我的设备适配器');
  final _blePrefix = TextEditingController(text: 'SOSEXY');
  final _serviceUuid = TextEditingController(
    text: '0000fff0-0000-1000-8000-00805f9b34fb',
  );
  final _writeUuid = TextEditingController(
    text: '0000fff3-0000-1000-8000-00805f9b34fb',
  );
  final _notifyUuid = TextEditingController(
    text: '0000fff4-0000-1000-8000-00805f9b34fb',
  );
  final _codecKey = TextEditingController(text: 'generic_triple_channel_v1');
  final _priority = TextEditingController(text: '100');
  final _modeMax = TextEditingController(text: '4');
  final _emsMax = TextEditingController(text: '20');

  bool _advancedMode = false;
  bool _writeWithoutResponse = true;
  bool _notifyRequired = false;
  bool _supportsSuck = true;
  bool _supportsVibe = true;
  bool _supportsEms = true;
  bool _supportsSetAll = true;
  bool _supportsStopAll = true;

  @override
  void dispose() {
    _adapterId.dispose();
    _displayName.dispose();
    _blePrefix.dispose();
    _serviceUuid.dispose();
    _writeUuid.dispose();
    _notifyUuid.dispose();
    _codecKey.dispose();
    _priority.dispose();
    _modeMax.dispose();
    _emsMax.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('表单生成适配器'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _field(_adapterId, 'adapterId', '如 custom.toy.v1'),
                _field(_displayName, 'displayName', '如 我的设备适配器'),
                _field(_blePrefix, 'bleNamePrefix', '如 SOSEXY'),
                _field(_codecKey, 'codecKey', '如 generic_triple_channel_v1'),
                _field(
                  _serviceUuid,
                  'serviceUuid',
                  '服务 UUID',
                  validator: _uuidValidator,
                ),
                _field(
                  _writeUuid,
                  'writeCharacteristicUuid',
                  '写入特征 UUID',
                  validator: _uuidValidator,
                ),
                _field(
                  _notifyUuid,
                  'notifyCharacteristicUuid',
                  '通知特征 UUID',
                  validator: _uuidValidator,
                ),
                SwitchListTile(
                  title: const Text('写入方式：writeWithoutResponse'),
                  value: _writeWithoutResponse,
                  onChanged: (value) =>
                      setState(() => _writeWithoutResponse = value),
                ),
                SwitchListTile(
                  title: const Text('连接后要求 notify'),
                  value: _notifyRequired,
                  onChanged: (value) => setState(() => _notifyRequired = value),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('开启高级模式'),
                  subtitle: const Text('配置能力开关、优先级、模式上限、EMS 上限'),
                  value: _advancedMode,
                  onChanged: (value) => setState(() => _advancedMode = value),
                ),
                if (_advancedMode) ...<Widget>[
                  _field(_priority, 'matching.priority', '如 100'),
                  _field(_modeMax, 'ranges.mode.max', '如 4'),
                  _field(_emsMax, 'ranges.emsIntensity.max', '最大 20'),
                  _boolSwitch('支持吮吸 supportsSuck', _supportsSuck, (v) {
                    setState(() => _supportsSuck = v);
                  }),
                  _boolSwitch('支持震动 supportsVibe', _supportsVibe, (v) {
                    setState(() => _supportsVibe = v);
                  }),
                  _boolSwitch('支持微电流 supportsEms', _supportsEms, (v) {
                    setState(() => _supportsEms = v);
                  }),
                  _boolSwitch('支持 setAll', _supportsSetAll, (v) {
                    setState(() => _supportsSetAll = v);
                  }),
                  _boolSwitch('支持 stopAll', _supportsStopAll, (v) {
                    setState(() => _supportsStopAll = v);
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _onGeneratePressed, child: const Text('生成')),
      ],
    );
  }

  Widget _boolSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator:
            validator ??
            (value) {
              if (value == null || value.trim().isEmpty) {
                return '该字段不能为空';
              }
              return null;
            },
      ),
    );
  }

  String? _uuidValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'UUID 不能为空';
    }
    if (!_uuidRegex.hasMatch(value.trim())) {
      return 'UUID 格式不正确';
    }
    return null;
  }

  Future<void> _onGeneratePressed() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final int modeMax = int.tryParse(_modeMax.text.trim()) ?? -1;
    final int emsMax = int.tryParse(_emsMax.text.trim()) ?? -1;
    final int priority = int.tryParse(_priority.text.trim()) ?? -1;

    if (modeMax < 1) {
      _showError('模式上限必须 >= 1');
      return;
    }
    if (emsMax < 0 || emsMax > 20) {
      _showError('EMS 上限必须在 0~20 之间');
      return;
    }
    if (priority < 0) {
      _showError('priority 不能为负数');
      return;
    }

    if (emsMax > 8) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('安全提醒'),
            content: Text('你设置的 EMS 上限是 $emsMax，超过默认软上限 8。建议仅在充分确认风险后使用。'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('返回修改'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('继续生成'),
              ),
            ],
          );
        },
      );
      if (confirmed != true) {
        return;
      }
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(_buildManifestJson(modeMax, emsMax, priority));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Map<String, Object?> _buildManifestJson(
    int modeMax,
    int emsMax,
    int priority,
  ) {
    return <String, Object?>{
      'schemaVersion': 1,
      'adapterId': _adapterId.text.trim(),
      'displayName': _displayName.text.trim(),
      'protocolKey': 'generic_triple_channel',
      'version': '1.0.0',
      'minAppVersion': '1.0.0',
      'adapterKind': 'codecBacked',
      'codecKey': _codecKey.text.trim(),
      'bleNamePrefixes': <String>[_blePrefix.text.trim()],
      'matching': <String, Object?>{
        'serviceUuids': <String>[_serviceUuid.text.trim()],
        'manufacturerDataPattern': null,
        'priority': priority,
      },
      'gatt': <String, Object?>{
        'serviceUuid': _serviceUuid.text.trim(),
        'writeCharacteristicUuid': _writeUuid.text.trim(),
        'notifyCharacteristicUuid': _notifyUuid.text.trim(),
        'writeWithoutResponse': _writeWithoutResponse,
      },
      'connection': <String, Object?>{
        'requiresBonding': false,
        'requestMtu': 185,
        'notifyRequired': _notifyRequired,
      },
      'capabilities': <String, Object?>{
        'supportsSuck': _supportsSuck,
        'supportsVibe': _supportsVibe,
        'supportsEms': _supportsEms,
        'supportsSetAll': _supportsSetAll,
        'supportsStopAll': _supportsStopAll,
      },
      'ranges': <String, Object?>{
        'suckIntensity': <String, Object?>{'min': 0, 'max': 100},
        'vibeIntensity': <String, Object?>{'min': 0, 'max': 100},
        'emsIntensity': <String, Object?>{'min': 0, 'max': emsMax},
        'mode': <String, Object?>{'min': 1, 'max': modeMax},
      },
      'notes': '由 ToyLink AI 表单向导生成，可继续手动调整。',
    };
  }
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

AdapterManifest? _findManifest({
  required List<AdapterManifest> manifests,
  required String? adapterId,
}) {
  if (adapterId == null || adapterId.isEmpty) {
    return null;
  }
  for (final manifest in manifests) {
    if (manifest.adapterId == adapterId) {
      return manifest;
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

String _statusLabel(VerifiedAdapterRecord? record) {
  if (record == null) {
    return '未验证';
  }
  return switch (record.status) {
    AdapterVerificationStatus.verified => '已验证',
    AdapterVerificationStatus.failed => '验证失败',
    AdapterVerificationStatus.revoked => '已撤销',
    AdapterVerificationStatus.needsReverify => '需重新验证',
    AdapterVerificationStatus.unverified => '未验证',
  };
}

String _stepSummary(VerifiedAdapterRecord? record) {
  if (record == null || record.stepResults.isEmpty) {
    return '无';
  }
  return record.stepResults
      .map((step) {
        final String status = step.skipped ? '⏭' : (step.passed ? '✅' : '❌');
        return '${step.stepKey}$status';
      })
      .join('  ');
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../application/providers/application_providers.dart';
import '../../../../domain/entities/adapter_manifest.dart';
import '../../../../domain/entities/verified_adapter_record.dart';
import '../../../../shared/widgets/toylink_background.dart';
import '../controllers/device_manager_controller.dart';

class DeviceManagerPage extends ConsumerStatefulWidget {
  const DeviceManagerPage({super.key});

  @override
  ConsumerState<DeviceManagerPage> createState() => _DeviceManagerPageState();
}

class _DeviceManagerPageState extends ConsumerState<DeviceManagerPage> {
  final TextEditingController _jsonController = TextEditingController();
  late final ProviderSubscription<DeviceManagerState> _importListener;

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
  }

  @override
  void dispose() {
    _importListener.close();
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

  @override
  Widget build(BuildContext context) {
    final DeviceManagerState state = ref.watch(deviceManagerControllerProvider);
    final recordsAsync = ref.watch(verifiedAdapterRecordsProvider);
    final activeStatus = ref.watch(activeDeviceStatusStreamProvider);
    final String? activeDeviceId = activeStatus.maybeWhen(
      data: (status) => status.deviceId,
      orElse: () => null,
    );
    final List<VerifiedAdapterRecord> records = recordsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <VerifiedAdapterRecord>[],
    );

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
                    const Text(
                      '建议先点“预检”查看结构与安全风险，再导入。也可用“表单生成”自动创建。',
                    ),
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
                                  final Map<String, Object?> sample =
                                      state.adapters.first.toJson();
                                  _jsonController.text = const JsonEncoder
                                      .withIndent('  ')
                                      .convert(sample);
                                },
                          child: const Text('填充示例'),
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
                          return ListTile(
                            dense: true,
                            title: Text(manifest.displayName),
                            subtitle: Text(
                              'ID: ${manifest.adapterId}\n'
                              'codec: ${manifest.codecKey}\n'
                              'version: ${manifest.version}\n'
                              '状态：$verifyLabel\n'
                              '$verifyTime\n'
                              '步骤：$stepSummary',
                            ),
                            trailing: OutlinedButton(
                              onPressed: () =>
                                  context.push('/verification/${manifest.adapterId}'),
                              child: const Text('开始验证'),
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
    return SwitchListTile(title: Text(label), value: value, onChanged: onChanged);
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
            content: Text(
              '你设置的 EMS 上限是 $emsMax，超过默认软上限 8。建议仅在充分确认风险后使用。',
            ),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Map<String, Object?> _buildManifestJson(int modeMax, int emsMax, int priority) {
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
  return record.stepResults.map((step) {
    final String status = step.skipped ? '⏭' : (step.passed ? '✅' : '❌');
    return '${step.stepKey}$status';
  }).join('  ');
}

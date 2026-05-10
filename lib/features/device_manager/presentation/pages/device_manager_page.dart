import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/entities/adapter_manifest.dart';
import '../../../../shared/widgets/toylink_background.dart';
import '../controllers/device_manager_controller.dart';

class DeviceManagerPage extends ConsumerStatefulWidget {
  const DeviceManagerPage({super.key});

  @override
  ConsumerState<DeviceManagerPage> createState() => _DeviceManagerPageState();
}

class _DeviceManagerPageState extends ConsumerState<DeviceManagerPage> {
  final TextEditingController _jsonController = TextEditingController();

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _openFormWizard() async {
    final Map<String, Object?>? result = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => const _AdapterWizardDialog(),
    );
    if (result == null) {
      return;
    }
    _jsonController.text = const JsonEncoder.withIndent('  ').convert(result);
  }

  @override
  Widget build(BuildContext context) {
    final DeviceManagerState state = ref.watch(deviceManagerControllerProvider);

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
                      '你可以粘贴外部逆向工具导出的 JSON。也可以点击“表单生成”，用向导自动生成基础适配器文件。',
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
                      ListTile(
                        dense: true,
                        title: Text(manifest.displayName),
                        subtitle: Text(
                          'ID: ${manifest.adapterId}\ncodec: ${manifest.codecKey}\nversion: ${manifest.version}',
                        ),
                        trailing: OutlinedButton(
                          onPressed: () =>
                              context.push('/verification/${manifest.adapterId}'),
                          child: const Text('开始验证'),
                        ),
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
  bool _writeWithoutResponse = true;
  bool _notifyRequired = false;

  @override
  void dispose() {
    _adapterId.dispose();
    _displayName.dispose();
    _blePrefix.dispose();
    _serviceUuid.dispose();
    _writeUuid.dispose();
    _notifyUuid.dispose();
    _codecKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('表单生成适配器'),
      content: SizedBox(
        width: 520,
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
                _field(_serviceUuid, 'serviceUuid', '服务 UUID'),
                _field(_writeUuid, 'writeCharacteristicUuid', '写入特征 UUID'),
                _field(_notifyUuid, 'notifyCharacteristicUuid', '通知特征 UUID'),
                SwitchListTile(
                  title: const Text('writeWithoutResponse'),
                  value: _writeWithoutResponse,
                  onChanged: (value) =>
                      setState(() => _writeWithoutResponse = value),
                ),
                SwitchListTile(
                  title: const Text('notifyRequired'),
                  value: _notifyRequired,
                  onChanged: (value) => setState(() => _notifyRequired = value),
                ),
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
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop(_buildManifestJson());
          },
          child: const Text('生成'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '该字段不能为空';
          }
          return null;
        },
      ),
    );
  }

  Map<String, Object?> _buildManifestJson() {
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
        'priority': 100,
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
        'supportsSuck': true,
        'supportsVibe': true,
        'supportsEms': true,
        'supportsSetAll': true,
        'supportsStopAll': true,
      },
      'ranges': <String, Object?>{
        'suckIntensity': <String, Object?>{'min': 0, 'max': 100},
        'vibeIntensity': <String, Object?>{'min': 0, 'max': 100},
        'emsIntensity': <String, Object?>{'min': 0, 'max': 20},
        'mode': <String, Object?>{'min': 1, 'max': 4},
      },
      'notes': '由 ToyLink AI 表单向导生成，可继续手动调整。',
    };
  }
}

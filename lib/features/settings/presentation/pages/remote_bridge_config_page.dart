import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/controllers/remote_bridge_config_controller.dart';
import '../../../../application/providers/application_providers.dart';
import '../../../../domain/entities/remote_bridge_config.dart';
import '../../../../domain/entities/remote_bridge_probe_result.dart';
import '../../../../shared/widgets/toylink_background.dart';

class RemoteBridgeConfigPage extends ConsumerStatefulWidget {
  const RemoteBridgeConfigPage({super.key});

  @override
  ConsumerState<RemoteBridgeConfigPage> createState() =>
      _RemoteBridgeConfigPageState();
}

class _RemoteBridgeConfigPageState
    extends ConsumerState<RemoteBridgeConfigPage> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _clientIdController;
  late final TextEditingController _clientTokenController;
  bool _enabled = false;
  bool _didSeedFields = false;
  bool _isTesting = false;
  RemoteBridgeProbeResult? _probeResult;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController();
    _clientIdController = TextEditingController(text: 'toylink-mobile-dev');
    _clientTokenController = TextEditingController();
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _clientIdController.dispose();
    _clientTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<RemoteBridgeConfig> configAsync = ref.watch(
      remoteBridgeConfigControllerProvider,
    );

    configAsync.whenData(_seedFieldsIfNeeded);

    return Scaffold(
      appBar: AppBar(title: const Text('远程桥接配置')),
      body: ToyLinkBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('启用真实远程桥接'),
                      subtitle: const Text(
                        '打开后，ToyLink 会优先使用你填写的公网 Bridge 地址，而不是本地 mock。',
                      ),
                      value: _enabled,
                      onChanged: configAsync.isLoading
                          ? null
                          : (bool value) {
                              setState(() {
                                _enabled = value;
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _baseUrlController,
                      enabled: !_isBusy(configAsync),
                      decoration: const InputDecoration(
                        labelText: 'Bridge 地址',
                        hintText: 'https://bridge.example.com',
                        helperText: '请填写公网可访问的 Bridge 根地址。',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _clientIdController,
                      enabled: !_isBusy(configAsync),
                      decoration: const InputDecoration(
                        labelText: '客户端 ID',
                        helperText: '默认值适合开发阶段，后续可按用户或设备分配。',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _clientTokenController,
                      enabled: !_isBusy(configAsync),
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '客户端令牌',
                        helperText: '令牌会保存在安全存储中，不会明文写入普通偏好设置。',
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_shouldShowValidation(configAsync))
                      Text(
                        '启用真实远程桥接前，请至少填写 Bridge 地址和客户端 ID。',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    if (configAsync.hasError) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        '配置读取失败，请稍后重试。',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (_probeResult != null) ...<Widget>[
                      const SizedBox(height: 12),
                      _ProbeResultCard(result: _probeResult!),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        FilledButton(
                          onPressed: _isBusy(configAsync)
                              ? null
                              : () => _save(context),
                          child: Text(
                            configAsync.isLoading ? '保存中...' : '保存配置',
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _isBusy(configAsync)
                              ? null
                              : () => _testConnection(context),
                          child: Text(_isTesting ? '测试中...' : '测试连接'),
                        ),
                        OutlinedButton(
                          onPressed: _isBusy(configAsync)
                              ? null
                              : () => _reset(context),
                          child: const Text('恢复默认'),
                        ),
                      ],
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

  bool _isBusy(AsyncValue<RemoteBridgeConfig> configAsync) {
    return configAsync.isLoading || _isTesting;
  }

  bool _shouldShowValidation(AsyncValue<RemoteBridgeConfig> configAsync) {
    return _enabled &&
        !configAsync.isLoading &&
        (_baseUrlController.text.trim().isEmpty ||
            _clientIdController.text.trim().isEmpty);
  }

  RemoteBridgeConfig _currentFormConfig() {
    return RemoteBridgeConfig(
      enabled: _enabled,
      baseUrl: _baseUrlController.text,
      clientId: _clientIdController.text,
      clientToken: _clientTokenController.text,
    ).normalized();
  }

  void _seedFieldsIfNeeded(RemoteBridgeConfig config) {
    if (_didSeedFields) {
      return;
    }
    _enabled = config.enabled;
    _baseUrlController.text = config.baseUrl;
    _clientIdController.text = config.clientId;
    _clientTokenController.text = config.clientToken;
    _didSeedFields = true;
  }

  Future<void> _reset(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    _didSeedFields = false;
    setState(() {
      _probeResult = null;
    });
    await ref.read(remoteBridgeConfigControllerProvider.notifier).reset();
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('远程桥接配置已恢复默认。')),
    );
  }

  Future<void> _save(BuildContext context) async {
    final RemoteBridgeConfig next = _currentFormConfig();
    if (!next.hasRequiredFields) {
      setState(() {});
      return;
    }
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    _didSeedFields = false;
    await ref.read(remoteBridgeConfigControllerProvider.notifier).save(next);
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(const SnackBar(content: Text('远程桥接配置已保存。')));
  }

  Future<void> _testConnection(BuildContext context) async {
    final RemoteBridgeConfig next = _currentFormConfig();
    if (!next.hasRequiredFields) {
      setState(() {
        _probeResult = const RemoteBridgeProbeResult(
          isSuccess: false,
          summary: '请先填写 Bridge 地址和客户端 ID。',
        );
      });
      return;
    }
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isTesting = true;
      _probeResult = null;
    });
    final RemoteBridgeProbeResult result = await ref
        .read(testRemoteBridgeConnectionUseCaseProvider)
        .execute(next);
    if (!mounted) {
      return;
    }
    setState(() {
      _isTesting = false;
      _probeResult = result;
    });
    messenger.showSnackBar(SnackBar(content: Text(result.summary)));
  }
}

class _ProbeResultCard extends StatelessWidget {
  const _ProbeResultCard({required this.result});

  final RemoteBridgeProbeResult result;

  @override
  Widget build(BuildContext context) {
    final Color tone = result.isSuccess
        ? Colors.green.shade700
        : Theme.of(context).colorScheme.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            result.summary,
            style: TextStyle(fontWeight: FontWeight.w600, color: tone),
          ),
          if (result.detail != null && result.detail!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(result.detail!),
          ],
        ],
      ),
    );
  }
}

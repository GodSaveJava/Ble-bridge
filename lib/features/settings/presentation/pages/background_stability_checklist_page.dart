import 'package:flutter/material.dart';

import '../../../../shared/widgets/toylink_background.dart';

class BackgroundStabilityChecklistPage extends StatefulWidget {
  const BackgroundStabilityChecklistPage({super.key});

  @override
  State<BackgroundStabilityChecklistPage> createState() =>
      _BackgroundStabilityChecklistPageState();
}

class _BackgroundStabilityChecklistPageState
    extends State<BackgroundStabilityChecklistPage> {
  bool _lockScreen30Min = false;
  bool _switchBackgroundAndBack = false;
  bool _autoReconnectAfterDisconnect = false;
  bool _mcpCallAvailableInBackground = false;

  @override
  Widget build(BuildContext context) {
    final bool allPassed = _lockScreen30Min &&
        _switchBackgroundAndBack &&
        _autoReconnectAfterDisconnect &&
        _mcpCallAvailableInBackground;

    return Scaffold(
      appBar: AppBar(title: const Text('后台稳定性验收清单')),
      body: ToyLinkBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const Card(
              child: ListTile(
                title: Text('使用说明'),
                subtitle: Text(
                  '请按顺序在真机上完成以下 4 项检查，全部通过后再进行对外演示或发布测试包。',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: <Widget>[
                  CheckboxListTile(
                    value: _lockScreen30Min,
                    onChanged: (value) =>
                        setState(() => _lockScreen30Min = value ?? false),
                    title: const Text('锁屏 30 分钟后连接仍保持'),
                  ),
                  CheckboxListTile(
                    value: _switchBackgroundAndBack,
                    onChanged: (value) => setState(
                      () => _switchBackgroundAndBack = value ?? false,
                    ),
                    title: const Text('切后台并返回前台后可继续控制'),
                  ),
                  CheckboxListTile(
                    value: _autoReconnectAfterDisconnect,
                    onChanged: (value) => setState(
                      () => _autoReconnectAfterDisconnect = value ?? false,
                    ),
                    title: const Text('蓝牙短断后自动重连成功'),
                  ),
                  CheckboxListTile(
                    value: _mcpCallAvailableInBackground,
                    onChanged: (value) => setState(
                      () => _mcpCallAvailableInBackground = value ?? false,
                    ),
                    title: const Text('后台状态下 MCP 调用可用'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: Text(allPassed ? '验收结果：通过' : '验收结果：未完成'),
                subtitle: Text(
                  allPassed
                      ? '四项检查均已通过，可以进入下一阶段。'
                      : '请继续完成未通过项，避免后台断连风险。',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

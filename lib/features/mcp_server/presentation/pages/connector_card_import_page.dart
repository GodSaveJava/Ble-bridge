import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../domain/connector_card_payload.dart';
import '../../../../shared/widgets/toylink_background.dart';

class ConnectorCardImportPage extends StatelessWidget {
  const ConnectorCardImportPage({required this.uri, super.key});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    final ConnectorCardPayload? payload = ConnectorCardPayload.tryParseDeepLink(
      uri,
    );
    final List<String> errors =
        payload?.validationErrors ?? const <String>['连接卡片链接缺少有效 payload。'];
    final bool isValid = payload != null && errors.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('导入连接卡片')),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          isValid
                              ? Icons.verified_outlined
                              : Icons.error_outline,
                          color: isValid
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                isValid ? '连接卡片已识别' : '连接卡片无法导入',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isValid
                                    ? '已解析 Safety V0 连接卡片。仍需要回到你的 AI 配置页完成接入，并用 get_status 做首次验证。'
                                    : '请确认二维码或 deep link 来自 ToyLink MCP 页，并且没有被截断或改写。',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!isValid) ...<Widget>[
                      for (final String error in errors)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            error,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ] else ...<Widget>[
                      _ConnectorCardPreview(payload: payload),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          FilledButton.icon(
                            onPressed: () => _copyCard(context, payload),
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('复制连接卡片'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/mcp'),
                            icon: const Icon(Icons.settings_ethernet, size: 18),
                            label: const Text('去 MCP 服务'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyCard(
    BuildContext context,
    ConnectorCardPayload payload,
  ) async {
    await Clipboard.setData(ClipboardData(text: payload.toPrettyJson()));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('连接卡片已复制')));
  }
}

class _ConnectorCardPreview extends StatelessWidget {
  const _ConnectorCardPreview({required this.payload});

  final ConnectorCardPayload payload;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _PreviewRow(label: '阶段', value: 'Safety V0'),
          _PreviewRow(label: '地址', value: payload.connectorUrl),
          _PreviewRow(label: 'Token', value: payload.maskedToken),
          _PreviewRow(label: '开放工具', value: payload.tools.join(' / ')),
          const SizedBox(height: 8),
          const Text('Phase 1 不开放 set_* 控制。'),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ToyLink AI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: ListTile(
              title: const Text('Device Status'),
              subtitle: const Text('No active device connected.'),
              trailing: FilledButton(
                onPressed: () => context.push('/scan'),
                child: const Text('Connect'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('MCP Service'),
              subtitle: const Text('Stopped'),
              trailing: FilledButton.tonal(
                onPressed: () => context.push('/mcp'),
                child: const Text('Open'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _QuickNavButton(
                label: 'Scan',
                onTap: () => context.push('/scan'),
              ),
              _QuickNavButton(
                label: 'Control',
                onTap: () => context.push('/control'),
              ),
              _QuickNavButton(
                label: 'Chat',
                onTap: () => context.push('/chat'),
              ),
              _QuickNavButton(
                label: 'Settings',
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title page is planned in next implementation phase.'),
      ),
    );
  }
}

class _QuickNavButton extends StatelessWidget {
  const _QuickNavButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: OutlinedButton(onPressed: onTap, child: Text(label)),
    );
  }
}

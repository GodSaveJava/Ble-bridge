enum ControlChannel { suck, vibe, ems }

enum CommandSource { ui, mcp, system }

class ControlCommand {
  const ControlCommand({
    required this.channel,
    required this.intensity,
    required this.mode,
    required this.source,
    required this.requestedAt,
    this.requiresConfirmation = false,
  });

  final ControlChannel channel;
  final int intensity;
  final int mode;
  final CommandSource source;
  final DateTime requestedAt;
  final bool requiresConfirmation;
}

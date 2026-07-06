class RemoteBridgeTaskAssignment {
  const RemoteBridgeTaskAssignment({
    required this.requestId,
    required this.tool,
    this.input = const <String, Object?>{},
  });

  final String requestId;
  final String tool;
  final Map<String, Object?> input;
}
